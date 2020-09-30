_start_redis() {
    wget --no-check-certificate -cv -t3 -T60 -O /etc/init.d/redis ${download_sysv_url}/redis
    if [ "$?" == 0 ]; then
        sed -i "s|^prefix={redis_location}$|prefix=${redis_location}|i" /etc/init.d/redis
        chmod +x /etc/init.d/redis
        chkconfig --add redis > /dev/null 2>&1
        update-rc.d -f redis defaults > /dev/null 2>&1
        service redis start
    else
        _info "Start ${redis_filename}"
        ${redis_location}/bin/redis-server ${redis_location}/etc/redis.conf
    fi
}

install_redis(){
    if [ $# -lt 1 ]; then
        echo "[ERROR]: Missing parameters: [redis_location]"
        exit 1
    fi
    redis_location=${1}

    # 安装前备份
    mkdir -p ${backup_dir}
    mv -f ${redis_location} ${backup_dir}/redis-$(date +%Y-%m-%d_%H:%M:%S).bak >/dev/null 2>&1

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
