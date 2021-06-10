#!/bin/bash

if [ -z "$LOCALNET" ]; then
	echo -e "*** No -e LOCALNET variable set, defaulting to 192.168.1.0/24. You probably dont want this"
        LOCALNET="192.168.1.0/24"
fi

if [ "$ACCOUNTID" ]; then
        if [ "$LICENSEKEY" ]; then
                echo -e "*** Found a Maxmind account and licensekey pair, ntopng will support GeoIP lookups if this is valid\nUpdating Maxmind Database"
                echo -e "*** AccountID $ACCOUNTID\nLicenseKey $LICENSEKEY\nEditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country" > /etc/GeoIP.conf
                /usr/bin/geoipupdate
        else
                echo -e "*** No Maxmind GeoIP account and licensekey pair found, ntop will not support GeoIP lookups. Please get a license from maxmind.com and add as docker run -e options"
        fi
else
        echo -e "*** No Maxmind GeoIP account and licensekey pair found, ntop will not support GeoIP lookups. Please get a license from maxmind.com and add as docker run -e options"
fi
echo "*** Starting Redis"
service redis-server start
echo "*** Starting netflow2ng"
cd /ntop/netflow2ng/dist  && ./netflow2ng-dockerv0.0.2-linux-x86_64 &
echo "*** Starting ntopng"
cd /ntop/ntopng && ./ntopng --local-networks $LOCALNET -i tcp://127.0.0.1:5556 

