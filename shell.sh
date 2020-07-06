{
TZ="Asia/Shanghai" 
echo -e "#Last Modified: $(date)"
echo "/log info \"Start updating CN_IP_List!\""
echo "/log info \"Start removing old list!\""
echo "/ip firewall address-list remove [/ip firewall address-list find list=CN]"
echo "/log info \"Remove finished!\""
echo "/log info \"Start importing CN_IP_List!\""
echo "/ip firewall address-list"
echo "add list=CN address=192.168.0.0/16"
nets=`cat ./china_ip_list.txt`
for net in $nets ; do
  echo "add list=CN address=$net "
done
echo "/log info \"Importing CN_IP_List finished!\""
} > china_ip_list.rsc 
