#!/usr/local/bin/bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

#Hard coded location of HCP scripts
#[ -z ${HCPDIR+x} ] && HCPDIR=/Users/bphilip/Documents/HCP
[ -z ${HCPDIR+x} ] && HCPDIR=/Users/Shared/pipeline/HCP

#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer

#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2 
#freesurferVersion=5.3.0-HCP
freesurferVersion=7.3.2

#setup0=220714SetUpHCPPipeline.sh
setup0=221203SetUpHCPPipeline.sh

#Hard coded HCP batch scripts
pre0=220504PreFreeSurferPipelineBatch_dircontrol.sh
free0=221027FreeSurferPipelineBatch_editFS_dircontrol.sh
post0=220523PostFreeSurferPipelineBatch_dircontrol.sh

#Resolution. options: 1, 0.7 or 0.8
Hires=1

helpmsg(){
    echo "$0"
    echo "    -d | --dat               dat file"
    echo "    -b | --batchscript       Output batch script."
    echo "    -H | --HCPDIR            HCP directory. Optional if set at the top of this script or elsewhere."
    echo "    -F | --freesurferVersion 5.3.0-HCP, 7.2.0 or 7.3.2. Default is 7.3.2."
    echo "    -m | --HOSTNAME          Flag. Use machine name instead of user named file."
    echo "    -D | --DATE              Flag. Add date to name of output script."
    echo "    -r | --hires             Resolution. Should match that for the sturctural pipeline. options : 0.7, 0.8 or 1mm. Default is 1mm."
    echo "    -h | --help              Echo this help message."
    exit
    }
if((${#@}<2));then
    helpmsg
    exit
fi
dat=;bs=;lchostname=0;lcdate=0
echo $0 $@
arg=($@)
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -d | --dat)
            dat=${arg[((++i))]}
            echo "dat=$dat"
            ;;
        -b | --batchscript)
            bs=${arg[((++i))]}
            echo "bs=$bs"
            ;;
        -H | --HCPDIR)
            HCPDIR=${arg[((++i))]}
            echo "HCPDIR=$HCPDIR"
            ;;
        -F | --freesurferVersion)
            freesurferVersion=${arg[((++i))]}
            echo "freesurferVersion=$freesurferVersion"
            ;;
        -m | --HOSTNAME)
            lchostname=1
            echo "lchostname=$lchostname"
            ;;
        -D | --DATE)
            lcdate=1
            echo "lcdate=$lcdate"
            ;;
        -r | --hires)
            Hires=${arg[((++i))]}
            echo "Hires=$Hires"
            ;;
        -h | --help)
            helpmsg
            exit
            ;;
        *) echo "Unexpected option: ${arg[i]}"
            exit
            ;;
    esac
done
if [ -z "${dat}" ];then
    echo "Need to specify -d | --dat"
    exit
fi
if [ -z "${bs}" ];then
    echo "Need to specify -b | --batchscript"
    exit
fi

PRE=${HCPDIR}/scripts/${pre0}
FREE=${HCPDIR}/scripts/${free0}
POST=${HCPDIR}/scripts/${post0}
ES=${HCPDIR}/scripts/${setup0}

IFS=$'\n\r' read -d '' -ra csv < $dat


#fs0=;lcsinglereconall=0;lctworeconall=0
#if [[ "${freesurferVersion}" != "5.3.0-HCP" && "${freesurferVersion}" != "7.2.0" && "${freesurferVersion}" != "7.3.2" ]];then
#    echo "Unknown version of freesurfer. freesurferVersion=${freesurferVersion}"
#    exit
#fi
#fs0="export FREESURFER_HOME=${FREESURFDIR}/${freesurferVersion}"
#[[ "${freesurferVersion}" = "7.2.0" || "${freesurferVersion}" = "7.3.2" ]] && lctworeconall=1
#START221210
lcsinglereconall=0;lctworeconall=0
if [[ "${freesurferVersion}" != "5.3.0-HCP" && "${freesurferVersion}" != "7.2.0" && "${freesurferVersion}" != "7.3.2" ]];then
    echo "Unknown version of freesurfer. freesurferVersion=${freesurferVersion}"
    exit
fi
[[ "${freesurferVersion}" = "7.2.0" || "${freesurferVersion}" = "7.3.2" ]] && lctworeconall=1



bs0=${bs%/*}
mkdir -p ${bs0}
#echo -e "#!/bin/bash\n" > $bs
#echo -e "#!/usr/bin/env bash\n" > $bs
echo -e "#!/usr/local/bin/bash\n" > $bs

for((i=0;i<${#csv[@]};++i));do
    IFS=$',\n\r ' read -ra line <<< ${csv[i]}
    if [[ "${line[0]:0:1}" = "#" ]];then
        echo "Skiping line $((i+1))"
        continue
    fi

    echo ${line[0]}

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

    #mkdir -p ${line[1]}
    #START221204
    dir0=${line[1]}${freesurferVersion}
    mkdir -p ${dir0}

    if((lchostname==0));then
        IFS=$'/' read -ra line2 <<< ${line[1]}
        #echo "line2=${line2[@]}"
        sub0=${line2[-2]}
        #echo "sub0=${sub0}"
    fi


    #if((lcdate==0));then
    #    F0=${line[1]}/${line[0]////_}_hcp3.27struct.sh
    #else
    #    F0=${line[1]}/${line[0]////_}_hcp3.27struct_$(date +%y%m%d%H%M%S).sh
    #fi
    #START221204
    if((lcdate==0));then
        F0=${dir0}/${line[0]////_}_hcp3.27struct.sh
    else
        F0=${dir0}/${line[0]////_}_hcp3.27struct_$(date +%y%m%d%H%M%S).sh
    fi


    echo "    ${F0}"

    #echo -e "#!/bin/bash\n" > ${F0}
    #echo -e "#!/usr/bin/env bash\n" > ${F0} 
    echo -e "#!/usr/local/bin/bash\n" > ${F0} 

    #[ -n "${fs0}" ] && echo -e "${fs0}\n" >> ${F0}
    #START221210
    echo "freesurferVersion=${freesurferVersion}" >> ${F0}
    echo -e export FREESURFER_HOME=${FREESURFDIR}/'${freesurferVersion}'"\n" >> ${F0}

    echo 'PRE='${PRE} >> ${F0}
    echo 'FREE='${FREE} >> ${F0}
    echo 'POST='${POST} >> ${F0}
    echo -e "ES=${ES}\n" >> ${F0}


    #echo "sf0=${line[1]}" >> ${F0}
    #if((lchostname==1));then
    #    echo 's0=$(hostname)' >> ${F0}
    #else
    #    echo "s0=${sub0}" >> ${F0}
    #fi
    #echo "freesurferVersion=${freesurferVersion}" >> ${F0}
    #echo -e "Hires=${Hires}\n" >> ${F0}
    #START221204
    #echo "freesurferVersion=${freesurferVersion}" >> ${F0}
    echo "sf0=${line[1]}"'${freesurferVersion}' >> ${F0}
    if((lchostname==1));then
        echo 's0=$(hostname)' >> ${F0}
    else
        echo "s0=${sub0}" >> ${F0}
    fi
    echo -e "Hires=${Hires}\n" >> ${F0}



    echo '${PRE} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --T1='${T1f}' \' >> ${F0}
    echo '    --T2='${T2f}' \' >> ${F0}
    echo '    --GREfieldmapMag="NONE" \' >> ${F0}
    echo '    --GREfieldmapPhase="NONE" \' >> ${F0}
    echo '    --EnvironmentScript=${ES} \' >> ${F0}
    echo '    --Hires=${Hires} \' >> ${F0}
    echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}

    echo '${FREE} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --Hires=${Hires} \' >> ${F0}
    echo '    --freesurferVersion=${freesurferVersion} \' >> ${F0}
    ((lcsinglereconall)) && echo '    --singlereconall \' >> ${F0}
    ((lctworeconall)) && echo '    --tworeconall \' >> ${F0}
    echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}

    echo '${POST} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --EnvironmentScript=${ES}' >> ${F0}

    chmod +x ${F0}
    echo "${F0} > ${F0}.txt 2>&1 &" >> $bs
done
chmod +x $bs
echo "Output written to $bs"
