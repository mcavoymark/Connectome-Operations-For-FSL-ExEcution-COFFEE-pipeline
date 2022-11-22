#!/usr/bin/env bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

#Hard coded location of HCP scripts
[ -z ${HCPDIR+x} ] && HCPDIR=/Users/bphilip/Documents/HCP

##Freesurfer version
#freesurferVersion=5.3HCP
##freesurferVersion=7.2
##Hard coded SetUpHCPPipeline.sh
#setup53HCP=220714SetUpHCPPipeline.sh
#setup72HCP=220209SetUpHCPPipeline_FS7.2.sh
#START221027
#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer
#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2
freesurferVersion=5.3.0-HCP
setup0=220714SetUpHCPPipeline.sh

#Hard coded GenericfMRIVolumeProcessingPipelineBatch.sh
#P0=220504GenericfMRIVolumeProcessingPipelineBatch_dircontrol.sh
#START221103
P0=221103GenericfMRIVolumeProcessingPipelineBatch_dircontrol.sh

#Hard coded MakeMat.sh
P1=220722MakeMat.sh

#Hard coded SmoothingProcess.sh
P2=220723SmoothingProcess.sh

#Resolution. Should match that for the sturctural pipeline. options: 1, 0.7 or 0.8
hires=1

helpmsg(){
    echo "$0"
    echo "    -d | --dat               dat file"
    echo "    -b | --batchScript       Output batch script."
    echo "    -H | --HCPDIR            HCP directory. Optional if set at the top of this script or elsewhere."

    #echo "    -F | --freesurferVersion Default is 5.3HCP. We hope to evaluate 7.2 in the future."
    #START221027
    echo "    -F | --freesurferVersion 5.3.0-HCP, 7.2.0 or 7.3.2. Default is 5.3.0-HCP."

    echo "    -m | --HOSTNAME          Flag. Use machine name instead of user named file."
    echo "    -D | --DATE              Flag. Add date to name of output script."

    #echo "    -r | --hires             T1 resolution: 0.7, 0.8 or 1mm. Default is 1mm."
    #START221027
    echo "    -r | --hires             Resolution. Should match that for the sturctural pipeline. options : 0.7, 0.8 or 1mm. Default is 1mm."

    echo "    -f | --fwhm              Smoothing in mm for SUSAN. Multiple values ok."
    echo "    -p | --paradigm_hp_sec   High pass filter cutoff in sec"
    echo "    -s | --SMOOTHONLY        Flag. Only do the smoothing: SUSAN and high pass filtering."
    echo "    -h | --help              Echo this help message."
    exit
    }
if((${#@}<2));then
    helpmsg
    exit
fi

#dat=;bs=;lchostname=0;fwhm=;paradigm_hp_sec=;lcdate=0;lcsmoothonly=0
dat=;bs=;lchostname=0;lcdate=0;fwhm=;paradigm_hp_sec=;lcsmoothonly=0

echo $0 $@
arg=($@)
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -d | --dat)
            dat=${arg[((++i))]}
            echo "dat=$dat"
            ;;
        -b | --batchScript)
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
            hires=${arg[((++i))]}
            echo "hires=$hires"
            ;;
        -f | --fwhm)
            fwhm=
            for((j=0;++i<${#@};));do
                if [ "${arg[i]:0:1}" = "-" ];then
                    ((--i));
                    break
                else
                    fwhm[((j++))]=${arg[i]}
                fi
            done
            echo "fwhm=${fwhm[@]} nelements=${#fwhm[@]}"
            ;;
        -p | --paradigm_hp_sec)
            paradigm_hp_sec=${arg[((++i))]}
            echo "paradigm_hp_sec=$paradigm_hp_sec"
            ;;
        -s | --SMOOTHONLY)
            lcsmoothonly=1
            echo "lcsmoothonly=$lcsmoothonly"
            ;;
        -h | --help)
            helpmsg
            ;;
        *) echo "Unexpected option: ${arg[i]}"
            ;;
    esac
done
if [ -z "${dat}" ];then
    echo "Need to specify -d | --dat"
    exit
fi
if [ -z "${bs}" ];then
    echo "Need to specify -b | --batchScript"
    exit
fi
if [ -z "${fwhm}" ];then
    echo "-f | --fwhm has not been specified. SUSAN noise reduction will not be performed."
    fwhm=0
fi
if [ -z "${paradigm_hp_sec}" ]; then
    echo "-p | --paradigm_hp_sec has not been specified. High pass filtering will not be performed."
    paradigm_hp_sec=0
fi

SCRIPT0=${HCPDIR}/scripts/${P0}
SCRIPT1=${HCPDIR}/scripts/${P1}
SCRIPT2=${HCPDIR}/scripts/${P2}
ES=${HCPDIR}/scripts/${setup0}

#if [ "${freesurferVersion}" = "5.3HCP" ];then
#    ES=${HCPDIR}/scripts/${setup53HCP}
#elif [ "${freesurferVersion}" = "7.2" ];then
#    ES=${HCPDIR}/scripts/${setup72HCP}
#else
#    echo "Unknown version of freesurfer"
#    exit
#fi
#START221027
if [[ "${freesurferVersion}" != "5.3.0-HCP" && "${freesurferVersion}" != "7.2.0" && "${freesurferVersion}" != "7.3.2" ]];then
    echo "Unknown version of freesurfer. freesurferVersion=${freesurferVersion}"
    exit
fi
fs0="export FREESURFER_HOME=${FREESURFDIR}/${freesurferVersion}"
export FREESURFER_HOME=${FREESURFDIR}/${freesurferVersion}

IFS=$'\n\r' read -d '' -ra csv < $dat
#printf '%s\n' "${csv[@]}"

bs0=${bs%/*}
mkdir -p ${bs0}

#echo -e "#!/bin/bash\n" > $bs
echo -e "#!/usr/bin/env bash\n" > $bs

for((i=0;i<${#csv[@]};++i));do
    IFS=$',\n\r ' read -ra line <<< ${csv[i]}
    if [[ "${line[0]:0:1}" = "#" ]];then
        echo "Skiping line $((i+1))"
        continue
    fi
    echo ${line[0]}
    if [ ! -d "${line[1]}" ];then
        echo "${line[1]} does not exist"
        continue
    fi

    #check for bolds
    declare -a bold
    for((j=7;j<=23;j+=2));do
        bold[j]=0
        if [ "${line[j]}" != "NONE" ] && [ "${line[j]}" != "NOTUSEABLE" ];then
            if [ ! -f ${line[j]} ];then
                echo "    ${line[j]} does not exist"
            else
                bold[j]=1
            fi
        fi
    done
    #echo "bold=${bold[@]}"

    lcbold=$(IFS=+;echo "$((${bold[*]}))")
    ((lcbold==0)) && continue

    #make sure bolds and SBRef have same phase encoding direction
    lcSBRef=0
    for((j=6;j<=22;j+=2));do
        if((${bold[j+1]}==1));then
            if [ "${line[j]}" = "NONE" ] || [ "${line[j]}" = "NOTUSEABLE" ];then
                bold[j]=${line[j]}
            else
                if [ ! -f ${line[j]} ];then
                    echo "    ${line[j]} does not exist"
                    bold[j]=DOESNOTEXIST
                else
                    ped=
                    for((k=j;k<=((j+1));++k));do
                        json=${line[j]%%.*}.json
                        if [ ! -f $json ];then
                            echo "    $json not found. Abort!"
                            exit
                        fi
                        mapfile -t PhaseEncodingDirection < <( grep PhaseEncodingDirection $json )
                        IFS=$' ,' read -ra line0 <<< ${PhaseEncodingDirection}
                        IFS=$'"' read -ra line1 <<< ${line0[1]}
                        ped[k]=${line1[1]}
                    done
                    if [[ "${ped[j]}" != "${ped[j+1]}" ]];then
                        echo "ERROR: ${line[j]} ${PED[j]}, ${line[j+1]} ${PED[j+1]}. Phases should be the same. Will not use this SBRef."
                        bold[j]=PHASEWRONG
                    else
                        bold[j]=${line[j]}
                        ((lcSBRef++))
                    fi
                fi
            fi
        fi
    done

    if((lchostname==0));then
        IFS=$'/' read -ra line2 <<< ${line[1]}
        sub0=${line2[-2]}
    fi
    ((lcsmoothonly==0)) && l0=hcp3.27fMRIvol || l0=smooth
    if((lcdate==0));then
        F0=${line[1]}/${line[0]////_}_${l0}.sh
    else
        F0=${line[1]}/${line[0]////_}_${l0}_$(date +%y%m%d%H%M%S).sh
    fi


    echo "    ${F0}"

    #echo -e "#!/bin/bash\n" > ${F0}
    echo -e "#!/usr/bin/env bash\n" > ${F0} 

    [ -n "${fs0}" ] && echo -e "${fs0}\n" >> ${F0}

    if((lcsmoothonly==0));then
        echo 'P0='${SCRIPT0} >> ${F0}
        echo 'P1='${SCRIPT1} >> ${F0}
    fi
    echo 'P2='${SCRIPT2} >> ${F0}
    echo -e 'ES='${ES}"\n" >> ${F0}

    echo "sf0=${line[1]}" >> ${F0}

    #if((lchostname==1));then
    #    echo -e 's0=$(hostname)'"\n" >> ${F0} 
    #else
    #    echo -e "s0=${sub0}\n" >> ${F0} 
    #fi
    #START221103
    if((lchostname==1));then
        echo 's0=$(hostname)' >> ${F0}
    else
        echo "s0=${sub0}" >> ${F0}
    fi
    echo -e "freesurferVersion=${freesurferVersion}\n" >> ${F0}

    if((lcsmoothonly==0));then
        echo '${P0} \' >> ${F0}
        echo '    --StudyFolder=${sf0} \' >> ${F0}
        echo '    --Subject=${s0} \' >> ${F0}
        echo '    --runlocal \' >> ${F0}

        declare -a endquote
        for((j=23;j>=7;j-=2));do
            if [ "${line[j]}" != "NONE" ] && [ "${line[j]}" != "NOTUSEABLE" ];then
                endquote[j]='"'
                break
            fi
        done
        echo '    --fMRITimeSeries="\' >> ${F0}
        for((j=7;j<=23;j+=2));do
            ((${bold[j]}==1)) && echo '        '${line[j]}${endquote[j]}' \' >> ${F0}
        done
        if((lcSBRef>0));then
            echo '    --fMRISBRef="\' >> ${F0}
            for((j=6;j<=22;j+=2));do
                if((${bold[j+1]}==1));then
                    echo '        '${bold[j]}${endquote[j+1]}' \' >> ${F0}
                fi
            done
        fi

        declare -a PED;
        if [[ "${line[4]}" != "NONE" && "${line[4]}" != "NOTUSEABLE" && "${line[5]}" != "NONE" && "${line[5]}" != "NOTUSEABLE" ]];then
            for((j=4;j<=5;j++));do
                json=${line[j]%%.*}.json
                if [ ! -f $json ];then
                    echo "    $json not found"
                    rm -f ${F0}
                    continue
                fi
                mapfile -t PhaseEncodingDirection < <( grep PhaseEncodingDirection $json )
                IFS=$' ,' read -ra line0 <<< ${PhaseEncodingDirection}
                IFS=$'"' read -ra line1 <<< ${line0[1]}
                PED[j]=${line1[1]}
            done
            lcbadFM=0
            for((j=4;j<5;j+=2));do
                if [[ "${PED[j]}" = "${PED[j+1]}" ]];then
                    echo "ERROR: ${line[j]} ${PED[j]}, ${line[j+1]} ${PED[j+1]}. Fieldmap phases should be opposite."
                    lcbadFM=1 
                fi
            done
            if((lcbadFM==0));then
                for((j=4;j<=5;j++));do
                    if [[ "${PED[j]}" == "j-" ]];then
                        echo '    --SpinEchoPhaseEncodeNegative="\' >> ${F0}
                        for((k=7;k<=23;k+=2));do
                            if((${bold[k]}==1));then
                                echo '        '${line[j]}${endquote[k]}' \' >> ${F0}
                            fi
                        done
                    elif [[ "${PED[j]}" == "j" ]];then
                        echo '    --SpinEchoPhaseEncodePositive="\' >> ${F0}
                        for((k=7;k<=23;k+=2));do
                            if((${bold[k]}==1));then
                                echo '        '${line[j]}${endquote[k]}' \' >> ${F0}
                            fi
                        done
                    else
                        echo "ERROR: ${line[j]} ${PED[j]} Unknown phase encoding direction."
                        rm -f ${F0}
                        continue
                    fi
                done
            fi
        fi

        #START221103
        echo '    --freesurferVersion=${freesurferVersion} \' >> ${F0}

        echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}

        echo '${P1} \' >> ${F0}
        echo '    --example_func="\' >> ${F0}
        for((j=7;j<=23;j+=2));do
            if((bold[j]==1));then
                str0=${line[j]##*/}
                str0=${str0%.nii*}
                echo '        ${sf0}/MNINonLinear/Results/'${str0}/${str0}_SBRef.nii.gz${endquote[j]}' \' >> ${F0}
            fi
        done
        echo '    --gdc="\' >> ${F0}
        for((j=7;j<=23;j+=2));do
            if((bold[j]==1));then
                str0=${line[j]##*/}
                str0=${str0%.nii*}
                echo '        ${sf0}/'${str0}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/WarpField.nii.gz${endquote[j]}' \' >> ${F0}

            fi
        done
        pedstr=
        for((j=7;j<=23;j+=2));do
            if((bold[j]==1));then
                json=${line[j]%%.*}.json
                if [ ! -f $json ];then
                    echo "    $json not found"
                    rm -f ${F0}
                    continue
                fi
                #echo $json
                mapfile -t PhaseEncodingDirection < <( grep PhaseEncodingDirection $json )
                IFS=$' ,' read -ra line0 <<< ${PhaseEncodingDirection}
                IFS=$'"' read -ra line1 <<< ${line0[1]}
                if [[ "${line1[1]}" == "j-" ]];then
                    pedstr+='y- '
                elif [[ "${line1[1]}" == "j" ]];then
                    pedstr+='y '
                else
                    echo "ERROR: ${line[j]} ${line1[1]} Unknown phase encoding direction."
                    rm -f ${F0}
                    continue
                fi
            fi
        done
        echo '    --pedir="'${pedstr::-1}'" \' >> ${F0}
        echo '    --t1=${sf0}/T1w/T1w_acpc_dc_restore.nii.gz \' >> ${F0}
        echo '    --t1brain=${sf0}/T1w/T1w_acpc_dc_restore_brain.nii.gz \' >> ${F0}

        source ${ES}
        echo '    --ref='${HCPPIPEDIR_Templates}/MNI152_T1_${hires}mm_brain.nii.gz' \' >> ${F0}
        echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}
    fi

    #START220721
    declare -a endquote0
    for((j=17;j>=7;j-=2));do
        if [ "${line[j]}" != "NONE" ] && [ "${line[j]}" != "NOTUSEABLE" ];then
            endquote0[j]='"'
            break
        fi
    done

    #START220714
    #echo -e '\n${P2} \' >> ${F0}
    echo '${P2} \' >> ${F0}

    echo '    --fMRITimeSeriesResults="\' >> ${F0}
    #for((j=7;j<=23;j+=2));do
    for((j=7;j<=17;j+=2));do #task runs only
        if((bold[j]==1));then
            str0=${line[j]##*/}
            str0=${str0%.nii*}

            #echo '        ${sf0}/${s0}/MNINonLinear/Results/'${str0}/${str0}.nii.gz${endquote[j]}' \' >> ${F0}
            #START220721
            #echo '        ${sf0}/${s0}/MNINonLinear/Results/'${str0}/${str0}.nii.gz${endquote0[j]}' \' >> ${F0}
            #START220722
            echo '        ${sf0}/MNINonLinear/Results/'${str0}/${str0}.nii.gz${endquote0[j]}' \' >> ${F0}

        fi
    done
    if((${fwhm[0]}>0));then
        echo '    --fwhm="'${fwhm[@]}'" \' >> ${F0}
    fi
    if((paradigm_hp_sec>0));then
        echo '    --paradigm_hp_sec="'${paradigm_hp_sec}'" \' >> ${F0}
        trstr=
        #for((j=7;j<=23;j+=2));do
        for((j=7;j<=17;j+=2));do #task runs only
            if((bold[j]==1));then
                json=${line[j]%%.*}.json
                if [ ! -f $json ];then
                    echo "    $json not found"
                    rm -f ${F0}
                    continue
                fi
                #echo $json
                mapfile -t RepetitionTime < <( grep RepetitionTime $json )
                IFS=$' ,' read -ra line0 <<< ${RepetitionTime}
                trstr+="${line0[1]} "
            fi
        done
        echo '    --TR="'${trstr::-1}'" \' >> ${F0}
    fi

    #echo '    --SmoothFolder=${smooth0} \' >> ${F0}

    echo '    --EnvironmentScript=${ES}' >> ${F0}

    chmod +x ${F0}
    echo "${F0} > ${F0}.txt 2>&1 &" >> $bs

    #unset endquote;unset bold;unset PED;
    #START220721
    unset endquote;unset bold;unset PED;unset endquote0

done
chmod +x $bs
echo "Output written to $bs"
