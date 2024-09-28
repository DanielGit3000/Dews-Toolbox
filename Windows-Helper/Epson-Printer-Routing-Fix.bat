ECHO change broken default route to epson printer

route delete  0.0.0.0 192.168.223.1
route delete 192.168.223.0
route delete 192.168.223.1
route delete 192.168.223.12


route add -p 192.168.223.1 MASK 255.255.255.255 192.168.223.12 METRIC 1000 IF 15
