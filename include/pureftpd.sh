_install_pureftpd_depends(){
    _info "Starting to install dependencies packages for Pureftpd..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(openssl-devel zlib-devel)
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(libssl-dev zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt -y install ${depend}"
        done
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    mkdir -p ${pureftpd_location}
    _success "Install dependencies packages for Pureftpd completed..."
}

_start_pureftpd() {
    CheckError "${pureftpd_location}/sbin/pure-ftpd ${pureftpd_location}/etc/pure-ftpd.conf"
    DownloadUrl "/etc/init.d/pureftpd" "${download_sysv_url}/pureftpd"
    sed -i "s|^prefix={pureftpd_location}$|prefix=${pureftpd_location}|i" /etc/init.d/pureftpd
    CheckError "chmod +x /etc/init.d/pureftpd"
    chkconfig --add pureftpd > /dev/null 2>&1
    update-rc.d -f pureftpd defaults > /dev/null 2>&1
    CheckError "service pureftpd restart"
}

install_pureftpd(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: pureftpd_location [default_port]"
        exit 1
    fi
    pureftpd_location=${1}

    # 如果存在第二个参数
    if [ $# -ge 2 ]; then
        ftp_port=${2}
    fi

    CheckError "rm -fr ${pureftpd_location}"
    _install_pureftpd_depends
    cd /tmp
    _info "Downloading and Extracting ${pureftpd_filename} files..."
    DownloadFile "${pureftpd_filename}.tar.gz" ${pureftpd_download_url}
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
    --with-ftpwho \
    --with-tls"
    CheckError "./configure ${pureftpd_configure_args}"
    CheckError "parallel_make"
    CheckError "make install"
    _info "Config ${pureftpd_filename}"
    _create_pureftpd_config
    _config_pureftpd
    mkdir -p /etc/ssl/private
    openssl req -x509 -nodes -subj /C=CN/ST=Sichuan/L=Chengdu/O=HWS-LINUXMASTER/OU=HWS/CN=$(GetIp)/emailAddress=admin@hws.com -days 3560 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
    if [ -f '/etc/ssl/private/pure-ftpd.pem' ];then
        chmod 600 /etc/ssl/private/pure-ftpd.pem
    fi

    _start_pureftpd
    _success "Install ${pureftpd_filename} completed..."
    rm -fr /tmp/${pureftpd_filename}
}

_create_pureftpd_config(){
    cat > ${pureftpd_location}/etc/pure-ftpd.conf <<EOF
# default 21
Bind 0.0.0.0,${ftp_port}

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
PassivePortRange 55000 56000

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
CreateHomeDir no

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
    touch ${pureftpd_location}/etc/pureftpd.passwd
    touch ${pureftpd_location}/etc/pureftpd.pdb
}
