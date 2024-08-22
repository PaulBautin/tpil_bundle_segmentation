# tpil_bundle_segmentation

## Usage
This repository uses output folder of tractoflow to segment a bundle of interest. Here are the steps to segment bundles of interest you might need singularity and nextflow (installation instructions are present in next section):

<details><summary><b>Steps</b></summary>

  1. `git clone https://github.com/PaulBautin/tpil_bundle_segmentation.git` this will clone this repository in a new folder *tpil_bundle_segmentation*
  2. Download ressourcess and put into *tpil_bundle_segmentation* folder  

     - Prebuild Singularity images ([scilus_1.6.0.sif](https://scil.usherbrooke.ca/containers/scilus_1.6.0.sif)): https://scil.usherbrooke.ca/pages/containers/
     - Brainnetome atlas in MNI space ([BN_Atlas_246_1mm.nii.gz](https://pan.cstcloud.cn/s/gfGflpp3Q0E)): https://atlas.brainnetome.org/download.html
     - FA template in MNI space ([FSL_HCP1065_FA_1mm.nii.gz](https://pitt-my.sharepoint.com/:u:/g/personal/yehfc_pitt_edu/EV3F_eZvN6NDv-PN4I05dzwBu1kLrqnK_N6VplznsVQv0Q?e=wXGOo7)): https://brain.labsolver.org/hcp_template.html
  4. Open file `run_bundle_segmentation.sh` in file editor and modify all "my_*" file paths
  5. Run (in output result folder) with: `bash run_bundle_segmentation.sh`. The code can be run with other parcels by modifying `--source_ROI`, `--target_ROI`, and other bundle streamline outlier removal variable `--outlier_alpha` in the main run bash file `run_bundle_segmentation.sh`
</details>

<details><summary><b>Output</b></summary>
By default outputs will be stored in `results_bundle`.

                                        [results_bundle]
                                        ├── sub-001_ses-v1
                                        │   ├── Apply_transform (Atlas in diffusion space)
                                        │   ├── bundle_QC_screenshot (png screenshot of the bundle)
                                        |   ├── Register_Anat (Computation of the transform that sends MNI template to diffusion space)
                                        |   ├── Register_Bundle (Bundle in MNI space)
                                        |   ├── Subcortex_registration (Subcortical segmentation in diffusion space)
                                        |   ├── Subcortex_segmentation (FSL FIRST Subcortical segmentation in T1 space)
                                        |   ├── Tractography_filtering (trk files of: source ROI projections, bundle and bundle cleaned)
                                        ├── sub-002_ses-v1
                                        |   └── *
                                        ├── Bundle_Pairwise_Comparaison_Inter_Subject
                                        └── Bundle_Pairwise_Comparaison_Intra_Subject

</details>

<details><summary><b>Tractometry</b></summary>
  
To run Tractometry on the segmented bundle the [combine_flows/tree_for_tractometry.sh](https://github.com/scilus/combine_flows/blob/main/tree_for_tractometry.sh) must be slightly modified. Use `tree_for_tractometry_p.sh` present in this directory to add the segmented bundle to to the tractometry pipeline tree.
</details>

## Installations
<details><summary><b>Nextflow</b></summary>

Follow SCIL nextflow installation procedure: [https://scil-documentation.readthedocs.io/en/latest/arriving/setup_computer.html#nextflow](https://scil-documentation.readthedocs.io/en/latest/arriving/setup_computer.html#nextflow)

Optionally, move the nextflow file to a directory accessible by your $PATH variable (this is only required to avoid remembering and typing the full path to nextflow each time you need to run it). Example: `sudo mv ~/Downloads/nextflow /usr/local/bin`

You can temporarily switch to a specific version of Nextflow by prefixing the nextflow command with the NXF_VER environment variable. For example: `NXF_VER=20.04.0 nextflow run`
</details>
<details><summary><b>Singularity (Apptainer)</b></summary>

Singularity (Apptainer) is used to package scientific software and deploy that package to different clusters having the same environment. However, it is a linux only friendly platform (use Docker to run locally with mac or windows). Installation intructions can be found: [https://scil-documentation.readthedocs.io/en/latest/arriving/setup_computer.html#apptainer](https://scil-documentation.readthedocs.io/en/latest/arriving/setup_computer.html#apptainer)

Launch `run_bundle_segmentation.sh` and make sure nextflow is run with option: `-with-singularity $my_singularity_img`
</details>
<details><summary><b>Docker</b></summary>

Contrary to Apptainer, Docker containers cannot run without elevated privileges or root access; therefore, Docker is not available on High Performance Computers from the Digital Alliance of Canada. Installation intructions can be found: [https://scil-documentation.readthedocs.io/en/latest/arriving/setup_computer.html#docker](https://scil-documentation.readthedocs.io/en/latest/arriving/setup_computer.html#docker)

Once docker is installed, it is possible to run command: `docker pull scilus/scilus:1.6.0`

Launch `run_bundle_segmentation.sh` and make sure nextflow is run with option: `-with-docker scilus/scilus:1.6.0`
</details>

## Testing
Tested locally on 3 subjects `ses_v1`. FSL (with command run_first_all) must be installed locally. WAS NOT TESTED on compute canada because FSL FIRST is not in the SCIl Singularity container anymore -- a solution would be to use another container.


## How it works?
Parcel to parcel segmentation: was carried out using a pipeline developed by our laboratory using Nextflow. The pipeline consists of 4 main steps. (i) first apply FSL First to the T1-w images processed by Tractoflow (without registration) and register the T1-w image to the DWI image (b=0) -- to avoid redundancy in label names, 1000 was added to the generic FSL First labels. (ii) registration of the Brainnetome atlas (located in MNI space) to the diffusion space using the FA template (HCP-1065 in MNI space) and the FA reference image in diffusion space, (iii) creation of masks of the mPFC (Brainnetome atlas regions : 27) and NAc (FSL FIRST regions: 26), (iv) filter the tractogram by removing streamlines that don't join the mPFC and NAC masks or have outlier shapes (filtering by clustering or rejecting outlier streamlines with the function scil_outlier_rejection. py and α = 0.4, tested with α = 0.6)

**Alternative not presented in the code that uses Freesurfer:** Plot-by-plot beam segmentation with Freesurfer and FSL: the NextFlow pipeline requires the results of Freesurfer recon-all and consists of 3 main steps: (i) first apply FSL First to the T1-w images processed by Tractoflow (without registration) and register the T1-w image to the DWI image (b=0). (ii) Apply Brainnetome's Freesufer gaussian classifier atlas (GCs) to parcel/label each subject's cortical surface with mris_ca_label and then create volumes with each subject's Brainnetome surface parcelization by projecting the labels along the normal to the Freesurfer surface with mri_label2vol and re-align the volumes to the DWI image (b=0) (iii) Concatenate the FSL First and Freesurfer segmentations in the same image (to avoid redundancy in label names, 1000 was added to the generic FSL First labels).



