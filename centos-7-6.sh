echo '==> Setting time zone'

timedatectl set-timezone Canada/Pacific
timedatectl | grep 'Time zone:'

echo '==> Cleaning yum cache'

yum -q -y clean all
rm -rf /var/cache/yum

echo '==> Installing Linux tools'

yum -q -y install nano tree zip unzip whois
cp $CONFIG_PATH/bashrc /home/vagrant/.bashrc
chown vagrant:vagrant /home/vagrant/.bashrc

echo '==> Setting Git 2.18 repository'

cp $CONFIG_PATH/WANdisco-git.repo /etc/yum.repos.d/WANdisco-git.repo
rpm --import http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco

echo '==> Installing Git'

yum -q -y install git

echo '==> Installing Apache'

yum -q -y install httpd mod_ssl openssl 

echo '==> Setting MariaDB 10.3 repository'

cp $CONFIG_PATH/MariaDB.repo /etc/yum.repos.d/MariaDB.repo
rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB

echo '==> Installing MariaDB'

yum -q -y install MariaDB MariaDB-server

echo '==> Setting PHP 7.2 repository'

yum -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -q -y install epel-release
yum -q -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -q -y install yum-utils
yum-config-manager -q -y --enable remi-php72 > /dev/null
yum -q -y update

echo '==> Installing PHP'

yum -q -y install php php-common \
    php-bcmath php-devel php-gd php-imap php-intl php-ldap \
    php-mbstring php-pecl-mcrypt php-mysqlnd php-opcache php-pdo php-pear \
    php-pecl-xdebug php-pspell php-soap php-tidy php-xml php-xmlrpc

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer/plugins
    curl -LsS https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php -o /usr/share/adminer/adminer-$ADMINER_VERSION.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/plugin.php -o /usr/share/adminer/plugins/plugin.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/login-password-less.php -o /usr/share/adminer/plugins/login-password-less.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi

echo '==> Configuring Apache'

# Log file permissions
usermod vagrant -G apache
chown -R root:apache /var/log/httpd

# Localhost
cp $CONFIG_PATH/localhost.conf /etc/httpd/conf.d/localhost.conf

# VirtualHost(s)
cp $CONFIG_PATH/virtualhost.conf /etc/httpd/conf.d/virtualhost.conf
sed -i 's#PROJECTS_DIR#'$PROJECTS_DIR'#' /etc/httpd/conf.d/virtualhost.conf
sed -i 's#PORT_80#'$PORT_80'#' /etc/httpd/conf.d/virtualhost.conf

# Adminer
cp $CONFIG_PATH/adminer.conf /etc/httpd/conf.d/adminer.conf
sed -i 's#PORT_80#'$PORT_80'#' /etc/httpd/conf.d/adminer.conf
cp $CONFIG_PATH/adminer.php /usr/share/adminer/adminer.php
ESCAPED_ADMINER_VERSION=`echo $ADMINER_VERSION | sed 's/\./\\\\./g'`
sed -i 's#ADMINER_VERSION#'$ESCAPED_ADMINER_VERSION'#' /usr/share/adminer/adminer.php

# PHP.ini
cp $CONFIG_PATH/php.ini.htaccess /var/www/.htaccess

echo '==> Starting Apache'

apachectl configtest
systemctl start httpd.service
systemctl enable httpd.service

echo '==> Starting MariaDB'

systemctl start mariadb.service
systemctl enable mariadb.service
mysqladmin -u root password ""

echo '==> Versions:'

cat /etc/redhat-release
echo $(curl --version | head -n1)
echo $(git --version)
echo $(httpd -V | head -n1)
echo $(mysql -V)
echo $(php -v | head -n1)
echo Adminer $ADMINER_VERSION
