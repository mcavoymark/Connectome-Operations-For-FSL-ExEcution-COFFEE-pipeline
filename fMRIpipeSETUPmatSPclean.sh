#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

#Hard coded location of HCP scripts
[ -z ${HCPDIR+x} ] && HCPDIR=/Users/Shared/pipeline/HCP

#START230319
[ -z ${FSLDIR+x} ] && export FSLDIR=/usr/local/fsl

#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer

#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2
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
setup0=230319SetUpHCPPipeline.sh

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} <mydatfile>"
    echo "    -d --dat -dat"
    echo "        dat file(s). Arguments without options are assumed to be dat files."
    echo "        Ex 1. ${root0} 1001.dat 2000.dat"
    echo "        Ex 2. ${root0} \"1001.dat -d 2000.dat\""
    echo "        Ex 3. ${root0} -d 1001.dat 2000.dat"
    echo "        Ex 4. ${root0} -d \"1001.dat 2000.dat\""
    echo "        Ex 5. ${root0} -d 1001.dat -d 2000.dat"
    echo "        Ex 6. ${root0} 1001.dat -d 2000.dat"
    echo "    -A --autorun -autorun --AUTORUN -AUTORUN"
    echo "        Flag. Automatically execute script. Default is not execute *_autorun.sh"
    echo "    -b --batchscript -batchscript"
    echo "        *_autorun.sh scripts are collected in the executable batchscript."
    echo "    -H --HCPDIR -HCPDIR --hcpdir -hcpdir"
    echo "        HCP directory. Optional if set at the top of this script or elsewhere via variable HCPDIR."
    echo "    -F --FREESURFVER -FREESURFVER --freesurferVersion -freesurferVersion"
    echo "        5.3.0-HCP, 7.2.0 or 7.3.2. Default is 7.3.2 unless set elsewhere via variable FREESURFVER."
    echo "    -m --HOSTNAME"
    echo "        Flag. Use machine name instead of user named file."
    echo "    -D --DATE -DATE --date -date"
    echo "        Flag. Add date (YYMMDD) to name of output script."
    echo "    -DL --DL --DATELONG -DATELONG --datelong -datelong"
    echo "        Flag. Add date (YYMMDDHHMMSS) to name of output script."

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
    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

lcautorun=0;bs=;lchostname=0;lcdate=0;fwhm=;paradigm_hp_sec=;lct1copymaskonly=0;lcsmoothonly=0;lccleanonly=0;lcclean=0;fsf1=;fsf2=;lcmakeregdironly=0 #do not set dat or unexpected

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -d | --dat | -dat)
            dat+=(${arg[((++i))]})
            for((j=i;j<${#@};++i));do #i is incremented only if dat is appended
                dat0=(${arg[((++j))]})
                [ "${dat0::1}" = "-" ] && break
                dat+=(${dat0[@]})
            done
            ;;
        -A | --autorun | -autorun | --AUTORUN | -AUTORUN)
            lcautorun=1
            echo "lcautorun=$lcautorun"
            ;;
        -b | --batchScript | -batchscript)
            bs=${arg[((++i))]}
            echo "bs=$bs"
            ;;
        -H | --HCPDIR | -HCPDIR | --hcpdir | -hcpdir)
            HCPDIR=${arg[((++i))]}
            echo "HCPDIR=$HCPDIR"
            ;;
        -F | --FREESURFVER | -FREESURFVER | --freesurferVersion | -freesurferVersion)
            FREESURFVER=${arg[((++i))]}
            echo "FREESURFVER=$FREESURFVER"
            ;;
        -m | --HOSTNAME)
            lchostname=1
            echo "lchostname=$lchostname"
            ;;
        -D | --DATE | -DATE | --date | -date)
            lcdate=1
            echo "lcdate=$lcdate"
            ;;
        -DL | --DL | --DATELONG | -DATELONG | --datelong | -datelong)
            lcdate=2
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
        -h | --help | -help)
            helpmsg
            exit
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done
[ -n "${unexpected}" ] && dat+=(${unexpected[@]})
if [ -z "${dat}" ];then
    echo "Need to provide dat file"
    exit
fi
#echo "dat[@]=${dat[@]}"
#echo "#dat[@]=${#dat[@]}"


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
    IFS=$'\r\n,\t ' read -d '' -ra FSF1 < $fsf1
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
        IFS=$'\r\n,\t ' read -d '' -ra FSF2 < $fsf2
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

#IFS=$'\r\n' read -d '' -ra csv < $dat
#START230405
for((i=0;i<${#dat[@]};++i));do
    IFS=$'\r\n' read -d '' -ra csv0 < ${dat[i]}
    csv+=("${csv0[@]}")
done
#printf '%s\n' "${csv[@]}"


#START230305
if [ -z "${bs}" ];then
    num_sub=0
    for((i=0;i<${#csv[@]};++i));do

        #IFS=$'\r\n,\t ' read -ra line <<< ${csv[i]}
        #START230404
        IFS=$'\r\n\t, ' read -ra line <<< ${csv[i]}

        if [[ "${line[0]:0:1}" = "#" ]];then
            #echo "Skiping line $((i+1))"
            continue
        fi
        ((num_sub++))
    done
    num_cores=$(sysctl -n hw.ncpu)
    ((num_sub>num_cores)) && echo "${num_sub} will be run, however $(hostname) only has ${num_cores}. Please consider -b | --batchscript."
fi

if [[ "${FREESURFVER}" != "5.3.0-HCP" && "${FREESURFVER}" != "7.2.0" && "${FREESURFVER}" != "7.3.2" ]];then
    echo "Unknown version of freesurfer. FREESURFVER=${FREESURFVER}"
    exit
fi

if [ -n "${bs}" ];then
    bs0=${bs%/*}
    mkdir -p ${bs0}
    echo -e "$shebang\n" > $bs
fi
wd0=$(pwd)


for((i=0;i<${#csv[@]};++i));do

    #IFS=$',\r\n ' read -ra line <<< ${csv[i]}
    IFS=$'\r\n\t, ' read -ra line <<< ${csv[i]}


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

    #START230326
    if((lcdate==1));then
        date0=$(date +%y%m%d)
    elif((lcdate==2));then
        date0=$(date +%y%m%d%H%M%S)
    fi
    #echo "date0=${date0}"


    F0=
    if((lcmakeregdironly==0));then
        if((lcsmoothonly==0)) && ((lccleanonly==0));then
            l0=hcp3.27fMRIvol 
        else
            ((lccleanonly==0)) && l0=smooth || l0=clean
        fi 
    else
        l0=makeregdir
    fi


    #((lcdate==0)) && F0[0]=${dir0}/${line[0]////_}_${l0}.sh || F0[0]=${dir0}/${line[0]////_}_${l0}_${date0}.sh
    #if((lcmakeregdironly==0));then
    #    ((lcdate==0)) && F0[1]=${dir0}/${line[0]////_}_makeregdir.sh || F0[1]=${dir0}/${line[0]////_}_makeregdir_${date0}.sh
    #fi
    #START230405
    ((lcdate==0)) && F0stem=${dir0}/${line[0]////_}_${l0} || F0stem=${dir0}/${line[0]////_}_${l0}_${date0}
    F0[0]=${F0stem}.sh
    F1=${F0stem}_autorun.sh
    if((lcmakeregdironly==0)) && [ -n "${outputdir1}" ];then
        ((lcdate==0)) && F0[1]=${dir0}/${line[0]////_}_makeregdir.sh || F0[1]=${dir0}/${line[0]////_}_makeregdir_${date0}.sh
    fi

    #echo "here0 #F0[@]=${#F0[@]}"
    for((j=0;j<${#F0[@]};++j));do
        echo -e "$shebang\n" > ${F0[j]} 
        echo -e "#$0 $@\n" >> ${F0[j]}
    done 
    echo -e "$shebang\n" > ${F1}

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
    fi
    if((lcmakeregdironly==0));then
        echo "FREESURFDIR=${FREESURFDIR}" >> ${F0[0]}
        echo "FREESURFVER=${FREESURFVER}" >> ${F0[0]}
        if((lccleanonly==0));then
            echo -e export FREESURFER_HOME='${FREESURFDIR}/${FREESURFVER}'"\n" >> ${F0[0]}
        fi
    fi
    if [ -n "${outputdir1}" ];then
        for((j=0;j<${#F0[@]};++j));do
            echo "FSLDIR=${FSLDIR}" >> ${F0[j]}
            echo -e export FSLDIR='${FSLDIR}'"\n" >> ${F0[j]}
        done
    fi
    if((lcmakeregdironly==0));then
        if((lcsmoothonly==0)) && ((lccleanonly==0)) && ((lct1copymaskonly==0));then
            echo 'P0='${SCRIPT0} >> ${F0[0]}
        fi
        if((lcsmoothonly==0)) && ((lccleanonly==0));then
            echo 'P1='${SCRIPT1} >> ${F0[0]}
        fi
        if((lct1copymaskonly==0)) && ((lccleanonly==0));then
            echo 'P2='${SCRIPT2} >> ${F0[0]}
        fi
    fi
    if [ -n "${outputdir1}" ];then
        for((j=0;j<${#F0[@]};++j));do
            echo 'P3='${SCRIPT3} >> ${F0[j]}
        done
    fi
    if((lcmakeregdironly==0));then
        ((lccleanonly==0)) && echo 'ES='${ES} >> ${F0[0]}
        echo "" >> ${F0[0]}
        echo "sf0=${line[1]}"'${FREESURFVER}' >> ${F0[0]}
        if((lct1copymaskonly==0)) && ((lccleanonly==0));then
            if((lchostname==1));then
                echo 's0=$(hostname)' >> ${F0[0]}
            else
                IFS=$'/' read -ra line2 <<< ${line[1]}
                sub0=${line2[-2]}
                echo "s0=${sub0}" >> ${F0[0]}
            fi
        fi
        echo "" >> ${F0[0]}

        #START230502
        lcbadFM=0;lcjsonNOTFOUND=0

        if((lcsmoothonly==0)) && ((lccleanonly==0)) && ((lct1copymaskonly==0));then
            echo '${P0} \' >> ${F0[0]}
            echo '    --StudyFolder=${sf0} \' >> ${F0[0]}
            echo '    --Subject=${s0} \' >> ${F0[0]}
            echo '    --runlocal \' >> ${F0[0]}

            declare -a endquote
            for((j=23;j>=7;j-=2));do
                if [ "${line[j]}" != "NONE" ] && [ "${line[j]}" != "NOTUSEABLE" ];then
                    endquote[j]='"'
                    break
                fi
            done
            echo '    --fMRITimeSeries="\' >> ${F0[0]}
            for((j=7;j<=23;j+=2));do
                ((${bold[j]}==1)) && echo '        '${line[j]}${endquote[j]}' \' >> ${F0[0]}
            done
            if((lcSBRef>0));then
                echo '    --fMRISBRef="\' >> ${F0[0]}
                for((j=6;j<=22;j+=2));do
                    if((${bold[j+1]}==1));then
                        echo '        '${bold[j]}${endquote[j+1]}' \' >> ${F0[0]}
                    fi
                done
            fi

            declare -a PED;
            if [[ "${line[4]}" != "NONE" && "${line[4]}" != "NOTUSEABLE" && "${line[5]}" != "NONE" && "${line[5]}" != "NOTUSEABLE" ]];then
                for((j=4;j<=5;j++));do
                    json=${line[j]%%.*}.json
                    if [ ! -f $json ];then
                        echo "    $json not found"
                        rm -f ${F0[0]}

                        #START230502
                        lcjsonNOTFOUND=1

                        continue
                    fi
                    IFS=$' ,' read -ra line0 < <( grep PhaseEncodingDirection $json )
                    IFS=$'"' read -ra line1 <<< ${line0[1]}
                    PED[j]=${line1[1]}
                done


                #for((j=4;j<5;j+=2));do
                #    if [[ "${PED[j]}" = "${PED[j+1]}" ]];then
                #        echo "ERROR: ${line[j]} ${PED[j]}, ${line[j+1]} ${PED[j+1]}. Fieldmap phases should be opposite."
                #        lcbadFM=1 
                #    fi
                #done
                #START230502
                if((lcjsonNOTFOUND==0));then
                    for((j=4;j<5;j+=2));do
                        if [[ "${PED[j]}" = "${PED[j+1]}" ]];then
                            echo "ERROR: ${line[j]} ${PED[j]}, ${line[j+1]} ${PED[j+1]}. Fieldmap phases should be opposite."
                            lcbadFM=1 
                        fi
                    done
                fi


                #if((lcbadFM==0));then
                #START230502
                if((lcjsonNOTFOUND==0)) && ((lcbadFM==0));then

                    for((j=4;j<=5;j++));do
                        if [[ "${PED[j]}" == "j-" ]];then
                            echo '    --SpinEchoPhaseEncodeNegative="\' >> ${F0[0]}
                            for((k=7;k<=23;k+=2));do
                                if((${bold[k]}==1));then
                                    echo '        '${line[j]}${endquote[k]}' \' >> ${F0[0]}
                                fi
                            done
                        elif [[ "${PED[j]}" == "j" ]];then
                            echo '    --SpinEchoPhaseEncodePositive="\' >> ${F0[0]}
                            for((k=7;k<=23;k+=2));do
                                if((${bold[k]}==1));then
                                    echo '        '${line[j]}${endquote[k]}' \' >> ${F0[0]}
                                fi
                            done
                        else
                            echo "ERROR: ${line[j]} ${PED[j]} Unknown phase encoding direction."
                            rm -f ${F0[0]}
                            continue
                        fi
                    done
                fi
            fi

            #echo '    --freesurferVersion=${FREESURFVER} \' >> ${F0[0]}
            #echo -e '    --EnvironmentScript=${ES}\n' >> ${F0[0]}
            #START230502
            if((lcjsonNOTFOUND==0)) && ((lcbadFM==0));then
                echo '    --freesurferVersion=${FREESURFVER} \' >> ${F0[0]}
                echo -e '    --EnvironmentScript=${ES}\n' >> ${F0[0]}
            fi

        fi

        #if((lcsmoothonly==0)) && ((lccleanonly==0));then
        #START230502
        if((lcsmoothonly==0)) && ((lccleanonly==0)) && ((lcjsonNOTFOUND==0)) && ((lcbadFM==0));then

            echo '${P1} \' >> ${F0[0]}
            for((j=7;j<=23;j+=2));do
                if((bold[j]==1));then
                    str0=${line[j]##*/}
                    str0=${str0%.nii*}
                    echo '    --t1=${sf0}/'${str0}/T1w_restore.2.nii.gz' \' >> ${F0[0]}
                    echo '    --mask=${sf0}/'${str0}/brainmask_fs.2.nii.gz' \' >> ${F0[0]}
                    echo '    --outpath=${sf0}/MNINonLinear/Results \' >> ${F0[0]}
                    echo -e '    --EnvironmentScript=${ES}\n' >> ${F0[0]}
                    break
                fi
            done
        fi

        #if((lct1copymaskonly==0)) && ((lccleanonly==0));then
        #START230502
        if((lct1copymaskonly==0)) && ((lccleanonly==0)) && ((lcjsonNOTFOUND==0)) && ((lcbadFM==0));then

            declare -a endquote0
            for((j=17;j>=7;j-=2));do
                if [ "${line[j]}" != "NONE" ] && [ "${line[j]}" != "NOTUSEABLE" ];then
                    endquote0[j]='"'
                    break
                fi
            done
            echo '${P2} \' >> ${F0[0]}
            echo '    --fMRITimeSeriesResults="\' >> ${F0[0]}
            #for((j=7;j<=23;j+=2));do
            for((j=7;j<=17;j+=2));do #task runs only
                if((bold[j]==1));then
                    str0=${line[j]##*/}
                    str0=${str0%.nii*}
                    echo '        ${sf0}/MNINonLinear/Results/'${str0}/${str0}.nii.gz${endquote0[j]}' \' >> ${F0[0]}
                fi
            done
            if((${fwhm[0]}>0));then
                echo '    --fwhm="'${fwhm[@]}'" \' >> ${F0[0]}
            fi
            if((paradigm_hp_sec>0));then
                echo '    --paradigm_hp_sec="'${paradigm_hp_sec}'" \' >> ${F0[0]}
                trstr=
                #for((j=7;j<=23;j+=2));do
                for((j=7;j<=17;j+=2));do #task runs only
                    if((bold[j]==1));then
                        json=${line[j]%%.*}.json
                        if [ ! -f $json ];then
                            echo "    $json not found"
                            rm -f ${F0[0]}
                            continue
                        fi
                        IFS=$' ,' read -ra line0 < <( grep RepetitionTime $json )
                        trstr+="${line0[1]} "
                    fi
                done
                echo '    --TR="'${trstr::-1}'" \' >> ${F0[0]}
            fi
            echo '    --EnvironmentScript=${ES}' >> ${F0[0]}
        fi
    fi
    if [ -n "${outputdir1}" ];then
        for((j=0;j<${#F0[@]};++j));do
            echo "" >> ${F0[j]}
            printf '${FSLDIR}/bin/feat %s\n' "${FSF1[@]}" >> ${F0[j]}
            echo "" >> ${F0[j]}
            printf '${P3}'" ${line[0]} %s\n" "${outputdir1[@]##*/}" >> ${F0[j]}
            if [ -n "${outputdir2}" ];then
                echo "" >> ${F0[j]}
                printf '${FSLDIR}/bin/feat %s\n' "${FSF2[@]}" >> ${F0[j]}
            fi
        done
    fi
    if((lcmakeregdironly==0));then
        if((lcclean==1)) || ((lccleanonly==1));then
            echo -e '\nrm -rf ${sf0}/T1w' >> ${F0[0]}
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
                echo 'rm -rf ${sf0}/T2w' >> ${F0[0]}
            fi
            for((j=7;j<=23;j+=2));do
                if((bold[j]==1));then
                    str0=${line[j]##*/}
                    str0=${str0%.nii*}
                    echo 'rm -rf ${sf0}/'${str0} >> ${F0[0]}
                fi
            done
        fi 
    fi


    #echo "${F0[0]} > ${F0[0]}.txt 2>&1 &" >> ${F1}
    #for((j=0;j<${#F0[@]};++j));do
    #    chmod +x ${F0[j]}
    #    echo "    Output written to ${F0[j]}"
    #done
    #chmod +x ${F1}
    #echo "    Output written to ${F1}"
    #START230502
    if [ -f "${F0[0]}" ];then
        echo "${F0[0]} > ${F0[0]}.txt 2>&1 &" >> ${F1}
        for((j=0;j<${#F0[@]};++j));do
            chmod +x ${F0[j]}
            echo "    Output written to ${F0[j]}"
        done
        chmod +x ${F1}
        echo "    Output written to ${F1}"
    else
        rm -f ${F1}
    fi


    if [ -n "${bs}" ];then
        echo "cd ${dir0}" >> $bs
        echo -e "${F0[0]} > ${F0[0]}.txt 2>&1 &\n" >> $bs
    fi 
    if((lcautorun==1 && lcmakeregdironly==0));then
        cd ${dir0}

        #${F0[0]} > ${F0[0]}.txt 2>&1 &
        #START230409
        ${F1}
        echo "    ${F1} has been executed"

        cd ${wd0} #"cd -" echoes the path

        #START230409
        #echo "    ${F0[0]} has been executed"
    fi

    unset endquote;unset bold;unset PED;unset endquote0
done
if [ -n "${bs}" ];then
    chmod +x $bs
    echo "Output written to $bs"
fi
