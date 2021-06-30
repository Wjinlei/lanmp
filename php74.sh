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

_install_php_depend(){
    _info "Starting to install dependencies packages for PHP..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(
            autoconf patch m4 bison bzip2-devel pam-devel gmp-devel
            pcre-devel libtool-libs libtool-ltdl-devel libwebp-devel
            libvpx-devel libjpeg-devel libpng-devel oniguruma-devel
            aspell-devel enchant-devel readline-devel unixODBC-devel
            libxslt-devel sqlite-devel libiodbc-devel php-odbc zlib-devel
            libXpm-devel libtidy-devel freetype-devel python2-devel
        )
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
        _install_mhash
        _install_libmcrypt
        _install_mcrypt
        _install_libzip
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(
            autoconf patch m4 bison libbz2-dev libgmp-dev libldb-dev
            libpam0g-dev autoconf2.13 pkg-config libxslt1-dev zlib1g-dev
            libpcre3-dev libtool libjpeg-dev libpng-dev libpspell-dev
            libmhash-dev libenchant-dev libwebp-dev libxpm-dev libvpx-dev
            libreadline-dev libzip-dev libmcrypt-dev unixodbc-dev
            libtidy-dev python-dev libsqlite3-dev libonig-dev
        )
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt-get -y install ${depend}"
        done
        if Is64bit; then
            if [ ! -d /usr/lib64 ] && [ -d /usr/lib ]; then
                ln -sf /usr/lib /usr/lib64
            fi

            if [ -f /usr/include/gmp-x86_64.h ]; then
                ln -sf /usr/include/gmp-x86_64.h /usr/include/
            elif [ -f /usr/include/x86_64-linux-gnu/gmp.h ]; then
                ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/
            fi

            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.a ] && [ ! -f /usr/lib64/libXpm.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.a /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.so ] && [ ! -f /usr/lib64/libXpm.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.so /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.a ] && [ ! -f /usr/lib64/libjpeg.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.a /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.so ] && [ ! -f /usr/lib64/libjpeg.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.a ] && [ ! -f /usr/lib64/libpng.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.a /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.so ] && [ ! -f /usr/lib64/libpng.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib64
            fi
        else
            if [ -f /usr/include/gmp-i386.h ]; then
                ln -sf /usr/include/gmp-i386.h /usr/include/
            elif [ -f /usr/include/i386-linux-gnu/gmp.h ]; then
                ln -sf /usr/include/i386-linux-gnu/gmp.h /usr/include/
            fi

            if [ -f /usr/lib/i386-linux-gnu/libXpm.a ] && [ ! -f /usr/lib/libXpm.a ]; then
                ln -sf /usr/lib/i386-linux-gnu/libXpm.a /usr/lib
            fi
            if [ -f /usr/lib/i386-linux-gnu/libXpm.so ] && [ ! -f /usr/lib/libXpm.so ]; then
                ln -sf /usr/lib/i386-linux-gnu/libXpm.so /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.a ] && [ ! -f /usr/lib/libjpeg.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.a /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.so ] && [ ! -f /usr/lib/libjpeg.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.a ] && [ ! -f /usr/lib/libpng.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.a /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.so ] && [ ! -f /usr/lib/libpng.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib
            fi
        fi
        _install_freetype
    fi
    CheckError "_install_openssl102" ${openssl102_location}
    CheckError "_install_pcre2" ${pcre2_location}
    _install_re2c
    CheckError "_install_icu4c" ${icu4c_location}
    CheckError "_install_libxml2" ${libxml2_location}
    CheckError "_install_libiconv" ${libiconv_location}
    CheckError "_install_curl" ${curl102_location}
    _success "Install dependencies packages for PHP completed..."
    # Fixed unixODBC issue
    if [ -f /usr/include/sqlext.h ] && [ ! -f /usr/local/include/sqlext.h ]; then
        ln -sf /usr/include/sqlext.h /usr/local/include/
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    mkdir -p ${php74_location} > /dev/null 2>&1
}

_install_openssl102(){
    cd /tmp
    _info "${openssl102_filename} install start..."
    rm -fr ${openssl102_filename}
    DownloadFile "${openssl102_filename}.tar.gz" "${openssl102_download_url}"
    tar zxf ${openssl102_filename}.tar.gz
    cd ${openssl102_filename}
    CheckError "./config --prefix=${openssl102_location} --openssldir=${openssl102_location} -fPIC shared zlib"
    CheckError "parallel_make"
    CheckError "make install"

    #Debian8
    if Is64bit; then
        if [ -f /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libssl.so.1.0.0 /usr/lib/x86_64-linux-gnu
        fi
        if [ -f /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libcrypto.so.1.0.0 /usr/lib/x86_64-linux-gnu
        fi
    else
        if [ -f /usr/lib/i386-linux-gnu/libssl.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libssl.so.1.0.0 /usr/lib/i386-linux-gnu
        fi
        if [ -f /usr/lib/i386-linux-gnu/libcrypto.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libcrypto.so.1.0.0 /usr/lib/i386-linux-gnu
        fi
    fi

    AddToEnv "${openssl102_location}"
    CreateLib64Dir "${openssl102_location}"
    export PKG_CONFIG_PATH=${openssl102_location}/lib/pkgconfig:$PKG_CONFIG_PATH
    if ! grep -qE "^${openssl102_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${openssl102_location}/lib" > /etc/ld.so.conf.d/openssl102.conf
    fi
    ldconfig
    _success "${openssl102_filename} install completed..."
    rm -f /tmp/${openssl102_filename}.tar.gz
    rm -fr /tmp/${openssl102_filename}
}

_install_pcre2(){
    cd /tmp
    _info "${pcre2_filename} install start..."
    rm -fr ${pcre2_filename}
    DownloadFile "${pcre2_filename}.tar.gz" "${pcre2_download_url}"
    tar zxf ${pcre2_filename}.tar.gz
    cd ${pcre2_filename}
    CheckError "./configure --prefix=${pcre2_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${pcre2_location}"
    CreateLib64Dir "${pcre2_location}"
    export PKG_CONFIG_PATH=${pcre2_location}/lib/pkgconfig:$PKG_CONFIG_PATH
    if ! grep -qE "^${pcre2_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${pcre2_location}/lib" > /etc/ld.so.conf.d/pcre2.conf
    fi
    ldconfig
    _success "${pcre2_filename} install completed..."
    rm -f /tmp/${pcre2_filename}.tar.gz
    rm -fr /tmp/${pcre2_filename}
}

_install_icu4c() {
    cd /tmp
    _info "${icu4c_filename} install start..."
    rm -fr ${icu4c_dirname}
    DownloadFile "${icu4c_filename}.tgz" "${icu4c_download_url}"
    tar zxf ${icu4c_filename}.tgz
    cd ${icu4c_dirname}/source
    CheckError "./configure --prefix=${icu4c_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${icu4c_location}"
    CreateLib64Dir "${icu4c_location}"
    export PKG_CONFIG_PATH=${icu4c_location}/lib/pkgconfig:$PKG_CONFIG_PATH
    if ! grep -qE "^${icu4c_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${icu4c_location}/lib" > /etc/ld.so.conf.d/icu4c.conf
    fi
    ldconfig
    _success "${icu4c_filename} install completed..."
    rm -f /tmp/${icu4c_filename}.tgz
    rm -fr /tmp/${icu4c_dirname}
}

_install_libxml2() {
    cd /tmp
    _info "${libxml2_filename} install start..."
    rm -fr ${libxml2_filename}
    DownloadFile "${libxml2_filename}.tar.gz" "${libxml2_download_url}"
    tar zxf ${libxml2_filename}.tar.gz
    cd ${libxml2_filename}
    CheckError "./configure --prefix=${libxml2_location} --with-icu=${icu4c_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${libxml2_location}"
    CreateLib64Dir "${libxml2_location}"
    export PKG_CONFIG_PATH=${libxml2_location}/lib/pkgconfig:$PKG_CONFIG_PATH
    if ! grep -qE "^${libxml2_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${libxml2_location}/lib" > /etc/ld.so.conf.d/libxml2.conf
    fi
    ldconfig
    _success "${libxml2_filename} install completed..."
    rm -f /tmp/${libxml2_filename}.tar.gz
    rm -fr /tmp/${libxml2_filename}
}

_install_curl(){
    cd /tmp
    _info "${curl_filename} install start..."
    rm -fr ${curl_filename}
    DownloadFile "${curl_filename}.tar.gz" "${curl_download_url}"
    tar zxf ${curl_filename}.tar.gz
    cd ${curl_filename}
    CheckError "./configure --prefix=${curl102_location} --with-ssl=${openssl102_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${curl102_location}"
    CreateLib64Dir "${curl102_location}"
    export PKG_CONFIG_PATH=${curl102_location}/lib/pkgconfig:$PKG_CONFIG_PATH
    _success "${curl_filename} install completed..."
    rm -f /tmp/${curl_filename}.tar.gz
    rm -fr /tmp/${curl_filename}
}

_install_libiconv(){
    cd /tmp
    _info "${libiconv_filename} install start..."
    DownloadFile "${libiconv_filename}.tar.gz" "${libiconv_download_url}"
    rm -fr ${libiconv_filename}
    tar zxf ${libiconv_filename}.tar.gz
    DownloadFile "${libiconv_patch_filename}.tar.gz" "${libiconv_patch_download_url}"
    rm -f ${libiconv_patch_filename}.patch
    tar zxf ${libiconv_patch_filename}.tar.gz
    patch -d ${libiconv_filename} -p0 < ${libiconv_patch_filename}.patch
    cd ${libiconv_filename}
    CheckError "./configure --prefix=${libiconv_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${libiconv_location}"
    CreateLib64Dir "${libiconv_location}"
    if ! grep -qE "^${libiconv_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${libiconv_location}/lib" > /etc/ld.so.conf.d/libiconv.conf
    fi
    ldconfig
    _success "${libiconv_filename} install completed..."
    rm -fr /tmp/${libiconv_filename}
    rm -f /tmp/${libiconv_filename}.tar.gz
    rm -f /tmp/${libiconv_patch_filename}.tar.gz
    rm -f /tmp/${libiconv_patch_filename}.patch
}

_install_re2c(){
    cd /tmp
    _info "${re2c_filename} install start..."
    DownloadFile "${re2c_filename}.tar.xz" "${re2c_download_url}"
    tar Jxf ${re2c_filename}.tar.xz
    cd ${re2c_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${re2c_filename} install completed..."
    rm -f /tmp/${re2c_filename}.tar.xz
    rm -fr /tmp/${re2c_filename}
}

_install_mhash(){
    cd /tmp
    _info "${mhash_filename} install start..."
    DownloadFile "${mhash_filename}.tar.gz" "${mhash_download_url}"
    tar zxf ${mhash_filename}.tar.gz
    cd ${mhash_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${mhash_filename} install completed..."
    rm -f /tmp/${mhash_filename}.tar.gz
    rm -fr /tmp/${mhash_filename}
}

_install_mcrypt(){
    cd /tmp
    _info "${mcrypt_filename} install start..."
    DownloadFile "${mcrypt_filename}.tar.gz" "${mcrypt_download_url}"
    tar zxf ${mcrypt_filename}.tar.gz
    cd ${mcrypt_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${mcrypt_filename} install completed..."
    rm -f /tmp/${mcrypt_filename}.tar.gz
    rm -fr /tmp/${mcrypt_filename}
}

_install_libmcrypt(){
    cd /tmp
    _info "${libmcrypt_filename} install start..."
    DownloadFile "${libmcrypt_filename}.tar.gz" "${libmcrypt_download_url}"
    tar zxf ${libmcrypt_filename}.tar.gz
    cd ${libmcrypt_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${libmcrypt_filename} install completed..."
    rm -f /tmp/${libmcrypt_filename}.tar.gz
    rm -fr /tmp/${libmcrypt_filename}
}

_install_libzip(){
    cd /tmp
    _info "${libzip_filename} install start..."
    DownloadFile "${libzip_filename}.tar.gz" "${libzip_download_url}"
    tar zxf ${libzip_filename}.tar.gz
    cd ${libzip_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
    _success "${libzip_filename} install completed..."
    rm -f /tmp/${libzip_filename}.tar.gz
    rm -fr /tmp/${libzip_filename}
}

_install_freetype() {
    cd /tmp
    _info "${freetype_filename} install start..."
    rm -fr ${freetype_filename}
    DownloadFile "${freetype_filename}.tar.gz" "${freetype_download_url}"
    tar zxf ${freetype_filename}.tar.gz
    cd ${freetype_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${freetype_filename} install completed..."
    rm -f /tmp/${freetype_filename}.tar.gz
    rm -fr /tmp/${freetype_filename}
}

_create_sysv_script(){
    cat > /etc/init.d/php74 << 'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: php-fpm service script

### BEGIN INIT INFO
# Provides:          php-fpm
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: php-fpm
# Description:       php-fpm service script
### END INIT INFO

prefix={php-fpm_location}

NAME=php-fpm
BIN=$prefix/sbin/$NAME
PID_FILE=$prefix/var/run/default.pid
CONFIG_FILE=$prefix/etc/default.conf

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
    $BIN --daemonize --fpm-config $CONFIG_FILE --pid $PID_FILE
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
        if [ "$isRunning" = '' ];then
            echo "$NAME is not running."
            exit 1
        fi
    else
        echo "PID file found, $NAME is not running ?"
        exit 1
    fi
    kill -USR2 `cat $PID_FILE`
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
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
    sed -i "s|^prefix={php-fpm_location}$|prefix=${php74_location}|g" /etc/init.d/php74
}

_config_php(){
    sed -i 's/default_charset =.*/default_charset = "UTF-8"/g' ${php74_location}/etc/php.ini
    sed -i 's/;always_populate_raw_post_data =.*/always_populate_raw_post_data = -1/g' ${php74_location}/etc/php.ini
    sed -i 's/post_max_size =.*/post_max_size = 100M/g' ${php74_location}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 100M/g' ${php74_location}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php74_location}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php74_location}/etc/php.ini
    sed -i 's/expose_php =.*/expose_php = Off/g' ${php74_location}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php74_location}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php74_location}/etc/php.ini
    if [ -f /etc/pki/tls/certs/ca-bundle.crt ]; then
        sed -i 's#;curl.cainfo =.*#curl.cainfo = /etc/pki/tls/certs/ca-bundle.crt#g' ${php74_location}/etc/php.ini
        sed -i 's#;openssl.cafile=.*#openssl.cafile=/etc/pki/tls/certs/ca-bundle.crt#g' ${php74_location}/etc/php.ini
    elif [ -f /etc/ssl/certs/ca-certificates.crt ]; then
        sed -i 's#;curl.cainfo =.*#curl.cainfo = /etc/ssl/certs/ca-certificates.crt#g' ${php74_location}/etc/php.ini
        sed -i 's#;openssl.cafile=.*#openssl.cafile=/etc/ssl/certs/ca-certificates.crt#g' ${php74_location}/etc/php.ini
    fi
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,proc_open,pcntl_exec,ini_alter,ini_restore,dl,openlog,syslog,popepassthru,pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,imap_open,apache_setenv/g' ${php74_location}/etc/php.ini

    mkdir -p ${php74_location}/php.d
    extension_dir=$(${php74_location}/bin/php-config --extension-dir)
    cat > ${php74_location}/php.d/opcache.ini<<EOF
[opcache]
zend_extension=${extension_dir}/opcache.so
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.save_comments=1
EOF

    # php-fpm
    cat > ${php74_location}/etc/default.conf<<EOF
[global]
    pid = ${php74_location}/var/run/default.pid
    error_log = ${php74_location}/var/log/default.log
[default]
    security.limit_extensions = .php .php3 .php4 .php5 .php7
    listen = /tmp/${php74_filename}-default.sock
    listen.owner = www
    listen.group = www
    listen.mode = 0660
    listen.allowed_clients = 127.0.0.1
    user = www
    group = www
    pm = dynamic
    pm.max_children = 5
    pm.start_servers = 2
    pm.min_spare_servers = 1
    pm.max_spare_servers = 3
EOF
    mkdir -p ${php74_location}/var/run
    mkdir -p ${php74_location}/var/log
}

install_php74(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: php_location"
        exit 1
    fi
    php74_location=${1}

    _install_php_depend

    CheckError "rm -fr ${php74_location}"
    cd /tmp
    _info "Downloading and Extracting ${php74_filename} files..."
    DownloadFile  "${php74_filename}.tar.gz" "${php74_download_url}"
    rm -fr ${php74_filename}
    tar zxf ${php74_filename}.tar.gz
    cd ${php74_filename}
    _info "Install ${php74_filename} ..."
    Is64bit && with_libdir="--with-libdir=lib64" || with_libdir=""
    php_configure_args="--prefix=${php74_location} \
    --with-config-file-path=${php74_location}/etc \
    --with-config-file-scan-dir=${php74_location}/php.d \
    --with-external-pcre=${pcre2_location} \
    --with-openssl=${openssl102_location} \
    ${with_libdir} \
    --with-mysqli=mysqlnd \
    --with-mysql-sock=/tmp/mysql.sock \
    --with-pdo-mysql=mysqlnd \
    --with-webp \
    --with-jpeg \
    --with-xpm \
    --with-freetype \
    --with-zlib \
    --with-bz2 \
    --with-curl=${curl102_location} \
    --with-gettext \
    --with-gmp \
    --with-mhash \
    --with-pdo-odbc=unixODBC \
    --with-pspell=/usr \
    --with-enchant=/usr \
    --with-readline \
    --with-tidy=/usr \
    --with-xmlrpc \
    --with-xsl \
    --with-zip \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-iconv=${libiconv_location} \
    --without-pear \
    --disable-phar \
    --enable-mysqlnd \
    --enable-fpm \
    --enable-bcmath \
    --enable-calendar \
    --enable-dba \
    --enable-exif \
    --enable-ftp \
    --enable-gd \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    ${disable_fileinfo}"
    unset LD_LIBRARY_PATH
    unset CPPFLAGS
    ldconfig
    CheckError "./configure ${php_configure_args}"
    CheckError "parallel_make ZEND_EXTRA_LIBS='-liconv'"
    CheckError "make install"
    # Config
    _info "Config ${php74_filename}..."
    mkdir -p ${php74_location}/etc
    cp -f php.ini-production ${php74_location}/etc/php.ini
    _config_php
    _warn "Please add the following two lines to your httpd.conf"
    echo AddType application/x-httpd-php .php .phtml
    echo AddType application/x-httpd-php-source .phps
    # Start
    _create_sysv_script
    chmod +x /etc/init.d/php74
    update-rc.d -f php74 defaults > /dev/null 2>&1
    chkconfig --add php74 > /dev/null 2>&1
    /etc/init.d/php74 start
    # Clean
    rm -fr /tmp/${php74_filename}
    _success "${php74_filename} install completed..."
}

rpminstall_php74(){
    rpm_package_name="php74-7.4.13-1.el7.x86_64.rpm"
    php74_location=/hws.com/hwsmaster/server/php-7_4_13
    _install_php_depend
    DownloadUrl ${rpm_package_name} ${download_root_url}/rpms/${rpm_package_name}
    CheckError "rpm -ivh ${rpm_package_name} --force --nodeps"
    _config_php
    /etc/init.d/php74 restart
}

debinstall_php74(){
    deb_package_name="php-7.4.13-linux-amd64.deb"
    _install_php_depend
    DownloadUrl ${deb_package_name} ${download_root_url}/debs/${deb_package_name}
    CheckError "dpkg --force-depends -i ${deb_package_name}"
}

main() {
    case "$1" in
        -h|--help)
            printf "Usage: $0 Options prefix
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
            install_php74 ${2}
            ;;
        -pm|--pm-install)
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
            if [ ${PM} == "yum" ]; then
                rpminstall_php74
            else
                debinstall_php74
            fi
            ;;
        *)
            echo "Missing parameters,Please Usage: $0 -h, Show Help" && exit 1
            ;;
    esac
}

echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
