_install_pureftpd_depends(){
    _info "Starting to install dependencies packages for Pureftpd..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(pcre-devel openssl-devel zlib-devel)
        for depend in ${yum_depends[@]}
        do
            install_package "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(libpcre3-dev libssl-dev zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            install_package "apt -y install ${depend}"
        done
    fi
    _success "Install dependencies packages for Pureftpd completed..."
}

_install_pureftpd(){
    _install_pureftpd_depends
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${pureftpd_filename} files..."
    download_file "${pureftpd_filename}.tar.gz" ${pureftpd_filename_url}
    tar zxf ${pureftpd_filename}.tar.gz
    cd ${pureftpd_filename}
    pureftpd_configure_args="--prefix=${pureftpd_location} \
    --with-puredb \
    --with-quotas \
    --with-cookie \
    --with-virtualhosts \
    --with-diraliases \
    --with-sysquotas \
    --with-ratios \
    --with-altlog \
    --with-paranoidmsg \
    --with-shadow \
    --with-welcomemsg \
    --with-throttling \
    --with-uploadscript \
    --with-language=english \
    --with-rfc2640 \
    --with-ftpwho \
    --with-tls"
    check_error "./configure ${pureftpd_configure_args}"
    check_error "parallel_make"
    check_error "make install"
    sqlite3 ${install_prefix}/hwslinuxmaster.db <<EOF
PRAGMA foreign_keys = ON;
INSERT INTO hws_ftpserver (path, name, version, port, servertype) VALUES ("${pureftpd_location}", "${pureftpd_filename}", "${pureftpd_version}", ${pureftpd_port}, 1);
UPDATE hws_sysconfig SET value="${pureftpd_filename}" WHERE key="CurrentFtpServer";
EOF
    _info "Config ${pureftpd_filename}"
    _create_pureftpd_config
    _config_pureftpd
    _info "Start ${pureftpd_filename}"
    ${pureftpd_location}/sbin/pure-ftpd  ${pureftpd_location}/etc/pure-ftpd.conf
    _success "Install ${pureftpd_filename} completed..."
}

_create_pureftpd_config(){
    cat > ${pureftpd_location}/etc/pure-ftpd.conf <<EOF
# default 21
Bind 0.0.0.0,${pureftpd_port}

# default yes
ChrootEveryone yes

# default no
BrokenClientsCompatibility no

# default 50
MaxClientsNumber 50

# default yes
Daemonize yes

# default 8
MaxClientsPerIP 10

# default no
VerboseLog no

# default yes
DisplayDotFiles yes

# default no
AnonymousOnly no

# default no
NoAnonymous yes

# default ftp
SyslogFacility ftp

# default yes
DontResolve yes

# default 15
MaxIdleTime 15

# default /etc/pureftpd.pdb
PureDB ${pureftpd_location}/etc/pureftpd.pdb

# default yes
UnixAuthentication yes

# default 10000 8
LimitRecursion 20000 8

# default no
AnonymousCanCreateDirs no

# default 4
MaxLoad 4

# default 30000 50000
PassivePortRange 55000 60000

# default yes
AntiWarez yes

# default 133:022
Umask 133:022

# default 100
MinUID 100

# default no
AllowUserFXP no

# default no
AllowAnonymousFXP no

# default no
ProhibitDotFilesWrite no

# default no
ProhibitDotFilesRead no

# default no
AutoRename no

# default no
AnonymousCantUpload no

# default yes
CreateHomeDir yes

# default /var/run/pure-ftpd.pid
PIDFile ${pureftpd_location}/var/run/pure-ftpd.pid

# default 99
MaxDiskUsage 99

# default yes
CustomerProof yes

# default 1
TLS 1
EOF
}

_config_pureftpd(){
    mkdir -p ${pureftpd_location}/var/run
    mkdir -p /etc/ssl/private
    openssl req -x509 -nodes -subj /C=CN/ST=Sichuan/L=Chengdu/O=HWS-LINUXMASTER/OU=HWS/CN=$(get_ip)/emailAddress=admin@hws.com -days 3560 -newkey rsa:1024 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
    if [ -f '/etc/ssl/private/pure-ftpd.pem' ];then
        chmod 600 /etc/ssl/private/pure-ftpd.pem
    fi
    touch ${pureftpd_location}/etc/pureftpd.passwd
    touch ${pureftpd_location}/etc/pureftpd.pdb
}

install_pureftpd(){
    _install_pureftpd
}
