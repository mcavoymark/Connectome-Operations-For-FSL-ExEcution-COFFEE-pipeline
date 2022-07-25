#!/usr/bin/env bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

# Resolution of T1: 1, 0.7 or 0.8
hires=1

#Hard coded location of HCP scripts
hcpdir=/Users/bphilip/Documents/HCP

#Freesurfer version
freesurferVersion=5.3HCP
#freesurferVersion=7.2

#Hard coded SetUpHCPPipeline.sh
setup53HCP=220714SetUpHCPPipeline.sh
setup72HCP=220209SetUpHCPPipeline_FS7.2.sh
#ES=$hcpdir/scripts/${setup53HCP}

#Hard coded GenericfMRIVolumeProcessingPipelineBatch.sh
P0=220504GenericfMRIVolumeProcessingPipelineBatch_dircontrol.sh

#Hard coded MakeMat.sh
#P1=220524MakeMat.sh
#START220722
P1=220722MakeMat.sh

#Hard coded SmoothingProcess.sh
#P2=220721SmoothingProcess.sh
#P2=220722SmoothingProcess.sh
P2=220723SmoothingProcess.sh

#SCRIPT0=$HCPDIR/scripts/${P0}
#SCRIPT1=$HCPDIR/scripts/${P1}
#SCRIPT2=$HCPDIR/scripts/${P2}
#START220719
#SCRIPT0=$hcpdir/scripts/${P0}
#SCRIPT1=$hcpdir/scripts/${P1}
#SCRIPT2=$hcpdir/scripts/${P2}

helpmsg(){
    echo "$0"
    echo "    -dat               dat file"
    echo "    -batchScript       Output batch script."
    echo "    -hcpdir            HCP directory"
    echo "    -freesurferVersion Default is 5.3HCP. We hope to evaluate 7.2 in the future."
    echo "    -hires             T1 resolution: 0.7, 0.8 or 1mm. Default is 1mm."
    echo "    -HOSTNAME          Flag. Use machine name instead if user named file."
    echo "    -fwhm              Smoothing in mm for SUSAN. Multiple values ok."
    echo "    -paradigm_hp_sec   High pass filter cutoff in sec"
    echo "    -DATE              Flag. Add date to name of output script."
    echo "    -SMOOTHONLY        Flag. Only do the smoothing: SUSAN and high pass filtering."
    exit
    }
if((${#@}<2));then
    helpmsg
fi
dat=;bs=;lchostname=0;fwhm=;paradigm_hp_sec=;lcdate=0;lcsmoothonly=0
echo $0 $@
arg=($@)
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -dat)
            dat=${arg[((++i))]}
            echo "dat=$dat"
            ;;
        -batchScript)
            bs=${arg[((++i))]}
            echo "bs=$bs"
            ;;
        -hcpdir)
            hcpdir=${arg[((++i))]}
            echo "hcpdir=$hcpdir"
            ;;
        -freesurferVersion)
            freesurferVersion=${arg[((++i))]}
            echo "freesurferVersion=$freesurferVersion"
            ;;
        -HOSTNAME)
            lchostname=1
            echo "lchostname=$lchostname"
            ;;
        -fwhm)
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

        -paradigm_hp_sec)
            paradigm_hp_sec=${arg[((++i))]}
            echo "paradigm_hp_sec=$paradigm_hp_sec"
            ;;
        -DATE)
            lcdate=1
            echo "lcdate=$lcdate"
            ;;
        -SMOOTHONLY)
            lcsmoothonly=1
            echo "lcsmoothonly=$lcsmoothonly"
            ;;
        -h | -help | --h | --help)
            helpmsg
            ;;
        *) echo "Unexpected option: ${arg[i]}"
            ;;
    esac
done
if [ -z "${dat}" ];then
    echo "Need to specify -dat"
    exit
fi
if [ -z "${bs}" ];then
    echo "Need to specify -batchScript"
    exit
fi

#if [ -z "${hcpdir}" ];then
#    SCRIPT0=${hcpdir}/scripts/${P0}
#    SCRIPT1=${hcpdir}/scripts/${P1}
#fi
#START220719
SCRIPT0=${hcpdir}/scripts/${P0}
SCRIPT1=${hcpdir}/scripts/${P1}
SCRIPT2=${hcpdir}/scripts/${P2}

#if [ -n "${freesurferVersion}" ];then
#    if [ "${freesurferVersion}" = "5.3HCP" ];then
#        ES=$hcpdir/scripts/${setup53HCP}
#    elif [ "${freesurferVersion}" = "7.2" ];then
#        ES=$hcpdir/scripts/220209SetUpHCPPipeline_FS7.2.sh
#    else
#        echo "Unknown version of freesurfer"
#        exit
#    fi
#fi
#START220719
if [ "${freesurferVersion}" = "5.3HCP" ];then
    ES=$hcpdir/scripts/${setup53HCP}
elif [ "${freesurferVersion}" = "7.2" ];then
    ES=$hcpdir/scripts/220209SetUpHCPPipeline_FS7.2.sh
else
    echo "Unknown version of freesurfer"
    exit
fi







if [ -z "${fwhm}" ];then
    echo "-fwhm has not been specified. SUSAN noise reduction will not be performed."
    fwhm=0
fi
if [ -z "${paradigm_hp_sec}" ]; then
    echo "-paradigm_hp_sec has not been specified. High pass filtering will not be performed."
    paradigm_hp_sec=0
fi

IFS=$'\n' read -d '' -ra csv < $dat
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

    #if((lchostname==1));then
    #    dir0=${line[1]}
    #else
    #    IFS=$'/' read -ra line2 <<< ${line[1]}
    #    dir0=/$(join_by / ${line2[@]::${#line2[@]}-1})
    #    sub0=${line2[-1]}
    #    #echo "sub0=${sub0}"
    #fi
    #START220720
    dir0=${line[1]}
    if((lchostname==0));then
        IFS=$'/' read -ra line2 <<< ${line[1]}
        sub0=${line2[-2]}
    fi
    #START220720
    #if((lchostname==1));then
    #    dir0=${line[1]}
    #else
    #    IFS=$'/' read -ra line2 <<< ${line[1]}
    #    dir0=/$(join_by / ${line2[@]::${#line2[@]}-1})
    #    sub0=${line2[-2]}
    #fi
    #START220721
    IFS=$'/' read -ra line2 <<< ${line[1]}
    dir0=/$(join_by / ${line2[@]::${#line2[@]}-1})
    dirpipeline=${line[1]}
    if((lchostname==0));then
        sub0=${line2[-2]}
    fi
    dirsmooth=${dir0}/smooth

    #if((lcdate==0));then
    #    F0=${dir0}/${line[0]////_}_hcp3.27fMRIvol.sh
    #else
    #    F0=${dir0}/${line[0]////_}_hcp3.27fMRIvol_$(date +%y%m%d%H%M%S).sh
    #fi
    #START220721
    ((lcsmoothonly==0)) && l0=hcp3.27fMRIvol || l0=smooth
    if((lcdate==0));then
        F0=${dir0}/${line[0]////_}_${l0}.sh
    else
        F0=${dir0}/${line[0]////_}_${l0}_$(date +%y%m%d%H%M%S).sh
    fi

    echo ${line[0]}
    echo "    ${F0}"

    #echo -e "#!/bin/bash\n" > ${F0}
    echo -e "#!/usr/bin/env bash\n" > ${F0} 
    echo 'ES='${ES} >> ${F0}


    #echo 'P0='${SCRIPT0} >> ${F0}
    #echo 'P1='${SCRIPT1} >> ${F0}
    #echo 'P2='${SCRIPT2} >> ${F0}
    #START220721
    if((lcsmoothonly==0));then
        echo 'P0='${SCRIPT0} >> ${F0}
        echo 'P1='${SCRIPT1} >> ${F0}
    fi
    echo 'P2='${SCRIPT2} >> ${F0}


    #if((lchostname==1));then
    #    echo -e "sf0=${dir0}\n" >> ${F0}
    #else
    #    echo -e "sf0=${dir0}\ns0=${sub0}\n" >> ${F0}
    #fi
    #START220721
    echo "sf0=${line[1]}" >> ${F0}
    if((lchostname==1));then
        echo 's0=$(hostname)' >> ${F0}
    else
        echo "s0=${sub0}" >> ${F0}
    fi
    #echo -e "smooth0=${dirsmooth}\n"  >> ${F0}

    if((lcsmoothonly==0));then

        echo '${P0} \' >> ${F0}
        echo '    --StudyFolder=${sf0} \' >> ${F0}

        #if((lchostname==1));then
        #    echo '    --Subject=$(hostname) \' >> ${F0}
        #else
        #    echo '    --Subject=${s0} \' >> ${F0}
        #fi
        #START220721
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
        echo '    --EnvironmentScript=${ES}' >> ${F0}

        #START220523
        echo -e '\n${P1} \' >> ${F0}
        echo '    --example_func="\' >> ${F0}
        for((j=7;j<=23;j+=2));do
            if((bold[j]==1));then
                str0=${line[j]##*/}
                str0=${str0%.nii*}

                #echo '        ${sf0}/${s0}/MNINonLinear/Results/'${str0}/${str0}_SBRef.nii.gz${endquote[j]}' \' >> ${F0}
                #START220722
                echo '        ${sf0}/MNINonLinear/Results/'${str0}/${str0}_SBRef.nii.gz${endquote[j]}' \' >> ${F0}
            fi
        done
        echo '    --gdc="\' >> ${F0}
        for((j=7;j<=23;j+=2));do
            if((bold[j]==1));then
                str0=${line[j]##*/}
                str0=${str0%.nii*}

                #echo '        ${sf0}/${s0}/'${str0}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/WarpField.nii.gz${endquote[j]}' \' >> ${F0}
                #START220722
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

        #echo '    --t1=${sf0}/${s0}/T1w/T1w_acpc_dc_restore.nii.gz \' >> ${F0}
        #echo '    --t1brain=${sf0}/${s0}/T1w/T1w_acpc_dc_restore_brain.nii.gz \' >> ${F0}
        #START220722
        echo '    --t1=${sf0}/T1w/T1w_acpc_dc_restore.nii.gz \' >> ${F0}
        echo '    --t1brain=${sf0}/T1w/T1w_acpc_dc_restore_brain.nii.gz \' >> ${F0}


        source ${ES}
        echo '    --ref='${HCPPIPEDIR_Templates}/MNI152_T1_${hires}mm_brain.nii.gz' \' >> ${F0}

        #echo '    --EnvironmentScript=${ES}' >> ${F0}
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
    echo -e '\n${P2} \' >> ${F0}
    #echo '${P2} \' >> ${F0}

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
