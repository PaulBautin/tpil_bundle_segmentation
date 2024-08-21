#!/bin/bash

# This would run the TPIL Bundle Segmentation Pipeline with the following resources:
#     Prebuild Singularity images: https://scil.usherbrooke.ca/pages/containers/
#     Brainnetome atlas in MNI space: https://atlas.brainnetome.org/download.html
#     FA template in MNI space: https://brain.labsolver.org/hcp_template.html


my_singularity_img='/home/pabaua/dev_scil/containers/containers_scilus_1.6.0.sif' # or .sif
# main file for run_bundle segmentation
my_main_nf='/home/pabaua/dev_tpil/tpil_bundle_segmentation/main.nf'
# Results folder of tractoflow
my_input_tr='/home/pabaua/dev_tpil/results/results_tracto/23-09-01_tractoflow_bundling'
# Brainnetome atlas (the same space as commonly used by the scil)
my_atlas='/home/pabaua/dev_tpil/data/BN/BN_Atlas_for_FSL/Brainnetome/BNA-maxprob-thr0-1mm.nii.gz'
# FSL_HCP1065_FA_1mm template (the same space as commonly used by the scil)
my_template='/home/pabaua/dev_tpil/data/HCP/FSL_HCP1065_FA_1mm.nii.gz'


nextflow run $my_main_nf \
    --input_tr $my_input_tr \
    --atlas $my_atlas \
    --template $my_template \
    -with-singularity $my_singularity_img -resume


#my_main_nf_qc='/home/pabaua/dev_scil/dmriqc_flow/main.nf'
#my_input_qc='/home/pabaua/Documents/UdeS/2022-Aut_IMN-708/TP/data/Data_TP3/bundle_segmentation_results'

#NXF_VER=21.10.6 nextflow run $my_main_nf_qc -profile rbx_qc --input $my_input_qc \
#    -with-singularity $my_singularity_img -resume

