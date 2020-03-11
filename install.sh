#!/usr/bin/env bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

cur_dir=$(pwd)

include(){
    local include=${1}
    if [[ -s ${cur_dir}/include/${include}.sh ]];then
        . ${cur_dir}/include/${include}.sh
    else
        wget -P include https://d.hws.com/free/hwslinuxmaster/script/include/${include}.sh >/dev/null 2>&1
        if [ "$?" -ne 0 ]; then
            echo "Error: ${cur_dir}/include/${include}.sh not found, shell can not be executed."
            exit 1
        fi
        . ${cur_dir}/include/${include}.sh
    fi
}

install_prefix_setting(){
    while :
    do
        clear
        echo
        echo "+----------------------------------------------------------------------"
        echo "| Hws-LinuxMaster 1.0 FOR CentOS/Ubuntu/Debian"
        echo "+----------------------------------------------------------------------"
        echo "| Copyright © 2004-2099 HWS(https://www.hws.com) All rights reserved."
        echo "+----------------------------------------------------------------------"
        echo "| The Panel URL will be http://SERVER_IP:6588 when installed."
        echo "+----------------------------------------------------------------------"
        echo
        echo "+----------------------------------------------------------------------"
        echo -n "Do you want to install Hws-LinuxMaster to the /usr/local/hwslinuxmaster directory now?(y/n): "
        read user_select
        if [[ "${user_select}" == "y" || "${user_select}" == "Y" ]]; then
            install_prefix=/usr/local/hwslinuxmaster
            break
        elif [[ "${user_select}" == "n" || "${user_select}" == "N" ]]; then
            while :
            do
                echo -n "Input your absolute path(eg: /www): "
                read user_input
                mkdir -p ${user_input}
                if [ "$?" -ne 0 ]; then
                    echo "The directory name you entered is invalid,Please try again."
                    continue
                fi
                install_prefix=${user_input}
                break
            done
            break
        else
            continue
        fi
    done
}

main(){
    clear
    check_ram
    display_os_info
    begin_install
}

install_prefix_setting
include config
include public
include apache
include nginx
include mysql
include php
include pureftpd
load_config
rootness
check_command_exist "sqlite3"
sqlite3 "${install_prefix}/hwslinuxmaster.db" <<EOF
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS hws_webserver (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Path TEXT NOT NULL,
	Name TEXT NOT NULL,
	Version TEXT NOT NULL,
	ServerType INTEGER NOT NULL
	);
CREATE TABLE IF NOT EXISTS hws_dbserver (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Path TEXT NOT NULL,
	Name TEXT NOT NULL,
	Version TEXT NOT NULL,
	Port INTEGER NOT NULL DEFAULT 3306,
	PassWord TEXT,
	ServerType INTEGER NOT NULL
	);
CREATE TABLE IF NOT EXISTS hws_ftpserver (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Path TEXT NOT NULL,
	Name TEXT NOT NULL,
	Version TEXT NOT NULL,
	Port INTEGER NOT NULL DEFAULT 21,
	ServerType INTEGER NOT NULL
	);
CREATE TABLE IF NOT EXISTS hws_cacheserver (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Path TEXT NOT NULL,
	Name TEXT NOT NULL,
	Version TEXT NOT NULL,
	Port INTEGER NOT NULL DEFAULT 6379,
	ServerType INTEGER NOT NULL
	);
CREATE TABLE IF NOT EXISTS hws_php (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Path TEXT NOT NULL,
	Name TEXT NOT NULL,
	Version TEXT NOT NULL
	);
CREATE TABLE IF NOT EXISTS hws_sysconfig (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Key TEXT NOT NULL,
	Value TEXT
	);
CREATE TABLE IF NOT EXISTS hws_admin (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	UserName TEXT NOT NULL,
	PassWord TEXT NOT NULL,
	LastTime TEXT,
	LastIp TEXT
	);
CREATE TABLE IF NOT EXISTS hws_db (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	DbName TEXT NOT NULL,
	DbUser TEXT NOT NULL,
	PassWord TEXT,
	SiteName TEXT,
	FOREIGN KEY (SiteName) REFERENCES hws_host_site(Name) ON DELETE SET NULL ON UPDATE CASCADE
	);
CREATE TABLE IF NOT EXISTS hws_host (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Path TEXT NOT NULL,
	FtpUser TEXT NOT NULL,
	FtpPassWord TEXT NOT NULL,
	FtpStatus INTEGER NOT NULL DEFAULT 1,
	FtpSecType INTEGER NOT NULL DEFAULT 0,
	FtpSecList TEXT,
	DbId INTEGER,
	Comment TEXT,
	Connect INTEGER,
	BandWidth INTEGER,
	SiteNum INTEGER NOT NULL DEFAULT 5,
	SiteId INTEGER,
	FOREIGN KEY (DbId) REFERENCES hws_db(Id) ON DELETE SET NULL ON UPDATE CASCADE,
	FOREIGN KEY (SiteId) REFERENCES hws_host_site(Id) ON DELETE SET NULL ON UPDATE CASCADE
	);
CREATE TABLE IF NOT EXISTS hws_host_site (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	HostId INTEGER NOT NULL,
	Status INTEGER NOT NULL DEFAULT 1,
	Path TEXT NOT NULL,
	Name TEXT NOT NULL,
	SslId INTEGER,
	IndexFile TEXT DEFAULT 'index.php default.php index.html index.htm',
	Code404 TEXT DEFAULT '404.html 404.htm',
	Code301 TEXT,
	ToHttps INTEGER NOT NULL DEFAULT 0,
	PhpVersion INTEGER,
	LogStatus INTEGER NOT NULL DEFAULT 1,
	HtaccessStatus INTEGER NOT NULL DEFAULT 1,
	IpSecType INTEGER NOT NULL DEFAULT 0,
	IpSecList TEXT,
	FOREIGN KEY (HostId) REFERENCES hws_host(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (SslId) REFERENCES hws_ssl(Id) ON DELETE SET NULL ON UPDATE CASCADE,
	FOREIGN KEY (PhpVersion) REFERENCES hws_php(Id) ON DELETE SET NULL ON UPDATE CASCADE
	);
CREATE TABLE IF NOT EXISTS hws_host_site_domain (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	DomainName TEXT NOT NULL,
	Port INTEGER DEFAULT 80,
	SiteId INTEGER,
	FOREIGN KEY (SiteId) REFERENCES hws_host_site(Id) ON DELETE CASCADE ON UPDATE CASCADE
	);
CREATE TABLE IF NOT EXISTS hws_ssl (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	Name TEXT NOT NULL,
	Pem TEXT NOT NULL,
	Key TEXT NOT NULL,
	Chain TEXT,
	Expire TEXT NOT NULL
	);
CREATE TABLE IF NOT EXISTS hws_log (
	Id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	LogTime TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
	Ip TEXT NOT NULL,
	LogType INTEGER NOT NULL,
	Content TEXT NOT NULL,
	User TEXT NOT NULL
	);

CREATE UNIQUE INDEX IF NOT EXISTS hws_webserver_unique_name ON hws_webserver (Name);
CREATE UNIQUE INDEX IF NOT EXISTS hws_dbserver_unique_name ON hws_dbserver (Name);
CREATE UNIQUE INDEX IF NOT EXISTS hws_ftpserver_unique_name ON hws_ftpserver (Name);
CREATE UNIQUE INDEX IF NOT EXISTS hws_cacheserver_unique_name ON hws_cacheserver (Name);
CREATE UNIQUE INDEX IF NOT EXISTS hws_php_unique_name ON hws_php (Name);
CREATE UNIQUE INDEX IF NOT EXISTS hws_sysconfig_unique_name ON hws_sysconfig (Key);
CREATE UNIQUE INDEX IF NOT EXISTS hws_admin_unique_username ON hws_admin (UserName);
CREATE UNIQUE INDEX IF NOT EXISTS hws_db_unique_dbname ON hws_db (DbName);
CREATE UNIQUE INDEX IF NOT EXISTS hws_db_unique_dbuser ON hws_db (DbUser);
CREATE UNIQUE INDEX IF NOT EXISTS hws_host_unique_ftpuser ON hws_host (FtpUser);
CREATE UNIQUE INDEX IF NOT EXISTS hws_host_site_unique_name ON hws_host_site (Name);
CREATE UNIQUE INDEX IF NOT EXISTS hws_host_site_domain_unique_domainname_port ON hws_host_site_domain (DomainName, Port);
CREATE UNIQUE INDEX IF NOT EXISTS hws_ssl_unique_name ON hws_ssl (Name);
CREATE UNIQUE INDEX IF NOT EXISTS hws_ssl_unique_pem ON hws_ssl (Pem);
CREATE UNIQUE INDEX IF NOT EXISTS hws_ssl_unique_key ON hws_ssl (Key);
CREATE INDEX IF NOT EXISTS hws_host_ftpstatus ON hws_host (FtpStatus);
CREATE INDEX IF NOT EXISTS hws_host_dbid ON hws_host (DbId);
CREATE INDEX IF NOT EXISTS hws_host_siteid ON hws_host (SiteId);
CREATE INDEX IF NOT EXISTS hws_host_comment ON hws_host (Comment);
CREATE INDEX IF NOT EXISTS hws_host_site_hostid ON hws_host_site (HostId);
CREATE INDEX IF NOT EXISTS hws_host_site_status ON hws_host_site (Status);
CREATE INDEX IF NOT EXISTS hws_host_site_sslid ON hws_host_site (SslId);
CREATE INDEX IF NOT EXISTS hws_host_site_phpversion ON hws_host_site (PhpVersion);
CREATE INDEX IF NOT EXISTS hws_host_site_domain_port ON hws_host_site_domain (Port);
CREATE INDEX IF NOT EXISTS hws_host_site_domain_siteid ON hws_host_site_domain (SiteId);
CREATE INDEX IF NOT EXISTS hws_log_ip ON hws_log (Ip);
CREATE INDEX IF NOT EXISTS hws_log_user ON hws_log (User);
CREATE INDEX IF NOT EXISTS hws_log_logtime ON hws_log (LogTime);

INSERT INTO hws_sysconfig (key, value) VALUES ("Prefix", "${install_prefix}");
INSERT INTO hws_sysconfig (key, value) VALUES ("WwwRootDir", "${web_root_dir}");
INSERT INTO hws_sysconfig (key, value) VALUES ("OsVersion", "$(get_opsy)");
INSERT INTO hws_sysconfig (key, value) VALUES ("CurrentWebServer", "");
INSERT INTO hws_sysconfig (key, value) VALUES ("CurrentDbServer", "");
INSERT INTO hws_sysconfig (key, value) VALUES ("CurrentFtpServer", "");
INSERT INTO hws_sysconfig (key, value) VALUES ("CurrentCacheServer", "");
EOF

main 2>&1 | tee /tmp/install.log
