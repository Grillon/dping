#!/bin/ksh
#script de diagnostique par ping
#ceci est un script de la collection jettable :)
trap 'quitter' EXIT INT QUIT
#Chargement bibliotheques
. ./libG.ksh
#constantes :
SOURCE=$(uname -n)
OS=$(uname -s)
CONF_DIR=
DESTINATION=${lst_dest:=destination}
ANALYSE_PING=analyse_ping.awk
nbr_iteration=50
if=PRODUCTION
COMPTE_RENDU=bilan.txt
function aide
{
echo "
USAGE : $0 [ -d hostname_destination-ip_dest ] || [ -f fichier_liste_destination ]
[ -i type_if (prod/admin) ]
[ -n nombre_iteration ]

# exemple d'une ligne du fichier :
hostname ip_prod ip_admin
"
}
function custom_ping
{
#ping HPUX : ping -i $lan_source $ip_dest -n $nbr_iteration
#ping Linux : ping -c "$nbr_iteration" "$ip_dest"
#ping Linux 3 param : ping -I "${lan_source}" -c "$nbr_iteration" "$ip_dest"
ip_dest=$1
nbr_iteration=$2
date_debut=$(date +%s)
if [ "$OS" = Linux ];then 
	ping -c "$nbr_iteration" "$ip_dest"
elif [ "$OS" = HP-UX ];then 
	ping $ip_dest -n $nbr_iteration
else erreur $KO "OS non supporte" $ESTOP
fi
date_fin=$(date +%s)

}
function analyse_ping
{
awk -v source=$SOURCE -v dest=$dest -v nom_if=$if -v nbr_iteration=$nbr_iteration -v debut="$date_debut" -v fin="$date_fin" -f $ANALYSE_PING $SORTIE_PING
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
}
function arg_d
{
#gestion de l'argument -d
arguments=$1
OLDIFS="$IFS";
IFS=\-;
set ${arguments}
if [ $# -ne 2 ];then erreur $KO "arguments de -${opt} invalides" $ESTOP aide;fi
dest=$1;
ip_dest=$2;
IFS="${OLDIFS}";
lst_dest=NO_FILE
}
#aiguillage :
while getopts ":d:n:i:f:h" opt;do
        case "$opt" in
                d) arg_d ${OPTARG}
                        ;;
                n) nbr_iteration=${OPTARG};
                        ;;
                i) if=${OPTARG}
                        ;;
                f) lst_dest=${OPTARG}
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
	SORTIE_PING=${dest}.ping.$$
	custom_ping ${ip_dest} ${nbr_iteration} >${SORTIE_PING}
	analyse_ping >>${COMPTE_RENDU}
else
	while read dest ip_dest nif;do
		lock=/tmp/dping.tmp
		touch $lock
		if [ -n "$nif" ];then
			$0 -d ${dest}-${ip_dest} -n ${nbr_iteration} -i ${nif}&
		else
			$0 -d ${dest}-${ip_dest} -n ${nbr_iteration} -i ${if}&
		fi
	done<${DESTINATION}
fi
