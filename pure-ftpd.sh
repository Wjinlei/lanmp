#!/usr/bin/env bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
cur_dir=$(pwd)

include(){
    local include=${1}
    if [[ -s ${cur_dir}/tmps/include/${include}.sh ]];then
        . ${cur_dir}/tmps/include/${include}.sh
    else
        wget --no-check-certificate -cv -t3 -T60 -P tmps/include http://d.hws.com/linux/master/script/include/${include}.sh >/dev/null 2>&1
        if [ "$?" -ne 0 ]; then
            echo "Error: ${cur_dir}/tmps/include/${include}.sh not found, shell can not be executed."
            exit 1
        fi
        . ${cur_dir}/tmps/include/${include}.sh
    fi
}

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
            InstallPack "apt-get -y install ${depend}"
        done
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    mkdir -p ${pureftpd_location} >/dev/null 2>&1
    _success "Install dependencies packages for Pureftpd completed..."
}

_create_sysv_script(){
    cat > /etc/init.d/pure-ftpd << 'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: pure-ftpd service script

### BEGIN INIT INFO
# Provides:          pure-ftpd
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: pure-ftpd
# Description:       pure-ftpd service script
### END INIT INFO

prefix={pureftpd_location}

NAME=pure-ftpd
BIN=$prefix/sbin/$NAME
PID_FILE=$prefix/var/run/$NAME.pid
CONFIG_FILE=$prefix/etc/$NAME.conf

wait_for_pid () {
    try=0
    while test $try -lt 35 ; do
        case "$1" in
            'created')
            if [ -f "$2" ] ; then
                try=''
                break
            fi
            ;;
            'removed')
            if [ ! -f "$2" ] ; then
                try=''
                break
            fi
            ;;
        esac
        echo -n .
        try=`expr $try + 1`
        sleep 1
    done
}

start()
{
    echo -n "Starting $NAME..."
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid $mPID) already running."
            exit 1
        fi
    fi
    $BIN $CONFIG_FILE
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    fi
    wait_for_pid created $PID_FILE
    if [ -n "$try" ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

stop()
{
    echo -n "Stoping $NAME... "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" = '' ];then
            echo "$NAME is not running."
            exit 1
        fi
    else
        echo "PID file found, $NAME is not running ?"
        exit 1
    fi
    kill -QUIT `cat $PID_FILE`
    wait_for_pid removed $PID_FILE
    if [ -n "$try" ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

restart(){
    $0 stop
    $0 start
}

reload() {
    echo -n "Reload service $NAME... "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            kill -USR2 `cat $PID_FILE`
            echo " done"
        else
            echo "$NAME is not running, can't reload."
            exit 1
        fi
    else
        echo "$NAME is not running, can't reload."
        exit 1
    fi
}

status(){
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid $mPID) is running."
            exit 0
        else
            echo "$NAME already stopped."
            exit 1
        fi
    else
        echo "$NAME already stopped."
        exit 1
    fi
}

force-stop() {
    echo -n "force-stop $NAME "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" = '' ];then
            echo "$NAME is not running."
            exit 1
        fi
    else
        echo "PID file found, $NAME is not running ?"
        exit 1
    fi
    kill -TERM `cat $PID_FILE`
    wait_for_pid removed $PID_FILE
    if [ -n "$try" ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    reload)
        reload
        ;;
    force-stop)
        force-stop
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status|force-stop}"
esac
EOF
    sed -i "s|^prefix={pureftpd_location}$|prefix=${pureftpd_location}|g" /etc/init.d/pure-ftpd
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

install_pure-ftpd(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: pureftpd_location [port]"
        exit 1
    fi
    pureftpd_location=${1}

    if [ $# -lt 2 ]; then
        ftp_port=21
    else
        ftp_port=${2}
    fi

    _install_pureftpd_depends

    CheckError "rm -fr ${pureftpd_location}"
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
    # Config
    _info "Config ${pureftpd_filename}"
    _create_pureftpd_config
    mkdir -p ${pureftpd_location}/var/run
    touch ${pureftpd_location}/etc/pureftpd.passwd
    touch ${pureftpd_location}/etc/pureftpd.pdb
    mkdir -p /etc/ssl/private
    openssl rand -writerand ~/.rnd
    openssl req -x509 -nodes -subj /C=CN/ST=Sichuan/L=Chengdu/O=HWS-LINUXMASTER/OU=HWS/CN=127.0.0.1/emailAddress=admin@hws.com -days 3560 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
    if [ -f '/etc/ssl/private/pure-ftpd.pem' ];then
        chmod 600 /etc/ssl/private/pure-ftpd.pem
    fi
    # Start
    _create_sysv_script
    chmod +x /etc/init.d/pure-ftpd
    update-rc.d -f pure-ftpd defaults > /dev/null 2>&1
    chkconfig --add pure-ftpd > /dev/null 2>&1
    /etc/init.d/pure-ftpd start
    # Clean
    rm -fr /tmp/${pureftpd_filename}
    _success "Install ${pureftpd_filename} completed..."
}

rpminstall_pure-ftpd(){
    rpm_package_name="pure-ftpd-1.0.49-1.el7.x86_64.rpm"
    _install_pureftpd_depends
    DownloadUrl ${rpm_package_name} ${download_root_url}/rpms/${rpm_package_name}
    CheckError "rpm -ivh ${rpm_package_name} --force --nodeps"
}

debinstall_pure-ftpd(){
    deb_package_name="pureftpd-1.0.49-linux-amd64.deb"
    _install_pureftpd_depends
    DownloadUrl ${deb_package_name} ${download_root_url}/debs/${deb_package_name}
    CheckError "dpkg --force-depends -i ${deb_package_name}"
}

main() {
    case "$1" in
        -h|--help)
            printf "Usage: $0 Options prefix [port]
Options:
-h, --help                      Print this help text and exit
-sc, --sc-install               Source code make install
-pm, --pm-install               Package manager install
"
            ;;
        -sc|--sc-install)
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
            install_pure-ftpd ${2} ${3}
            ;;
        -pm|--pm-install)
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
            if [ ${PM} == "yum" ]; then
                rpminstall_pure-ftpd
            else
                debinstall_pure-ftpd
            fi
            ;;
        *)
            install_pure-ftpd ${1} ${2}
            ;;
    esac
}

echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
