Hello from the test branch!

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

## Saving Changes to GitHub

This Cloud9 environment is shared by members of the UC3 team.

Therefore, it will be important to not save your github credentials into this working environement.

All of our code will live in a public repository, so it will be easy to pull code into this environment.

```
git fetch origin main
```

When you want to save changes back to GitHub, you have a few options
- push the changes from Cloud9 to GitHub
  - you will need to provide github credentials each time you push
  - because you have 2FA enabled (a good thing!), you will need to use a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) to save your work
    - Create a Personal Access Token
    - Name it something like "Leading Fellows Token"
    - Set the expiration date for the end of the fellowship
    - Enable only "public_repo" for this token
    - Save the generated token in a safe place that will be easy to copy/paste
  - When you are prompted for a username and password
    - use your github username for username
    - use your personal access token as a password
- make the changes through the github website
- clone the repository to your PC and push the changes from there

```
git push origin main
```

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
      - Terry will build a web service to make these accessible to the ingest service (done)
    - Url to the image files
      - Terry will build a web service to make these accessible to the ingest process (done)

## Tasks

### Weeks 1-3 (does this include travel time?) - starting Aug 9
- Analyze match between files in the inventory vs identifiers in mods
  - List of matching image and metadata
  - List images missing metadata
  - List metadata missing images
- Recommend local identifier(s) to utilize likely some form of: 0001.02.0001
- Map mods fields to Merritt erc
- Hand generate a manifest file for a single Pal Museum object (urls depend on where mods and images are served)
  - Create ingest manifest for an object with one or more files; supply metadata through Merritt UI
- Load hand generated manifest to Merritt stage

### Next steps
- Generate list of files per object identifier
- Create ingest manifests for objects with one or more files; create a manifest of manifests to supply corresponding metadata


## Questions to answer
- Where should the web server run for the image files?
  - Any UC3 dev or stage machine
- Where should the url run for the mods files
  - Will need to copy them 
  - Will need to think through processing if we modify the mods content
