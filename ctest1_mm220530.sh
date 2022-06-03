#!/usr/bin/env bash

if((${#@}<2));then
    echo "$0 <SUBNAME> <RUNNAME> <ANALYSISNAME - optional> HOSTNAME"
    echo "    ANALYSISNAME=RUNNAME if only two parameters"
    exit
fi
SUBNAME=$1
RUNNAME=$2
if((${#@}<3));then
    ANALYSISNAME=${RUNNAME} # if you only put in 2 inputs, it assumes your analysis output is exactly = your runname
else
    ANALYSISNAME=$3
fi
((${#@}>=4)) && lchostname=1 || lchostname=0

if ((lchostname==0)); then
SUBJDIR=/Users/bphilip/Documents/10_Connectivity/${SUBNAME}/pipeline
else
SUBJDIR=/Users/bphilip/Documents/10_Connectivity/${SUBNAME}/$(hostname)
fi
#((lchostname==0) && SUBJDIR=/Users/bphilip/Documents/10_Connectivity/${SUBNAME}/pipeline || SUBJDIR=/Users/bphilip/Documents/10_Connectivity/${SUBNAME}/$(hostname)

OUTDIR=${SUBJDIR}/model/${ANALYSISNAME}.feat/reg

echo ${OUTDIR}

# First, slide any preexisting reg/reg_standard folder off to to a datestamped backup
REGSTD=${SUBJDIR}/model/${ANALYSISNAME}.feat/reg
THEDATE=`date +%y%m%d_%H%M`
if [[ -d "$OUTDIR" ]];then
    echo "storing ${OUTDIR} as ${THEDATE}"
    mv ${OUTDIR} ${OUTDIR}_${THEDATE}
fi
if [[ -d "$REGSTD" ]];then
    echo "storing ${REGSTD} as ${THEDATE}"
    mv ${REGSTD} ${REGSTD}_${THEDATE}
fi

mkdir -p ${OUTDIR}

cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/example_func2standard.mat ${OUTDIR}/example_func2standard.mat
cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/highres2standard.mat ${OUTDIR}/highres2standard.mat
cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/${RUNNAME}_SBRef.nii.gz ${OUTDIR}/example_func.nii.gz # CHANGED 220530
cp -p ${SUBJDIR}/MNINonLinear/T1w_restore.2.nii.gz ${OUTDIR}/highres_head.nii.gz 

#cp -p ${SUBJDIR}/MNINonLinear/T1w_restore.2_brain.nii.gz ${OUTDIR}/highres.nii.gz #CURRENTLY MAKING THIS MANUALLY IN FSL-BET
cp -p ${SUBJDIR}/MNINonLinear/T1w_restore_brain.2.nii.gz ${OUTDIR}/highres.nii.gz

cp ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${OUTDIR}/standard_head.nii.gz
cp ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${OUTDIR}/standard.nii.gz