# tpil_bundle_segmentation

### Usage
Verify that the atlas and the template are in the same space with: `scil_verify_space_attributes_compatibility.py`

Create dataset tree from TractoFlow ouptut with: `tree_for_bundle_segmentation.sh`

Run with: `run_bundle_segmentation.sh`

### Ressources:
Prebuild Singularity images: https://scil.usherbrooke.ca/pages/containers/

Brainnetome atlas in MNI space: https://atlas.brainnetome.org/download.html

FA template in MNI space: https://brain.labsolver.org/hcp_template.html 

### Testing 
Tested locally on 2 subjects `ses_v1` and remotely (Compute Canada) on 73 subjects `ses_v1`, `ses_v2` and `ses_v3`. 


