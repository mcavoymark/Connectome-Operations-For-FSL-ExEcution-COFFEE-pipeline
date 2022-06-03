#!/usr/bin/env bash

#Hard coded SetUpHCPPipeline.sh
ES=/home/usr/mcavoy/HCP/scripts/220209SetUpHCPPipeline.sh

if((${#@}<2));then
    echo "$0 <IHC.dat> <out dir> <out script>"
    echo ""
    echo "    <HCP dir>"
    echo "        Ex. IHC.dat 
    echo "    <out dir>
    echo "        Ex. /export/scratch/mcavoy/bp/hcp3.27_220302_FS5.3HCP/10_200/211209/feat/reg
    exit
fi
bs=$2
IFS=$'\n' read -d '' -ra csv < $1

mkdir -p $od

cp -p $id/
