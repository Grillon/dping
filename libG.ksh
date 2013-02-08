#!/bin/ksh
#variable
OK=0;
KO=1;
ECONT=1;
ESTOP=251;
function debug
{
if [ $# -ne 1 ];then erreur $KO "$0 : nombre d'argument incorrects" $ECONT;fi
case $1 in
0) MODE_DEBUG=""
	;;
1)	MODE_DEBUG="set -x"
	;;
2)	MODE_DEBUG="set -xv"
	;;
*)	erreur $KO "$0 : argument $1 invalides" $ECONT
	MODE_DEBUG="set -xv"
	return 1
	;;
esac
return 0
}
function entierValide
{
if [ $# -ne 1 ];then erreur $KO "$0 : nombre d'argument incorrects" $ECONT;fi
return $(echo "$1" | awk '{if ($0 ~ /^[0-9]+$/) {print "0"} else print "1"}')
}
function decimalValide
{
if [ $# -ne 1 ];then erreur $KO "$0 : nombre d'argument incorrects" $ECONT;fi
return $(echo "$1" | awk '{if ($0 ~ /^[0-9]+\.[0-9]+$/) {print "0"} else print "1"}')
}
function IPValide
{
if [ $# -ne 1 ];then erreur $KO "$0 : nombre d'argument incorrects" $ECONT;fi
return $(echo "$1" | awk '{if ($0 ~ /^[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]$/) {print "0"} else print "1"}')
}
function hostValide
{
if [ $# -ne 1 ];then erreur $KO "$0 : nombre d'argument incorrects" $ECONT;fi
return $(echo "$1" | awk '{if ($0 ~ /^[a-zA-Z_-\.0-9]+$/) {print "0"} else print "1"}')
}
function alNumValide
{
if [ $# -ne 1 ];then erreur $KO "$0 : nombre d'argument incorrects" $ECONT;fi
return $(echo "$1" | awk '{if ($0 ~ /^[a-zA-Z0-9]+$/) {print "0"} else print "1"}')
}
function initCouleur
{
#usage : initCouleur (charge des variable portant les code ANSI de couleurs)
#ensuite il suffit d'entourer le texte comme avec du html
#tCouleur pour le texte et fCouleur pour le fond; a pour activation; d pour desactivation; raz pour revenir
#a l'etat d'origine
#cette fonction vient tout droit de wicked cool shell script;
$MODE_DEBUG
esc=""
tRouge="${esc}[31m";    tVert="${esc}[32m"
tBlanc="${esc}[37m";    tNoir="${esc}[30m"
fRouge="${esc}[41m";    fVert="${esc}[42m"
aGras="${esc}[1m";    dGras="${esc}[22m"
raz="${esc}[0m"
}
function erreur
{
$MODE_DEBUG
#erreur devient complexe
#arg 1 : numero d'erreur;
#arg 2 : message;
#arg 3 : code erreur(de 251 ` 254), $ECONT pour continuer, $ESTOP pour arret;
#args 4 : fonction ` appeller en cas d'erreur avant sortie

if [ $1 -ne 0 ];then
echo "${aGras} $(uname -n) ${dGras} : ${tRouge} $2 ${fRouge}${tBlanc} KO ${raz}" >&2
if [ -n "$4" ];then
$4
fi
if [ $3 -ge 251 ];then
exit $3
fi
else
echo "${aGras} $(uname -n) ${dGras} : ${tVert} $2 ${fVert}${tBlanc} OK ${raz}"
fi
}
initCouleur
