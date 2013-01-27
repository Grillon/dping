#!/bin/ksh
#script de diagnostique par ping
#ceci est un script de la collection jettable :)
trap 'rm /tmp/dping.tmp' EXIT INT QUIT
#Chargement bibliotheques
. ./libG.ksh
#constantes :
SOURCE=$(uname -n)
OS=$(uname -s)
CONF_DIR=
DESTINATION=${lst_dest:=destination}
ANALYSE_PING=analyse_ping.awk
nbr_iteration=15
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
date_debut=$(date)
if [ $OS = Linux ];then 
	ping -c "$nbr_iteration" "$ip_dest"
elif [ $OS = HP-UX ];then 
	ping $ip_dest -n $nbr_iteration
else erreur $KO "OS non supporte" $ESTOP
fi
date_fin=$(date)

}
function analyse_ping
{
awk -v source=$SOURCE -v dest=$dest -v nom_if=$if -v nbr_iteration=$nbr_iteration -v debut="$date_debut" -v fin="$date_fin" -f $ANALYSE_PING $SORTIE_PING
erreur $? "analyse ping" $ESTOP
}
#aiguillage :
while getopts ":d:n:i:f:" opt;do
        case "$opt" in
                d) OLDIFS="$IFS";
                        IFS=\-;
                        set ${OPTARG};
                        if [ $# -ne 2 ];then erreur $KO "arguments de -${opt} invalides" $ESTOP aide;fi
                        dest=$1;
                        ip_dest=$2;
                        IFS="${OLDIFS}";
                        lst_dest=NO_FILE
                        ;;
                n) nbr_iteration=${OPTARG};
                        ;;
                i) if=${OPTARG}
                        ;;
                f) lst_dest=${OPTARG}
                        ;;
                :) erreur $KO "ARGUMENT MANQUANT" $ESTOP
                        ;;
                \?)
                        ;;
        esac
done
#
#
#
#
#
#
#
#
#
#
#
#
#
#verification de coherence des options
#-din ou -fin OK si -df KO
if [ $lst_dest = NO_FILE ] && [ -n $ip_dest ];then
        erreur $KO "les options \"-d\" et \"-f\" sont exclusives" $ESTOP aide
fi
if [ -a /tmp/dping.tmp ];then
erreur $KO "$0 deja en cours d'execution" $ESTOP
fi
touch /tmp/dping.tmp
if [ ${lst_dest} = NO_FILE ];then
SORTIE_PING=${dest}.ping
custom_ping ${ip_dest} ${nbr_iteration} >${SORTIE_PING}
analyse_ping >>${COMPTE_RENDU}
else
while read dest ip_dest admin;do
	SORTIE_PING=${dest}.ping
        custom_ping ${ip_dest} ${nbr_iteration} >${SORTIE_PING}
        analyse_ping >>${COMPTE_RENDU}
done<${DESTINATION}
fi
