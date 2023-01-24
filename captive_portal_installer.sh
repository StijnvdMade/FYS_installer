# Install packages
sudo apt install apache2 libapache2-mod-wsgi-py3 python3-pip git mysql-server python3-virtualenv libmysqlclient-dev nodejs npm openssl python3-venv -y

# Enable apache2 wsgi module
sudo a2enmod wsgi

# Start mysql service
sudo systemctl start mysql.service

# Get git corendon-captive-portal repository and move to correct directory
sudo git clone https://github.com/StijnvdMade/corendon_raspi.git /var/www/

# Create virtual environment
sudo python3 -m venv /var/www/corendon_raspi/venv
# Activate virtual environment
. /var/www/corendon_raspi/venv/bin/activate
# Installing flask module in venv
sudo pip3 install -r /var/www/html/captive-portal/corendon-captive-portal/requirements.txt

# Get SSL certificate
sudo a2enmod ssl
openssl req -x509 -newkey rsa:4096 -nodes -keyout corendon-login.nl.key -out corendon-login.nl.cert -sha256 -days 1000 -subj '/CN=corendon-login.nl'

# Apache2 config for wsgi and flask site
sudo cat > /etc/apache2/sites-available/flask.conf << EOF
<VirtualHost *:80>
    ServerName corendon-login.nl
    ServerAlias www.corendon-login.nl


    Redirect permanent / https://corendon-login.nl/
</VirtualHost>

<VirtualHost *:443>
    ServerName corendon-login.nl
    ServerAlias www.corendon-login.nl
    RedirectMatch 302 /generate_204 /
    RedirectMatch 302 /hotspot-detect.html /

    Protocols h2 http/1.1

    WSGIDaemonProcess FlaskApp user=www-data group=www-data threads=5
    WSGIScriptAlias / /var/www/corendon_raspi/flaskapp.wsgi

    SSLCertificateFile "/etc/apache2/ssl/corendon-login.nl.crt"
    SSLCertificateKeyFile "/etc/apache2/ssl/corendon-login.nl.key"

    <Directory /var/www/corendon_raspi>
        WSGIProcessGroup FlaskApp
        WSGIApplicationGroup %{GLOBAL}
        Order deny,allow
        Allow from all
    </Directory>
</VirtualHost>
EOF

# Disabling default apache2 site and enabling flask site
sudo a2dissite 000-default
sudo a2ensite flask

# Giving www-data rights to run ipset
sudo cat > /etc/sudoers.d/www-data << EOF
www-data ALL=NOPASSWD: /usr/sbin/ipset
EOF

# Setup database
sudo flask --app /var/www/corendon_raspi/FlaskApp init-db

# Reload apache2 to load the right config
sudo systemctl reload apache2