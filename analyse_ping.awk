#!/usr/local/awk -f
#'/icmp_seq/ {split($5,a,"=");print a[2];} /rtt/ {print $0} /transmitted/ {print $0}'
BEGIN {
x=1
}
{
if ($0~/icmp_seq/) {
split($5,seq_encours,"=")
	if (seq_encours[2] == x) x++
	else {
		while (x<seq_encours[2]) {
			seq_manquantes=seq_manquantes" "x
			x++
			if (seq_encours[2] == x) x++
		}
	}
}
if ($0~/rtt/) { moyennes=$0 }
if ($0~/transmitted/) { statistiques=$0 }
}
END{
print "hostname : "source" destination : "dest" interface : "nom_if
print "date de debut : "debut" date de fin   : "fin
print "moyennes transmission : "moyennes
print "statistiques : "statistiques
print "liste des sequences perdues : "seq_manquantes
print "derniere seq recu : "x-1
}
