#!/usr/bin/python3

# pip3 install pyyaml
# import configparser
import os
import re
import json
import pprint
import csv
from xml.dom.minidom import parse

class Scan:
    def __init__(self):
        self.mods = "/mrt/mods"
        self.ids = []

    def report(self):
        files = []
        self.reportDir(files, self.mods)
        for entry in files:
            self.reportFile(entry)
        for id in self.ids:
            print(id)


    def reportDir(self, list, dir):
        with os.scandir(dir) as entries:
            for entry in entries:
                if (entry.is_dir()):
                    self.reportDir(list, entry)
                else:
                    list.append(os.path.join(dir, entry.name))

    def reportFile(self, file):
        doc = parse(file)
        nl = doc.getElementsByTagName("mods:identifier")
        print(os.path.basename(file))
        for i in range(0, nl.length-1):
            print(nl.item(i).firstChild.nodeValue)
        base = re.sub(r'\.xml$', '', os.path.basename(file))
        self.ids.append(base);
        
print("Pal Museum Mods Report")
scan = Scan()
scan.report()
