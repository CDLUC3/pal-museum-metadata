## Build

```
cd /home/ec2-user/environment/code/pal-museum-metadata/src-ruby
bundle install
```

## Run The Metadata Generator

```
ruby app.rb
```

## Run the preview server

- Right click "server.rb" and click "Run".
- Click the link that reads "Your code is running at ..."

## To view files without the preview server...

Page through output files

_Press 'q' to exit file preview_

```
less output/has_match.txt
less output/no_image.txt
less output/no_mods.txt
less output/mismatch_key.txt
less output/metadata.tsv
```

Preview generated manifests and erc files
```
less /mrt/output/manifests/0001/0001.01.0033.checkm 
less /mrt/output/manifests/0001/0001.01.0033.erc 
```
