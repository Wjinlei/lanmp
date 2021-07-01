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

_install_redis_depends(){
    _info "Starting to install dependencies packages for redis..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(centos-release-scl devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils)
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
        source /opt/rh/devtoolset-9/enable >/dev/null 2>&1
    fi
    mkdir -p ${redis_location}
    _success "Install dependencies packages for redis completed..."
}

_create_sysv_script(){
    cat > /etc/init.d/redis << 'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: redis service script

### BEGIN INIT INFO
# Provides:          redis
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: redis
# Description:       redis service script
### END INIT INFO

prefix={redis_location}

NAME=redis-server
BIN=$prefix/bin/$NAME
PID_FILE=$prefix/var/run/redis.pid
CONFIG_FILE=$prefix/etc/redis.conf

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
    kill -TERM `cat $PID_FILE`
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
    *)
        echo "Usage: $0 {start|stop|restart|status|reload}"
esac
EOF
    sed -i "s|^prefix={redis_location}$|prefix=${redis_location}|g" /etc/init.d/redis
}

install_redis609(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: redis_location [default_port]"
        exit 1
    fi
    redis_location=${1}

    if [ $# -lt 2 ]; then
        redis_port=6379
    else
        redis_port=${2}
    fi

    _install_redis_depends

    mkdir -p ${redis_location}
    CheckError "rm -fr ${redis_location}"
    local tram=$( free -m | awk '/Mem/ {print $2}' )
    local swap=$( free -m | awk '/Swap/ {print $2}' )
    local Mem=$(expr $tram + $swap)
    cd /tmp
    _info "redis-server install start..."
    DownloadFile "${redis609_filename}.tar.gz" "${redis609_download_url}"
    rm -fr ${redis609_filename}
    tar zxf ${redis609_filename}.tar.gz
    cd ${redis609_filename}
    ! Is64bit && sed -i '1i\CFLAGS= -march=i686' src/Makefile && sed -i 's@^OPT=.*@OPT=-O2 -march=i686@' src/.make-settings
    CheckError "make"
    if [ -f "src/redis-server" ]; then
        mkdir -p ${redis_location}/{bin,etc,var}
        mkdir -p ${redis_location}/var/{log,run}
        cp src/redis-benchmark ${redis_location}/bin
        cp src/redis-check-aof ${redis_location}/bin
        cp src/redis-check-rdb ${redis_location}/bin
        cp src/redis-cli ${redis_location}/bin
        cp src/redis-sentinel ${redis_location}/bin
        cp src/redis-server ${redis_location}/bin
        # Config
        _info "Config ${redis609_filename}"
        cp redis.conf ${redis_location}/etc/
        sed -i "s@pidfile.*@pidfile ${redis_location}/var/run/redis.pid@" ${redis_location}/etc/redis.conf
        sed -i "s@logfile.*@logfile ${redis_location}/var/log/redis.log@" ${redis_location}/etc/redis.conf
        sed -i "s@^dir.*@dir ${redis_location}/var@" ${redis_location}/etc/redis.conf
        sed -i 's@daemonize no@daemonize yes@' ${redis_location}/etc/redis.conf
        sed -i "s@port 6379@port ${redis_port}@" ${redis_location}/etc/redis.conf
        sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_location}/etc/redis.conf
        [ -z "$(grep ^maxmemory ${redis_location}/etc/redis.conf)" ] && sed -i "s@maxmemory <bytes>@maxmemory <bytes>\nmaxmemory $(expr ${Mem} / 8)000000@" ${redis_location}/etc/redis.conf
        # Start
        _create_sysv_script
        chmod +x /etc/init.d/redis
        update-rc.d -f redis defaults > /dev/null 2>&1
        chkconfig --add redis > /dev/null 2>&1
        /etc/init.d/redis start
        # Clean
        rm -fr ${redis609_filename}
        _success "redis-server install completed!"
    else
        _warn "redis-server install failed."
    fi
}

rpminstall_redis609(){
    rpm_package_name="redis-6.0.9-1.el7.x86_64.rpm"
    _install_redis_depends
    DownloadUrl ${rpm_package_name} ${download_root_url}/rpms/${rpm_package_name}
    CheckError "rpm -ivh ${rpm_package_name}"
}

debinstall_redis609(){
    deb_package_name="redis-6.0.9-linux-amd64.deb"
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
            install_redis609 ${2} ${3}
            ;;
        -pm|--pm-install)
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
            if [ ${PM} == "yum" ]; then
                rpminstall_redis609
            else
                debinstall_redis609
            fi
            ;;
        *)
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
            install_redis609 ${1} ${2}
            ;;
    esac
}

echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
