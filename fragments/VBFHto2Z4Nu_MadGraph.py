import FWCore.ParameterSet.Config as cms
 
externalLHEProducer = cms.EDProducer('ExternalLHEProducer',
    args = cms.vstring('/cvmfs/cms.cern.ch/phys_generator/gridpacks/PdmV/Run3Summer22/MadGraph5_aMCatNLO/NewTests/VBFH_madgraph-pythia8_slc7_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz'),
    nEvents = cms.untracked.uint32(5000),
    numberOfParameters = cms.uint32(1),
    outputFile = cms.string('cmsgrid_final.lhe'),
    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh'),
    generateConcurrently = cms.untracked.bool(False)
)
 
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunesRun3ECM13p6TeV.PythiaCP5Settings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *
 
generator = cms.EDFilter("Pythia8ConcurrentHadronizerFilter",
    PythiaParameters = cms.PSet(
        pythia8CommonSettingsBlock,
        pythia8CP5SettingsBlock,
        pythia8PSweightsSettingsBlock,
        processParameters = cms.vstring(
            'SpaceShower:dipoleRecoil = on',
            'TimeShower:mMaxGamma = 4.0',
            '25:m0 = 125.0',
            '25:onMode = off',
            '25:onIfMatch = 23 23', ## H -> ZZ
            '23:onMode = off',      # turn OFF all Z decays
            '23:onIfAny = 12 14 16',# turn ON Z->ll
        ),
        parameterSets = cms.vstring(
            'pythia8CommonSettings',
            'pythia8CP5Settings',
            'pythia8PSweightsSettings',
            'processParameters'
        )
    ),
    comEnergy = cms.double(13600),
    maxEventsToPrint = cms.untracked.int32(1),
    pythiaHepMCVerbosity = cms.untracked.bool(False),
    pythiaPylistVerbosity = cms.untracked.int32(1),
)

