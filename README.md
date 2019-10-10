# Vagrant box CentOS 7.6 LAMP

Make a Vagrant box with CentOS 7.6 LAMP stack, plus configure it for development.

- Host: Linux or Mac.
- Guest: CentOS 7.6, Apache 2.4, MariaDB 10.3, PHP 7.2, Git 2.18.

## Summary

In host terminal:

```bash
mkdir -p ~/vm && cd ~/vm
git clone https://github.com/stemar/vagrant-centos-7-6.git centos-7-6
cd ~/vm/centos-7-6
PROJECTS_PATH="projects" vagrant up --provision
vagrant ssh
```

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
    - You could copy/paste the Bash commands if you configured a VirtualBox manually without Vagrant.
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
```

> You can have more than one vagrant dirtree under the `~/vm` directory.  
> Ex.: `git clone https://github.com/stemar/vagrant-ubuntu-18-04.git ubuntu-18-04`

### Separate VMs dirtree

Vagrant supports the definition of [multiple VMs](https://www.vagrantup.com/docs/multi-machine) inside one `Vagrantfile`,
but if I separate my VMs by LAMP stack in a dirtree, I can run, maintain and troubleshoot them independently.

- I can have a smaller, focused `Vagrantfile` for each VM.
- I can have LAMP-specific `config` files to help the provision file.
- `.vagrant` is created independently within each VM directory.
- I can open separate tabs in my terminal, `cd` into separate VM dirtrees and `vagrant up`/`vagrant halt`
  without having to write the machine name: `vagrant up centos-7-6`/`vagrant halt centos-7-6`
- `vagrant global-status` still works as intended to see all VMs on the host machine.
- I change the HTTP and MySQL ports in `Vagrantfile` to avoid collisions and Vagrant errors at provisioning.

### adminer.php

We want `root` with no password in our VM to avoid writing a password zillions of time we access MySQL inside the VM.
Of course, you would have a `root` password on a server but this is a virtual machine hosted locally.

As of version 4.6.3, Adminer is blocking any user with no password.
To allow `root` with no password, `config/adminer.php` is created.

`ADMINER_VERSION` will be substituted by a `sed` command in the `centos-7-6.sh` provision script.

### php.ini file

We don't want to edit `php.ini` directly but we want to add a development-related custom set of `php.ini` overrides.

> PHP doesn't allow the loading of a custom `php.ini` file to override its own settings
> ([except when PHP is installed as CGI](http://php.net/manual/en/configuration.file.per-user.php)
> which is not the case here).

We have to do it with `.htaccess` at the `/var/www` level; see [PHP configuration settings](http://php.net/manual/en/configuration.changes.php)

## Provision centos-7-6

Edit the environment variable `PROJECTS_PATH` value with your own path name under your home directory.
Name it the same name to reduce confusion.
Ex.: if the host machine has `~/projects` a.k.a. `/Users/stemar/projects`,
the guest machine will have `~/projects`, a.k.a. `/home/vagrant/projects`.

In host terminal:

```bash
cd ~/vm/centos-7-6
PROJECTS_PATH="projects" vagrant up --provision
```

> You might see many red line warnings from `yum` during provisioning but let the script finish, most of them are not fatal errors.

### If you get this error after VirtualBox Guest Additions plugin changed versions

```
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:

mount -t vboxsf -o uid=1000,gid=1000 home_vagrant_vm /home/vagrant/vm

The error output from the command was:

/sbin/mount.vboxsf: mounting failed with the error: No such device
```

Halt the box and redo up

```bash
vagrant halt
PROJECTS_PATH="projects" vagrant up --provision
```

### If something goes wrong

In host terminal:

```bash
vagrant halt -f
OR
vagrant destroy -f
AND
PROJECTS_PATH="projects" vagrant up --provision
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

### Check Apache

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

In host browser:

```input
http://localhost:8001
```

#### Why 404 Not Found?

In `/etc/httpd/conf.d/welcome.conf`, it shows that when there is no `/var/www/html/index.html`, 
HTTP code `403 Forbidden` is returned with the content of `/usr/share/httpd/noindex/index.html`, 
the ["Testing 123.." page](https://www.atlantic.net/community/wp-content/uploads/2015/06/anet-install-lamp-centos-7-01.png).

However, we defined `VirtualHost`s in `virtualhost.conf` without defining a page at the root of localhost, 
so we get HTTP code `404 Not Found`.

### Check your domain

In host browser: (replace `example.com` with your domain)

```input
http://example.com.localhost:8001
```

You see the home page.

### Check Adminer

In guest terminal:

```bash
curl -I localhost/adminer.php
```

Result:

```http
HTTP/1.1 200 OK
...
```

In host browser:

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
