#!/bin/ksh
#script de diagnostique par ping
#ceci est un script de la collection jettable :)
trap 'quitter' EXIT INT QUIT
#Chargement bibliotheques
#constantes :
REP_SOURCE=/tmp/sidobre
###SOURCE DES LIBS
. $REP_SOURCE/libG.ksh
. $REP_SOURCE/lib_dping_linux.ksh
#
#la fonction debug peut recevoir en argument : 0(desactive) 1(set -x) 2(set -xv)
debug 0
$MODE_DEBUG
#aiguillage :
while getopts ":d:n:i:f:hl:t:e:s:c" opt;do
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
					IPValide $cible_scp
					erreur $? "format de l'ip $cible_scp" $ESTOP
					alNumValide $user_scp
					erreur $? "format du username $user_scp" $ESTOP
					if [ ! "$lan" ];then erreur $KO "nom du lan non fournit" $ESTOP;fi
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
				s) taille_packets=${OPTARG}
					decimalValide $taille_packets
					erreur $? "taille $taille_packets" $ESTOP
						;;
				c) echo "capture de trame"
					capture=1; #indique qu'une capture devra être faite
					lock_tcpdump=/tmp/ltcpdump
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
	lock=/tmp/dping.tmp
	if [ -a $lock ];then 
		erreur $KO "dping massif deja encours" $ESTOP
	fi
	touch $lock
	while read dest ip_dest lan nif taille_packets;do
		IPValide $ip_dest
		alNumValide $nif
		if [ "${capture}" -eq 1 ];then
			erreur $(baseOK) "la base est bien en place" $ECONT "$0 -e creation"
			if [ $ERREUR -gt 0 ];then 
				erreur $KO "echec creation de la base, aucune capture" $ECONT
			else
				if [ -x $TCPDUMP ];then
					fichier_dump=$TR_BASE/$(uname -n)_$(date +%Y%m%d_%H%M).dump
					TCPDUMP_COMMANDE="$TCPDUMP -i ${lan} -C 1 -W 5 -w $fichier_dump"
					if [ ! -a $lock_tcpdump ];then 
						touch $lock_tcpdump
						$TCPDUMP_COMMANDE&
						erreur $? "execution commande $TCPDUMP_COMMANDE" $ECONT
						capture=2
					else 
						erreur $KO "tcpdump deja en cours" $ECONT
					fi
				else
					erreur $KO "la commande $TCPDUMP n'existe pas" $ECONT
				fi
			fi
		fi	
		if [ -n "$taille_packets" ];then
			decimalValide $taille_packets
			$0 -d ${dest}-${ip_dest} -n ${nbr_iteration} -l ${lan} -i ${nif} -s ${taille_packets}&
		else
			$0 -d ${dest}-${ip_dest} -n ${nbr_iteration} -l ${lan} -i ${nif}&
		fi
		sleep 5
	done<${DESTINATION}
	if [ ${capture} -eq 2 ];then
		debut_dump=$(date +%s)
		while [ $(jobs -p | wc -l) -gt 0 ];
		do
			sleep 1;
			instant_dump=$(date +%s)
			if [ $(($instant_dump - $debut_dump)) -gt 120 ];then
				for i in $(jobs -p);do kill $i;done
			fi
			#on attends la fin des pings
		done
		erreur $(pertes) "receptions paquets ping" $ECONT "rm $fichier_dump[0-4]"
		rm $lock_tcpdump
	fi
fi
