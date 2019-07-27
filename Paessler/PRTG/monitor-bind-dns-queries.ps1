
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
	
$curStats = New-Object System.Xml.XmlDocument
$curStats.Load( $("http://"+$args[0]+":8053")) 
 
$prevStats = New-Object System.Xml.XmlDocument
$prevStats.Load("C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\bind9stats.xml")
 
$output = "<prtg>`n"
 
# Incoming Requests by DNS
for ($i = 0; $i -lt ($curStats.statistics.server.counters[0].counter | Where {$_.name -notlike 'RESERVED*'}).count; $i++) {  
    $output += "`t<result>`n"
    $output += "`t`t<channel>$(($curStats.statistics.server.counters[0].counter | Where {$_.name -notlike 'RESERVED*'}).name[$i])</channel>`n"
    
    $value = ($curStats.statistics.server.counters[0].counter | Where {$_.name -notlike 'RESERVED*'}).'#text'[$i] - ($prevStats.statistics.server.counters[0].counter | Where {$_.name -notlike 'RESERVED*'}).'#text'[$i]
    if($value -lt 0 ) { $value = ($curStats.statistics.server.counters[0].counter | Where {$_.name -notlike 'RESERVED*'}).'#text'[$i] }
 
    $output += "`t`t<value>$($value)</value>`n"
    $output += "`t</result>`n"
}
 
# Incoming Queries by Query Type
for ($i = 0; $i -lt ($curStats.statistics.server.counters[1].counter).count; $i++) {
   
    $output += "`t<result>`n"
    $output += "`t`t<channel>$(($curStats.statistics.server.counters[1].counter).name[$i])</channel>`n"
 
    $value = ($curStats.statistics.server.counters[1].counter).'#text'[$i] - ($prevStats.statistics.server.counters[1].counter).'#text'[$i]
    if($value -lt 0 ) { $value = ($curStats.statistics.server.counters[1].counter).'#text'[$i] }
 
    $output += "`t`t<value>$($value)</value>`n"
    $output += "`t</result>`n"
}
 
# Zone Maintenance Statistics
for ($i = 0; $i -lt ($curStats.statistics.server.counters[3].counter).count; $i++) {
   
    $output += "`t<result>`n"
    $output += "`t`t<channel>$(($curStats.statistics.server.counters[3].counter).name[$i])</channel>`n"
 
    $value = ($curStats.statistics.server.counters[3].counter).'#text'[$i] - ($prevStats.statistics.server.counters[3].counter).'#text'[$i]
    if($value -lt 0 ) { $value = ($curStats.statistics.server.counters[3].counter).'#text'[$i] }
 
    $output += "`t`t<value>$($value)</value>`n"
    $output += "`t</result>`n"
}
$output += "</prtg>"
 
# Output XML
$output
 
# Save BIND Stats in XML file
$curStats.Save("C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\bind9stats.xml") 
