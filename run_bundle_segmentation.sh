#!/bin/bash

# This would run the TPIL Bundle Segmentation Pipeline with the following resources:
#     Prebuild Singularity images: https://scil.usherbrooke.ca/pages/containers/
#     Brainnetome atlas in MNI space: https://atlas.brainnetome.org/download.html
#     FA template in MNI space: https://brain.labsolver.org/hcp_template.html


# my_singularity_img='/Users/pascaltravail/Dropbox/Prof_Sherbrooke/Recherche/Projets_humains/Resultats/Diffusion/Test_Paul_pipeline_accumbo/scilus_1.6.0.sif' # or .sif
# main file for run_bundle segmentation
my_main_nf='/Users/pascaltravail/Dropbox/Prof_Sherbrooke/Recherche/Projets_humains/Resultats/Diffusion/Test_Paul_pipeline_accumbo/tpil_bundle_segmentation/main.nf'
# Results folder of tractoflow
my_input_tr='/Users/pascaltravail/Dropbox/Prof_Sherbrooke/Recherche/Projets_humains/Resultats/Diffusion/Test_Paul_pipeline_accumbo/results_tractoflow'
# Brainnetome atlas (the same space as commonly used by the scil)
my_atlas='/Users/pascaltravail/Dropbox/Prof_Sherbrooke/Recherche/Projets_humains/Resultats/Diffusion/Test_Paul_pipeline_accumbo/BN_Atlas_246_1mm.nii.gz'
# FSL_HCP1065_FA_1mm template (the same space as commonly used by the scil)
my_template='/Users/pascaltravail/Dropbox/Prof_Sherbrooke/Recherche/Projets_humains/Resultats/Diffusion/Test_Paul_pipeline_accumbo/FSL_HCP1065_FA_1mm.nii.gz'


nextflow run $my_main_nf \
    --input_tr $my_input_tr \
    --atlas $my_atlas \
    --template $my_template \
    --source_roi 1026 \
    --target_roi 27 \
    --outlier_alpha 0.4 \
    --bundle_name 'accumbofrontal' \
    -with-docker scilus/scilus:1.6.0 -resume \ 
    -profile macos # uncomment for use with macos
    # for use with docker container: -with-docker scilus/scilus:1.6.0
    


#my_main_nf_qc='/home/pabaua/dev_scil/dmriqc_flow/main.nf'
#my_input_qc='/home/pabaua/Documents/UdeS/2022-Aut_IMN-708/TP/data/Data_TP3/bundle_segmentation_results'

#NXF_VER=21.10.6 nextflow run $my_main_nf_qc -profile rbx_qc --input $my_input_qc \
#    -with-singularity $my_singularity_img -resume

