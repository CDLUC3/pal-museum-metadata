# pal-museum-metadata
Metadata validation and packaging tools for Merritt Ingest.

This code will be run from a Cloud9 environment into which the following resources have been loaded.

## File structure
- an inventory listing of existing tif files residing in S3
  - /mrt/inventory/inventory.txt
- mods files describing the tif files
  - /mrt/mods
- temp dir for pulling tif file samples
  - /mrt/files
- code directory
  - /home/ec2-user/environment/code/pal-museum-metadata

## Running the code
```
cd ~/environment
python code/pal-museum-metadata/src/scan.py 
```
