#!/usr/bin/env nextflow
nextflow.enable.dsl=2

if(params.help) {
    usage = file("$baseDir/USAGE")
    cpu_count = Runtime.runtime.availableProcessors()

    bindings = ["outlier_alpha":"$params.outlier_alpha",
                "cpu_count":"$cpu_count"]

    engine = new groovy.text.SimpleTemplateEngine()
    template = engine.createTemplate(usage.text).make(bindings)
    print template.toString()
    return
}

log.info ""
log.info "TPIL Bundle Segmentation Pipeline"
log.info "=================================="
log.info "Start time: $workflow.start"
log.info ""
log.info "[Input info]"
log.info "Input TractoFlow Folder: $params.input_tr"
log.info "Atlas: $params.atlas"
log.info "Template: $params.template"
log.info ""
log.info "[Filtering options]"
log.info "Outlier Removal Alpha: $params.outlier_alpha"
log.info "Source ROI: $params.source_roi"
log.info "Target ROI: $params.target_roi"
log.info ""

if (!(params.atlas) | !(params.template)) {
    error "You must specify an atlas and a template with command line flags. --atlas and --template, "
}

workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    log.info "Execution duration: $workflow.duration"
}


process Subcortex_segmentation {
    input:
    tuple val(sid), path(T1nativepro_brain)

    output:
    tuple val(sid), file("${sid}__all_fast_firstseg.nii.gz"), emit: sub_parcels

    script:
    """
    run_first_all -i ${T1nativepro_brain} -o ${sid}_ -b -v
    """
}


process Subcortex_registration {
    input:
    tuple val(sid), path(sub_parcels), path(affine), path(warp), file(t1_diffpro_brain)

    output:
    tuple val(sid), file("${sid}__all_fast_firstseg_warped.nii.gz"), emit: sub_parcels_diff
    tuple val(sid), file(t1_diffpro_brain)

    script:
    """
    antsApplyTransforms -d 3 -i ${sub_parcels} -r ${t1_diffpro_brain} \
        -o ${sid}__all_fast_firstseg_warped.nii.gz -n genericLabel \
        -t ${warp} ${affine}  
    scil_image_math.py addition ${sid}__all_fast_firstseg_warped.nii.gz 1000 ${sid}__all_fast_firstseg_warped.nii.gz --exclude_background --data_type int16 -f
    """
}

process Register_Anat {
    input:
    tuple val(sid), file(fa_diff_brain), file(template)

    output:
    tuple val(sid), file("${sid}__output0GenericAffine.mat"), file("${sid}__output1Warp.nii.gz"), emit: transformations
    tuple val(sid), file("${sid}__fa_diff_brain.nii.gz"), emit: fa_diff_brain

    script:
    """
    antsRegistrationSyNQuick.sh -d 3 -f ${fa_diff_brain} -m ${template} -t s -o ${sid}__output
    cp ${fa_diff_brain} ${sid}__fa_diff_brain.nii.gz
    """
}

process Apply_transform {
    input:
    tuple val(sid), file(affine), file(warp), file(fa_diff_brain), file(atlas)

    output:
    tuple val(sid), file("${sid}__atlas_transformed.nii.gz"), emit: atlas_transformed

    script:
    """
    antsApplyTransforms -d 3 -i ${atlas} -t ${warp} -t ${affine} -r ${fa_diff_brain} -o ${sid}__atlas_transformed.nii.gz -n genericLabel -u int
    """
}

process Tractography_filtering {
    input:
    tuple val(sid), path(tracto_pft), path(seg_first), file(atlas_transformed)

    output:
    tuple val(sid), file("${bname}__source_proj.trk"), file("${bname}__${params.bundle_name}.trk")
    tuple val(sid), file("${bname}__${params.bundle_name}_cleaned.trk"), emit: cleaned_bundle

    script:
    bname = tracto_pft.name.split('.trk')[0]
    """
    scil_image_math.py convert ${seg_first} seg_first.nii.gz --data_type uint16 -f
    scil_filter_tractogram.py ${tracto_pft} ${bname}__source_proj.trk --atlas_roi ${seg_first} $params.source_roi any include -f -v

    scil_filter_tractogram.py ${bname}__source_proj.trk ${bname}__${params.bundle_name}.trk --atlas_roi ${atlas_transformed} $params.target_roi any include -f -v
    scil_outlier_rejection.py ${bname}__${params.bundle_name}.trk ${bname}__${params.bundle_name}_cleaned.trk --alpha $params.outlier_alpha
    """
}


process Register_Bundle {
    input:
    tuple val(sid), file(bundle), file(affine), file(warp), file(template)

    output:
    tuple val(sid), file("${bname}_mni.trk")

    script:
    bname = bundle.name.split('.trk')[0]
    """
    scil_apply_transform_to_tractogram.py $bundle $template $affine ${bname}_mni.trk --in_deformation $warp --reverse_operation
    """
}

process Bundle_Pairwise_Comparaison_Inter_Subject {
    publishDir = {"./results_bundle/$task.process/$b_name"}
    input:
    tuple val(b_name), file(bundles)

    output:
    tuple val(b_name), file("${b_name}.json")

    script:
    """
    scil_evaluate_bundles_pairwise_agreement_measures.py $bundles ${b_name}.json
    """
}

process Bundle_Pairwise_Comparaison_Intra_Subject {
    publishDir = {"./results_bundle/$task.process/$sid"}
    input:
    tuple val(sid), val(b_names), file(bundles)

    output:
    tuple val(sid), file("${b_names}_Pairwise_Comparaison.json")

    script:
    """
    scil_evaluate_bundles_pairwise_agreement_measures.py $bundles ${b_names}_Pairwise_Comparaison.json
    """
}

process bundle_QC_screenshot {
    input:
    tuple val(sid), file(bundle), file(ref_image)

    output:
    tuple val(sid), file("${sid}__${bname}.png")

    script:
    bname = bundle.name.split("__")[1].split('_L_')[0]
    """
    scil_visualize_bundles_mosaic.py $ref_image $bundle ${sid}__${bname}.png -f --light_screenshot --no_information
    """
}


workflow {
    // Input files to fetch
    input_tractoflow = file(params.input_tr)
    atlas = Channel.fromPath("$params.atlas")
    template = Channel.fromPath("$params.template")

    t1_nativepro_brain = Channel.fromPath("$input_tractoflow/*/Crop_T1/*__t1_bet_cropped.nii.gz").map{[it.parent.parent.name, it]}
    t1_diffpro_brain = Channel.fromPath("$input_tractoflow/*/Register_T1/*__t1_warped.nii.gz").map{[it.parent.parent.name, it]}
    t1_to_diff_affine = Channel.fromPath("$input_tractoflow/*/Register_T1/*__output0GenericAffine.mat").map{[it.parent.parent.name, it]}
    t1_to_diff_warp = Channel.fromPath("$input_tractoflow/*/Register_T1/*__output1Warp.nii.gz").map{[it.parent.parent.name, it]}
    t1_to_diff_inv_warp = Channel.fromPath("$input_tractoflow/*/Register_T1/*__output1InverseWarp.nii.gz").map{[it.parent.parent.name, it]}

    fa_diff_brain = Channel.fromPath("$input_tractoflow/*/DTI_Metrics/*__fa.nii.gz").map{[it.parent.parent.name, it]}

    dwi_tracto_pft = Channel.fromPath("$input_tractoflow/*/PFT_Tracking/*__pft_tracking_prob_wm_seed_0.trk").map{[it.parent.parent.name, it]}

    main:
    // Subcortex segmentation with first
    Subcortex_segmentation(t1_nativepro_brain)

    // Subcortex segmentation registration to diffusion space add 1000 to parcels to not be confused with cortex
    Subcortex_segmentation.out.sub_parcels.combine(t1_to_diff_affine, by:0).combine(t1_to_diff_warp, by:0).combine(t1_diffpro_brain, by:0).set{data_sub_reg}
    Subcortex_registration(data_sub_reg)

    // Register template (same space as the atlas and same contrast as the reference image) to reference image
    fa_diff_brain.combine(template).set{data_registration}
    Register_Anat(data_registration)

    // Appy registration transformation to atlas
    Register_Anat.out.transformations.join(fa_diff_brain, by:0).combine(atlas).set{data_transfo}
    Apply_transform(data_transfo)

    // filter tractogram first on NAc (parcel 1026) then on mPFC (parcel 27)
    dwi_tracto_pft.combine(Subcortex_registration.out.sub_parcels_diff, by:0).combine(Apply_transform.out.atlas_transformed, by:0).set{data_tracto_filt}
    Tractography_filtering(data_tracto_filt)

    // Register bundles in common template space
    Tractography_filtering.out.cleaned_bundle.combine(Register_Anat.out.transformations, by:0).combine(template).set{bundle_registration}
    Register_Bundle(bundle_registration)

    // Compute inter-subject pairwise bundle comparaison
    Register_Bundle.out.map{[it[1].name.split('_ses-')[1].split('_cleaned')[0], it[1]]}.groupTuple(by:0).set{bundle_comparaison_inter}
    Bundle_Pairwise_Comparaison_Inter_Subject(bundle_comparaison_inter)

    // Compute intra-subject pairwise bundle comparaison
    Register_Bundle.out.map{[it[0].split('_ses')[0], it[1].name.split('__')[1].split('_cleaned')[0], it[1]]}.groupTuple(by:[0,1]).set{bundle_comparaison_intra}
    Bundle_Pairwise_Comparaison_Intra_Subject(bundle_comparaison_intra)

    // Take screenshot of every bundle
    Tractography_filtering.out.cleaned_bundle.combine(fa_diff_brain, by:0).set{bundles_for_screenshot}
    bundle_QC_screenshot(bundles_for_screenshot)
}
