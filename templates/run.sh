# Run private production using RunIIFall18GS settings.
# Local example:
# source run.sh MyMCName /path/to/fragment.py 1000 1 1 filelist:/path/to/pileup/list.txt
echo $@

if [ -z "$1" ]; then
    echo "Argument 1 (name of job) is mandatory."
    return 1
fi
NAME=$1

if [ -z $2 ]; then
    echo "Argument 2 (fragment path) is mandatory."
    return 1
fi
FRAGMENT=$2
echo "Input arg 2 = $FRAGMENT"
FRAGMENT=$(readlink -e $FRAGMENT)
echo "After readlink fragment = $FRAGMENT"

if [ -z "$3" ]; then
    NEVENTS=10
else
    NEVENTS=$3
fi

if [ -z "$4" ]; then
    JOBINDEX=1
else
    JOBINDEX=$4
fi

if [ -z "$5" ]; then
    MAX_NTHREADS=8
else
    MAX_NTHREADS=$5
fi

RSEED=$(($(date +%s) % 100000 + 1))

PILEUP_FILELIST="filelist:pileupinput.txt"

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "Job index=$JOBINDEX"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"
echo "Pileup filelist=$PILEUP_FILELIST"

TOPDIR=$PWD

# wmLHEGS
export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_12_4_14_patch3/src ] ; then 
    echo release CMSSW_12_4_14_patch3 already exists
    cd CMSSW_12_4_14_patch3/src
    eval `scram runtime -sh`
else
    cmsrel CMSSW_12_4_14_patch3
    cd CMSSW_12_4_14_patch3/src
    eval `scram runtime -sh`
fi

mkdir -pv $CMSSW_BASE/src/Configuration/GenProduction/python
cp $FRAGMENT $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py
if [ ! -f "$CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py" ]; then
    echo "Fragment copy failed"
    exit 1
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

#cat $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py

cmsDriver.py Configuration/GenProduction/python/fragment.py \
    --python_filename "Run3Summer22wmLHEGS_${NAME}_cfg.py" \
    --eventcontent RAWSIM,LHE \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM,LHE \
    --fileout "file:Run3Summer22wmLHEGS_${NAME}_${JOBINDEX}.root" \
    --conditions 124X_mcRun3_2022_realistic_v12 \
    --beamspot Realistic25ns13p6TeVEarly2022Collision \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --era Run3 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --customise_commands "process.source.numberEventsInLuminosityBlock=cms.untracked.uint32(1000)\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}" \
    --mc \
    -n $NEVENTS 

cmsRun "Run3Summer22wmLHEGS_${NAME}_cfg.py"
if [ ! -f "Run3Summer22wmLHEGS_${NAME}_${JOBINDEX}.root" ]; then
    echo "Run3Summer22wmLHEGS_${NAME}_${JOBINDEX}.root not found. Exiting."
    return 1
fi


# DRPremix
export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_12_4_14_patch3/src ] ; then
    echo release CMSSW_12_4_14_patch3 already exists
    cd CMSSW_12_4_14_patch3/src
    eval `scram runtime -sh`
else
    cmsrel CMSSW_12_4_14_patch3
    cd CMSSW_12_4_14_patch3/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "Run3Summer22DRPremix_step1_${NAME}_cfg.py" \
    --eventcontent PREMIXRAW \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM-RAW \
    --filein "file:Run3Summer22wmLHEGS_${NAME}_${JOBINDEX}.root" \
    --fileout "file:Run3Summer22DRPremix_step1_${NAME}_${JOBINDEX}.root" \
    --pileup_input "$PILEUP_FILELIST" \
    --conditions 124X_mcRun3_2022_realistic_v12 \
    --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2022v12 \
    --procModifiers premix_stage2,siPixelQualityRawToDigi \
    --geometry DB:Extended \
    --datamix PreMix \
    --era Run3 \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS

cmsRun "Run3Summer22DRPremix_step1_${NAME}_cfg.py"
if [ ! -f "Run3Summer22DRPremix_step1_${NAME}_${JOBINDEX}.root" ]; then
    echo "Run3Summer22DRPremix_step1_${NAME}_${JOBINDEX}.root not found. Exiting."
    return 1
fi
rm Run3Summer22wmLHEGS_${NAME}_${JOBINDEX}.root

cmsDriver.py \
    --python_filename "Run3Summer22DRPremix_step2_${NAME}_cfg.py" \
    --eventcontent AODSIM \
    --datatier AODSIM \
    --filein "file:Run3Summer22DRPremix_step1_${NAME}_${JOBINDEX}.root" \
    --fileout "file:Run3Summer22DRPremix_step2_${NAME}_${JOBINDEX}.root" \
    --conditions 124X_mcRun3_2022_realistic_v12 \
    --step RAW2DIGI,L1Reco,RECO,RECOSIM \
    --procModifiers premix_stage2,siPixelQualityRawToDigi \
    --geometry DB:Extended \
    --era Run3 \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS

cmsRun "Run3Summer22DRPremix_step2_${NAME}_cfg.py"
if [ ! -f "Run3Summer22DRPremix_step2_${NAME}_${JOBINDEX}.root" ]; then
    echo "Run3Summer22DRPremix_step2_${NAME}_${JOBINDEX}.root not found. Exiting."
    return 1
fi
rm Run3Summer22DRPremix_step1_${NAME}_${JOBINDEX}.root

# MINIAODSIM
export SCRAM_ARCH=el8_amd64_gcc11
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_13/src ] ; then
    echo release CMSSW_13_0_13 already exists
    cd CMSSW_13_0_13/src
    eval `scram runtime -sh`
else
    cmsrel CMSSW_13_0_13
    cd CMSSW_13_0_13/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "Run3Summer22MiniAODv4_${NAME}_cfg.py" \
    --eventcontent MINIAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier MINIAODSIM \
    --filein "file:Run3Summer22DRPremix_step2_${NAME}_${JOBINDEX}.root" \
    --fileout "file:Run3Summer22MiniAODv4_${NAME}_${JOBINDEX}.root" \
    --conditions 130X_mcRun3_2022_realistic_v5 \
    --step PAT \
    --geometry DB:Extended \
    --era Run3,run3_miniAOD_12X \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS
 
cmsRun "Run3Summer22MiniAODv4_${NAME}_cfg.py"
if [ ! -f "Run3Summer22MiniAODv4_${NAME}_${JOBINDEX}.root" ]; then
    echo "Run3Summer22MiniAODv4_${NAME}_${JOBINDEX}.root not found. Exiting."
    return 1
fi
rm Run3Summer22DRPremix_step2_${NAME}_${JOBINDEX}.root

# NanoAOD
export SCRAM_ARCH=el8_amd64_gcc11
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_13/src ] ; then
    echo release CMSSW_13_0_13 already exists
    cd CMSSW_13_0_13/src
    eval `scram runtime -sh`
else
    cmsrel CMSSW_13_0_13
    cd CMSSW_13_0_13/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "Run3Summer22NanoAODv12_${NAME}_cfg.py" \
    --filein "file:Run3Summer22MiniAODv4_${NAME}_${JOBINDEX}.root" \
    --fileout "file:Run3Summer22NanoAODv12_${NAME}_${JOBINDEX}.root" \
    --eventcontent NANOAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier NANOAODSIM \
    --conditions 130X_mcRun3_2022_realistic_v5 \
    --step NANO \
    --scenario pp \
    --era Run3 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \ \
    --mc \
    -n $NEVENTS

cmsRun "Run3Summer22NanoAODv12_${NAME}_cfg.py"
if [ ! -f "Run3Summer22NanoAODv12_${NAME}_${JOBINDEX}.root" ]; then
    echo "Run3Summer22NanoAODv12_${NAME}_${JOBINDEX}.root not found. Exiting."
    return 1
fi

xrdfs root://cluster142.knu.ac.kr/ mkdir -p /store/user/shjeon/SAMPLEPRODUCTION/${NAME}
xrdcp Run3Summer22MiniAODv4_${NAME}_${JOBINDEX}.root root://cluster142.knu.ac.kr//store/user/shjeon/SAMPLEPRODUCTION/${NAME}/
rm *.root
rm *.py
