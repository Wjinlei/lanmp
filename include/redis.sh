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
        CheckError "service redis restart"
    fi
}

install_redis(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: redis_location [default_port]"
        exit 1
    fi
    redis_location=${1}

    # 如果存在第二个参数
    if [ $# -ge 2 ]; then
        redis_port=${2}
    fi

    mkdir -p ${redis_location}
    CheckError "rm -fr ${redis_location}"
    local tram=$( free -m | awk '/Mem/ {print $2}' )
    local swap=$( free -m | awk '/Swap/ {print $2}' )
    local Mem=$(expr $tram + $swap)
    cd /tmp
    _info "redis-server install start..."
    DownloadFile "${redis_filename}.tar.gz" "${redis_download_url}"
    rm -fr ${redis_filename}
    tar zxf ${redis_filename}.tar.gz
    cd ${redis_filename}
    ! Is64bit && sed -i '1i\CFLAGS= -march=i686' src/Makefile && sed -i 's@^OPT=.*@OPT=-O2 -march=i686@' src/.make-settings
    CheckError "make"
    if [ -f "src/redis-server" ]; then
        mkdir -p ${redis_location}/{bin,etc,var}
        mkdir -p ${redis_location}/var/{log,run}
        cp src/{redis-benchmark,redis-check-aof,redis-check-rdb,redis-cli,redis-sentinel,redis-server} ${redis_location}/bin/
        _info "Config ${redis_filename}"
        cp redis.conf ${redis_location}/etc/
        sed -i "s@pidfile.*@pidfile ${redis_location}/var/run/redis.pid@" ${redis_location}/etc/redis.conf
        sed -i "s@logfile.*@logfile ${redis_location}/var/log/redis.log@" ${redis_location}/etc/redis.conf
        sed -i "s@^dir.*@dir ${redis_location}/var@" ${redis_location}/etc/redis.conf
        sed -i 's@daemonize no@daemonize yes@' ${redis_location}/etc/redis.conf
        sed -i "s@port 6379@port ${redis_port}@" ${redis_location}/etc/redis.conf
        sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_location}/etc/redis.conf
        [ -z "$(grep ^maxmemory ${redis_location}/etc/redis.conf)" ] && sed -i "s@maxmemory <bytes>@maxmemory <bytes>\nmaxmemory $(expr ${Mem} / 8)000000@" ${redis_location}/etc/redis.conf

        _start_redis
        rm -fr ${redis_filename}
        _success "redis-server install completed!"
    else
        _warn "redis-server install failed."
    fi
}
