require 'nokogiri'

class Inventory
    def self.output_dir
        "/mrt/output"
    end
    
    def initialize
        @path = "/mrt/inventory/inventory.txt"
        @inventory = {}
        %x[ rm -rf #{Inventory.output_dir}/output/* ]
    end
    
    def read_inventory
        count = 0
        File.open(@path).each do |line|
            m = line.match(%r[\/([^\/]*)\.(tif|jpg)$]i)
            if (m) 
                key = m[1]
                mm = key.match(%r[([^.]+\.[^.]+\.[^.]+)\.*$])
                key = mm[1] if mm
                count += 1
                mods = getMods(key)
                mods.addFile(line[31..])
                addToInventory(mods)
            end
        end
        puts "Inventory Records Found: #{count}"
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
        mismatch_key = []
        
        @inventory.keys.sort.each do |k|
            m = @inventory[k]
            has_match.push(k) if m.has_match
            no_image.push(k) if m.no_image
            no_mods.push(k) if m.no_mods
            mismatch_key.push(k) if m.mismatch_key
        end
        
        File.open("output/index.md", "w") do |f|
          f.write("# Pal Museum Metadata Analysis\n")
          puts "Has Image and Mods: #{has_match.length}"
          f.write("- [Has Image and Mods: #{has_match.length}](/output/has_match.md)\n")
          puts "Has Mods Only - No Images:  #{no_image.length}"
          f.write("- [Has Mods Only - No Images: #{no_image.length}](/output/no_image.md)\n")
          puts "Has Image Only - No Mods:   #{no_mods.length}"
          f.write("- [Has Image Only - No Mods: #{no_mods.length}](/output/no_mods.md)\n")
          puts "Mods Key Name does not match filename:   #{mismatch_key.length}"
          f.write("- [Mods Key Name does not match filename: #{mismatch_key.length}](/output/mismatch_key.md)\n")
        end
        
        write_arr("output/has_match.md", "Has Image and Mods", has_match)
        write_arr("output/no_mods.md", "Has Image Only - No Mods", no_mods)
        write_arr("output/no_image.md", "Has Mods Only - No Images", no_image)
        write_arr("output/mismatch_key.md", "Mods Key Name does not match filename", no_image)
        
        File.open("output/metadata.tsv", "w") do |tsv|
            tsv.write("who\twhat\twhen\twhere\timg_count\n")
            has_match.each do |k|
                @inventory[k].write_manifest
                @inventory[k].write_erc(tsv)
            end
        end
    end
    
    def write_arr(fname, header, arr)
        File.open(fname, "w") do |f|
            f.write("# #{header}: #{arr.length}\n")
            arr.each do |k|
                m = @inventory[k]
                f.write("- *#{k}*  - #{m.image_count} images; ")
                if m.has_match
                  f.write("[checkm](/checkm/#{k}), ")
                  f.write("[erc](/erc/#{k}), ")
                end    
                if m.no_mods == false
                  f.write("[mods](/mods/#{k}); ")
                end
                m.images.each_with_index do |im, i|
                  f.write(", ") if i > 0
                  f.write("[Img #{i+1}](/image/#{im)})")
                end
                f.write("\n")
            end
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
        @mods = ""
        @title_trans = ""
        @title = ""
        @who = ""
        @when = ""
        @idnum = ""
        @id = ""
    end
    
    def key
        @key
    end
    
    def addFile(f)
        fs = f.strip.gsub(' ', '%20')
        @images.push(fs)
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
        whos = []
        doc.xpath("//mods:name[mods:role/mods:roleTerm[contains(.,'creator')]]/mods:namePart[not(@type)]/text()").each do |t|
            whos.push(t.to_s)
        end
        @who = whos.join("; ")
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
        @images.length > 0 && !@mods.empty?
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
        @title
    end

    def who
        @who
    end

    def when
        @when
    end

    def title_trans
        @title_trans
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
        dir = @key.split(".")[0]
        "#{Inventory.output_dir}/#{dir}"
    end

    def manifest_file
        "#{manifest_dir}/#{key}.checkm"
    end

    def erc_file
        "#{manifest_dir}/#{key}.erc"
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
            f.write("http://uc3-mrtdocker01x2-dev.cdlib.org:8097/mods/#{fname} |  |  |  |  | #{fname} | \n")
            @images.each do |im|
                f.write("http://uc3-mrtdocker01x2-dev.cdlib.org:8097/image/#{im} |  |  |  |  | #{File.basename(im)} | \n")
            end
            f.write("#%eof\n")
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

inventory = Inventory.new
inventory.read_inventory
scan = Scan.new
scan.scan(inventory)
scan.status
inventory.report
