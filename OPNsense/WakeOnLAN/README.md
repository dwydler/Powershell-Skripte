# Hinweis
Es empfiehlt sich für das Skript ein dediziertes Benutzerkonto auf der OPNsense anzulegen. Damit die Berechtigungen granular und zu gleich flexibel sind, am Besten die Berechtigungen für WOL über eine neue Gruppe realisieren. So dass der Benutzer schlussendlich Mitglied dieser Gruppen sind.
Im Benutzerkonto kann für die RESTful API ein Key mit dem dazugehörigen Secret erzeugt werden. Die Daten werden nach Generierung als Textdatei zum Download angeboten.

# Variablen
Nachstehend eine Erklärung der verwendeten Variablen, die benutzerdefiniert sind.

$strOpnSenseUsername: RESTful API Key
$strOpnSensePassword: RESTful API Secret
$strOpnSenseUri: IP-Adresse oder FQDN der OPNsense