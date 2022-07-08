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

## Goals
- What becomes a Merritt Object
- What identifier(s) will be used
  - This will be used for any metadata updates 
  - What if we get access to the database
- What metadata will be stored with the images
- What percent objects have / do not have images and metadata
- Create Merritt ingest manifest file(s) for each object
  - Has identifier(s)
  - Has erc descriptive metadata
  - Has full file list
    - Url to the mods files
      - Terry will build a web service to make these accessible to the ingest service 
    - Url to the image files
      - Terry will build a web service to make these accessible to the ingest process 