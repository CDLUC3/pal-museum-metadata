## Build

```
cd /home/ec2-user/environment/code/pal-museum-metadata/src-ruby
bundle install
```

## Run

```
ruby app.rb
```

## Results

Page through output files

_Press 'q' to exit file preview_

```
less output/has_match.txt
less output/no_image.txt
less output/no_mods.txt
less output/mismatch_key.txt
less output/metadata.tsv
```

Preview generated manifests
```
less /mrt/output/manifests/0001/0001.01.0033.checkm 
```
