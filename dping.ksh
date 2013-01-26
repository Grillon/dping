#!/bin/ksh
#script de diagnostique par ping
#ceci est un script de la collection jettable :)
trap 'rm /tmp/dping.tmp' EXIT INT QUIT
#Chargement bibliotheques
. ~/.thierry/lib/libG.ksh
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
#usage : custom_ping [ "lan_source" ] "ip_dest" "nbr_iteration"
date_debut_${dest}="$(date)"
if [ ${OS} = "HP-UX" ];then
        if [ $# -eq 3 ];then
                lan_source="$1"
                ip_dest=$2
                nbr_iteration="$3"
                ping -i $lan_source $ip_dest -n $nbr_iteration
        else erreur $KO "$0 argmuments $@ invalides - usage HPUX : ping lan_source ip_dest nbr_iteration" $ESTOP
        fi
elif [ ${OS} = "Linux" ];then
        if [ $# -eq 2 ];then
                ip_dest="$1"
                nbr_iteration="$2"
                ping -c "$nbr_iteration" "$ip_dest"
        elif [ $# -eq 3 ];then
                lan_source=$1
                ip_dest=$2
                nbr_iteration=$3
                ping -I "${lan_source}" -c "$nbr_iteration" "$ip_dest"
        else erreur $KO "$0 argmuments $@ invalides - usage LINUX : ping [ lan_source ] ip_dest nbr_iteration" $ESTOP
        fi
else erreur $KO "OS $OS non supporte" $ESTOP
fi
date_fin_${dest}="$(date)"
return 0
}
function enchainement
{
custom_ping
analyse_ping
}
function actions_sur_liste
{
#usage : actions_sur_liste "action separe par un -" "fichier contenant une liste"
echo "non implemente"
}
function analyse_ping
{
awk -v"variable=$SOURCE,$dest,$if,$nbr_iteration" -f $ANALYSE_PING
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
###############################CONSTANTES
#
#
#
#
SOURCE=$(uname -n)
OS=$(uname -s)
CONF_DIR="~/.thierry/.dping"
DESTINATION=${lst_dest:=${CONF_DIR}/destination}
ANALYSE_PING=~/.thierry/bin/analyse_ping.awk
#options obligatoire pour hpux
#if [ $OS = "HP-UX" ];then
#LAN_SOURCE=1
#fi
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
custom_ping ${LAN_SOURCE} ${ip_dest} ${nbr_iteration} >${SORTIE_PING}
else
while read dest ip_dest admin;do
        custom_ping ${LAN_SOURCE} ${ip_dest} ${nbr_iteration} >${SORTIE_PING}
        analyse_ping
done<${DESTINATION}
fi
