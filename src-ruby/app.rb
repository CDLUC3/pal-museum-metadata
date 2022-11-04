require 'nokogiri'

class Inventory
    def self.output_dir
        "/mrt/output"
    end
    
    def self.merritt_user
        ENV.fetch('MERRITT_USER', 'foo')
    end

    def self.merritt_password
        ENV.fetch('MERRITT_PASSWORD', 'bar')
    end

    def self.merritt_instance
        ENV.fetch('MERRITT_INSTANCE', 'merritt-stage')
    end
    
    def self.show_settings
        puts("export MERRITT_USER='#{self.merritt_user}'")
        puts("export MERRITT_PASSWORD='#{self.merritt_password}'")
        puts("export MERRITT_INSTANCE='#{self.merritt_instance}'")
    end
    
    def initialize
        @invalid_filename = []
        @scripts = {}
        @mds = {}
        @mds_stats = {}
        @path = "/mrt/inventory/inventory.txt"
        @titles = "/mrt/files/title.txt"
        @inventory = {}
        %x[ rm -rf #{Inventory.output_dir}/* ]
    end
    
    def scripts
        @scripts
    end

    def mds
        @mds
    end

    def mds_stats
        @mds_stats
    end
    
    def read_inventory
        count = 0
        File.open(@path).each do |line|
            next if line =~ %r[( mods\/| consistency-reports| mrt\/| scan-review\/|sorttable.js|palmu.db.sql| index.html| README.md| api-table| _config.yml)]
            m = line.match(%r[\/([^\/]*)\.(bmp|mp3|jpg|pdf|jpeg|png|tiff|tif)$]i)
            if (m) 
                key = m[1]
                mm = key.match(%r[^([^.]+\.[^.]+\.[^.]+)\..*$])
                key = mm[1] if mm
                count += 1
                mods = getMods(key)
                mods.addFile(line[31..], line[20..30])
                addToInventory(mods)
            else
                @invalid_filename.push("#{line[31..]} (#{line[20..30].strip})") unless line =~ %r[(\/|\.db)$]
            end
        end
        puts "Inventory Records Found: #{count}"
    end

    def read_titles
        count = 0
        File.open(@titles).each do |line|
            arr = line.split("\t")
            next if arr.length != 3
            key = arr[0].gsub(%r[http.*$], '')
            count += 1
            mods = getMods(key)
            mods.setTitle(arr[2].gsub(%r[http.*$], ''))
            addToInventory(mods)
        end
        puts "Title Records Found: #{count}"
    end
    
    def register_md(m)
        k = m.md_file_key
        @mds[k] = @mds.fetch(k, [])
        @mds[k].push(m.get_md)
        @mds_stats[k] = @mds_stats.fetch(k, 0) + 1 if m.has_metadata
    end

    def register_script(m)
        script = m.write_script
        @scripts[script] = @scripts.fetch(script, 0) + 1
    end
    
    def getMods(key)
        @inventory[key] = ModsFile.new(key) unless @inventory.key?(key)
        @inventory[key]
    end
    
    def addToInventory(mods)
       @inventory[mods.key] = mods
    end
    
    def report
        has_match = []
        no_image = []
        no_mods = []
        bad_file = []
        mismatch_key = []
        invalid_key = []
        invalid_filename = @invalid_filename

        @inventory.keys.sort.each do |k|
            m = @inventory[k]
            if m.valid_key
                if m.has_match
                    has_match.push(k) 
                elsif m.no_image
                    no_image.push(k)
                end

                unless m.has_metadata
                    if m.has_bad_file
                        bad_file.push(k)
                    else
                        no_mods.push(k) 
                    end
                end
            else
                invalid_key.push(k)
            end
            mismatch_key.push(k) if m.mismatch_key
        end
        
        File.open("#{Inventory.output_dir}/index.md", "w") do |f|
          f.write("# Pal Museum Metadata Analysis\n")
          f.write("\n## Questions \n")
          f.write("- For the missing collection names, can we supplement that from the Museum Website? \n")
          f.write("- For the objects missing metadata, how much could be found from the museum website? \n")
          f.write("- Is the available content across all collections or just specific ones? \n")
          f.write("- Can we convey any meaning without mods data? \n")
          f.write("- If the database is unhelpful, could a finding aid exist that could provide skeletal metadata? \n")

          f.write("\n## Analysis of Content \n")
          f.write("- [Inventory](/inventory)\n")
          f.write("- [Titles - from Database Dump](/titles)\n")
          f.write("- [Metadata Spreadsheet](/output/metadata.tsv)\n")
          puts "Has Image and Mods: #{has_match.length}"
          f.write("- [Has Image and Mods: #{has_match.length}](/output/has_match.md)\n")
          puts "Has Mods Only - No Images:  #{no_image.length}"
          f.write("- [Has Mods Only - No Images: #{no_image.length}](/output/no_image.md)\n")
          puts "Has Image Only - No Metadata:   #{no_mods.length}"
          f.write("- [Has Image Only - No Metadata: #{no_mods.length}](/output/no_mods.md)\n")
          puts "Has Metadata Only - Bad Image Names:   #{bad_file.length}"
          f.write("- [Has Metadata Only - Bad Image Name: #{bad_file.length}](/output/bad_file.md)\n")
          puts "Mods Key Name does not match filename:   #{mismatch_key.length}"
          f.write("- [Mods Key Name does not match filename: #{mismatch_key.length}](/output/mismatch_key.md)\n")
          puts "Unsupported File Type:   #{invalid_filename.length}"
          f.write("- [Unsupported File Type: #{invalid_filename.length}](/output/invalid_filename.md)\n")
          puts "Invalid Object Key:   #{invalid_key.length}"
          f.write("- [Invalid Object Key: #{invalid_key.length}](/output/invalid_key.md)\n")
        end
        
        write_arr("#{Inventory.output_dir}/has_match.md", "Has Image and Mods", has_match)
        write_arr("#{Inventory.output_dir}/no_mods.md", "Has Image Only - No Metadata", no_mods)
        write_arr("#{Inventory.output_dir}/no_image.md", "Has Metadata Only - No Images", no_image)
        write_arr("#{Inventory.output_dir}/bad_file.md", "Has Metadata Only - Bad Image Name", bad_file)
        write_arr("#{Inventory.output_dir}/mismatch_key.md", "Mods Key Name does not match filename", mismatch_key)
        write_str("#{Inventory.output_dir}/invalid_filename.md", "Unsupported File Type", invalid_filename)
        write_arr("#{Inventory.output_dir}/invalid_key.md", "Object Key Does not Match Expected Pattern", invalid_key)
        
        File.open("#{Inventory.output_dir}/metadata.tsv", "w") do |tsv|
            tsv.write("who\twhat\twhen\twhere\timg_count\n")
            has_match.each do |k|
                @inventory[k].write_erc(tsv)
            end
        end

        has_match.each do |k|
            m = @inventory[k]
            m.write_manifest
            register_script(m)
            m.write_obj_md
            register_md(m)
        end

        invalid_key.each do |k|
            m = @inventory[k]
            m.write_manifest
            m.write_obj_md
            register_md(m)
        end

        bad_file.each do |k|
            m = @inventory[k]
            m.write_manifest
            m.write_obj_md
            register_md(m)
        end

        no_mods.each do |k|
            m = @inventory[k]
            m.write_manifest
            register_script(m)
            m.write_obj_md
            register_md(m)
        end
    
        File.open("#{Inventory.output_dir}/index.md", "a") do |f|
          f.write("\n## Markdown Files \n\n")
          @mds.keys.sort.each do |k|
              p = 0
              p = @mds_stats.fetch(k, 0) * 100 / @mds[k].length if @mds[k].length > 0
              f.write("- [`#{k}` (#{@mds[k].length} - #{p}%)](/output/#{k}.md)\n")
              File.open("#{Inventory.output_dir}/#{k}.md", "w") do |mdf|
                 mdf.write("\n[Home](/output/index.md)\n\n")
                 @mds[k].sort.each do |line|
                    mdf.write(line)
                 end
              end
          end

          f.write("\n## Script Files \n\n")
          @scripts.keys.each do |k|
              f.write("- [`#{k}` (#{@scripts[k]})](#{k})\n")
          end
        end
    end
    
    def write_file_ext_counts(f, arr)
        exts = {}
        arr.each do |k|
            if @inventory.key?(k)
                m = @inventory[k]
                m.images.each do |i|
                    ext = i.split(".")[-1].strip.downcase
                    exts[ext] = exts.fetch(ext, 0) + 1
                end
            end
        end
        f.write("\n\n### File Extension Counts\n")
        exts.each do |ext|
            f.write("- #{ext}: #{exts[ext]}\n")
        end
    end
    
    def write_record(f, m, as_md)
        if as_md
            f.write("- `#{m.key_sanitized}`; ")
            f.write("[Metadata](/erc/#{m.key_sanitized});  #{m.dbtitle}.") if m.has_match
            f.write("[#{m.images.length} img.](/checkm/#{m.key_sanitized}) ") if m.images.length > 0 
            f.write("\n")
        else
            f.write("#{m.key_sanitized}; ")
            f.write("#{m.dbtitle}.") if m.has_metadata
            f.write("#{m.images.length} img. ") if m.images.length > 0 
            f.write("\n")
        end
    end
    
    def write_arr(fname, header, arr)
        File.open(fname, "w") do |f|
            f.write("# #{header}: #{arr.length}\n")
            f.write("\n[Home](/output/index.md)\n\n")
            write_file_ext_counts(f, arr)
            
            f.write("\n\n### Object Keys - Valid Keys\n")
            
            as_md = arr.length < 50000
            f.write("\n\n<pre>\n") unless as_md
            arr.each do |k|
                m = @inventory[k]
                next unless m.valid_key
                write_record(f, m, as_md)
            end
            f.write("\n\n</pre>\n") unless as_md

            f.write("\n\n### Object Keys - Invalid Keys\n")
            f.write("\n\n<pre>\n") unless as_md
            arr.each do |k|
                m = @inventory[k]
                next if m.valid_key
                write_record(f, m, as_md)
            end
            f.write("\n\n</pre>\n") unless as_md
        end
    end

    def write_str(fname, header, arr)
        exts = {}
        arr.each do |k|
            ext = k.split(' (')[0].split(".")[-1].strip.downcase
            exts[ext] = exts.fetch(ext, 0) + 1
        end

        File.open(fname, "w") do |f|
            f.write("# #{header}: #{arr.length}\n")
            f.write("\n[Home](/output/index.md)\n\n")

            f.write("\n\n### File Extension Counts\n")
            exts.keys.sort.each do |ext|
                f.write("- #{ext}: #{exts[ext]}\n")
            end

            f.write("\n\n##Keys\n\n<pre>")
            arr.each do |k|
               f.write("#{k.gsub(%r[\n], ' ')}\n")
            end
            f.write("</pre>\n")
        end
    end
end

class Scan
    def initialize
        @path = "/mrt/mods"
        @ndir = 0;
        @nfile = 0;
    end
    
    def scan(inventory, dir = @path)
        
        Dir.foreach(dir) do |d|
            next if d == "."
            next if d == ".."
            
            fd = "#{dir}/#{d}"
            if File.directory?(fd)
                @ndir += 1;
                scan(inventory, fd)
            else
                next unless fd.downcase =~ %r[\.xml$]
                @nfile += 1
                process(inventory, fd)
            end
        end
    end
    
    def status
        #puts "Dirs Scanned:  #{@ndir}"
        #puts "Files Scanned: #{@nfile}"
    end
    
    def process(inventory, fd)
        key = File.basename(fd).gsub(".xml", "").gsub("_", ".")
        modsfile = inventory.getMods(key)
        modsfile.parse(fd)
    end
end

class ModsFile
    def initialize(key)
        @key = key
        @images = []
        @file_size = []
        @mods = ""
        @dbtitle = ""
        @title_trans = ""
        @title = ""
        @who = ""
        @when = ""
        @idnum = ""
        @id = ""
        @coll = ""
        @where = "pal_museum_#{key}"
    end
    
    def setTitle(t)
        @dbtitle = t.strip
    end
    
    def dbtitle
        return @dbtitle if @coll.empty?
        "#{@dbtitle}. The #{@coll} Collection." 
    end
    
    def has_dbtitle
        !@dbtitle.empty?
    end
    
    def key
        @key
    end
    
    def key_sanitized
        @key.gsub(%r[^a-zA-Z0-9\.], '_')
    end
    
    def valid_key
        @key =~ %r[^[0-9]{4,4}\.[0-9]+\.[0-9]+$]
    end
    
    def addFile(f, size)
        fs = f.strip.gsub(' ', '%20')
        if f =~ %r[2022-10-08-xfer\/]
          f = f.gsub(%r[2022-10-08-xfer\/], '').gsub(%r[\/(tiff|TIFF|mp3)\/], '/')
        end
        @images.push(fs)
        @file_size.push(size.strip.to_i)
        m = f.match(%r[^[0-9]{4,4} ? ?- ?([^\/]*)\/])
        m2 = f.match(%r[^([0-9]{4,4})\/])
        if m
          @coll = m[1]
        elsif (m2)
          @coll = m2[1]
        else
          puts f
        end
    end
    
    def file_size
        @file_size
    end
    
    def has_bad_file
        @file_size.each do |sz|
            return true if sz < 5000
        end
        false
    end
    
    def image_count
        @images.length
    end
    
    def images
        @images
    end
    
    def fname
        File.basename(@mods)
    end
    
    def parse(fd)
        @mods = fd
        doc = Nokogiri::XML(File.open(fd))
        @title_trans = doc.xpath("//mods:titleInfo/mods:title[@type='translated']/text()").to_s
        @title_trans = "#{@title_trans}. The #{@coll} Collection." unless @coll.empty?
        whos = []
        doc.xpath("//mods:name[mods:role/mods:roleTerm[contains(.,'creator')]]/mods:namePart[not(@type)]/text()").each do |t|
            whos.push(t.to_s)
        end
        @who = whos[0]
        @when = doc.xpath("//mods:originInfo/mods:dateCreated[not(@type)]/text()").to_s
        titles = []
        doc.xpath("//mods:titleInfo/mods:title[@lang]/text()").each do |t|
            titles.push(t.to_s)
        end
        @title = titles.join(" ")
        @idnum = doc.xpath("//mods:identifier[@type='local']/text()[not(contains(., '.'))]").to_s
        @id = doc.xpath("//mods:identifier[@type='local']/text()[contains(., '.')]").to_s
        @where = "pal_museum_#{id}"
    end
    
    def has_match
        @images.length > 0 && has_metadata
    end
    
    def has_metadata
        !@mods.empty? || !@dbtitle.empty?
    end
    
    def no_mods
        return false if has_match
        @mods.empty?
    end

    def no_image
        return false if has_match
        @images.length == 0
    end
    
    def id
        @id
    end

    def where
        @where
    end
    
    def idnum
        @idnum
    end

    def mods
        @mods
    end

    def title
        @title.gsub('"', ' ')
    end

    def who
        @who.gsub('"', ' ')
    end

    def when
        @when
    end

    def title_trans
        @title_trans.gsub('"', ' ')
    end
    
    def mismatch_key
        return false if @id.empty?
        return false if @key == @id
        true
    end
    
    def print
        puts "Key: #{@key}"
        puts "\tMods:   #{@mods}" unless @mods.empty?
        puts "\tTitle*: #{@title_trans}" unless @title_trans.empty?
        puts "\tTitle:  #{@title}" unless @title.empty?
        puts "\tNum:    #{@id}" unless @id.empty?
        puts "\tId:     #{@idnum}" unless @idnum.empty?
        puts "\tImgCnt: #{image_count}"
    end
    
    def manifest_dir
        if valid_key
            dir = @key.split(".")[0]
        else
            dir = 'invalid_key_dir'
        end
        "#{Inventory.output_dir}/#{dir}"
    end

    def script_file
        dir = @key.split(".")[0]
        "#{Inventory.output_dir}/#{dir}.sh"
    end

    def md_file_key
        if valid_key
            dir = @key.split(".")[0]
        else
            dir = 'invalid_key'
        end
        dir
    end

    def manifest_file
        "#{manifest_dir}/#{key_sanitized}.checkm"
    end

    def obj_md_file
        "#{manifest_dir}/#{key_sanitized}.md"
    end

    def erc_file
        "#{manifest_dir}/#{key}.erc"
    end
    
    def write_script
        return if mismatch_key
        File.open(script_file, "a") do |f|
            f.write("curl -u '#{Inventory.merritt_user}:#{Inventory.merritt_password}' -H 'Accept: application/json' \\\n")
            f.write("-F 'file=@#{manifest_dir}/#{key}.checkm' \\\n")
            f.write("-F 'type=manifest' \\\n")
            f.write("-F 'submitter=foo/PalMuseum' \\\n")
            f.write("-F 'responseForm=xml' \\\n")   
            f.write("-F 'profile=merritt_demo_content' \\\n")
            f.write("-F \"title=#{@title_trans}\" \\\n")
            f.write("-F \"creator=#{@who}\" \\\n")
            f.write("-F 'date=#{@when}' \\\n")
            f.write("-F 'localIdentifier=#{@where}' \\\n")
            f.write("https://#{Inventory.merritt_instance}.cdlib.org/object/update\n\n")
        end
        script_file
    end

    def get_md
        return if mismatch_key
        m = has_metadata ? "": "No metadata."
        v = valid_key ? "" : "Invalid Key."
        "- [#{key}.md](/output/#{md_file_key}/#{key}.md) #{image_count} img. #{@dbtitle}. #{m} #{v}\n"
    end
    
    def write_manifest
        return if mismatch_key
        %x[ mkdir -p #{manifest_dir} ]
        File.open(manifest_file, "w") do |f|
            f.write("#%checkm_0.7\n")
            f.write("#%profile | http://uc3.cdlib.org/registry/ingest/manifest/mrt-ingest-manifest\n")
            f.write("#%prefix | mrt: | http://merritt.cdlib.org/terms#\n")
            f.write("#%prefix | nfo: | http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#\n")
            f.write("#%fields | nfo:fileurl | nfo:hashalgorithm | nfo:hashvalue | nfo:filesize | nfo:filelastmodified | nfo:filename | mrt:mimetype\n")
            f.write("http://uc3-mrtdocker01x2-dev.cdlib.org:8097/mods/#{fname} |  |  |  |  | #{fname} | \n") unless no_mods
            @images.each do |im|
                f.write("http://uc3-mrtdocker01x2-dev.cdlib.org:8097/image/#{im} |  |  |  |  | #{File.basename(im)} | \n")
            end
            f.write("#%eof\n")
        end
    end

    def write_obj_md
        %x[ mkdir -p #{manifest_dir} ]
        File.open(obj_md_file, "w") do |f|
            f.write("\n[Home](/output/index.md)\n\n")
            f.write("## dbtitle: #{@dbtitle}\n")
            f.write("## who: #{@who}\n")
            f.write("## what: #{@title_trans}\n")
            f.write("## when: #{@when}\n")
            f.write("## where: `#{@where}`\n")

            f.write("- [mods](/mods/#{key_sanitized})\n") unless no_mods
            @images.each_with_index do |im,i|
                f.write("- [#{File.basename(im)} (#{@file_size[i]})](/image/#{im})\n")
            end
        end
    end
    
    def write_erc(tsv)
        return if mismatch_key
        %x[ mkdir -p #{manifest_dir} ]
        File.open(erc_file, "w") do |f|
            f.write("erc:\n")
            f.write("who: #{@who}\n")
            f.write("what: #{@title_trans}\n")
            f.write("when: #{@when}\n")
            f.write("where: #{@where}\n")
        end
        tsv.write(@who)
        tsv.write("\t")
        tsv.write(@title_trans)
        tsv.write("\t")
        tsv.write(@when)
        tsv.write("\t")
        tsv.write(@where)
        tsv.write("\t")
        tsv.write(@images.length)
        tsv.write("\n")
    end
        
end

Inventory.show_settings
inventory = Inventory.new
inventory.read_inventory
inventory.read_titles
scan = Scan.new
scan.scan(inventory)
scan.status
inventory.report
