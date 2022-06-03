#!/usr/bin/env bash

get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_example_func
    unset command_line_specified_gdc
    unset command_line_specified_pedir
    unset command_line_specified_t1
    unset command_line_specified_t1brain
    unset command_line_specified_ref
    unset command_line_specified_EnvironmentScript

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --example_func=*)
                command_line_specified_example_func=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --gdc=*)
                command_line_specified_gdc=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --pedir=*)
                command_line_specified_pedir=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --t1=*)
                command_line_specified_t1=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --t1brain=*)
                command_line_specified_t1brain=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --ref=*)
                command_line_specified_ref=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --EnvironmentScript=*)
                command_line_specified_EnvironmentScript=${argument#*=}
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

if [ -n "${command_line_specified_example_func}" ]; then
    example_func=($command_line_specified_example_func)
else
    echo "Need to specify --example_func"
    exit
fi
if [ -n "${command_line_specified_gdc}" ]; then
    gdc=($command_line_specified_gdc)
else
    echo "Need to specify --gdc"
    exit
fi
if [ -n "${command_line_specified_pedir}" ]; then
    pedir=($command_line_specified_pedir)
else
    echo "Need to specify --pedir"
    exit
fi
if [ -n "${command_line_specified_t1}" ]; then
    t1=$command_line_specified_t1
else
    echo "Need to specify --t1"
    exit
fi
if [ -n "${command_line_specified_t1brain}" ]; then
    t1brain=$command_line_specified_t1brain
else
    echo "Need to specify --t1brain"
    exit
fi
if [ -n "${command_line_specified_ref}" ]; then
    ref=$command_line_specified_ref
else
    echo "Need to specify --ref"
    exit
fi
if [ -n "${command_line_specified_EnvironmentScript}" ]; then
    EnvironmentScript=$command_line_specified_EnvironmentScript
else
    echo "Need to specify --EnvironmentScript"
    exit
fi
if((${#example_func[@]}!=${#gdc[@]}));then
    echo "example_func has ${#example_func[@]} elements, but gdc has ${#gdc[@]} elements. Must be equal. Abort!"
    exit
fi
if((${#example_func[@]}!=${#pedir[@]}));then
    echo "example_func has ${#example_func[@]} elements, but pedir has ${#pedir[@]} elements. Must be equal. Abort!"
    exit
fi
source $EnvironmentScript
for((i=0;i<${#example_func[@]};++i));do
    od=${example_func[i]%/*}
    echo "Starting ${od##*/}"

    #date
    #echo -e "${FSLDIR}/bin/epi_reg --epi=${example_func[i]} --t1=${t1} --t1brain=${t1brain} --gdc=${gdc[i]} --pedir=${pedir[i]} --out=${od}/example_func2highres\n"
    ${FSLDIR}/bin/epi_reg --epi=${example_func[i]} --t1=${t1} --t1brain=${t1brain} --gdc=${gdc[i]} --pedir=${pedir[i]} --out=${od}/example_func2highres

    #date
    #echo -e "${FSLDIR}/bin/flirt -in ${t1brain} -ref ${ref} -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear -out ${od}/highres2standard.nii.gz -omat ${od}/highres2standard.mat\n"
    #${FSLDIR}/bin/flirt -in ${t1brain} -ref ${ref} -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear -out ${od}/highres2standard.nii.gz -omat ${od}/highres2standard.mat
    if((i==0));then
        h2sf=${od}/highres2standard.nii.gz
        h2sm=${od}/highres2standard.mat
        ${FSLDIR}/bin/flirt -in ${t1brain} -ref ${ref} -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear -out ${h2sf} -omat ${h2sm}
    else
        cp ${h2sf} ${od}/highres2standard.nii.gz
        cp ${h2sm} ${od}/highres2standard.mat
    fi

    #date
    #echo -e "${FSLDIR}/bin/convert_xfm -concat ${od}/highres2standard.mat ${od}/example_func2highres.mat -omat ${od}/example_func2standard.mat\n\n"
    ${FSLDIR}/bin/convert_xfm -concat ${od}/highres2standard.mat ${od}/example_func2highres.mat -omat ${od}/example_func2standard.mat 

    echo "Finished ${od##*/}"
done
