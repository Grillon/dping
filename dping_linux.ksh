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
debug 1
$MODE_DEBUG
#aiguillage :
arguments_aiguillage="$@"
script_appellant="$0"
while getopts ":d:n:i:f:hl:t:e:s:co:" opt;do
        case "$opt" in
                d) 	arg_d ${OPTARG}
					nbr_arg_single_ping=$((nbr_arg_single_ping+2))
				 #-d nom_dest-ip_dest, OBLIGATOIRE, argument ip_dest et nom_dest
                        ;;
                n) nbr_iteration=${OPTARG}
					#-n nbr_iteration, optionnel, nombre de ping vers destination(par defaut 50)
                        ;;
                i) if=${OPTARG}
					nbr_arg_single_ping=$((nbr_arg_single_ping+1))
					#-i interface, OBLIGATOIRE, type d'interface prod ou admin en general
                        ;;
                f) DESTINATION=${OPTARG}
                        ;;
				l) lan=${OPTARG}
					if [ $nbr_arg_single_ping -ge 1 ];then
						nbr_arg_single_ping=$((nbr_arg_single_ping+1))
					elif [ $nbr_arg_transfert -ge 1 ];then
						nbr_arg_transfert=$((nbr_arg_transfert+1))
					fi
					#-l lan, OBLIGATOIRE, identifiant de l'interface exemple : bond0@1495
						;;
				t)	user_at_cible_scp=${OPTARG}
					nbr_arg_transfert=$((nbr_arg_transfert+1))
					#-t user@cible, OBLIGATOIRE, nom d'utilisateur suivi d'un @ et de l'ip de la plateforme distante pour echange scp
						;;
				e)  if [ ${OPTARG} == "creation" ];then
						creation_env_dd
					elif [ ${OPTARG} == "destruction" ];then
						destruction_env_dd
					else erreur $KO "argument ${OPTARG} incorrect pour l'option -${opt}" $ESTOP
					fi
					exit 0
					#-e creation ou -e destruction, OBLIGATOIRE, met en place l'environnement de dump fichier et tcp
						;;
				s) 	taille_packets=${OPTARG}
					#-s taille_packets, optionnel, definit la taille d'un paquet ping
						;;
				c) echo "capture de trame"
					#indique qu'une capture devra être faite, n'est valable qu'avec -f
					capture=1
					#-c, optionnel, active la capture de trame tcp
						;;
				o) #ordonancement : C'est simplement l'ajout dans la crontab
					#l'argument c'est le texte à ajouter ou à retirer de la crontab
					#
					ligne_ordo=${OPTARG}
					aide
					exit 0
						;;
                :) erreur $KO "ARGUMENT MANQUANT" $ESTOP
                        ;;
                \?) aide
						;;
		*) aide
			exit 0
			;;
        esac
done
#
#verification de coherence des options
#-f DESTINATION existe
#-fc destination existe et capture=1
#-dli obligatoires : nbr_arg_single_ping=4 / -cns optionnels
#-tl le -t doit être avant le -l : nbr_arg_transfert=2
#-cl lan existe et capture=1
#NB : -e et -o sont des options independantes et ne comptent pas dans l'aiguillage
#si -df ou -if KO
#
if [ $DESTINATION ];then
	multiple_ping
	exit 0;
fi
if [ "$nbr_arg_single_ping" -eq 4 ];then
	sortie_ping=${nom_dest}.${if}.ping.$$
	sortie_ping=$REP_SOURCE/$sortie_ping
	if [ -a ${nom_dest}.${if}.ping* ];then
		erreur $KO "ping de l'interface ${if} du serveur ${nom_dest} en cours d'execution" $ESTOP
	fi
	if [ $capture -eq 1 ];then
		capture ${lan}
	fi
	custom_ping ${ip_dest} ${nbr_iteration} ${taille_paquets} ${lan} >${sortie_ping}
	analyse_ping >>${COMPTE_RENDU}
	if [ $capture -eq 1 ];then
		arret_job_capture $job_tcpdump $tmout_tcpdump
	fi
	exit 0;
elif [ "$nbr_arg_transfert" -eq 2 ];then
	test_bp $user_at_cible_scp $lan 2>>$RESULTAT_ERR 1>>$RESULTAT_BPP
	sed -ni "/maintenant/p" $RESULTAT_ERR
	exit 0;
elif [ "$capture" -eq 1 ];then
	#la capture est invoqué seule
	if [ ! ${lan} ];then
		erreur $KO "lan non définit" $ESTOP
	fi
	capture ${lan}
	arret_job_capture $job_tcpdump $tmout_tcpdump
else 
	erreur $KO "arguments $arguments_aiguillage incorrects" $ESTOP
fi
