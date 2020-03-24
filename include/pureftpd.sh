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
    _success "Install dependencies packages for Pureftpd completed..."
}

install_pureftpd(){
    killall pure-ftpd > /dev/null 2>&1
    mkdir -p ${backup_dir}
    if [ -d "${pureftpd_location}" ]; then 
        if [ -d "${backup_dir}/${pureftpd_install_path_name}" ]; then
            mv ${backup_dir}/${pureftpd_install_path_name} ${backup_dir}/${pureftpd_install_path_name}-$(date +%Y-%m-%d_%H:%M:%S).bak
        fi
        mv ${pureftpd_location} ${backup_dir}
    fi
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
    if [ -d "${backup_dir}/${pureftpd_install_path_name}" ]; then
        if [ -d "${backup_dir}/${pureftpd_install_path_name}/etc" ]; then
            rm -fr ${pureftpd_location}/etc
            cp -fr ${backup_dir}/${pureftpd_install_path_name}/etc ${pureftpd_location}
        fi
    else
        _info "Config ${pureftpd_filename}"
        _create_pureftpd_config
        _config_pureftpd
    fi
    mkdir -p /etc/ssl/private
    openssl req -x509 -nodes -subj /C=CN/ST=Sichuan/L=Chengdu/O=HWS-LINUXMASTER/OU=HWS/CN=$(GetIp)/emailAddress=admin@hws.com -days 3560 -newkey rsa:1024 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
    if [ -f '/etc/ssl/private/pure-ftpd.pem' ];then
        chmod 600 /etc/ssl/private/pure-ftpd.pem
    fi
    _info "Start ${pureftpd_filename}"
    ${pureftpd_location}/sbin/pure-ftpd  ${pureftpd_location}/etc/pure-ftpd.conf > /dev/null 2>&1
    _success "Install ${pureftpd_filename} completed..."
    cat >> ${prefix}/install.result <<EOF
Install Time: $(date +%Y-%m-%d_%H:%M:%S)
Pureftpd Install Path:${pureftpd_location}

EOF
    rm -fr /tmp/${pureftpd_filename}
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
