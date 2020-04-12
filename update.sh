#!/bin/bash
HERE=$(cd -P -- $(dirname -- "$0") && pwd -P)
RULES_DIR=$1
CURRENT_DATE=$(date +%Y-%m-%d)
test -d $RULES_DIR || mkdir -p $RULES_DIR
test -f $RULES_DIR/versions || echo -e '\n\n\n\n\n' > $RULES_DIR/versions

# ======================================
# get gfwlist for shadowsocks ipset mode
python $HERE/fwlist.py gfwlist_download.conf

grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" gfwlist_download.conf > gfwlist_download_tmp.conf

if [ -f "gfwlist_download.conf" ]; then
	cat gfwlist_download_tmp.conf | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" > gfwlist_merge.conf
	cat gfwlist_download_tmp.conf | sed "s/^/ipset=&\/./g" | sed "s/$/\/gfwlist/g" >> gfwlist_merge.conf
fi

sort -k 2 -t. -u gfwlist_merge.conf > gfwlist.conf
rm -f gfwlist_merge.conf

# delete site below
sed -i '/m-team/d' "gfwlist.conf"
sed -i '/windowsupdate/d' "gfwlist.conf"

md5sum1=$(md5sum gfwlist.conf | awk '{print $1}')
test -f $RULES_DIR/gfwlist.conf && md5sum2=$(md5sum $RULES_DIR/gfwlist.conf | awk '{print $1}')

if [ "$md5sum1"x = "$md5sum2"x ]; then
	echo 'gfwlist is already up to date.'
else
	echo 'Update gfwlist!'
	cp -f gfwlist.conf $RULES_DIR/
	sed -i "1c $CURRENT_DATE # $md5sum1 gfwlist" $RULES_DIR/versions
fi

# ======================================
# get chnroute for shadowsocks chn and game mode
# use ipip_country_cn ip database sync by https://github.com/firehol/blocklist-ipsets from ipip.net（source: https://cdn.ipip.net/17mon/country.zip）.
wget -4 -O- https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset | sed '/^#/d' > chnroute.txt

md5sum3=$(md5sum chnroute.txt | awk '{print $1}')
test -f $RULES_DIR/chnroute.txt && md5sum4=$(md5sum $RULES_DIR/chnroute.txt | awk '{print $1}')

if [ "$md5sum3"x = "$md5sum4"x ]; then
	echo 'chnroute is already up to date.'
else
	IPLINE=$(cat chnroute.txt | wc -l)
	IPCOUN=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' chnroute.txt)
	echo "update chnroute, $IPLINE subnets, $IPCOUN unique IPs !"
	cp -f chnroute.txt $RULES_DIR/
	sed -i "2c $CURRENT_DATE # $md5sum3 chnroute" $RULES_DIR/versions
fi

# ======================================
# use apnic data
wget -4 -c http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -O apnic.txt

echo -e "[Local Routing]\n## China mainland routing blocks\n## Sources: https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest" > Routing.txt
echo "## Last update: $CURRENT_DATE" >> Routing.txt

# IPv4
echo "## IPv4" >> Routing.txt
grep ipv4 apnic.txt | grep CN | awk -F\| '{printf("%s/%d\n", $4, 32-log($5)/log(2))}' >> Routing.txt
echo -e "\n" >> Routing.txt

# IPv6
echo "## IPv6" >> Routing.txt
grep ipv6 apnic.txt| grep CN | awk -F\| '{printf("%s/%d\n", $4, $5)}' >> Routing.txt

md5sum5=$(md5sum Routing.txt | awk '{print $1}')
test -f $RULES_DIR/Routing.txt && md5sum6=$(md5sum $RULES_DIR/Routing.txt | awk '{print $1}')

if [ "$md5sum5"x = "$md5sum6"x ]; then
	echo 'Routing is already up to date.'
else
	echo 'Update Routing!'
	cp -f Routing.txt $RULES_DIR/
	sed -i "3c $CURRENT_DATE # $md5sum5 Routing" $RULES_DIR/versions
fi

# ======================================
# get cdn list for shadowsocks chn and game mode
wget -4 -c https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
wget -4 -c https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf
wget -4 -c https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf

sed '/^#/d' apple.china.conf | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > apple_download.txt
sed '/^#/d' google.china.conf | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > google_download.txt

md5sum7=$(md5sum apple_download.txt | awk '{print $1}')
test -f $RULES_DIR/apple_china.txt && md5sum8=$(md5sum $RULES_DIR/apple_china.txt | awk '{print $1}')

md5sum9=$(md5sum google_download.txt | awk '{print $1}')
test -f $RULES_DIR/google_china.txt && md5sum10=$(md5sum $RULES_DIR/google_china.txt | awk '{print $1}')

if [ "$md5sum7"x = "$md5sum8"x ]; then
	echo 'apple china list is already up to date.'
else
	echo 'Update apple china list!'
	cp -f apple_download.txt $RULES_DIR/apple_china.txt
	sed -i "4c $CURRENT_DATE # $md5sum7 apple_china" $RULES_DIR/versions
fi
if [ "$md5sum9"x = "$md5sum10"x ]; then
	echo 'google china list is already up to date.'
else
	echo 'Update goole china list!'
	cp -f google_download.txt $RULES_DIR/google_china.txt
	sed -i "5c $CURRENT_DATE # $md5sum9 google_china" $RULES_DIR/versions
fi

# ======================================
# get cdn list for shadowsocks chn and game mode
cat accelerated-domains.china.conf apple.china.conf google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" > cdn.txt

md5sum11=$(md5sum cdn.txt | awk '{print $1}')
test -f $RULES_DIR/cdn.txt && md5sum12=$(md5sum $RULES_DIR/cdn.txt | awk '{print $1}')

if [ "$md5sum11"x = "$md5sum12"x ]; then
    echo 'cdn list is already up to date.'
else
    echo 'Update cdn!'
    cp -f cdn.txt $RULES_DIR/
    sed -i "6c $CURRENT_DATE # $md5sum11 cdn" $RULES_DIR/versions
fi

# ======================================
rm -f *.conf *.txt
