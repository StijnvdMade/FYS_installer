sudo apt-get install dnsmasq hostapd dhcpd dhcpcd5

sudo systemctl stop dnsmasq
sudo systemctl stop hostapd
sudo systemctl stop systemd-resolved

sudo cat > /etc/dhcpcd.conf << EOF
	denyinterface wlan0
EOF

sudo cat > /etc/network/interfaces << EOF
	Allow-hotplug wlan0
	iface wlan0 inet static
	address 192.168.4.1
	netmask 255.255.255.0
 network 192.168.4.0
 broadcast 192.168.4.255
#wpa-conf /etc/wpa_supplicant.conf
EOF

sudo service dhcpcd restart

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

sudo cat > /etc/dnsmasq.conf << EOF
  interface=wlan0
	bin-interfaces
	server=8.8.8.8
	bogus-priv
	dhcp-range=192.168.4.2,192.168.20,255.255.255.0,24h
EOF

sudo systemctl start dnsmasq

sudo cat > /etc/hostapd/hostapd.conf << EOF
	interface=wlan0
	hw_mode=g
	channel=1-4
	ssid=Fly Corendon
	wpa=0
	wpa_passphrase=YOURPWD
	wpa_key_mgmt=WPA-PSK
	wpa_pairwise=TKIP CCMP
  	rsn_pairwise=CCMP
EOF

sudo cat > /etc/default/hostapd << EOF
  DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

sudo cat > /etc/sysctl.conf << EOF
  net.ipv4.ip_foward=1
EOF

sudo iptables -t nat -A POSTROUTING -o etho0 -j MASQUERADE
sudo iptables -A FROWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FROWARD -i wlan0 -o eth0 -j ACCEPT

sudo sh -c "iptables-save > /etc/ipatables.ipv4.nat"