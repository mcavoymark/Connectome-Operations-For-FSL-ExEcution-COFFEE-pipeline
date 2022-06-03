#!/usr/bin/env bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

Hires=1

#Hard coded location of HCP scripts
HCPDIR=/home/usr/mcavoy/HCP

#Hard coded SetUpHCPPipeline.sh
ES=$HCPDIR/scripts/220209SetUpHCPPipeline.sh

#Hard coded GenericfMRIVolumeProcessingPipelineBatch.sh
P0=220504GenericfMRIVolumeProcessingPipelineBatch_dircontrol.sh

#Hard coded MakeMat.sh
P1=220524MakeMat.sh

SCRIPT0=$HCPDIR/scripts/${P0}
SCRIPT1=$HCPDIR/scripts/${P1}

if((${#@}<2));then
    echo "$0 <IHC3.dat> <batch script> <HCPDIR> <5.3HCP 7.2> HOSTNAME"
    echo ""
    echo "    <IHC.dat> Space or comma separated is ok."
    echo "    Ex. #Scans can be labeled NONE or NOTUSEABLE. Lines beginning with a # are ignored."
    echo "        #SUBNAME OUTDIR T1 T2 FM1 FM2 run1_RH_SBRef run1_RH run1_LH_SBRef run1_LH run2_RH_SBRef run2_RH run2_LH_SBRef run2_LH run3_RH_SBRef run3_RH run3_LH_SBRef run3_LH rest01_SBRef rest01 rest02_SBRef rest02 rest03_SBRef rest03"
    echo ""

    exit
fi
bs=$2

if((${#@}>=3));then
    HCPDIR=$3
    D0=${HCPDIR}/scripts
    SCRIPT0=${D0}/${P0}
    SCRIPT1=${D0}/${P1}
fi
if((${#@}>=4));then
    if [ "${4}" = "5.3HCP" ];then
        setup0=220209SetUpHCPPipeline.sh
    elif [ "${4}" = "7.2" ];then
        setup0=220209SetUpHCPPipeline_FS7.2.sh
    else
        echo "Unknown version of freesurfer"
        exit
    fi
    ES=${D0}/${setup0}
fi
((${#@}>=5)) && lchostname=1 || lchostname=0


IFS=$'\n' read -d '' -ra csv < $1
#printf '%s\n' "${csv[@]}"

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
    if [ ! -d "${line[1]}" ];then
        echo "${line[1]} does not exist"
        continue
    fi

    #check for bolds
    declare -a bold
    for((j=7;j<=23;j+=2));do
        if [ "${line[j]}" != "NONE" ] && [ "${line[j]}" != "NOTUSEABLE" ];then
            if [ ! -f ${line[j]} ];then
                echo "    ${line[j]} does not exist"
            else
                bold[j]=1
            fi
        fi
    done
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

    if((lchostname==1));then
        dir0=${line[1]}
    else
        IFS=$'/' read -ra line2 <<< ${line[1]}
        dir0=/$(join_by / ${line2[@]::${#line2[@]}-1})
        sub0=${line2[-1]}
        echo "sub0=${sub0}"
    fi
    #echo "dir0=${dir0}"
    F0=${dir0}/${line[0]////_}_hcp3.27fMRIvol.sh
    echo "    ${F0}"
    #echo -e "#!/bin/bash\n" > ${F0}
    echo -e "#!/usr/bin/env bash\n" > ${F0} 
    echo 'ES='${ES} >> ${F0}
    echo 'P0='${SCRIPT0} >> ${F0}
    echo 'P1='${SCRIPT1} >> ${F0}
    if((lchostname==1));then
        echo -e "sf0=${dir0}\n" >> ${F0}
    else
        echo -e "sf0=${dir0}\ns0=${sub0}\n" >> ${F0}
    fi
    echo '${P0} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    if((lchostname==1));then
        echo '    --Subject=$(hostname) \' >> ${F0}
    else
        echo '    --Subject=${s0} \' >> ${F0}
    fi
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
    echo '    --EnvironmentScript=${ES}' >> ${F0}

    #START220523
    echo -e '\n${P1} \' >> ${F0}
    echo '    --example_func="\' >> ${F0}
    for((j=7;j<=23;j+=2));do
        if((bold[j]==1));then
            str0=${line[j]##*/}
            str0=${str0%.nii*}
            echo '        ${sf0}/${s0}/MNINonLinear/Results/'${str0}/${str0}_SBRef.nii.gz${endquote[j]}' \' >> ${F0}
        fi
    done
    echo '    --gdc="\' >> ${F0}
    for((j=7;j<=23;j+=2));do
        if((bold[j]==1));then
            str0=${line[j]##*/}
            str0=${str0%.nii*}
            echo '        ${sf0}/${s0}/'${str0}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/WarpField.nii.gz${endquote[j]}' \' >> ${F0}
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
    echo '    --t1=${sf0}/${s0}/T1w/T1w_acpc_dc_restore.nii.gz \' >> ${F0}
    echo '    --t1brain=${sf0}/${s0}/T1w/T1w_acpc_dc_restore_brain.nii.gz \' >> ${F0}
    source ${ES}
    echo '    --ref='${HCPPIPEDIR_Templates}/MNI152_T1_${Hires}mm_brain.nii.gz' \' >> ${F0}
    echo '    --EnvironmentScript=${ES}' >> ${F0}

    chmod +x ${F0}
    echo "${F0} > ${F0}.txt 2>&1 &" >> $bs
    unset endquote;unset bold;unset PED;
done
chmod +x $bs
echo "Output written to $bs"
