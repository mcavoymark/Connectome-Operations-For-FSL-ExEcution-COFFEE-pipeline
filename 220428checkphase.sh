#!/usr/bin/env bash

if [ ${#@} != 2 ]; then
    echo "$0 <MRI.dat> <output file>"
    echo ""
    echo "    <MRI.dat>"
    echo "        #Scans can be labeled NONE or NOTUSEABLE. Lines beginning with a # are ignored."
    echo "        #SUBNAME OUTDIR T1 T2 FM1 FM2 run1_RH_SBRef run1_RH run1_LH_SBRef run1_LH run2_RH_SBRef run2_RH run2_LH_SBRef run2_LH run3_RH_SBRef run3_RH run3_LH_SBRef run3_LH rest01_SBRef rest01 rest02_SBRef rest02 rest03_SBRef rest03"
    echo "        #-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    exit
fi
of=$2

IFS=$'\n' read -d '' -ra csv < $1
#printf '%s\n' "${csv[@]}"

#echo -e "subject\tFieldMap\tFieldMap\tERR\trun1_RH_SBRef\trun1_RH\tERR\trun1_LH_SBRef\trun1_LH\tERR\trun2_RH_SBRef\trun2_RH\tERR\trun2_LH_SBRef\trun2_LH\tERR\trun3_RH_SBRef\trun3_RH\tERR\trun3_LH_SBRef\trun3_LH\tERR\trest01_SBRef\trest01\tERR\trest02_SBRef\trest02\tERR\trest03_SBRef\trest03\tERR" > $of
echo -e "subject\tFieldMap\tFieldMap\tmsg\trun1_RH_SBRef\trun1_RH\tmsg\trun1_LH_SBRef\trun1_LH\tmsg\trun2_RH_SBRef\trun2_RH\tmsg\trun2_LH_SBRef\trun2_LH\tmsg\trun3_RH_SBRef\trun3_RH\tmsg\trun3_LH_SBRef\trun3_LH\tmsg\trest01_SBRef\trest01\tmsg\trest02_SBRef\trest02\tmsg\trest03_SBRef\trest03\tmsg" > $of

for((i=0;i<${#csv[@]};++i));do
    IFS=$',\n ' read -ra line <<< ${csv[i]} 
    if [[ "${line[0]:0:1}" = "#" ]];then
        #echo "Skiping line $((i+1))"
        continue
    fi
    echo "${line[0]}"

    declare -a PED;declare -a n0;declare -a ped0
    notes=;lcnotes=0
    errors=;#lcerrors=0
    lcprint=0
    err0last=${#line[@]}
    errorsi=0

    for((k=4;k<${#line[@]};k++));do
    #for((k=3;k<${#line[@]};k++));do
        if [ "${line[k]}" != "NONE" ] && [ "${line[k]}" != "NOTUSEABLE" ];then
            json=${line[k]%%.*}.json
            if [ ! -f $json ];then
                echo "    $json not found"
                exit
            fi
            mapfile -t PhaseEncodingDirection < <( grep PhaseEncodingDirection $json )
            IFS=$' ,' read -ra line0 <<< ${PhaseEncodingDirection}
            IFS=$'"' read -ra line1 <<< ${line0[1]}
            PED[k]=${line1[1]}
            ped0[k]="        ${line[k]} ${PED[k]}"
        fi
    done
    for((k=4;k<5;k+=2));do
    #for((k=3;k<4;k+=2));do
        if [ "${line[k]}" != "NONE" ] && [ "${line[k]}" != "NOTUSEABLE" ];then
            if [[ "${PED[k]}" = "${PED[k+1]}" ]];then
                err0="Fieldmap phases should be opposite."
                msg0="ERROR: ${line[k]} ${PED[k]}, ${line[k+1]} ${PED[k+1]}. ${err0}" 
                ped0[k+1]+=" ERROR: ${err0}"
                n0[k]="ERR"
                #((lcerrors > 0)) && errors+="\n"
                #errors+="\t${msg0}"
                #((lcerrors++))
                errors[((errorsi++))]=${msg0}
            else
                ped0[k+1]+=" OK"
                n0[k]="OK"
            fi
            for((l=k;l<k+2;l++));do
                if [[ "${line[l]}" = *"SpinEchoFieldMap"*"AP"* || "${line[l]}" = *"se-ap-FieldMAP"* ]];then
                    if [[ "${PED[l]}" != "j-" ]];then
                        err0="wrong orientation. Should be j-."
                        ped0[l]+=" ERROR: ${err0}"
                        msg0="ERROR: ${line[l]} ${PED[l]} ${err0}" 
                        n0[k]="ERR"
                        #((lcerrors > 0)) && errors+="\n"
                        #errors+="\t${msg0}"
                        #((lcerrors++))
                        errors[((errorsi++))]=${msg0}
                    #else
                    #    ped0[l]+=" OK"
                    #    n0[k]="OK"
                    fi
                elif [[ "${line[l]}" = *"SpinEchoFieldMap"*"PA"* ]] || [[ "${line[l]}" = *"se_pa_FieldMAP"* ]];then
                    if [ "${PED[l]}" != "j" ];then
                        err0="wrong orientation. Should be j."
                        ped0[l]+=" ERROR: ${err0}"
                        msg0="ERROR: ${line[l]} ${PED[l]} ${err0}"
                        n0[k]="ERR"
                        #((lcerrors > 0)) && errors+="\n"
                        #errors+="\t${msg0}"
                        #((lcerrors++))
                        errors[((errorsi++))]=${msg0}
                    #else
                    #    ped0[l]+=" OK"
                    #    n0[k]="OK"
                    fi
                fi
            done
        fi
    done
    for((k=6;k<=${#line[@]};k+=2));do
    #for((k=5;k<=${#line[@]};k+=2));do
        if [ "${line[k]}" != "NONE" ] && [ "${line[k]}" != "NOTUSEABLE" ];then
            ((lcprint++))
            if [[ "${PED[k]}" != "${PED[k+1]}" ]];then
                err0="wrong orientation. Needs to match ${line[k+1]}"
                ped0[k]+=" ERROR: ${err0}"
                n0[k+1]="ERR"

                #((lcerrors > 0)) && errors="${errors};"
                #errors="${errors} ${line[k]}"
                ((lcerrors > 0)) && errors+="\n"
                #errors+="ERROR: ${line[k]} ${PED[k]} ${err0[k]}"
                errors[((errorsi++))]="ERROR: ${line[k]} ${PED[k]} ${err0}"

                #((lcerrors++))
            else
                #ped0[k]+=" OK"
                ped0[k+1]+="\t\tOK"
                n0[k+1]="OK"
            fi
            if [[ "${line[k]}" = *"AP"* ]];then
                if [[ "${PED[k]}" != "j-" ]];then
                    err0="wrong orientation. Should be j-."
                    ped0[k]+=" ${err0}"
                    msg0="${line[k]} ${PED[k]} ${err0}" 

                    #echo "        ERROR: ${msg0}" 
                    #((lcnotes > 0)) && notes="${notes};"
                    #notes="${notes}${line[k]} ${err0}"
                    #((lcnotes++))
                    #((lcerrors > 0)) && errors+=";"
                    #((lcerrors > 0)) && errors+="\n"
                    #errors+="${msg0}"
                    #((lcerrors++))
                    errors[((errorsi++))]=${msg0}
                #else
                #    ped0[k]+=" OK"
                fi 
            elif [[ "${line[k]}" = *"PA"* ]];then
                if [ "${PED[k]}" != "j" ];then
                    err0="wrong orientation. Should be j."
                    ped0[k]+=" ${err0}"
                    msg0="${line[k]} ${PED[k]} ${err0}" 

                    #echo "        ERROR: ${msg0}" 
                    #((lcnotes > 0)) && notes="${notes};"
                    #notes="${notes}${line[k]} ${err0[k]}"
                    #((lcnotes++))
                    #((lcerrors > 0)) && errors+=";"
                    #((lcerrors > 0)) && errors+="\n"
                    #errors+="${msg0}"
                    #((lcerrors++))
                    errors[((errorsi++))]=${msg0}
                #else
                #    ped0[k]+=" OK"
                fi
            fi
        fi
    done

    #echo "#ped0[@]=${#ped0[@]}"

    #for((k=4;k<${#ped0[@]};k++));do
    for((k=4;k<err0last;k++));do
    #for((k=3;k<err0last;k++));do
        #echo "${ped0[k]}"
        echo -e "${ped0[k]}"
    done
    if ((lcprint>0));then
        #echo -e "${errors}\t${line[0]}\t${PED[4]}\t${PED[5]}\t${n0[4]}\t${PED[6]}\t${PED[7]}\t${n0[7]}\t${PED[8]}\t${PED[9]}\t${n0[9]}\t${PED[10]}\t${PED[11]}\t${n0[11]}\t${PED[12]}\t${PED[13]}\t${n0[13]}\t${PED[14]}\t${PED[15]}\t${n0[15]}\t${PED[16]}\t${PED[17]}\t${n0[17]}\t${PED[18]}\t${PED[19]}\t${n0[19]}\t${PED[20]}\t${PED[21]}\t${n0[21]}\t${PED[22]}\t${PED[23]}\t${n0[23]}" >> $of
        #echo -e "${line[0]}\t${PED[4]}\t${PED[5]}\t${n0[4]}\t${PED[6]}\t${PED[7]}\t${n0[7]}\t${PED[8]}\t${PED[9]}\t${n0[9]}\t${PED[10]}\t${PED[11]}\t${n0[11]}\t${PED[12]}\t${PED[13]}\t${n0[13]}\t${PED[14]}\t${PED[15]}\t${n0[15]}\t${PED[16]}\t${PED[17]}\t${n0[17]}\t${PED[18]}\t${PED[19]}\t${n0[19]}\t${PED[20]}\t${PED[21]}\t${n0[21]}\t${PED[22]}\t${PED[23]}\t${n0[23]}\n${errors}" >> $of
        #echo -e "${line[0]}\t${PED[4]}\t${PED[5]}\t${n0[4]}\t${PED[6]}\t${PED[7]}\t${n0[7]}\t${PED[8]}\t${PED[9]}\t${n0[9]}\t${PED[10]}\t${PED[11]}\t${n0[11]}\t${PED[12]}\t${PED[13]}\t${n0[13]}\t${PED[14]}\t${PED[15]}\t${n0[15]}\t${PED[16]}\t${PED[17]}\t${n0[17]}\t${PED[18]}\t${PED[19]}\t${n0[19]}\t${PED[20]}\t${PED[21]}\t${n0[21]}\t${PED[22]}\t${PED[23]}\t${n0[23]}" >> $of
        echo -e "${line[0]}\t${PED[4]}\t${PED[5]}\t${n0[4]}\t${PED[6]}\t${PED[7]}\t${n0[7]}\t${PED[8]}\t${PED[9]}\t${n0[9]}\t${PED[10]}\t${PED[11]}\t${n0[11]}\t${PED[12]}\t${PED[13]}\t${n0[13]}\t${PED[14]}\t${PED[15]}\t${n0[15]}\t${PED[16]}\t${PED[17]}\t${n0[17]}\t${PED[18]}\t${PED[19]}\t${n0[19]}\t${PED[20]}\t${PED[21]}\t${n0[21]}\t${PED[22]}\t${PED[23]}\t${n0[23]}" >> $of
        printf '\t%s\n' "${errors[@]}" >> $of
    fi
    unset PED;unset n0;unset ped0
done
echo "Output written to $of"
