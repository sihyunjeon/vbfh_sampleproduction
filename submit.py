#!/usr/bin/env python3
import os, sys

fragmentFile = sys.argv[1]
jobName = fragmentFile.split("/")[1].split(".")[0]

nEvents = sys.argv[2]
nJobs = sys.argv[3]

os.system(f"mkdir -p {jobName}")
os.system(f"cp {fragmentFile} {jobName}/fragment.py")
os.system(f"cp templates/condor.jds {jobName}/")
os.system(f"cp templates/pileupinput.txt {jobName}/")
os.system(f"cp templates/run.sh {jobName}/")

os.system(f"sed -i 's|@@jobName@@|{jobName}|g' {jobName}/condor.jds")
os.system(f"sed -i 's|@@nEvents@@|{nEvents}|g' {jobName}/condor.jds")
os.system(f"sed -i 's|@@nJobs@@|{nJobs}|g' {jobName}/condor.jds")

os.chdir(jobName)
#os.system("condor_submit condor.jds")
os.chdir("..")
