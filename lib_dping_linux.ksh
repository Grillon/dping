#!/usr/bin/env ksh
MODE_DEBUG=""
ERREUR=0
RESULTAT=~
TCPDUMP=/usr/sbin/tcpdump
SOURCE=$(uname -n)
OS=$(uname -s)
CONF_DIR=
TR_BASE=/tmp/yst/test_dd
T_IO=$TR_BASE/tio.data
R_IO=$TR_BASE/rio.data
#DESTINATION=destination
ANALYSE_PING=analyse_ping_linux.awk
ANALYSE_PING=$REP_SOURCE/$ANALYSE_PING
RESULTAT_BPP=${RESULTAT}/rrdtool_bp
RESULTAT_ERR=${RESULTAT}/log.err
nbr_iteration=50
taille_paquets=56
COMPTE_RENDU=bilan.txt
COMPTE_RENDU=${RESULTAT}/${COMPTE_RENDU}
#variable d'aiguillage :
capture=0 # par defaut pas de capture
nbr_arg_single_ping=0
nbr_arg_transfert=0


function aide
{
echo "
USAGE : $0 [ -d hostname_destination-ip_dest ] [ -i type_if (prod/admin) ] [ -n nombre_iteration ]
$0 [ -f fichier_liste_destination ] [ -i type_if (prod/admin) ] [ -n nombre_iteration ] [ -c ]
$0 [ -t user@ip_cible ]

# exemple d'une ligne du fichier :
hostname ip interface nom_interface nbr_iteration
#lorsque le nom_interface n'est pas fournit il est remplace par PRODUCTION
"
}
function custom_ping
{
#ping HPUX : ping -i $lan_source $ip_dest -n $nbr_iteration
#ping Linux : ping -c "$nbr_iteration" -s "$taille_paquets" "$ip_dest"
#ping Linux 3 param : ping -I "${lan_source}" -c "$nbr_iteration" "$ip_dest"
if [ $# -ne 4 ];then
	erreur $KO "nombre d'arguments invalides" $ESTOP
fi 
typeset ip_dest=$1
typeset nbr_iteration=$2
typeset taille_paquets=$3
typeset lan=$4

date_debut=$(date +%s)
ping -c "$nbr_iteration" -s "$taille_paquets" "$ip_dest"
bp=analyse_bp ${lan}
date_fin=$(date +%s)
}
function test_bp
{
if [ $# -ne 2 ];then erreur $KO "$0 : nombre d'argument incorrects" $ESTOP;fi
typeset user_at_cible_scp=$1
typeset lan=$2
typeset date_debut=$(date +%s)
scp ${T_IO} ${user_at_cible_scp}:${R_IO}&
scp_pid=$(jobs -p)
while [ $(jobs -p) ];do
	analyse_bp ${lan}
	typeset date_fin=$(date +%s)
	if [ ${txbps} -lt 10000000 ];then erreur $KO "${cible_scp} - debut : ${date_debut} - maintenant : ${date_fin} -- sortie : ${txbps} bps - entree : ${rxbps} bps" $ECONT;fi
	erreur $OK "${date_fin}:${txbps}:${rxbps}" $ECONT
	if [ $((${date_fin} - ${date_debut})) -gt 100 ];then 
		erreur $KO "transfert trop long" $ECONT
		kill $scp_pid
	fi
	sleep 5
done
}
function analyse_bp
{
#arg lan
#sar -n DEV 2 1 | awk '/Average/ && (/bond0.1495/ || /IFACE/) {print $0}'
#Average:        IFACE   rxpck/s   txpck/s   rxbyt/s   txbyt/s   rxcmp/s   txcmp/s  rxmcst/s
#Average:    bond0.1495      0.50      0.00     25.00      0.00      0.00      0.00      0.50
#analyse_bp ${lan}
if [ $# -ne 1 ];then
	erreur $KO "nombre d'arguments invalides" $ESTOP
fi 
typeset lan=$1
txbps=$(sar -n DEV 2 1 | awk -v lan=${lan} '/Average/ && $0 ~ lan {sub("\\.[0-9][0-9]","",$6);print $6}')
rxbps=$(sar -n DEV 2 1 | awk -v lan=${lan} '/Average/ && $0 ~ lan {sub("\\.[0-9][0-9]","",$5);print $5}')
echo ${txbps}-${rxbps}
}
function analyse_ping
{
#c'est une fonction non utilisable directement donc je en verifie pas les arguments
awk -v bp_tr=$bp -v source=$SOURCE -v dest=$dest -v nom_if=$if -v nbr_iteration=$nbr_iteration -v debut=$date_debut -v fin=$date_fin -f $ANALYSE_PING $sortie_ping
erreur $? "analyse ping" $ESTOP
}
function quitter
{
if [ -n "$lock" ];then 
rm "$lock"
fi
if [ -n "$SORTIE_PING" ];then
rm "$SORTIE_PING"
fi
if [ -n "$lock_tcpdump" ];then
rm "$lock_tcpdump"
fi
}
function arg_d
{
#gestion de l'argument -d
arguments=$1
OLDIFS="$IFS";
IFS=\-;
set ${arguments}
if [ $# -ne 2 ];then erreur $KO "arguments de -${opt} invalides" $ESTOP aide;fi
nom_dest=$1;
ip_dest=$2;
IFS="${OLDIFS}";
}
function arg_t
{
#cette fonction n'est plus utile
#gestion de l'argument -d pourra etre remplace par cette fonction
arguments="$1"
OLDIFS=${IFS}
IFS=\-;
set ${arguments}
if [ $# -ne 3 ];then erreur $KO "arguments ${OPTARG} invalides pour -${opt} " $ESTOP aide;fi
arg1=$1;
arg2=$2;
arg3=$3;
IFS=${OLDIFS}
}
function creation_env_dd
{
if [ -a $TR_BASE ];then 
	erreur $KO "$TR_BASE existe! veuillez faire les verification necesaires manuellement" $ESTOP
fi
mkdir -m 777 -p $TR_BASE
erreur $? "creation du repertoire $TR_BASE" $ESTOP
mount -t tmpfs tmpfs $TR_BASE
erreur $? "montage $TR_BASE" $ESTOP
dd if=/dev/zero bs=32k count=16k of=${T_IO}
erreur $? "creation ${T_IO}" $ESTOP
}
function destruction_env_dd
{
if [ -a $TR_BASE ];then 
	umount $TR_BASE
	erreur $? "demontage $TR_BASE" $ESTOP
	rmdir $TR_BASE
	erreur $? "suppression du rep $TR_BASE" $ESTOP
else erreur $KO "le repertoire $TR_BASE n'existe pas" $ESTOP
fi
}
function pertes
{
#indique s'il y a des pertes
typeset pertes=1
for i in $(grep _ $COMPTE_RENDU | tail -$(wc -l $DESTINATION | cut -d" " -f1) | cut -d: -f2);do if [ $i -gt 0 ]; then pertes=0;fi;done;
echo $pertes
}
function baseOK
{
typeset fs_base=$(df -hP $TR_BASE | awk 'NR>1 {print $1}')
if [ $fs_base = "tmpfs" ];then 
	echo 0
else 
	echo 1
fi
}
function capture
{
#capture ${lan}
if [ $# -ne 1 ];then 
	erreur $KO "$0 : nombre d'argument incorrects" $ESTOP
fi
erreur $(baseOK) "presence de la base" $ECONT "$0 -e creation"
if [ $ERREUR -gt 0 ];then 
	erreur $KO "echec creation de la base, aucune capture" $ECONT
else
	if [ -x $TCPDUMP ];then
		lock_tcpdump=${TR_BASE}/$(uname -n)_${lan}
		fichier_dump=${TR_BASE}/$(uname -n)_${lan}_$(date +%Y%m%d_%H%M).dump
		TCPDUMP_COMMANDE="$TCPDUMP -i ${lan} -C 1 -W 5 -w $fichier_dump"
		if [ ! -a $lock_tcpdump ];then 
			touch $lock_tcpdump
			$TCPDUMP_COMMANDE&
			erreur $? "execution commande $TCPDUMP_COMMANDE" $ECONT
			debut_dump=$(date +%s)
			if [ $ERREUR -eq 0 ];then
				job_tcpdump=$(echo $a | awk '{print $NF}')
			else
				job_tcpdump=""
			fi
		else 
			erreur $KO "tcpdump deja en cours" $ECONT
		fi
	else
		erreur $KO "la commande $TCPDUMP n'existe pas" $ECONT
	fi
fi
}
function arret_job_capture
{
if [ $# -eq 2 ];then
	typeset tmout_dump=$2
elif [ $# -ne 1 ];then 
	erreur $KO "$0 : nombre d'argument incorrects" $ESTOP
fi
typeset job_tcpdump=$1
while [ $(jobs -p | egrep "^${job_tcpdump}$") ];
	do
		sleep 1;
		instant_dump=$(date +%s)
		if [ ! $debut_dump ];then
			kill ${job_tcpdump}
		elif [ $(($instant_dump - $debut_dump)) -gt $tmout_dump ];then
			kill ${job_tcpdump}
		fi
		#on attends la fin des pings
	done
	erreur $(pertes) "receptions paquets ping" $ECONT "rm $fichier_dump[0-4]"
	rm $lock_tcpdump
}