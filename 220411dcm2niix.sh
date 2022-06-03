#!/bin/bash

#Set path to dcm2niix if not set elsewhere
DCM2NIIXDIR=/data/nil-bluearc/vlassenko/PKG/dcm2niix211006

P0="${DCM2NIIXDIR}/dcm2niix -w 0 -z i" #-w 0 skip duplicates

if [ ${#@} != 4 ];then
    echo "$0 <csv> <input directory> <output directory> <output script>"
    echo ""
    echo "    <csv> Ex. /export/scratch/mcavoy/bp/sub/10_200/10_200_scanlist.csv"
    echo "        Scan,Series Desc,nii"
    echo "        7,t1_mpr_1mm_p2_pos50,07_t1_mpr_1mm_p2_pos50"
    echo "        8,SpinEchoFieldMap2_AP,08_SpinEchoFieldMap2_AP"
    echo "        9,SpinEchoFieldMap2_PA,09_SpinEchoFieldMap2_PA"
    echo "        10,CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef,10_CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef"
    echo "        11,CMRR_fMRI_TASK_R1_AP_3mm_488meas,11_CMRR_fMRI_TASK_R1_AP_3mm_488meas"
    echo "        13,CMRR_fMRI_TASK_R2_AP_3mm_488meas_SBRef,13_CMRR_fMRI_TASK_R2_AP_3mm_488meas_SBRef"
    echo "        14,CMRR_fMRI_TASK_R2_AP_3mm_488meas,14_CMRR_fMRI_TASK_R2_AP_3mm_488meas"
    echo "        16,CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef,16_CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef"
    echo "        17,CMRR_fMRI_TASK_R3_AP_3mm_488meas,17_CMRR_fMRI_TASK_R3_AP_3mm_488meas"
    echo "        25,CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef,25_CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef"
    echo "        26,CMRR_fMRI_TASK_R3_AP_3mm_488meas,26_CMRR_fMRI_TASK_R3_AP_3mm_488meas"
    echo "        28,CMRR_fMRI_TASK_R4_AP_3mm_488meas_SBRef,28_CMRR_fMRI_TASK_R4_AP_3mm_488meas_SBRef"
    echo "        29,CMRR_fMRI_TASK_R4_AP_3mm_488meas,29_CMRR_fMRI_TASK_R4_AP_3mm_488meas"
    echo "        31,CMRR_fMRI_TASK_R5_AP_3mm_488meas_SBRef,31_CMRR_fMRI_TASK_R5_AP_3mm_488meas_SBRef"
    echo "        32,CMRR_fMRI_TASK_R5_AP_3mm_488meas,32_CMRR_fMRI_TASK_R5_AP_3mm_488meas"
    echo "        34,CMRR_fMRI_TASK_R6_AP_3mm_488meas_SBRef,34_CMRR_fMRI_TASK_R6_AP_3mm_488meas_SBRef"
    echo "        35,CMRR_fMRI_TASK_R6_AP_3mm_488meas,35_CMRR_fMRI_TASK_R6_AP_3mm_488meas"
    echo "        39,CMRR_fMRI_REST_R1_AP_3mm_550meas_SBRef,39CMRR_fMRI_REST_R1_AP_3mm_550meas_SBRef"
    echo "        40,CMRR_fMRI_REST_R1_AP_3mm_550meas,40_CMRR_fMRI_REST_R1_AP_3mm_550meas"
    echo "        48,CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef,48_CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef"
    echo "        49,CMRR_fMRI_TASK_R1_AP_3mm_488meas,49_CMRR_fMRI_TASK_R1_AP_3mm_488meas"
    echo "        51,CMRR_fMRI_REST_R2_AP_3mm_550meas_SBRef,51_CMRR_fMRI_REST_R2_AP_3mm_550meas_SBRef"
    echo "        52,CMRR_fMRI_REST_R2_AP_3mm_550meas,52_CMRR_fMRI_REST_R2_AP_3mm_550meas"
    echo "        54,CMRR_fMRI_REST_R3_AP_3mm_550meas_SBRef,54_CMRR_fMRI_REST_R3_AP_3mm_550meas_SBRef"
    echo "        55,CMRR_fMRI_REST_R3_AP_3mm_550meas,55_CMRR_fMRI_REST_R3_AP_3mm_550meas"
    echo "        57,t2_spc_sag_p2_iso_1.0,57_t2_spc_sag_p2_iso_1.0"
    echo "    <input directory>"
    echo "        /export/scratch/mcavoy/bp/sub/10_901/DICOM"
    echo "    <output directory>"
    echo "        /export/scratch/mcavoy/bp/sub/10_901/nii"
    echo "    <output script>"
    echo "        /export/scratch/mcavoy/bp/scriptsdcm2niix/211212_10_901.sh"
    exit
fi

id=$2;od=$3;sd=$4;
IFS=$'\n' read -d '' -ra csv < $1
#printf '%s\n' "${csv[@]}"
mkdir -p $od
echo "#!/bin/bash" > $sd
echo "" >> $sd
for((i=1;i<${#csv[@]};++i));do
    IFS=$',\n ' read -ra line <<< ${csv[i]}
    dir0=$id/${line[0]}/DICOM
    echo -e "${P0} -o ${od} -f ${line[2]} ${dir0}\n" >> $sd
done

#START220411
tr -d '\r' <${sd} >${sd}.new && mv ${sd}.new ${sd} 

chmod +x $sd
echo "Output written to $sd"
$sd > $sd.txt 2>&1 & 
echo "$sd has been executed"
