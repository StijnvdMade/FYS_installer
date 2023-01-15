# Install packages 
sudo apt install ipset iptables netfilter-persistent ipset-persistent iptables-persistent -y

# Clean the firewall rules
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X


# Create the inset whitelisted
sudo ipset create whitelisting hash:ip


# Start netfilter-persistents
sudo systemctl enable netfilter-persistent
sudo systemctl start netfilter-persistent


# Dropping everything that isn't whitelisted
sudo iptables -t filter -A FORWARD -i wlan0 -m set ! --match-set whitelisting src -j DROP

# Accepting everything that is whitelisted
sudo iptables -t nat -I PREROUTING -i wlan0 -m set --match-set whitelisting src -j ACCEPT 

# Forwarding to the website
sudo iptables -t nat -A PREROUTING -p tcp -m multiport --dport 80,443 -i wlan0 -j DNAT --to-destination 192.168.137.60

# Vervangt de ipadressen met die van de sbc
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save the netfilter
sudo netfilter-persistent save