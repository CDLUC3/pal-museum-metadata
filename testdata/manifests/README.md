Sample ingested object using pm.checkm: https://merritt-stage.cdlib.org/m/ark%253A%252F99999%252Ffk4cz4r82j

ERC metadata added manually through the Merritt UI.

## Final delivery

- Create an [object manifest](https://github.com/CDLUC3/mrt-doc/wiki/Manifests#i-a-single-object) for every Pal Museum object
- We will copy these manifests to S3 or some other web server
- Create a [batch manifest](https://github.com/CDLUC3/mrt-doc/wiki/Manifests#iv-a-batch-of-object-manifest-files) that references each of these object manifests
  - The batch manifest will contain the url to an object manifest + ERC metadata
  
[Merritt Manifest Tool](https://cdluc3.github.io/mrt-doc/manifest/index.html?unittest=1)
