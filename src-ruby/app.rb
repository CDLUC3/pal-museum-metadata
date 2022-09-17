require 'nokogiri'

class Inventory
    def initialize
        @path = "/mrt/inventory/inventory.txt"
        @inventory = {}
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
        
        @inventory.keys.sort.each do |k|
            m = @inventory[k]
            has_match.push(k) if m.has_match
            no_image.push(k) if m.no_image
            no_mods.push(k) if m.no_mods
        end
        
        puts "Has Match: #{has_match.length}"
        puts "No Image:  #{no_image.length}"
        puts "No Mods:   #{no_mods.length}"
        
        write_arr("has_match.txt", has_match)
        write_arr("no_mods.txt", no_mods)
        write_arr("no_image.txt", no_image)
    end
    
    def write_arr(fname, arr)
        File.open(fname, "w") do |f|
            arr.each do |k|
                m = @inventory[k]
                f.write("#{k} - #{m.image_count} images, id=#{m.id}\n")
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
        puts "Dirs Scanned:  #{@ndir}"
        puts "Files Scanned: #{@nfile}"
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
        @idnum = ""
        @id = ""
    end
    
    def key
        @key
    end
    
    def addFile(f)
        @images.push(f)
    end
    
    def image_count
        @images.length
    end
    
    def parse(fd)
        @mods = fd
        doc = Nokogiri::XML(File.open(fd))
        @title_trans = doc.xpath("//mods:titleInfo/mods:title[@type='translated']/text()")
        titles = []
        doc.xpath("//mods:titleInfo/mods:title[@lang]/text()").each do |t|
            titles.push(t)
        end
        @title = titles.join(" ")
        @idnum = doc.xpath("//mods:identifier[@type='local']/text()[not(contains(., '.'))]")
        @id = doc.xpath("//mods:identifier[@type='local']/text()[contains(., '.')]")
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
    
    def idnum
        @idnum
    end

    def mods
        @mods
    end
    def title
        @title
    end

    def title_trans
        @title_trans
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
end

inventory = Inventory.new
inventory.read_inventory
scan = Scan.new
scan.scan(inventory)
scan.status
inventory.report
