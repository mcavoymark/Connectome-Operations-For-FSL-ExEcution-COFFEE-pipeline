#!/usr/bin/env bash

RUNNAME=run3_LH # should be set by creator script
HCPDIR=/Users/bphilip/Documents/HCP # this never gets called - instead, SUBJDIR
OUTDIR=/Users/bphilip/Documents/hcp2feat/output220517_BP/${RUNNAME}/reg # this "reg" dir must be copied into FSL run directory
SUBJDIR=/Users/bphilip/Documents/10_Connectivity/10_200/pipeline/ # output of pipeline

# Direct placement of output folder. Omitted for testing.
# Needs improvement: if dir doesn't exist, will create an error message that should be ignored. And creates problems if you run this script repeatedly (since then you just overwrite reg+)
#mv ${SUBJDIR}/${RUNNAME}/reg ${SUBJDIR}/${RUNNAME}/reg+ # remove preexisting directory - this one you'll recreate
#mv ${SUBJDIR}/${RUNNAME}/reg_standard ${SUBJDIR}/${RUNNAME}/reg_standard+ # remove preexisting directory - this one is not needed
#OUTDIR=${SUBJDIR}/${RUNNAME}/reg # Direct placement of output folder

mkdir -p ${OUTDIR}


cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/example_func2standard.mat ${OUTDIR}/example_func2standard.mat
cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/highres2standard.mat ${OUTDIR}/highres2standard.mat
cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/${RUNNAME}_SBRef.nii.gz ${OUTDIR}/example_func.nii.gz #CHANGED
cp -p ${SUBJDIR}/MNINonLinear/T1w_restore.2.nii.gz ${OUTDIR}/highres_head.nii.gz #CHANGED2
cp -p ${SUBJDIR}/MNINonLinear/T1w_restore.2_brain.nii.gz ${OUTDIR}/highres.nii.gz #CHANGED- CURRENTLY MAKING THIS MANUALLY IN FSL-BET
cp ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${OUTDIR}/standard_head.nii.gz
cp ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${OUTDIR}/standard.nii.gz
#