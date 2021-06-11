
# The SOHO FOSS ntopng. nProbe license not needed. 

### Small Office/Home office ntopng & DPI monitoring of OpenWRT / pfSense / DD-WRT 

### Why
So a friend wanted something to monitor their home network, and I remembered ntop from back in the day before my world got big. My friend just wanted to know who was talking to who on their network and didnt really need all the bells and whistles. So they, like many of you loveable lot, came to me for advice. Now normally id be saying, "hey go check out [Security Onion](https://securityonionsolutions.com/software/)," but that is way to over the top for their use case and threat model. I assume it is for you too, if you are reading this.

So i figured - why not use softflowd to export from their OpenWRT router to ntop? 

Well, ntop has been ntopng for quite some time and (unless you want to play about with ethernet port mirroring) the most common use for it is having NetFlow exporters on routers, which feed NetFlow v5/v9/v10 packets into a collector (nProbe) which in turn pushes those NetFlows into a message queue (ZMQ) system. ntopng then connects as a MQ client, pulls the flows out of the MQ and presents them in a pretty way in a web interface and lets you do things like alerting etc. 

#### It looks like this (sorta)

> router(exporter) --> Netflow Packet --> nProbe(collector) --> ZMQ <-- ntopng 

### Cash Monies

While that tried and tested recipie is great, [nProbe costs (at time of writing) 299.95 EUR](https://shop.ntop.org/) to license. If you try various docker images with ntopng and nProbe, they will work for a few minutes, than bail after a certain number of Netflow packets as there is no license. It seems that those playing with this kinda thing at home /SOHO end up getting frustrated thinking that they did something wrong. This leads to people giving up on having an extra layer of security on their home / SOHO LAN.

Now, for a SME or big enterprise, 300EUR is nothing - but for a security concious kiddo on a budget, that is a whole bunch of finger fabric (and in many cases, four or five times the cost of the router which is to be monitored). If you are a Small, Meduim or Large enterprse, [go buy the 300 EUR nProbe software from ntop](https://shop.ntop.org/), it is worth it. It does a whole heap more and its going to make your life easier in the long run. 

But, if you are just wanting to monitor your Home / SOHO LAN, dont need to high hundred megabit (or above) speeds and can sacrifice some things then; read on....**_Flying by the seat of your FOSS pants is fun!_**


### Components

 1. A router which exports NetFlow v9 (such as via the FOSS softflowd daemon)
 2. This docker image which runs 
..* ntopng
..* nDPI
..* netflow2ng
..* Redis

#### Deep Packet Inspection?
Why yes! This soltuion supports DPI. It compiles [nDPI](https://github.com/ntop/nDPI), the Open and Extensible LGPLv3 Deep Packet Inspection Library, into ntopng at build time. So if something on the network is talking on an uncommon port, you should catch it. 

#### How do you replace costly nProbe?

Ive cobbled together a solution which relies upon [Aaron Turner/synfinatic](https://github.com/synfinatic), who it seems not only writes great utilities with quirkly names (such as the awesomely catchphrased ['udp-proxy'2000' - a crappy UDP router for the year 2020 and beyond](https://github.com/synfinatic/udp-proxy-2020), but who takes time out of their busy day to replce the nProbe component with a FOSS utlity to do the same thing - introducing [netflow2ng](https://github.com/synfinatic/netflow2ng)

#### Netflow2ng Features

 * Collect NetFlow v9 stats from one or more exporters (only v9, it doesnt do sFlow/v5/IPFIX)
 * Run a ZMQ Publisher for ntopng to collect metrics from
 * Prometheus metrics
 * NetFlow Templates
 * Absolutely no commerical support whatsoever
 * Hardly any testing
 * May not support the latest versions/features of ntopng
 * Written in GoLang instead of C/C++
 * Netflow2ng utilizes [goflow](https://github.com/cloudflare/goflow) for NetFlow decoding (For more information on what NetFlow fields are supported in netflow2ng, please read the goflow docs)

#### 'Hardly any testing' .... Wait, waht?

Well I did say this is flying by the seat of your pants, budget stuff. but disclaimers from [synfinatic](https://github.com/synfinatic) aside, Ive seen this solution working just fine at several hunderd meg without hardly making CPU sweat. I also love that Aaron lists "not tested" and "no commercial support" as features. 

I like Aaron even more already. Its free, it seems pretty stable and hey, if you want guarantees then go buy nProbe. 

### Docker Switches 

#### Network
You need docker to expose TCP port 3000 (for ntopng) and UDP port 2055 (NetFlow collector).

```
-p 3000:3000/tcp -p 2055:2055/udp 
```

#### GeoIP lookups

OK, GeoIP you need a license for, go to [maxmind.com](https://www.maxmind.com) Sign up. Maxmind is free for you so just go do it. You can leave them out but you wont get the geoIP lookup in ntopng and its like 5 mintues out of your day. You want it to generate a 'GeoIP.conf' for 'geoipupdate' (select for 'the newer versions') and then copy/paste your AccountId and license key as docker variables. You can check in the downloaded GeoIP.conf and then pass the UserID and license Key from in there as docker variables. 

```
-e ACCOUNTID="123456" -e LICENSEKEY="xxxxxxxxxxxxxxxx"
```

#### Local Network

ntopng likes to know whats local. It makes it easier for you to too. You can tell it this by using the -e LOCALNET option and provider a CIDR format notation. So if yournetwork is 192.168.1.0 then its like this;

```
-e LOCALNET="192.168.1.0/24"
```

If you have multiple exporters and a few nets, then you can use CSV format

```
-e LOCALNET="192.168.1.0/24,192.168.2.0/24"
```

#### Persist data dir

Unless you want to start alerts etc from scratch every time you trash the container, you might want to persist 

```
-v /path/to/save/files/on/host:/var/lib/ntopng
```

## Get it

### Build from source

```
git clone https://github.com/shamen123/ntopng-netflowng
cd ntopng-docker
docker build -t ntopng-netflowng .
```
### Or Pull from docker hub...

```
docker pull theplexus/ntopng-netflowng
```
## Run

### after pulling from hub

```
docker run -it \
--name ntopng-netflowng \
-p 3000:3000/tcp \
-p 2055:2055/udp \
-e ACCOUNTID="123456" \
-e LICENSEKEY="xxxxxxxxxxxxxxx" \
-e LOCALNET="192.168.1.0/24" \
-v /path/to/save/files/on/host:/var/lib/ntopng \
--restart unless-stopped \
theplexus/ntopng-netflowng
```

### After building from source

```
docker run -it \
--name ntopng-netflowng \
-p 3000:3000/tcp \
-p 2055:2055/udp \
-e ACCOUNTID="123456" \
-e LICENSEKEY="xxxxxxxxxxxxxxx" \
-e LOCALNET="192.168.1.0/24" \
-v /path/to/save/files/on/host:/var/lib/ntopng \
--restart unless-stopped \
ntopng-netflowng
```

### Firewall

Make sure the machine running docker allows port 3000 TCP and port 2055 UDP inbound from your router IP. Else this wont end well. Dont forget to restart your firewall to pick up the change. 

## What about softflowd on my router? 

There are loads of NetFlow exporters out there in the commercial market. But for OpenWRT (and many others) you want to install [softflowd](https://github.com/irino/softflowd). You can do that in Luci (OpenWRT web), or do it in SSH. As there is not a Luci web interface to softflowd, you may as well SSH into your router as you need to do that to configure softflowd anyway. 

```
ssh root@your.router.ip
opkg update
opkg install softflowd
vi /etc/config/softflowd
```

You want /etc/config/softflowd to look something like this. 'Samplerate' of 100 is going to sample 1 in 100 packets. 'Samplerate' of 1 is going to sample every packet but may make your CPU hurt under load. Depending on your router model and capacity, I recommend setting it low (like 1 or 2) and then stress test the network while monitoring the routers CPU use. Tune it to a point you are not using more than 75% CPU under full load - on a Asus RT-AC86U I found it would run 300+mbps on br-lan with 'samplerate 1' and not even hit 40% use.

Obviously, change 'docker.host.ip.address.goes.here' to the IP of the machine the docker image is running on. 

```
config softflowd
	option enabled        '1'
	option interface      'br-lan'
	option pcap_file      ''
	option timeout        'maxlife=60'
	option max_flows      '8192'
	option host_port      'docker.host.ip.address.goes.here:2055'
	option pid_file       '/var/run/softflowd.pid'
	option control_socket '/var/run/softflowd.ctl'
	option export_version '9'
	option hoplimit       ''
	option tracking_level 'full'
	option track_ipv6     '1'
	option sampling_rate  '1'
```

When you are happy, exit vi ( press : then type wq and press enter ) then you can start softflowd

```
/etc/init.d/softflowd restart
```

## Done

Now just point your browser here:
```
http://docker.host.ip.address.goes.here:3000
```
You now are monitoring your home network with ntopng fed from your Netflow collector via NetFlow v9 packets into netflow2ng.

**And it didnt cost you anything more than some time.**






