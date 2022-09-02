#!/usr/bin/env bash 

#P0=/home/usr/mcavoy/HCP/scripts/200305FreeSurferPipeline_editFS.sh
#START220209
#P0=${HCPMOD}/200305FreeSurferPipeline_editFS.sh
#START220211
#P0=200305FreeSurferPipeline_editFS.sh
#P0=220224FreeSurferPipeline_editFS.sh
#START220308
#P0=220308FreeSurferPipeline_editFS.sh
#P0=220812FreeSurferPipeline_editFS.sh
P0=220901FreeSurferPipeline_editFS.sh

echo "Running $0"

get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_study_folder
    unset command_line_specified_subj
    unset command_line_specified_run_local
    unset command_line_specified_EnvironmentScript

    #START200219
    cls_editFS="FALSE"
    cls_singlereconall="FALSE"
    unset cls_FSeditDIR
    unset cls_FSeditSUB


    #START201015
    cls_startHiresPial="FALSE"

    #START201015
    cls_startHiresWhite="FALSE"

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --StudyFolder=*)
                command_line_specified_study_folder=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --Subject=*)
                command_line_specified_subj=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
            --EnvironmentScript=*)
                    command_line_specified_EnvironmentScript=${argument#*=}
                    index=$(( index + 1 ))
                    ;;

            #START200219
            --editFS)
                cls_editFS="TRUE"
                index=$(( index + 1 ))
                ;;
            --singlereconall)
                cls_singlereconall="TRUE"
                index=$(( index + 1 ))
                ;;
            --FSeditDIR=*)
                cls_FSeditDIR=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --FSeditSUB=*)
                cls_FSeditSUB=${argument#*=}
                index=$(( index + 1 ))
                ;;

            #START201015
            --startHiresPial)
                cls_startHiresPial="TRUE"
                index=$(( index + 1 ))
                ;;

            #START220308
            --startHiresWhite)
                cls_startHiresWhite="TRUE"
                index=$(( index + 1 ))
                ;;


	    *)
		echo ""
		echo "ERROR: Unrecognized Option: ${argument}"
		echo ""
		exit 1
		;;
        esac
    done
}

get_batch_options "$@"

StudyFolder="${HOME}/projects/Pipelines_ExampleData" #Location of Subject folders (named by subjectID)
Subjlist="100307" #Space delimited list of subject IDs


if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj}" ]; then
    Subjlist="${command_line_specified_subj}"
fi

#EnvironmentScript="${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script
if [ -n "${command_line_specified_EnvironmentScript}" ];then
    EnvironmentScript="${command_line_specified_EnvironmentScript}"
else
    echo "MUST PROVIDE EnvironmentScript"
    echo "    Ex. --EnvironmentScript=/home/usr/mcavoy/HCP/scripts/SetUpHCPPipeline_mm.sh"
    exit 
fi

#echo "************************ here0 ************************************"


# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP), gradunwarp (HCP version 1.0.2)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
source ${EnvironmentScript}

#START220211
P0=${HCPMOD}/${P0}

# Log the originating call
echo "$@"

#if [ X$SGE_ROOT != X ] ; then
#    QUEUE="-q long.q"
    QUEUE="-q hcp_priority.q"
#fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"


########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the PreFreeSurfer Pipeline

######################################### DO WORK ##########################################

for Subject in $Subjlist ; do
  echo $Subject

  #Input Variables
  SubjectID="$Subject" #FreeSurfer Subject ID Name
  SubjectDIR="${StudyFolder}/T1w" #Location to Put FreeSurfer Subject's Folder
  T1wImage="${StudyFolder}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T1wImageBrain="${StudyFolder}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)

  #T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)
  #START200310
  T2wImage=
  if [ -d "${StudyFolder}/T2w" ];then
      T2wImage="${StudyFolder}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)
  fi

  #if [ -n "${command_line_specified_run_local}" ] ; then
  #    echo "About to run ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh"
  #    queuing_command=""
  #else
  #    echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh"
  #    queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  #fi
  #START200220
  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${P0}"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${P0}"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  fi


  #START200220
  #if [ -z "${cls_FSeditDIR}" ];then
  #    cls_FSeditDIR=$SubjectDIR
  #fi
  [ -z "${cls_FSeditDIR}" ] && cls_FSeditDIR=$SubjectDIR
  #if [ -z "${cls_FSeditSUB}" ];then
  #    cls_FSeditSUB=$Subject
  #fi
  [ -z "${cls_FSeditSUB}" ] && cls_FSeditSUB=$Subject

  #${queuing_command} ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
  #    --subject="$Subject" \
  #    --subjectDIR="$SubjectDIR" \
  #    --t1="$T1wImage" \
  #    --t1brain="$T1wImageBrain" \
  #    --t2="$T2wImage" \
  #    --printcom=$PRINTCOM
  #START190530
  #${queuing_command} ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline_mm.sh \
  #START200114
  #${queuing_command} ${P0} \
  #    --subject="$Subject" \
  #    --subjectDIR="$SubjectDIR" \
  #    --t1="$T1wImage" \
  #    --t1brain="$T1wImageBrain" \
  #    --t2="$T2wImage" \
  #    --printcom=$PRINTCOM \
  #START200219
  echo "cls_editFS = $cls_editFS"
  echo "cls_singlereconall = $cls_singlereconall"
  #START2208308
  echo "cls_startHiresWhite = $cls_startHiresWhite"
  echo "cls_startHiresPial = $cls_startHiresPial"
  ${queuing_command} ${P0} \
      --subject="$Subject" \
      --subjectDIR="$SubjectDIR" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --t2="$T2wImage" \
      --printcom=$PRINTCOM \
      --editFS=$cls_editFS \
      --singlereconall=$cls_singlereconall \
      --FSeditDIR=$cls_FSeditDIR \
      --FSeditSUB=$cls_FSeditSUB \
      --startHiresWhite=$cls_startHiresWhite \
      --startHiresPial=$cls_startHiresPial
      
  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  #echo "set -- --subject="$Subject" \
  #    --subjectDIR="$SubjectDIR" \
  #    --t1="$T1wImage" \
  #    --t1brain="$T1wImageBrain" \
  #    --t2="$T2wImage" \
  #    --printcom=$PRINTCOM \
  #START200219
#  echo "set -- --subject="$Subject" \
#      --subjectDIR="$SubjectDIR" \
#      --t1="$T1wImage" \
#      --t1brain="$T1wImageBrain" \
#      --t2="$T2wImage" \
#      --printcom=$PRINTCOM \
#      --editFS=$cls_editFS \
#      --singlereconall=$cls_singlereconall \
#      --FSeditDIR=$cls_FSeditDIR \
#      --FSeditSUB=$cls_FSeditSUB \
#      --startHiresPial=$cls_startHiresPial"


#  echo "${P0}"
#  echo ". ${EnvironmentScript}"

done
