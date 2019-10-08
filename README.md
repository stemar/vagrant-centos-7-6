# Vagrant box CentOS 7.6 LAMP

Make a Vagrant box with CentOS 7.6 LAMP stack, plus configure it for development.

- Host: Linux or Mac.
- Guest: CentOS 7.6, Apache 2.4, MariaDB 10.3, PHP 7.2, Git 2.18.

## Goals

- Use a clean CentOS 7.6 box available from Bento with 64GB HDD virtual space.
- Leave code and version control files physically outside the VM while virtually accessing them inside the VM.
- Use any GUI tool outside the VM to access data inside the VM.
    - IDEs, browsers, database administration applications, Git clients
- Use `http://localhost:8001` in a browser outside the VM to access Apache inside the VM.
- Use the same SSH keys inside and outside VM.
- Use the same Git config inside and outside VM.
- Have `Vagrantfile` and its provision file be located anywhere on your host machine, independently of your projects location.
- Use `~` as `/home/vagrant` inside the VM for the location of synchronized directories.
    - Disable the default `/vagrant` synchronized to `Vagrantfile`'s location.
- Use Bash for provisioning.
    - Every developer will know Bash; not every developer will know Ansible, Chef and Puppet.
    - You copy/paste the Bash commands if you configured a VirtualBox manually without Vagrant.
- Use MariaDB and Adminer without a password for username `root`.
- Use _repository_ `.repo` files outside the VM to fetch and install updated Git and MariaDB versions inside the VM.
- Use Apache `.conf` files outside the VM to customize the web server configuration inside the VM.

## Prerequisites

### Vagrant and Oracle VM VirtualBox installed

- [VirtualBox 6.0.10](https://www.virtualbox.org/wiki/Downloads)
- [VirtualBox 6.0.10 Extension Pack](https://www.virtualbox.org/wiki/Downloads)
- [VirtualBox Guest Additions](https://www.virtualbox.org/manual/ch04.html#additions-linux)
- [Vagrant 2.2.5](https://www.vagrantup.com/downloads.html)

Look at all VirtualBox downloads [here](https://download.virtualbox.org/virtualbox)

### VirtualBox Guest Additions Vagrant plugin installed

<https://github.com/dotless-de/vagrant-vbguest>

In host terminal:

```bash
vagrant plugin update
vagrant plugin install vagrant-vbguest
```

### SSH keys already set on host machine

In host terminal:

```bash
cat ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

And maybe:

```bash
cat ~/.ssh/authorized_keys
cat ~/.ssh/config
cat ~/.ssh/known_hosts
```

### Git already configured on host machine

In host terminal:

```bash
cat ~/.gitconfig
```

## Start here

In host terminal:

```bash
mkdir -p ~/vm && cd ~/vm
git clone https://github.com/stemar/vagrant-centos-7-6.git centos-7-6
tree -aF --dirsfirst -I ".git" ~/vm
```

```console
/Users/stemar/vm/
└── centos-7-6
    ├── config
    │   ├── MariaDB.repo
    │   ├── WANdisco-git.repo
    │   ├── adminer.conf
    │   ├── adminer.php
    │   ├── localhost.conf
    │   ├── php.ini.htaccess
    │   └── virtualhost.conf
    ├── .gitignore
    ├── LICENSE
    ├── README.md
    ├── Vagrantfile
    └── centos-7-6.sh
```

> You can have more than one vagrant dirtree under the `~/vm` directory.

Vagrant supports the definition of [multiple VMs](https://www.vagrantup.com/docs/multi-machine) inside one `Vagrantfile`,
but if I separate my VMs by LAMP stack in a dirtree, I can run, maintain and troubleshoot them independently.

- I can have a smaller, focused `Vagrantfile` for each VM.
- I can have LAMP-specific `config` files to help the provision file.
- `.vagrant` is created independently within each VM directory.
- I can open separate tabs in my terminal, `cd` into separate VM dirtrees and `vagrant up`/`vagrant halt`
  without having to write the machine name: `vagrant up centos-7-6`/`vagrant halt centos-7-6`
- `vagrant global-status` still works as intended to see all VMs on the host machine.
- I change the HTTP and MySQL ports to avoid collisions and Vagrant errors at provisioning.

## Main files

### Vagrantfile

On line 1, edit the `projects_path` value with your own path name.
Name it the same name to reduce confusion.
Ex.: if the host machine has `~/projects` a.k.a. `/Users/stemar/projects`,
the guest machine will have `~/projects`, a.k.a. `/home/vagrant/projects`.

```ruby
projects_path = "projects"
Vagrant.require_version ">= 2.0.0"
Vagrant.configure("2") do |config|
  config.vm.define "centos-7-6"
  config.vm.box = "bento/centos-7.6" # 64GB HDD
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072" # 3GB RAM
    vb.cpus = 1
  end
  # vagrant@ubuntu-18-04
  config.vm.hostname = "centos-7-6"
  # Synchronize projects and vm directories
  config.vm.synced_folder "~/#{projects_path}", "/home/vagrant/#{projects_path}", owner: "vagrant", group: "vagrant"
  config.vm.synced_folder "~/vm", "/home/vagrant/vm", owner: "vagrant", group: "vagrant"
  # Disable default dir sync
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # Apache: http://localhost:8001
  config.vm.network :forwarded_port, guest: 80, host: 8001 # HTTP
  config.vm.network :forwarded_port, guest: 3306, host: 33061 # MySQL
  # Copy SSH keys and Git config
  config.vm.provision :file, source: "~/.ssh", destination: "$HOME/.ssh"
  config.vm.provision :file, source: "~/.gitconfig", destination: "$HOME/.gitconfig"
  # Provision bash script
  config.vm.provision :shell, path: "centos-7-6.sh"
end
```

#### Forwarded ports

Look at these lines:

```ruby
config.vm.network :forwarded_port, guest: 80, host: 8001    # HTTP
config.vm.network :forwarded_port, guest: 3306, host: 33061 # MySQL
```

I forward the ports to 8001 and 33061 because I already use 8000 and 33060 in another VM.

### Provision file centos-7-6.sh

```bash
VM_CONFIG_PATH=/home/vagrant/vm/centos-7-6/config

echo '==> Setting time zone'

timedatectl set-timezone Canada/Pacific
timedatectl | grep 'Time zone:'

echo '==> Cleaning yum cache'

yum -q -y clean all
rm -rf /var/cache/yum

echo '==> Installing Linux tools'

yum -q -y install nano tree zip unzip whois
echo '
alias ll="ls -lAFh"
' | tee -a /home/vagrant/.bashrc > /dev/null

echo '==> Setting Git 2.18 repository'

cp $VM_CONFIG_PATH/WANdisco-git.repo /etc/yum.repos.d/WANdisco-git.repo
rpm --import http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco

echo '==> Installing Git'

yum -q -y install git

echo '==> Installing Apache'

yum -q -y install httpd mod_ssl openssl 

echo '==> Setting MariaDB 10.3 repository'

cp $VM_CONFIG_PATH/MariaDB.repo /etc/yum.repos.d/MariaDB.repo
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

echo '==> Installing Composer (globally)'

if [ ! -f /usr/local/bin/composer ]; then
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --quiet
fi

echo '==> Installing Adminer'

ADMINER_VERSION=4.7.3
if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer/plugins
    curl -LsS https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php -o /usr/share/adminer/adminer-$ADMINER_VERSION.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/plugin.php -o /usr/share/adminer/plugins/plugin.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/login-password-less.php -o /usr/share/adminer/plugins/login-password-less.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi

echo '==> Configuring Apache'

# Localhost
cp $VM_CONFIG_PATH/localhost.conf /etc/httpd/conf.d/localhost.conf

# VirtualHost(s)
cp $VM_CONFIG_PATH/virtualhost.conf /etc/httpd/conf.d/virtualhost.conf

# Adminer
cp $VM_CONFIG_PATH/adminer.conf /etc/httpd/conf.d/adminer.conf
cp $VM_CONFIG_PATH/adminer.php /usr/share/adminer/adminer.php
ESCAPED_ADMINER_VERSION=`echo $ADMINER_VERSION | sed 's/\./\\\\./g'`
sed -i 's/ADMINER_VERSION/'$ESCAPED_ADMINER_VERSION'/' /usr/share/adminer/adminer.php

# PHP.ini
cp $VM_CONFIG_PATH/php.ini.htaccess /var/www/.htaccess

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
```

## Config files

### Repository files

#### MariaDB.repo

<http://downloads.mariadb.org/mariadb/repositories>

```
# http://downloads.mariadb.org/mariadb/repositories
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

#### WANdisco-git.repo

<https://linuxize.com/post/how-to-install-git-on-centos-7>

```
# https://linuxize.com/post/how-to-install-git-on-centos-7
[wandisco-git]
name=Wandisco GIT Repository
baseurl=http://opensource.wandisco.com/centos/7/git/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco
```

### Apache .conf files

#### localhost.conf

I override some `httpd.conf` lines without editing `httpd.conf` itself.

```apache
# Override /etc/httpd/conf/httpd.conf
# User apache
# Group apache
User vagrant
Group vagrant
EnableSendfile Off

# Set default http://localhost:8001
ServerName localhost

# Allow .htaccess for all sites
<Directory /var/www>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
```

#### virtualhost.conf

```apache
# ~/projects
# └── example.com
#     ├── app
#     │   └── ...
#     └── www
#         └── {public files}

# http://example.com.localhost:8001 => VirtualDocumentRoot
<VirtualHost *:80>
    UseCanonicalName Off
    ServerAlias *.localhost
    VirtualDocumentRoot /home/vagrant/projects/%-2+/www
    <Directory /home/vagrant/projects>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    # /var/log/httpd
    ErrorLog /etc/httpd/logs/error_log/example.com-error.log
    CustomLog /etc/httpd/logs/access_log/example.com-access.log combined
</VirtualHost>
```

I use [VirtualDocumentRoot](https://httpd.apache.org/docs/2.4/mod/mod_vhost_alias.html)
to access all my domain dirtrees from `~/projects` with `http://example.com.localhost:8001`

```console
~/projects
└── example.com
    ├── app
    │   └── ...
    └── www
        └── {public files}
```

You can create `<VirtualHost *:80>` entries the regular way too for example:

```apache
# http://example.com.localhost:8001 => DocumentRoot
<VirtualHost *:80>
    ServerName example.com.localhost
    DocumentRoot /var/www/example.com/www
    <Directory /var/www/example.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    # /var/log/httpd
    ErrorLog /etc/httpd/logs/error_log/example.com-error.log
    CustomLog /etc/httpd/logs/access_log/example.com-access.log combined
</VirtualHost>
```

### Adminer files

#### adminer.conf

```apache
# http://localhost:8001/adminer.php
Alias /adminer.php /usr/share/adminer/adminer.php
Alias /adminer.css /usr/share/adminer/adminer.css
<Directory /usr/share/adminer>
    Options FollowSymlinks
    AllowOverride All
    Require all granted
    Allow from 127.0.0.1
</Directory>
```

#### adminer.php

We want `root` with no password in our VM to avoid writing a password zillions of time we access MySQL inside the VM.
Of course, you would have a `root` password on a server but this is a virtual machine hosted locally.

As of version 4.6.3, Adminer is blocking any user with no password.
To allow `root` with no password, we have to create a custom `adminer.php` file.

```php
<?php
// https://www.adminer.org/en/plugins/#use
function adminer_object() {
    include_once "./plugins/plugin.php";
    include_once "./plugins/login-password-less.php";
    class AdminerCustomPlugin extends AdminerPlugin {
        function login($login, $password) {
            return TRUE;
        }
    }
    return new AdminerCustomPlugin(array(
        new AdminerLoginPasswordLess(""),
    ));
}
include "./adminer-ADMINER_VERSION.php";
```

`ADMINER_VERSION` is there to be substituted by a `sed` command in the `centos-7-6.sh` provision script.

### php.ini file

We don't want to edit `php.ini` directly but we want to add a development-related custom set of `php.ini` overrides.

> PHP doesn't allow the loading of a custom `php.ini` file to override its own settings
> ([except when PHP is installed as CGI](http://php.net/manual/en/configuration.file.per-user.php)
> which is not the case here).

We have to do it with `.htaccess` at the `/var/www` level; see [PHP configuration settings](http://php.net/manual/en/configuration.changes.php)

#### php.ini.htaccess

```apache
# http://php.net/manual/en/configuration.changes.php
# http://php.net/manual/en/ini.list.php

# Development environment error settings
php_flag display_startup_errors on
php_flag display_errors on
php_flag html_errors on
php_flag ignore_repeated_errors off
php_flag ignore_repeated_source off
php_flag report_memleaks on
php_flag track_errors on
php_value docref_root 0
php_value docref_ext 0
php_flag log_errors off
php_value log_errors_max_len 0
# E_ALL
# php_value error_reporting -1
# E_ALL & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT
php_value error_reporting 22519

# Application settings
php_value upload_max_filesize 512M
php_value post_max_size 512M
php_value memory_limit 512M
```

## Provision centos-7-6

In host terminal:

```bash
cd ~/vm/centos-7-6
vagrant up --provision
```

!! You might see many red line warnings from `yum` during provisioning but let the script finish, they are not fatal errors.

### If something goes wrong

In host terminal:

```bash
vagrant halt -f
vagrant destroy -f
vagrant up --provision
```


## Log in centos-7-6

In host terminal:

```bash
vagrant ssh
```

### Prompt inside centos-7-6

In guest terminal:

```console
[vagrant@centos-7-6 ~]$
```

## Checks

### Test `ll` alias and show .bashrc

In guest terminal:

```bash
ll
...
cat ~/.bashrc
```

### Check MariaDB root no password

In guest terminal:

```bash
mysql -u root
MariaDB [(none)]> SHOW DATABASES; quit;
```

## Check Apache

In guest terminal:

```bash
cat /etc/hosts
cat /etc/httpd/conf/httpd.conf
ll /etc/httpd/conf.d
cat /etc/httpd/conf.d/README
cat /etc/httpd/conf.d/welcome.conf
cat /etc/httpd/conf.d/php.conf
cat /etc/httpd/conf.d/localhost.conf
cat /etc/httpd/conf.d/virtualhost.conf
cat /etc/httpd/conf.d/adminer.conf
httpd -D DUMP_VHOSTS
apachectl configtest
curl -I localhost
```

Result:

```http
HTTP/1.1 404 Not Found
...
```

#### Why 404 Not Found?

In `/etc/httpd/conf.d/welcome.conf`, it shows that when there is no `/var/www/html/index.html`, 
HTTP code `403 Forbidden` is returned with the content of `/usr/share/httpd/noindex/index.html`, the ["Testing 123.." page](https://www.atlantic.net/community/wp-content/uploads/2015/06/anet-install-lamp-centos-7-01.png).

However, we defined `VirtualHost`s in `virtualhost.conf` without defining a page at the root of localhost, so we get HTTP code `404 Not Found`.

### In host browser

```input
http://example.com.localhost:8001
```

You see the `example.com` home page.

## Check Adminer

### In guest terminal

```bash
curl -I localhost/adminer.php
```

Result:

```http
HTTP/1.1 200 OK
...
```

### In host browser

```input
http://localhost:8001/adminer.php
```

- Username: `root`
- Password: leave empty

---

## References

- Vagrant: <https://www.vagrantup.com>
- Vagrant troubleshooting: <https://www.mediawiki.org/wiki/MediaWiki-Vagrant#Troubleshooting_startup>
- Oracle VirtualBox: <https://www.virtualbox.org/wiki/Downloads>
- Oracle VirtualBox Guest Additions: <https://www.virtualbox.org/manual/ch04.html>
- CentOS: <https://centos.org>
- Bento box: <https://app.vagrantup.com/bento/boxes/centos-7.6>
- Bento GitHub: <https://github.com/chef/bento>
- <https://linuxize.com/post/how-to-set-up-apache-virtual-hosts-on-centos-7>
