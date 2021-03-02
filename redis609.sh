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

_start_redis() {
    CheckError "${redis_location}/bin/redis-server ${redis_location}/etc/redis.conf"
    wait_for_pid created ${redis_location}/var/run/redis.pid
    if [ -n "$try" ] ; then
        echo "wait_for_pid failed"
        exit 1
    else
        DownloadUrl "/etc/init.d/redis" "${download_sysv_url}/redis"
        sed -i "s|^prefix={redis_location}$|prefix=${redis_location}|g" /etc/init.d/redis
        CheckError "chmod +x /etc/init.d/redis"
        chkconfig --add redis > /dev/null 2>&1
        update-rc.d -f redis defaults > /dev/null 2>&1
        CheckError "/etc/init.d/redis restart"
    fi
}

install_redis609(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: redis_location [default_port]"
        exit 1
    fi
    redis_location=${1}

    # 如果存在第二个参数
    if [ $# -ge 2 ]; then
        redis_port=${2}
    fi

    # Install SCL
    if [ "${PM}" = "yum" ];then
        yum -y install centos-release-scl >/dev/null 2>&1
        yum -y install devtoolset-9-gcc >/dev/null 2>&1
        yum -y install devtoolset-9-gcc-c++ >/dev/null 2>&1
        yum -y install devtoolset-9-binutils >/dev/null 2>&1
        source /opt/rh/devtoolset-9/enable >/dev/null 2>&1
    fi

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
        cp src/{redis-benchmark,redis-check-aof,redis-check-rdb,redis-cli,redis-sentinel,redis-server} ${redis_location}/bin/
        _info "Config ${redis609_filename}"
        cp redis.conf ${redis_location}/etc/
        sed -i "s@pidfile.*@pidfile ${redis_location}/var/run/redis.pid@" ${redis_location}/etc/redis.conf
        sed -i "s@logfile.*@logfile ${redis_location}/var/log/redis.log@" ${redis_location}/etc/redis.conf
        sed -i "s@^dir.*@dir ${redis_location}/var@" ${redis_location}/etc/redis.conf
        sed -i 's@daemonize no@daemonize yes@' ${redis_location}/etc/redis.conf
        sed -i "s@port 6379@port ${redis_port}@" ${redis_location}/etc/redis.conf
        sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_location}/etc/redis.conf
        [ -z "$(grep ^maxmemory ${redis_location}/etc/redis.conf)" ] && sed -i "s@maxmemory <bytes>@maxmemory <bytes>\nmaxmemory $(expr ${Mem} / 8)000000@" ${redis_location}/etc/redis.conf

        _start_redis
        rm -fr ${redis609_filename}
        _success "redis-server install completed!"
    else
        _warn "redis-server install failed."
    fi
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    install_redis609 ${1} ${2}
}
echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
