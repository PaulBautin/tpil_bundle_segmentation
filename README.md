# tpil_bundle_segmentation

### Usage
Run (in output result folder) with: `bash run_bundle_segmentation.sh`

### Ressources:
Prebuild Singularity images: https://scil.usherbrooke.ca/pages/containers/

Brainnetome atlas in MNI space: https://atlas.brainnetome.org/download.html

FA template in MNI space: https://brain.labsolver.org/hcp_template.html 

### Testing 
Tested locally on 3 subjects `ses_v1`. FSL (with command run_first_all) must be installed locally. WAS NOT TESTED on compute canada because FSL FIRST is not in the SCIl Singularity container anymore -- a solution would to be use another container.

Can be tested with other parcels by modifying `process Tractography_filtering`

### How it works?
Parcel to parcel segmentation: was carried out using a pipeline developed by our laboratory using Nextflow. The pipeline consists of 4 main steps. (i) first apply FSL First to the T1-w images processed by Tractoflow (without registration) and register the T1-w image to the DWI image (b=0). (ii) registration of the Brainnetome atlas (located in MNI space) to the diffusion space using the FA template (HCP-1065 in MNI space) and the FA reference image in diffusion space, (iii) creation of masks of the mPFC (Brainnetome atlas regions : 27) and NAc (FSL FIRST regions: 26), (iv) filter the tractogram by removing streamlines that don't join the mPFC and NAC masks or have outlier shapes (filtering by clustering or rejecting outlier streamlines with the function scil_outlier_rejection. py and α = 0.4, tested with α = 0.6)

**Alternative not presented in the code that uses Freesurfer:** Plot-by-plot beam segmentation with Freesurfer and FSL: the NextFlow pipeline requires the results of Freesurfer recon-all and consists of 3 main steps: (i) first apply FSL First to the T1-w images processed by Tractoflow (without registration) and register the T1-w image to the DWI image (b=0). (ii) Apply Brainnetome's Freesufer gaussian classifier atlas (GCs) to parcel/label each subject's cortical surface with mris_ca_label and then create volumes with each subject's Brainnetome surface parcelization by projecting the labels along the normal to the Freesurfer surface with mri_label2vol and re-align the volumes to the DWI image (b=0) (iii) Concatenate the FSL First and Freesurfer segmentations in the same image (to avoid redundancy in label names, 1000 was added to the generic FSL First labels).


