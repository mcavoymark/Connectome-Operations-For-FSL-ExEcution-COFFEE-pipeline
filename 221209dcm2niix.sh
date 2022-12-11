#!/usr/local/bin/bash

#Hard coded location of dcm2niix
[ -z ${DCM2NIIXDIR+x} ] && DCM2NIIXDIR=/Users/Shared/pipeline

P0="${DCM2NIIXDIR}/dcm2niix -w 0 -z i" #-w 0 skip duplicates


#if [ ${#@} != 4 ];then
#    echo "$0 <csv> <input directory> <output directory> <output script>"
#    echo ""
#    echo "    <csv> Ex. /export/scratch/mcavoy/bp/sub/10_200/10_200_scanlist.csv"
#    echo "        Scan,Series Desc,nii"
#    echo "        7,t1_mpr_1mm_p2_pos50,07_t1_mpr_1mm_p2_pos50"
#    echo "        8,SpinEchoFieldMap2_AP,08_SpinEchoFieldMap2_AP"
#    echo "        9,SpinEchoFieldMap2_PA,09_SpinEchoFieldMap2_PA"
#    echo "        10,CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef,10_CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef"
#    echo "        11,CMRR_fMRI_TASK_R1_AP_3mm_488meas,11_CMRR_fMRI_TASK_R1_AP_3mm_488meas"
#    echo "        13,CMRR_fMRI_TASK_R2_AP_3mm_488meas_SBRef,13_CMRR_fMRI_TASK_R2_AP_3mm_488meas_SBRef"
#    echo "        14,CMRR_fMRI_TASK_R2_AP_3mm_488meas,14_CMRR_fMRI_TASK_R2_AP_3mm_488meas"
#    echo "        16,CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef,16_CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef"
#    echo "        17,CMRR_fMRI_TASK_R3_AP_3mm_488meas,17_CMRR_fMRI_TASK_R3_AP_3mm_488meas"
#    echo "        25,CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef,25_CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef"
#    echo "        26,CMRR_fMRI_TASK_R3_AP_3mm_488meas,26_CMRR_fMRI_TASK_R3_AP_3mm_488meas"
#    echo "        28,CMRR_fMRI_TASK_R4_AP_3mm_488meas_SBRef,28_CMRR_fMRI_TASK_R4_AP_3mm_488meas_SBRef"
#    echo "        29,CMRR_fMRI_TASK_R4_AP_3mm_488meas,29_CMRR_fMRI_TASK_R4_AP_3mm_488meas"
#    echo "        31,CMRR_fMRI_TASK_R5_AP_3mm_488meas_SBRef,31_CMRR_fMRI_TASK_R5_AP_3mm_488meas_SBRef"
#    echo "        32,CMRR_fMRI_TASK_R5_AP_3mm_488meas,32_CMRR_fMRI_TASK_R5_AP_3mm_488meas"
#    echo "        34,CMRR_fMRI_TASK_R6_AP_3mm_488meas_SBRef,34_CMRR_fMRI_TASK_R6_AP_3mm_488meas_SBRef"
#    echo "        35,CMRR_fMRI_TASK_R6_AP_3mm_488meas,35_CMRR_fMRI_TASK_R6_AP_3mm_488meas"
#    echo "        39,CMRR_fMRI_REST_R1_AP_3mm_550meas_SBRef,39CMRR_fMRI_REST_R1_AP_3mm_550meas_SBRef"
#    echo "        40,CMRR_fMRI_REST_R1_AP_3mm_550meas,40_CMRR_fMRI_REST_R1_AP_3mm_550meas"
#    echo "        48,CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef,48_CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef"
#    echo "        49,CMRR_fMRI_TASK_R1_AP_3mm_488meas,49_CMRR_fMRI_TASK_R1_AP_3mm_488meas"
#    echo "        51,CMRR_fMRI_REST_R2_AP_3mm_550meas_SBRef,51_CMRR_fMRI_REST_R2_AP_3mm_550meas_SBRef"
#    echo "        52,CMRR_fMRI_REST_R2_AP_3mm_550meas,52_CMRR_fMRI_REST_R2_AP_3mm_550meas"
#    echo "        54,CMRR_fMRI_REST_R3_AP_3mm_550meas_SBRef,54_CMRR_fMRI_REST_R3_AP_3mm_550meas_SBRef"
#    echo "        55,CMRR_fMRI_REST_R3_AP_3mm_550meas,55_CMRR_fMRI_REST_R3_AP_3mm_550meas"
#    echo "        57,t2_spc_sag_p2_iso_1.0,57_t2_spc_sag_p2_iso_1.0"
#    echo "    <input directory>"
#    echo "        /export/scratch/mcavoy/bp/sub/10_901/DICOM"
#    echo "    <output directory>"
#    echo "        /export/scratch/mcavoy/bp/sub/10_901/nii"
#    echo "    <output script>"
#    echo "        /export/scratch/mcavoy/bp/scriptsdcm2niix/211212_10_901.sh"
#    exit
#fi
id=$2;od=$3;sd=$4;
helpmsg(){
    #echo "$0"
    echo "    Minimal: dcm2niix <scanlist.csv>"
    echo "             Ex. $0 /Users/Shared/10_Connectivity/05_20/05_20_scanlist_2fields.csv"
    echo "                 Dicoms read from /Users/Shared/10_Connectivity/05_20/dicom"
    echo "                 Niftis written to /Users/Shared/10_Connectivity/05_20/nifti"
    echo "                 Script written to scripts/dcm2niix/05_20_scanlist_2fields.sh"
    echo ""
    echo "    -s | --sub         scanlist.csv."
    echo "                       First row is labels. Currently no used. "
    echo "                       Two or more columns. First column identifies the dicom directory. Last column is the output name of the nifti."
    echo "                       Ex. Scan,nii"
    echo "                           16,run1_RH_SBRef"
    echo "                           17,run1_RH"
    echo "                       This would produce two niftis: 1) <out dir>/run1_RH_SBRef.nii.gz from dicoms <in dir>/16/DICOM"
    echo "                                                      2) <out dir>/run1_RH.nii.gz from dicoms <in dir>/17/DICOM"
    echo "    -I | --indir       <in dir> Input directory. Location of dicoms. Ex. /Users/Shared/10_Connectivity/05_20/dicom"
    echo "                       Ex. /Users/Shared/10_Connectivity/05_20/dicom"
    echo "    -O | --outdir      <out dir> Output directory. Where to write niftis. Ex. /Users/Shared/10_Connectivity/05_20/nifti"
    echo "                       Ex. /Users/Shared/10_Connectivity/05_20/nifti"
    echo "    -b | --batchscript Name of output script. Ex. /Users/Shared/10_Connectivity/scripts/dcm2niix/05_20_2fields.sh"
    echo "                       Ex. /Users/Shared/10_Connectivity/scripts/dcm2niix/05_20_2fields.sh"
    #echo "    -D | --DATE        Flag. Add date to name of output script."
    echo "    -h | --help        Echo this help message."
    exit
    }
echo $0 $@
arg=($@)
c0=;id=;od=;sd=;#lcdate=0
if((${#@}<1));then
    helpmsg
    exit
elif((${#@}==1)) && [[ $1 != "-h" && $1 != "--help" ]];then
    dat=$1
    id=${1%/*}/dicom
    od=${1%/*}/nifti
    sd0=scripts/dcm2niix
    mkdir -p ${sd0}
    root=${1##*/}
    sd=${sd0}/${root%%.*}.sh
else
    for((i=0;i<${#@};++i));do
        #echo "i=$i ${arg[i]}"
        case "${arg[i]}" in
            -s | --sub)
                dat=${arg[((++i))]}
                echo "dat=$dat"
                ;;
            -I | --indir)
                id=${arg[((++i))]}
                echo "id=$id"
                ;;
            -O | --outdir)
                od=${arg[((++i))]}
                echo "od=$od"
                ;;
            -b | --batchScript)
                bs=${arg[((++i))]}
                echo "bs=$bs"
                ;;
            #-D | --DATE)
            #    lcdate=1
            #    echo "lcdate=$lcdate"
            #    ;;
            -h | --help)
                helpmsg
                exit
                ;;
            *) echo "Unexpected option: ${arg[i]}"
                ;;
        esac
    done
fi


#IFS=$'\n' read -d '' -ra csv < $1
#IFS=$'\n' read -d '' -ra csv < $dat
#START221210
IFS=$'\n\r' read -d '' -ra csv < $dat

#printf '%s\n' "${csv[@]}"
mkdir -p $od

echo "#!/usr/local/bin/bash" > $sd

echo "" >> $sd
for((i=1;i<${#csv[@]};++i));do
    IFS=$',' read -ra line <<< ${csv[i]}
    dir0=$id/${line[0]}/DICOM
    echo -e "${P0} -o ${od} -f ${line[((${#line[@]}-1))]} ${dir0}\n" >> $sd
done

#START220411
tr -d '\r' <${sd} >${sd}.new && mv ${sd}.new ${sd} 

chmod +x $sd
echo "Output written to $sd"
$sd > $sd.txt 2>&1 & 
echo "$sd has been executed"
