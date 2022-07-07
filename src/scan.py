#!/usr/bin/python3

# pip3 install pyyaml
# import configparser
import os
import re
import json
import pprint
import csv

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
        self.ids.append(re.sub(r'\.xml$', '', os.path.basename(file)));
        
print("Pal Museum Mods Report")
scan = Scan()
scan.report()
