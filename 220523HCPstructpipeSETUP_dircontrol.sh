#!/usr/bin/env bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

#Hard coded location of HCP scripts
HCPDIR=/home/usr/mcavoy/HCP

#Hard coded
pre0=220504PreFreeSurferPipelineBatch_dircontrol.sh
free0=220504FreeSurferPipelineBatch_editFS_dircontrol.sh
post0=220523PostFreeSurferPipelineBatch_dircontrol.sh

if((${#@}<2));then
    
    echo "$0 <IHC3.dat> <batch script> <HCPDIR> <5.3HCP 7.2> HOSTNAME"
    echo ""
    echo "    <IHC.dat> Space or comma separated is ok."
    echo "    Ex. #Scans can be labeled NONE or NOTUSEABLE. Lines beginning with a # are ignored."
    echo "        #SUBNAME OUTDIR T1 T2 FM1 FM2 run1_LH_SBRef run1_LH run1_RH_SBRef run1_RH run2_LH_SBRef run2_LH run2_RH_SBRef run2_RH run3_LH_SBRef run3_LH run3_RH_SBRef run3_RH rest01_SBRef rest01 rest02_SBRef rest02 rest03_SBRef rest03"
    echo ""

    exit
fi
bs=$2

((${#@}>=3)) && HCPDIR=$3
if((${#@}>=4));then
    if [ "${4}" = "5.3HCP" ];then
        setup0=220209SetUpHCPPipeline.sh
    elif [ "${4}" = "7.2" ];then
        setup0=220209SetUpHCPPipeline_FS7.2.sh
    else
        echo "Unknown version of freesurfer"
        exit
    fi
fi
((${#@}>=5)) && lchostname=1 || lchostname=0


D0=${HCPDIR}/scripts
SCRIPT1=${D0}/${setup0}
SCRIPT0=${D0}/${pre0}
SCRIPT2=${D0}/${free0}
SCRIPT3=${D0}/${post0}


IFS=$'\n' read -d '' -ra csv < $1

bs0=${bs%/*}
mkdir -p ${bs0}

#echo -e "#!/bin/bash\n" > $bs
echo -e "#!/usr/bin/env bash\n" > $bs

for((i=0;i<${#csv[@]};++i));do
    IFS=$',\n ' read -ra line <<< ${csv[i]}
    if [[ "${line[0]:0:1}" = "#" ]];then
        echo "Skiping line $((i+1))"
        continue
    fi

    if((lchostname==1));then
        dir0=${line[1]}
    else
        IFS=$'/' read -ra line2 <<< ${line[1]}
        dir0=/$(join_by / ${line2[@]::${#line2[@]}-1})
        sub0=${line2[-1]}
        echo "sub0=${sub0}"
    fi
    echo "dir0=${dir0}"


    T1f=${line[2]}
    if [[ "${T1f}" = "NONE" || "${T1f}" = "NOTUSEABLE" ]];then
        echo "    T1 ${T1f}"
        continue
    fi
    if [ ! -f "$T1f" ];then
        echo "    T1 ${T1f} not found"
        continue
    fi
    echo "    T1 ${T1f}"

    T2f=;T20=${line[3]}
    if [[ "${T20}" = "NONE" || "${T20}" = "NOTUSEABLE" ]];then
        echo "    T2 ${T20}"
    elif [ ! -f "${T20}" ];then
        echo "    T2 ${T20} not found"
    else
        T2f=${T20}
        echo "    T2 ${T2f}"
    fi

    mkdir -p ${dir0}
    #if((lchostname==1));then
    #    F0=${dir0}/hcp3.27struct.sh
    #else
    #    F0=${dir0}/${line[0]}_hcp3.27struct.sh
    #fi
    F0=${dir0}/${line[0]////_}_hcp3.27struct.sh

    echo "    ${F0}"

    #echo -e "#!/bin/bash\n" > ${F0}
    echo -e "#!/usr/bin/env bash\n" > ${F0} 

    if((lchostname==1));then
        echo -e "sf0=${dir0}\nes0=${SCRIPT1}\n" >> ${F0}
    else
        echo -e "sf0=${dir0}\ns0=${sub0}\nes0=${SCRIPT1}\n" >> ${F0}
    fi

    echo ${SCRIPT0}' \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    if((lchostname==1));then
        echo '    --Subject=$(hostname) \' >> ${F0}
    else
        echo '    --Subject=${s0} \' >> ${F0}
    fi
    echo '    --runlocal \' >> ${F0}
    echo '    --T1='${T1f}' \' >> ${F0}
    echo '    --T2='${T2f}' \' >> ${F0}
    echo '    --GREfieldmapMag="NONE" \' >> ${F0}
    echo '    --GREfieldmapPhase="NONE" \' >> ${F0}
    echo '    --EnvironmentScript=${es0} \' >> ${F0}
    echo '    --Hires=1' >> ${F0}
    echo '' >> ${F0}
    echo ${SCRIPT2}' \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    if((lchostname==1));then
        echo '    --Subject=$(hostname) \' >> ${F0}
    else
        echo '    --Subject=${s0} \' >> ${F0}
    fi
    echo '    --runlocal \' >> ${F0}
    echo '    --EnvironmentScript=${es0}' >> ${F0}
    echo '' >> ${F0}
    echo ${SCRIPT3}' \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    if((lchostname==1));then
        echo '    --Subject=$(hostname) \' >> ${F0}
    else
        echo '    --Subject=${s0} \' >> ${F0}
    fi
    echo '    --runlocal \' >> ${F0}
    echo '    --EnvironmentScript=${es0}' >> ${F0}
    chmod +x ${F0}
    echo "${F0} > ${F0}.txt 2>&1 &" >> $bs
done
chmod +x $bs
echo "Output written to $bs"
