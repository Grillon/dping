#!/bin/ksh
#script de diagnostique par ping
#ceci est un script de la collection jettable :)
trap 'quitter' EXIT INT QUIT
#Chargement bibliotheques
#constantes :
MODE_DEBUG=""
REP_SOURCE=/tmp/sidobre
RESULTAT=~
SOURCE=$(uname -n)
OS=$(uname -s)
CONF_DIR=
TR_BASE=/tmp/yst/test_dd
T_IO=$TR_BASE/tio.data
R_IO=$TR_BASE/rio.data
DESTINATION=destination
ANALYSE_PING=analyse_ping_linux.awk
ANALYSE_PING=$REP_SOURCE/$ANALYSE_PING
RESULTAT_BPP=${RESULTAT}/rrdtool_bp
RESULTAT_ERR=${RESULTAT}/log.err
nbr_iteration=50
if=PRODUCTION
COMPTE_RENDU=bilan.txt
COMPTE_RENDU=${RESULTAT}/${COMPTE_RENDU}
###SOURCE DES LIBS
. $REP_SOURCE/libG.ksh
. $REP_SOURCE/lib_dping_linux.ksh
#
#la fonction debug peut recevoir en argument : 0(desactive) 1(set -x) 2(set -xv)
debug 1
$MODE_DEBUG
#aiguillage :
while getopts ":d:n:i:f:hl:t:e:" opt;do
        case "$opt" in
                d) arg_d ${OPTARG}
                        ;;
                n) nbr_iteration=${OPTARG};
                        ;;
                i) if=${OPTARG}
                        ;;
                f) #lst_dest=${OPTARG}
                	DESTINATION=${OPTARG}
                        ;;
				l) lan=${OPTARG}
						;;
				t)	arg_t ${OPTARG}
					user_scp=${arg1}
					cible_scp=${arg2}
					lan=${arg3}
					unset arg1 
					unset arg2
					unset arg3
					test_bp 2>>$RESULTAT_ERR 1>>$RESULTAT_BPP
					#resultat test BandePassanteNegative et Positive
					sed -ni "/maintenant/p" $RESULTAT_ERR
					exit 0
						;;
				e)  if [ ${OPTARG} == "creation" ];then
						creation_env_dd
					elif [ ${OPTARG} == "destruction" ];then
						destruction_env_dd
					else erreur $KO "argument ${OPTARG} incorrect pour l'option -${opt}" $ESTOP
					fi
					exit 0
						;;
					
                :) erreur $KO "ARGUMENT MANQUANT" $ESTOP
                        ;;
                \?) aide
                        ;;
		*) aide
			;;
        esac
done
#
#verification de coherence des options
#-din ou -fin OK si -df KO
#
if [ "$lst_dest" = NO_FILE ] && [ -z "$ip_dest" ];then
        erreur $KO "les options \"-d\" et \"-f\" sont exclusives" $ESTOP aide
fi
if [ -a "$lock" ];then
erreur $KO "$0 deja en cours d'execution" $ESTOP
fi
if [ "${lst_dest}" = NO_FILE ];then
	SORTIE_PING=${dest}.${if}.ping.$$
	SORTIE_PING=$REP_SOURCE/$SORTIE_PING
	if [ -a ${dest}.${if}.ping* ];then
		erreur $KO "ping de l'interface ${if} du serveur ${dest} en cours d'execution" $ESTOP
	fi
	custom_ping ${ip_dest} ${nbr_iteration} >${SORTIE_PING}
	analyse_ping >>${COMPTE_RENDU}
else
	while read dest ip_dest lan nif;do
		lock=/tmp/dping.tmp
		touch $lock
		if [ -n "$nif" ];then
			$0 -d ${dest}-${ip_dest} -n ${nbr_iteration} -l ${lan} -i ${nif}&
		else
			$0 -d ${dest}-${ip_dest} -n ${nbr_iteration} -l ${lan} -i ${if}&
		fi
		sleep 5
	done<${DESTINATION}
fi
