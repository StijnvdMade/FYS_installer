sudo apt-get update

sudo apt-get install dnsmasq hostapd dhcpd dhcpcd5

sudo systemctl stop dnsmasq
sudo systemctl stop hostapd
sudo systemctl stop systemd-resolved

sudo cat > /etc/dhcpcd.conf << EOF
denyinterface wlan0
static ip_address=192.168.137.60

interface wlan0
static ip_address=192.168.2.3/24
denyinterfaces eth0
denyinterfaces wlan0
EOF

sudo cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address 192.168.137.60
netmask 255.255.255.0
gateway 192.168.137.1
dns-nameservers 8.8.8.8
dns-search google.com

auto wlan0
EOF

sudo service dhcpcd restart

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

sudo cat > /etc/dnsmasq.conf << EOF
server=8.8.8.8
dhcp-option=option:router,192.168.2.3
dhcp-option=option:dns-server,192.168.2.3
interface=wlan0
    dhcp-range=192.168.2.11,192.168.2.200,255.255.255.0,24h

address=/corendon-login.nl/192.168.2.3
EOF

sudo systemctl start dnsmasq

sudo cat > /etc/hostapd/hostapd.conf << EOF
interface=wlan0
# driver=brcmfmac
hw_mode=g
channel=1
ssid=Fly Corendon
wpa=0
#wpa_passphrase=YOURPWD
#wpa_key_mgmt=WPA-PSK
#wpa_pairwise=TKIP CCMP
#rsn_pairwise=CCMP
EOF

sudo cat > /etc/default/hostapd <<EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

sudo cat > /etc/sysctl.conf << EOF
net.ipv4.ip_foward=1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

sudo iptables -t nat -A POSTROUTING -o etho0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

sudo sh -c "iptables-save > /etc/ipatables.ipv4.nat"
