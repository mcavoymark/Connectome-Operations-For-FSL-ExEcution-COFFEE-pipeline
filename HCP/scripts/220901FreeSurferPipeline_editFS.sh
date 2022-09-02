#!/usr/bin/env bash 
set -e

#P0=/home/usr/mcavoy/HCP/scripts/200305FreeSurferHiresWhite.sh
#P1=/home/usr/mcavoy/HCP/scripts/200305FreeSurferHiresPial.sh
#START220209
#P0=${HCPMOD}/200305FreeSurferHiresWhite.sh
#START220308
#P0=${HCPMOD}/220308FreeSurferHiresWhite.sh
P0=${HCPMOD}/220806FreeSurferHiresWhite.sh
#P1=${HCPMOD}/200305FreeSurferHiresPial.sh
P1=${HCPMOD}/220807FreeSurferHiresPial.sh

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR 

########################################## PIPELINE OVERVIEW ########################################## 

#TODO

########################################## OUTPUT DIRECTORIES ########################################## 

#TODO

# --------------------------------------------------------------------------------
#  Load Function Libraries
# --------------------------------------------------------------------------------

source $HCPPIPEDIR/global/scripts/log.shlib  # Logging related functions
source $HCPPIPEDIR/global/scripts/opts.shlib # Command line option functions

########################################## SUPPORT FUNCTIONS ########################################## 

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

show_usage() {
    echo "Usage information To Be Written"
    exit 1
}

# --------------------------------------------------------------------------------
#   Establish tool name for logging
# --------------------------------------------------------------------------------
#log_SetToolName "FreeSurferPipeline.sh"
#START200220
log_SetToolName "$0"

################################################## OPTION PARSING #####################################################

opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
    show_usage
fi

log_Msg "Parsing Command Line Options"

# Input Variables
SubjectID=`opts_GetOpt1 "--subject" $@` #FreeSurfer Subject ID Name
SubjectDIR=`opts_GetOpt1 "--subjectDIR" $@` #Location to Put FreeSurfer Subject's Folder
T1wImage=`opts_GetOpt1 "--t1" $@` #T1w FreeSurfer Input (Full Resolution)
T1wImageBrain=`opts_GetOpt1 "--t1brain" $@` 
T2wImage=`opts_GetOpt1 "--t2" $@` #T2w FreeSurfer Input (Full Resolution)
recon_all_seed=`opts_GetOpt1 "--seed" $@`

#START200219
editFS=`opts_GetOpt1 "--editFS" $@`
singlereconall=`opts_GetOpt1 "--singlereconall" $@`
FSeditDIR=`opts_GetOpt1 "--FSeditDIR" $@`
FSeditSUB=`opts_GetOpt1 "--FSeditSUB" $@`

#START220308
startHiresWhite=`opts_GetOpt1 "--startHiresWhite" $@`
#START201015
startHiresPial=`opts_GetOpt1 "--startHiresPial" $@`


# ------------------------------------------------------------------------------
#  Show Command Line Options
# ------------------------------------------------------------------------------

log_Msg "Finished Parsing Command Line Options"
log_Msg "SubjectID: ${SubjectID}"
log_Msg "SubjectDIR: ${SubjectDIR}"
log_Msg "T1wImage: ${T1wImage}"
log_Msg "T1wImageBrain: ${T1wImageBrain}"
log_Msg "T2wImage: ${T2wImage}"
log_Msg "recon_all_seed: ${recon_all_seed}"

#START200219
log_Msg "editFS: ${editFS}"
log_Msg "singlereconall: ${singlereconall}"
log_Msg "FSeditDIR: ${FSeditDIR}"
log_Msg "FSeditSUB: ${FSeditSUB}"
#START220308
log_Msg "startHiresWhite: ${startHiresWhite}"
log_Msg "startHiresPial: ${startHiresPial}"


# figure out whether to include a random seed generator seed in all the recon-all command lines
seed_cmd_appendix=""
if [ -z "${recon_all_seed}" ] ; then
	seed_cmd_appendix=""
else
	seed_cmd_appendix="-norandomness -rng-seed ${recon_all_seed}"
fi
log_Msg "seed_cmd_appendix: ${seed_cmd_appendix}"

# ------------------------------------------------------------------------------
#  Show Environment Variables
# ------------------------------------------------------------------------------

log_Msg "HCPPIPEDIR: ${HCPPIPEDIR}"
log_Msg "HCPPIPEDIR_FS: ${HCPPIPEDIR_FS}"

# ------------------------------------------------------------------------------
#  Identify Tools
# ------------------------------------------------------------------------------

which_flirt=`which flirt`
flirt_version=`flirt -version`
log_Msg "which flirt: ${which_flirt}"
log_Msg "flirt -version: ${flirt_version}"

which_applywarp=`which applywarp`
log_Msg "which applywarp: ${which_applywarp}"

which_fslstats=`which fslstats`
log_Msg "which fslstats: ${which_fslstats}"

which_fslmaths=`which fslmaths`
log_Msg "which fslmaths: ${which_fslmaths}"

which_recon_all=`which recon-all`
recon_all_version=`recon-all --version`
log_Msg "which recon-all: ${which_recon_all}"
log_Msg "recon-all --version: ${recon_all_version}"

which_mri_convert=`which mri_convert`
log_Msg "which mri_convert: ${which_mri_convert}"

which_mri_em_register=`which mri_em_register`
mri_em_register_version=`mri_em_register --version`
log_Msg "which mri_em_register: ${which_mri_em_register}"
log_Msg "mri_em_register --version: ${mri_em_register_version}"

which_mri_watershed=`which mri_watershed`
mri_watershed_version=`mri_watershed --version`
log_Msg "which mri_watershed: ${which_mri_watershed}"
log_Msg "mri_watershed --version: ${mri_watershed_version}"

# Start work


#T1wImageFile=`remove_ext $T1wImage`;
#T1wImageBrainFile=`remove_ext $T1wImageBrain`;
#PipelineScripts=${HCPPIPEDIR_FS}
#if [ -e "$SubjectDIR"/"$SubjectID"/scripts/IsRunning.lh+rh ] ; then
#  rm "$SubjectDIR"/"$SubjectID"/scripts/IsRunning.lh+rh
#fi
##Make Spline Interpolated Downsample to 1mm
#log_Msg "Make Spline Interpolated Downsample to 1mm"
#Mean=`fslstats $T1wImageBrain -M`
#flirt -interp spline -in "$T1wImage" -ref "$T1wImage" -applyisoxfm 1 -out "$T1wImageFile"_1mm.nii.gz
#applywarp --rel --interp=spline -i "$T1wImage" -r "$T1wImageFile"_1mm.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wImageFile"_1mm.nii.gz
#applywarp --rel --interp=nn -i "$T1wImageBrain" -r "$T1wImageFile"_1mm.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wImageBrainFile"_1mm.nii.gz
#fslmaths "$T1wImageFile"_1mm.nii.gz -div $Mean -mul 150 -abs "$T1wImageFile"_1mm.nii.gz
##Initial Recon-all Steps
#log_Msg "Initial Recon-all Steps"
## Both the SGE and PBS cluster schedulers use the environment variable NSLOTS to indicate the number of cores
## a job will use.  If this environment variable is set, we will use it to determine the number of cores to
## tell recon-all to use.
#if [[ -z ${NSLOTS} ]];then
#    num_cores=8
#else
#    num_cores="${NSLOTS}"
#fi
## Call recon-all with flags that are part of "-autorecon1", with the exception of -skullstrip.
## -skullstrip of FreeSurfer not reliable for Phase II data because of poor FreeSurfer mri_em_register registrations with Skull on, 
## so run registration with PreFreeSurfer masked data and then generate brain mask as usual.
#recon-all -i "$T1wImageFile"_1mm.nii.gz -subjid $SubjectID -sd $SubjectDIR -motioncor -talairach -nuintensitycor -normalization -openmp ${num_cores} ${seed_cmd_appendix}
## Generate brain mask
#mri_convert "$T1wImageBrainFile"_1mm.nii.gz "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz --conform
#mri_em_register -mask "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz "$SubjectDIR"/"$SubjectID"/mri/nu.mgz $FREESURFER_HOME/average/RB_all_2008-03-26.gca "$SubjectDIR"/"$SubjectID"/mri/transforms/talairach_with_skull.lta
#mri_watershed -T1 -brain_atlas $FREESURFER_HOME/average/RB_all_withskull_2008-03-26.gca "$SubjectDIR"/"$SubjectID"/mri/transforms/talairach_with_skull.lta "$SubjectDIR"/"$SubjectID"/mri/T1.mgz "$SubjectDIR"/"$SubjectID"/mri/brainmask.auto.mgz
#cp "$SubjectDIR"/"$SubjectID"/mri/brainmask.auto.mgz "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz
## Call recon-all to run most of the "-autorecon2" stages, but turning off smooth2, inflate2, curvstats, and segstats stages
#recon-all -subjid $SubjectID -sd $SubjectDIR -autorecon2 -nosmooth2 -noinflate2 -nocurvstats -nosegstats -openmp ${num_cores} ${seed_cmd_appendix}
##Highres white stuff and Fine Tune T2w to T1w Reg
#log_Msg "High resolution white matter and fine tune T2w to T1w registration"
#"$PipelineScripts"/FreeSurferHiresWhite.sh "$SubjectID" "$SubjectDIR" "$T1wImage" "$T2wImage"
##Intermediate Recon-all Steps
#log_Msg "Intermediate Recon-all Steps"
#recon-all -subjid $SubjectID -sd $SubjectDIR -smooth2 -inflate2 -curvstats -sphere -surfreg -jacobian_white -avgcurv -cortparc -openmp ${num_cores} ${seed_cmd_appendix}
##Highres pial stuff (this module adjusts the pial surface based on the the T2w image)
#log_Msg "High Resolution pial surface"
#"$PipelineScripts"/FreeSurferHiresPial.sh "$SubjectID" "$SubjectDIR" "$T1wImage" "$T2wImage"
##Final Recon-all Steps
#log_Msg "Final Recon-all Steps"
#recon-all -subjid $SubjectID -sd $SubjectDIR -surfvolume -parcstats -cortparc2 -parcstats2 -cortparc3 -parcstats3 -cortribbon -segstats -aparc2aseg -wmparc -balabels -label-exvivo-ec -openmp ${num_cores} ${seed_cmd_appendix}
#START200219
# Both the SGE and PBS cluster schedulers use the environment variable NSLOTS to indicate the number of cores
# a job will use.  If this environment variable is set, we will use it to determine the number of cores to
# tell recon-all to use.
if [[ -z ${NSLOTS} ]];then
    num_cores=8
else
    num_cores="${NSLOTS}"
fi

if [ "${editFS}" != "TRUE" ];then
    if [[ "${startHiresWhite}" != "TRUE" && "${startHiresPial}" != "TRUE" ]];then
        T1wImageFile=`remove_ext $T1wImage`;
        T1wImageBrainFile=`remove_ext $T1wImageBrain`;
        PipelineScripts=${HCPPIPEDIR_FS}
        if [ -e "$SubjectDIR"/"$SubjectID"/scripts/IsRunning.lh+rh ] ; then
          rm "$SubjectDIR"/"$SubjectID"/scripts/IsRunning.lh+rh
        fi
        #Make Spline Interpolated Downsample to 1mm
        log_Msg "Make Spline Interpolated Downsample to 1mm"
        Mean=`fslstats $T1wImageBrain -M`
        flirt -interp spline -in "$T1wImage" -ref "$T1wImage" -applyisoxfm 1 -out "$T1wImageFile"_1mm.nii.gz
        applywarp --rel --interp=spline -i "$T1wImage" -r "$T1wImageFile"_1mm.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wImageFile"_1mm.nii.gz
        applywarp --rel --interp=nn -i "$T1wImageBrain" -r "$T1wImageFile"_1mm.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wImageBrainFile"_1mm.nii.gz
        fslmaths "$T1wImageFile"_1mm.nii.gz -div $Mean -mul 150 -abs "$T1wImageFile"_1mm.nii.gz

        if [ "${singlereconall}" = "TRUE" ];then
            recon-all -all -i "$T1wImageFile"_1mm.nii.gz -subjid $SubjectID -sd $SubjectDIR -motioncor -talairach -nuintensitycor -normalization -openmp ${num_cores} ${seed_cmd_appendix}
        else
            #Initial Recon-all Steps
            log_Msg "Initial Recon-all Steps"
            # Call recon-all with flags that are part of "-autorecon1", with the exception of -skullstrip.
            # -skullstrip of FreeSurfer not reliable for Phase II data because of poor FreeSurfer mri_em_register registrations with Skull on, 
            # so run registration with PreFreeSurfer masked data and then generate brain mask as usual.
            recon-all -i "$T1wImageFile"_1mm.nii.gz -subjid $SubjectID -sd $SubjectDIR -motioncor -talairach -nuintensitycor -normalization -openmp ${num_cores} ${seed_cmd_appendix}
        fi

        # Generate brain mask
        mri_convert "$T1wImageBrainFile"_1mm.nii.gz "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz --conform
    
        #mri_em_register -mask "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz "$SubjectDIR"/"$SubjectID"/mri/nu.mgz $FREESURFER_HOME/average/RB_all_2008-03-26.gca "$SubjectDIR"/"$SubjectID"/mri/transforms/talairach_with_skull.lta
        #mri_watershed -T1 -brain_atlas $FREESURFER_HOME/average/RB_all_withskull_2008-03-26.gca "$SubjectDIR"/"$SubjectID"/mri/transforms/talairach_with_skull.lta "$SubjectDIR"/"$SubjectID"/mri/T1.mgz "$SubjectDIR"/"$SubjectID"/mri/brainmask.auto.mgz
        #START220224
        dangerous0="$FREESURFER_HOME/average/RB_all_2008-03-26.gca"
        dangerous1="$FREESURFER_HOME/average/RB_all_withskull_2008-03-26.gca"
        if [ ! -f "${dangerous0}" ];then #assume freesurfer 7.2.0
            dangerous0="$FREESURFER_HOME/average/RB_all_2020-01-02.gca"
            dangerous1="$FREESURFER_HOME/average/RB_all_withskull_2020_01_02.gca"
        fi
        mri_em_register -mask "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz "$SubjectDIR"/"$SubjectID"/mri/nu.mgz ${dangerous0} "$SubjectDIR"/"$SubjectID"/mri/transforms/talairach_with_skull.lta
        mri_watershed -T1 -brain_atlas ${dangerous1} "$SubjectDIR"/"$SubjectID"/mri/transforms/talairach_with_skull.lta "$SubjectDIR"/"$SubjectID"/mri/T1.mgz "$SubjectDIR"/"$SubjectID"/mri/brainmask.auto.mgz
        cp "$SubjectDIR"/"$SubjectID"/mri/brainmask.auto.mgz "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz

        if [ "${singlereconall}" != "TRUE" ];then
            # Call recon-all to run most of the "-autorecon2" stages, but turning off smooth2, inflate2, curvstats, and segstats stages
            recon-all -subjid $SubjectID -sd $SubjectDIR -autorecon2 -nosmooth2 -noinflate2 -nocurvstats -nosegstats -openmp ${num_cores} ${seed_cmd_appendix}
        fi
    fi
    if [ "${singlereconall}" != "TRUE" ];then
        if [[ "${startHiresPial}" != "TRUE" ]];then
            #Highres white stuff and Fine Tune T2w to T1w Reg
            log_Msg "High resolution white matter and fine tune T2w to T1w registration"
            ${P0} "$SubjectID" "$SubjectDIR" "$T1wImage" "$T2wImage"
            #Intermediate Recon-all Steps
            log_Msg "Intermediate Recon-all Steps"
            recon-all -subjid $SubjectID -sd $SubjectDIR -smooth2 -inflate2 -curvstats -sphere -surfreg -jacobian_white -avgcurv -cortparc -openmp ${num_cores} ${seed_cmd_appendix}
        fi

        #Highres pial stuff (this module adjusts the pial surface based on the the T2w image)
        log_Msg "High Resolution pial surface"
        ${P1} "$SubjectID" "$SubjectDIR" "$T1wImage" "$T2wImage"

        #Final Recon-all Steps
        log_Msg "Final Recon-all Steps"
        recon-all -subjid $SubjectID -sd $SubjectDIR -surfvolume -parcstats -cortparc2 -parcstats2 -cortparc3 -parcstats3 -cortribbon -segstats -aparc2aseg -wmparc -balabels -label-exvivo-ec -openmp ${num_cores} ${seed_cmd_appendix}
    fi

else
    log_Msg "Running Freesurfer edits"

    # Call recon-all with flags that are part of "-autorecon1", with the exception of -skullstrip.
    # -skullstrip of FreeSurfer not reliable for Phase II data because of poor FreeSurfer mri_em_register registrations with Skull on, 
    # so run registration with PreFreeSurfer masked data and then generate brain mask as usual.
    if [ "${singlereconall}" = "TRUE" ];then
        recon-all -all -subjid $FSeditSUB -sd $FSeditDIR -motioncor -talairach -nuintensitycor -normalization -openmp ${num_cores} ${seed_cmd_appendix}
    else

        #START201015
        if [ "${startHiresPial}" != "TRUE" ];then


            #recon-all -i "$T1wImageFile"_1mm.nii.gz -subjid $SubjectID -sd $SubjectDIR -motioncor -talairach -nuintensitycor -normalization -openmp ${num_cores} ${seed_cmd_appendix}
            recon-all -subjid $FSeditSUB -sd $FSeditDIR -motioncor -talairach -nuintensitycor -normalization -openmp ${num_cores} ${seed_cmd_appendix}

            # Generate brain mask
    
            #If you've edited brainmask, this command will crush it.
            #mri_convert "$T1wImageBrainFile"_1mm.nii.gz "$SubjectDIR"/"$SubjectID"/mri/brainmask.mgz --conform
    
            #START201014
            ##Changes with brainmask and nu (ie "in brain volume"
            #mri_em_register -mask "$FSeditDIR"/"$FSeditSUB"/mri/brainmask.mgz "$FSeditDIR"/"$FSeditSUB"/mri/nu.mgz $FREESURFER_HOME/average/RB_all_2008-03-26.gca "$FSeditDIR"/"$FSeditSUB"/mri/transforms/talairach_with_skull.lta
            #mri_watershed -T1 -brain_atlas $FREESURFER_HOME/average/RB_all_withskull_2008-03-26.gca "$FSeditDIR"/"$FSeditSUB"/mri/transforms/talairach_with_skull.lta "$FSeditDIR"/"$FSeditSUB"/mri/T1.mgz "$FSeditDIR"/"$FSeditSUB"/mri/brainmask.auto.mgz 
            #cp "$FSeditDIR"/"$FSeditSUB"/mri/brainmask.auto.mgz "$FSeditDIR"/"$FSeditSUB"/mri/brainmask.mgz 

    
            # Call recon-all to run most of the "-autorecon2" stages, but turning off smooth2, inflate2, curvstats, and segstats stages
            recon-all -subjid $FSeditSUB -sd $FSeditDIR -autorecon2 -nosmooth2 -noinflate2 -nocurvstats -nosegstats -openmp ${num_cores} ${seed_cmd_appendix}
            #Highres white stuff and Fine Tune T2w to T1w Reg
            log_Msg "High resolution white matter and fine tune T2w to T1w registration"
    
            #"$PipelineScripts"/FreeSurferHiresWhite.sh "$FSeditSUB" "$FSeditDIR" "$T1wImage" "$T2wImage"
            #START200310
            ${P0} "$FSeditSUB" "$FSeditDIR" "$T1wImage" "$T2wImage"
    
            #Intermediate Recon-all Steps
            log_Msg "Intermediate Recon-all Steps"
            recon-all -subjid $FSeditSUB -sd $FSeditDIR -smooth2 -inflate2 -curvstats -sphere -surfreg -jacobian_white -avgcurv -cortparc -openmp ${num_cores} ${seed_cmd_appendix}

        fi
 
        #Highres pial stuff (this module adjusts the pial surface based on the the T2w image)
        log_Msg "High Resolution pial surface"

        #"$PipelineScripts"/FreeSurferHiresPial.sh "$FSeditSUB" "$FSeditDIR" "$T1wImage" "$T2wImage"
        #START200309
        ${P1} "$FSeditSUB" "$FSeditDIR" "$T1wImage" "$T2wImage" 

        #Final Recon-all Steps
        log_Msg "Final Recon-all Steps"
        recon-all -subjid $FSeditSUB -sd $FSeditDIR -surfvolume -parcstats -cortparc2 -parcstats2 -cortparc3 -parcstats3 -cortribbon -segstats -aparc2aseg -wmparc -balabels -label-exvivo-ec -openmp ${num_cores} ${seed_cmd_appendix}
    fi
fi
log_Msg "Completed"
