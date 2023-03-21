#!/usr/bin/env bash
#!/usr/local/bin/bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

#Hard coded location of HCP scripts
[ -z ${HCPDIR+x} ] && HCPDIR=/Users/Shared/pipeline/HCP

#START230319
[ -z ${FSLDIR+x} ] && export FSLDIR=/usr/local/fsl

#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer

#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2
#[ -z ${freesurferVersion+x} ] && freesurferVersion=7.3.2
#START230319
[ -z ${FREESURFVER+x} ] && FREESURFVER=7.3.2

#Hard coded GenericfMRIVolumeProcessingPipelineBatch.sh
P0=221103GenericfMRIVolumeProcessingPipelineBatch_dircontrol.sh

#Hard coded T1w_restore.sh 
P1=230117T1w_restore.sh

#Hard coded SmoothingProcess.sh
P2=220723SmoothingProcess.sh

#Hard coded makeregdir.sh
P3=makeregdir230314.sh

#Hard coded pipeline settings
#setup0=221203SetUpHCPPipeline.sh
#START230319
setup0=230319SetUpHCPPipeline.sh


helpmsg(){
    echo " Required: $0 <mydatfile> or $0 -d <mydatfile> or $0 --dat <mydatfile>"
    echo "    -d --dat"
    echo "        dat file. If the option is not used, the first argument is assumed to be the dat file."
    echo "    -b --batchscript"
    echo "        Optional. Instead of immediate execution, scripts are collected in the executable batchscript."
    echo "        If the number of subjects to be run exceeds the number of cores, then this option should be considered."
    echo "        Also good for debugging because the script is not executed."
    echo "    -H --HCPDIR"
    echo "        HCP directory. Optional if set at the top of this script or elsewhere."

    #echo "    -F --freesurferVersion"
    #echo "        5.3.0-HCP, 7.2.0 or 7.3.2. Default is 7.3.2 unless set elsewhere."
    #START230319
    echo "    -F --FREESURFVER -FREESURFVER"
    echo "        5.3.0-HCP, 7.2.0 or 7.3.2. Default is 7.3.2 unless set elsewhere."

    echo "    -m --HOSTNAME"
    echo "        Flag. Use machine name instead of user named file."
    echo "    -D --DATE"
    echo "        Flag. Add date to name of output script."
    echo "    -f --fwhm"
    echo "        Smoothing in mm for SUSAN. Multiple values ok."
    echo "    -p --paradigm_hp_sec"
    echo "        High pass filter cutoff in sec"
    echo "    -T --T1COPYMASKONLY"
    echo "        Flag. Only copy the T1w_restore.2 and mask to create T1w_restore_brain.2"
    echo "    -s --SMOOTHONLY"
    echo "        Flag. Only do the smoothing: SUSAN and high pass filtering."
    echo "    -c --CLEANONLY"
    echo "        Flag. Only do the cleaning: remove all directories except MNINonLinear."
    echo "    -i --CLEAN"
    echo "        Flag. Include cleaning (ie remove all directories except MNINonLinear)."
    echo "        Cleaning is normally not included because little things can go wrong and who wants to have to rerun the structural pipeline."
    echo "    -o -fsf1 --fsf1"
    echo "        Text file. List of fsf files for first-level FEAT analysis. A makeregdir call is created for each fsf."
    echo "    -t -fsf2 --fsf2"
    echo "        Text file. List of fsf files for second-level FEAT analysis. A makeregdir call is created for each fsf."
    echo "        This option will not be executed unless -o is also included."
    echo "    -M --MAKEREGDIRONLY -MAKEREGDIRONLY"
    echo "        Flag. Only write the makeregdir scripts."
    echo "    -h --help"
    echo "        Echo this help message."
    exit

    }
if((${#@}<1));then
    helpmsg
    exit
fi

dat=;bs=;lchostname=0;lcdate=0;fwhm=;paradigm_hp_sec=;lct1copymaskonly=0;lcsmoothonly=0;lccleanonly=0;lcclean=0;fsf1=;fsf2=;lcmakeregdironly=0

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

        #-F | --freesurferVersion)
        #    freesurferVersion=${arg[((++i))]}
        #    echo "freesurferVersion=$freesurferVersion"
        #    ;;
        #START230319
        -F | --FREESURFVER | -FREESURFVER)
            FREESURFVER=${arg[((++i))]}
            echo "FREESURFVER=$FREESURFVER"
            ;;

        -m | --HOSTNAME)
            lchostname=1
            echo "lchostname=$lchostname"
            ;;
        -D | --DATE)
            lcdate=1
            echo "lcdate=$lcdate"
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
            #echo "fwhm=${fwhm[@]} nelements=${#fwhm[@]}"
            echo "fwhm=${fwhm[@]}"
            ;;
        -p | --paradigm_hp_sec)
            paradigm_hp_sec=${arg[((++i))]}
            echo "paradigm_hp_sec=$paradigm_hp_sec"
            ;;

        #-t | --T1COPYMASKONLY)
        #START230313
        -T | --T1COPYMASKONLY)

            lct1copymaskonly=1
            echo "lct1copymaskonly=$lct1copymaskonly"
            ;;

        -s | --SMOOTHONLY)
            lcsmoothonly=1
            echo "lcsmoothonly=$lcsmoothonly"
            ;;
        -c | --CLEANONLY)
            lccleanonly=1
            echo "lccleanonly=$lccleanonly"
            ;;
        -i | --CLEAN)
            lcclean=1
            echo "lcclean=$lcclean"
            ;;
        -o | -fsf1 | --fsf1)
            fsf1=${arg[((++i))]}
            echo "fsf1=$fsf1"
            ;;
        -t | -fsf2 | --fsf2)
            fsf2=${arg[((++i))]}
            echo "fsf2=$fsf2"
            ;;
        -M | --MAKEREGDIRONLY | -MAKEREGDIRONLY)
            lcmakeregdironly=1
            echo "lcmakeregdironly=$lcmakeregdironly"
            ;;
        -h | --help)
            helpmsg
            exit
            ;;
        #*) echo "Unexpected option: ${arg[i]}"
        #    exit
        #    ;;
    esac
done

#if [ -z "${dat}" ];then
#    echo "Need to specify -d | --dat"
#    exit
#fi
#START230313
if [ -z "${dat}" ];then
    dat=$1
fi


if [ -z "${fwhm}" ];then
    echo "-f | --fwhm has not been specified. SUSAN noise reduction will not be performed."
    fwhm=0
fi
if [ -z "${paradigm_hp_sec}" ]; then
    echo "-p | --paradigm_hp_sec has not been specified. High pass filtering will not be performed."
    paradigm_hp_sec=0
fi


#START230313
if [ -n "${fsf1}" ];then
    IFS=$'\r\n,\t ' read -d '' -ra FSF1 < $fsf1
    #printf '%s\n' "${FSF1[@]}"
    #echo "#FSF1[@]=${#FSF1[@]}"
    outputdir1=
    for((i=0;i<${#FSF1[@]};++i));do
        #echo "here0 ${FSF1[i]}"
        #grep "set fmri(outputdir)" ${FSF1[i]}

        #START230314
        IFS=$'"' read -ra line0 < <(grep "set fmri(outputdir)" ${FSF1[i]})
        #echo "line0=${line0[@]}"
        #echo "#line0[@]=${#line0[@]}"
        outputdir1[i]=${line0[1]}
        #echo "outputdir1[$i]=${outputdir1[i]}"
    done

    if [ -n "${fsf2}" ];then
        IFS=$'\r\n^M,\t ' read -d '' -ra FSF2 < $fsf2
        #printf '%s\n' "${FSF2[@]}"
        #echo "#FSF2[@]=${#FSF2[@]}"
        outputdir2=
        for((i=0;i<${#FSF2[@]};++i));do
            #echo "here0 ${FSF2[i]}"
            #grep "set fmri(outputdir)" ${FSF2[i]}
    
            #START230314
            IFS=$'"' read -ra line0 < <(grep "set fmri(outputdir)" ${FSF2[i]})
            #echo "line0=${line0[@]}"
            #echo "#line0[@]=${#line0[@]}"
            outputdir2[i]=${line0[1]}
            #echo "outputdir2[$i]=${outputdir2[i]}"
        done
    fi
fi

SCRIPT0=${HCPDIR}/scripts/${P0}
SCRIPT1=${HCPDIR}/scripts/${P1}
SCRIPT2=${HCPDIR}/scripts/${P2}
SCRIPT3=${HCPDIR}/scripts/${P3}
ES=${HCPDIR}/scripts/${setup0}

IFS=$'\n\r' read -d '' -ra csv < $dat
#printf '%s\n' "${csv[@]}"

#START230305
if [ -z "${bs}" ];then
    num_sub=0
    for((i=0;i<${#csv[@]};++i));do
        IFS=$',\n\r ' read -ra line <<< ${csv[i]}
        if [[ "${line[0]:0:1}" = "#" ]];then
            #echo "Skiping line $((i+1))"
            continue
        fi
        ((num_sub++))
    done
    num_cores=$(sysctl -n hw.ncpu)
    ((num_sub>num_cores)) && echo "${num_sub} will be run, however $(hostname) only has ${num_cores}. Please consider -b | --batchscript."
fi


#if [[ "${freesurferVersion}" != "5.3.0-HCP" && "${freesurferVersion}" != "7.2.0" && "${freesurferVersion}" != "7.3.2" ]];then
#    echo "Unknown version of freesurfer. freesurferVersion=${freesurferVersion}"
#    exit
#fi
#START230319
if [[ "${FREESURFVER}" != "5.3.0-HCP" && "${FREESURFVER}" != "7.2.0" && "${FREESURFVER}" != "7.3.2" ]];then
    echo "Unknown version of freesurfer. FREESURFVER=${FREESURFVER}"
    exit
fi


if [ -n "${bs}" ];then
    bs0=${bs%/*}
    mkdir -p ${bs0}
    #echo -e "#!/bin/bash\n" > $bs
    echo -e "#!/usr/bin/env bash\n" > $bs
    #echo -e "#!/usr/local/bin/bash\n" > $bs
fi
wd0=$(pwd)


for((i=0;i<${#csv[@]};++i));do
    IFS=$',\n\r ' read -ra line <<< ${csv[i]}
    if [[ "${line[0]:0:1}" = "#" ]];then
        #echo "Skiping line $((i+1))"
        continue
    fi
    echo ${line[0]}

    dir0=${line[1]}${FREESURFVER}
    if [ ! -d "${dir0}" ];then
        echo "${dir0} does not exist"
        continue
    fi

    if((lcmakeregdironly==0));then
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
                            IFS=$' ,' read -ra line0 < <( grep PhaseEncodingDirection $json )
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

        if((lcsmoothonly==0)) && ((lccleanonly==0));then
            l0=hcp3.27fMRIvol 
        else
            ((lccleanonly==0)) && l0=smooth || l0=clean
        fi 

        ((lcdate==0)) && F0=${dir0}/${line[0]////_}_${l0}.sh || F0=${dir0}/${line[0]////_}_${l0}_$(date +%y%m%d).sh
        [ -n "${bs}" ] && echo "    ${F0}"


        #echo -e "#!/bin/bash\n" > ${F0}
        echo -e "#!/usr/bin/env bash\n" > ${F0} 
        #echo -e "#!/usr/local/bin/bash\n" > ${F0} 

        #echo "freesurferVersion=${freesurferVersion}" >> ${F0}
        #if((lccleanonly==0));then
        #    echo -e export FREESURFER_HOME=${FREESURFDIR}/'${freesurferVersion}'"\n" >> ${F0}
        #fi
        #START230319
        echo "FREESURFDIR=${FREESURFDIR}" >> ${F0}
        echo "FREESURFVER=${FREESURFVER}" >> ${F0}
        if((lccleanonly==0));then
            echo -e export FREESURFER_HOME='${FREESURFDIR}/${FREESURFVER}'"\n" >> ${F0}
        fi
        if [ -n "${outputdir1}" ];then
            echo "FSLDIR=${FSLDIR}" >> ${F0}
            echo -e export FSLDIR='${FSLDIR}'"\n" >> ${F0}
        fi

        if((lcsmoothonly==0)) && ((lccleanonly==0)) && ((lct1copymaskonly==0));then
            echo 'P0='${SCRIPT0} >> ${F0}
        fi
        if((lcsmoothonly==0)) && ((lccleanonly==0));then
            echo 'P1='${SCRIPT1} >> ${F0}
        fi
        if((lct1copymaskonly==0)) && ((lccleanonly==0));then
            echo 'P2='${SCRIPT2} >> ${F0}
        fi

        #START30319
        if [ -n "${outputdir1}" ];then
            #echo FSLDIR='${FSLDIR}' >> ${F0}
            echo 'P3='${SCRIPT3} >> ${F0}
        fi


        if((lccleanonly==0));then
            echo 'ES='${ES} >> ${F0}
        fi
        echo "" >> ${F0}

        echo "sf0=${line[1]}"'${FREESURFVER}' >> ${F0}

        if((lct1copymaskonly==0)) && ((lccleanonly==0));then
            if((lchostname==1));then
                echo 's0=$(hostname)' >> ${F0}
            else
                echo "s0=${sub0}" >> ${F0}
            fi
        fi

        echo "" >> ${F0}

        if((lcsmoothonly==0)) && ((lccleanonly==0)) && ((lct1copymaskonly==0));then
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
                    IFS=$' ,' read -ra line0 < <( grep PhaseEncodingDirection $json )
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
            echo '    --freesurferVersion=${FREESURFVER} \' >> ${F0}
            echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}
        fi
        if((lcsmoothonly==0)) && ((lccleanonly==0));then
            echo '${P1} \' >> ${F0}
            for((j=7;j<=23;j+=2));do
                if((bold[j]==1));then
                    str0=${line[j]##*/}
                    str0=${str0%.nii*}
                    echo '    --t1=${sf0}/'${str0}/T1w_restore.2.nii.gz' \' >> ${F0}
                    echo '    --mask=${sf0}/'${str0}/brainmask_fs.2.nii.gz' \' >> ${F0}
                    echo '    --outpath=${sf0}/MNINonLinear/Results \' >> ${F0}
                    echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}
                    break
                fi
            done
        fi

        if((lct1copymaskonly==0)) && ((lccleanonly==0));then
            declare -a endquote0
            for((j=17;j>=7;j-=2));do
                if [ "${line[j]}" != "NONE" ] && [ "${line[j]}" != "NOTUSEABLE" ];then
                    endquote0[j]='"'
                    break
                fi
            done
            echo '${P2} \' >> ${F0}
            echo '    --fMRITimeSeriesResults="\' >> ${F0}
            #for((j=7;j<=23;j+=2));do
            for((j=7;j<=17;j+=2));do #task runs only
                if((bold[j]==1));then
                    str0=${line[j]##*/}
                    str0=${str0%.nii*}
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
                        IFS=$' ,' read -ra line0 < <( grep RepetitionTime $json )
                        trstr+="${line0[1]} "
                    fi
                done
                echo '    --TR="'${trstr::-1}'" \' >> ${F0}
            fi
            echo '    --EnvironmentScript=${ES}' >> ${F0}
        fi

        #START30319
        if [ -n "${outputdir1}" ];then
            echo "" >> ${F0}
            #for((i=0;i<${#FSF1[@]};++i));do
            #    echo '${FSLDIR}'/bin/feat ${FSF1[i]} >> ${F0}
            #done
            printf '${FSLDIR}/bin/feat %s\n' "${FSF1[@]}" >> ${F0}

            echo "" >> ${F0}
            #for((j=0;j<${#outputdir1[@]};++j));do
            #    echo '${P3}' ${line[0]} ${outputdir1[j]##*/} >> ${F0}
            #done
            printf '${P3}'" ${line[0]} %s\n" "${outputdir1[@]##*/}" >> ${F0}

            if [ -n "${outputdir2}" ];then
                echo "" >> ${F0}
                printf '${FSLDIR}/bin/feat %s\n' "${FSF2[@]}" >> ${F0}
            fi

        fi


        if((lcclean==1)) || ((lccleanonly==1));then
            echo -e '\nrm -rf ${sf0}/T1w' >> ${F0}
            T2f=;T20=${line[3]}
            if [[ "${T20}" = "NONE" || "${T20}" = "NOTUSEABLE" ]];then
                #echo "    T2 ${T20}"
                :
            elif [ ! -f "${T20}" ];then
                #echo "    T2 ${T20} not found"
                :
            else
                T2f=${T20}
                #echo "    T2 ${T2f}"
                echo 'rm -rf ${sf0}/T2w' >> ${F0}
            fi
            for((j=7;j<=23;j+=2));do
                if((bold[j]==1));then
                    str0=${line[j]##*/}
                    str0=${str0%.nii*}
                    echo 'rm -rf ${sf0}/'${str0} >> ${F0}
                fi
            done
        fi 

        chmod +x ${F0}
        if [ -n "${bs}" ];then
            echo "${F0} > ${F0}.txt 2>&1 &" >> $bs
        else
            cd ${dir0}
            ${F0} > ${F0}.txt 2>&1 &
            cd ${wd0} #"cd -" echoes the path
            echo "    ${F0} has been executed"
        fi
    fi

    #if [ -n "${outputdir1}" ];then
    #START230319
    if [ -n "${outputdir1}" ] && ((lcmakeregdironly==1));then

        l0=makeregdir1
        ((lcdate==0)) && F0=${dir0}/${line[0]////_}_${l0}.sh || F0=${dir0}/${line[0]////_}_${l0}_$(date +%y%m%d).sh
        echo -e "#!/usr/bin/env bash\n" > ${F0}
        echo -e "P0=${SCRIPT3}\n" >> ${F0}
        for((j=0;j<${#outputdir1[@]};++j));do
            #echo '${P0}' ${line[0]} ${outputdir1[j]} >> ${F0}
            echo '${P0}' ${line[0]} ${outputdir1[j]##*/} >> ${F0}
        done
        chmod +x ${F0}
        echo "    Output written to ${F0}"

        if [ -n "${outputdir2}" ];then
            l0=makeregdir2
            ((lcdate==0)) && F0=${dir0}/${line[0]////_}_${l0}.sh || F0=${dir0}/${line[0]////_}_${l0}_$(date +%y%m%d).sh
            echo -e "#!/usr/bin/env bash\n" > ${F0}
            echo -e "P0=${SCRIPT3}\n" >> ${F0}
            for((j=0;j<${#outputdir2[@]};++j));do
                echo '${P0}' ${line[0]} ${outputdir2[j]##*/} >> ${F0}
            done
            chmod +x ${F0}
            echo "    Output written to ${F0}"
        fi
    fi



    unset endquote;unset bold;unset PED;unset endquote0
done
if [ -n "${bs}" ];then
    chmod +x $bs
    echo "Output written to $bs"
fi
