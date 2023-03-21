#!/usr/local/bin/bash

#Hard coded location of dcm2niix
[ -z ${DCM2NIIXDIR+x} ] && DCM2NIIXDIR=/Users/Shared/pipeline

P0="${DCM2NIIXDIR}/dcm2niix -w 0 -z i" #-w 0 skip duplicates

helpmsg(){
    #echo "$0"
    echo "    Minimal: dcm2niix <scanlist.csv>"
    echo "             Ex. $0 /Users/Shared/10_Connectivity/05_20/05_20_scanlist_2fields.csv"
    echo "                 Dicoms read from /Users/Shared/10_Connectivity/05_20/dicom"
    echo "                 Niftis written to /Users/Shared/10_Connectivity/05_20/nifti"
    echo "                 Script written to scripts/dcm2niix/05_20_scanlist_2fields.sh"
    echo ""
    echo "    -s | --sub         scanlist.csv."
    echo "                       First row is labels. Currently not used. "
    echo "                       Two or more columns. First column identifies the dicom directory. Last column is the output name of the nifti."
    echo "                       Ex. Scan,nii"
    echo "                           16,run1_RH_SBRef"
    echo "                           17,run1_RH"
    echo "                       This would produce two niftis: 1) <out dir>/run1_RH_SBRef.nii.gz from dicoms <in dir>/16/DICOM"
    echo "                                                      2) <out dir>/run1_RH.nii.gz from dicoms <in dir>/17/DICOM"

    #echo "    -I | --indir       <in dir> Input directory. Location of dicoms. Ex. /Users/Shared/10_Connectivity/05_20/dicom"
    #START230307
    echo "    -i | --indir       <in dir> Input directory. Location of dicoms. Ex. /Users/Shared/10_Connectivity/05_20/dicom"

    #echo "                       Ex. /Users/Shared/10_Connectivity/05_20/dicom"

    #echo "    -O | --outdir      <out dir> Output directory. Where to write niftis. Ex. /Users/Shared/10_Connectivity/05_20/nifti"
    #START230307
    echo "    -o | --outdir      <out dir> Output directory. Where to write niftis. Ex. /Users/Shared/10_Connectivity/05_20/nifti"

    #echo "                       Ex. /Users/Shared/10_Connectivity/05_20/nifti"
    echo "    -b | --batchscript Name of output script. Ex. /Users/Shared/10_Connectivity/05_20/scripts/dcm2niix/05_20_scanlist.sh"
    #echo "                       Ex. /Users/Shared/10_Connectivity/05_20/scripts/dcm2niix/05_20_scanlist.sh"
    #echo "    -D | --DATE        Flag. Add date to name of output script."
    echo "    -h | --help        Echo this help message."
    exit
    }
echo $0 $@
arg=($@)

#c0=;id=;od=;sd=;#lcdate=0
#START230307
dat=;id=;od=;sd=;#lcdate=0

if((${#@}<1));then
    helpmsg
    exit
elif((${#@}==1)) && [[ $1 != "-h" && $1 != "--help" ]];then
    dat=$1

#START230307
#    id=${1%/*}/dicom
#    od=${1%/*}/nifti
#
#    #sd0=scripts/dcm2niix
#    #mkdir -p ${sd0}
#    #root=${1##*/}
#    #sd=${sd0}/${root%%.*}.sh
#    #START230307
#    IFS='/' read -ra subj <<< "${1%/*}"
#    #echo "subj=${subj[@]}"
#    #echo "#subj=${#subj[@]}"
#    subj=${subj[${#subj[@]}-1]}
#    #echo "subj=${subj}"
#    sd=${1%/*}/${subj}_dcm2niix.sh
#    #echo "sd=${sd}"
#    #exit 

else
    for((i=0;i<${#@};++i));do
        #echo "i=$i ${arg[i]}"
        case "${arg[i]}" in
            -s | --sub)
                dat=${arg[((++i))]}
                echo "dat=$dat"
                ;;

            #-I | --indir)
            #START230307
            -i | --indir)

                id=${arg[((++i))]}
                #echo "id=$id"
                ;;

            #-O | --outdir)
            #START230307
            -o | --outdir)

                od=${arg[((++i))]}
                #echo "od=$od"
                ;;

            #-b | --batchScript)
            #START230307
            -b | --batchscript)

                #bs=${arg[((++i))]}
                #echo "bs=$bs"
                #START230221
                sd=${arg[((++i))]}
                #echo "sd=$sd"

                ;;
            #-D | --DATE)
            #    lcdate=1
            #    echo "lcdate=$lcdate"
            #    ;;
            -h | --help)
                helpmsg
                exit
                ;;

            #START230307
            #*) echo "Unexpected option: ${arg[i]}"
            #    ;;

        esac
    done
fi

#if [ ! -d "$id" ];then
#    echo "**** ERROR: $id does not exist. ****"
#    exit
#fi
#START230307
[ -z "${dat}" ] && dat=$1
dir0=${dat%/*}
#[ -z "${id}" ] && id=${1%/*}/dicom 
[ -z "${id}" ] && id=${dir0}/dicom 
if [ ! -d "$id" ];then
    echo "**** ERROR: $id does not exist. ****"
    exit
fi
#[ -z "${od}" ] && od=${1%/*}/nifti
[ -z "${od}" ] && od=${dir0}/nifti
if [ -z "${sd}" ];then
    #IFS='/' read -ra subj <<< "${1%/*}"
    IFS='/' read -ra subj <<< "${dir0}"
    subj=${subj[${#subj[@]}-1]}
    #sd=${1%/*}/${subj}_dcm2niix.sh
    sd=${dir0}/${subj}_dcm2niix.sh
fi



#IFS=$'\n' read -d '' -ra csv < $1
#IFS=$'\n' read -d '' -ra csv < $dat
#START221210
#IFS=$'\n
#\r' read -d '' -ra csv < $dat
#START230307
#https://stackoverflow.com/questions/15433188/what-is-the-difference-between-r-n-r-and-n
#https://stackoverflow.com/questions/23027637/ifs-n-doesnt-change-ifs-to-breaklines
IFS=$'\r
\n' read -d '' -ra csv < $dat

#printf '%s\n' "${csv[@]}"
mkdir -p $od

echo "#!/usr/local/bin/bash" > $sd

#START230307
if [ ! -f "$sd" ];then
    echo "**** ERROR: Unable to create $sd. Please check your permissions. ****"
    exit
fi


echo "" >> $sd
for((i=1;i<${#csv[@]};++i));do
    IFS=$',' read -ra line <<< ${csv[i]}
    dir0=$id/${line[0]}/DICOM
    echo -e "${P0} -o ${od} -f ${line[((${#line[@]}-1))]} ${dir0}\n" >> $sd
done

#START220411
tr -d '\r' <${sd} >${sd}.new && mv ${sd}.new ${sd} 

chmod +x $sd

#echo "Output written to $sd"
#START230307
cd ${dir0}

$sd > $sd.txt 2>&1 & 
echo "$sd has been executed"
