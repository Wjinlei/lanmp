_install_php_depend(){
    _info "Starting to install dependencies packages for PHP..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(
            autoconf patch m4 bison bzip2-devel pam-devel gmp-devel libicu-devel
            curl-devel libtool-libs libtool-ltdl-devel libwebp-devel libXpm-devel
            libvpx-devel libjpeg-devel libpng-devel freetype-devel oniguruma-devel
            aspell-devel enchant-devel readline-devel unixODBC-devel libtidy-devel
            openldap-devel libxslt-devel net-snmp net-snmp-devel krb5-devel sqlite-devel
            libiodbc-devel php-odbc mhash-devel libmcrypt-devel mcrypt re2c
            pcre-devel openssl-devel zlib-devel
        )
        for depend in ${yum_depends[@]}
        do
            install_package "yum -y install ${depend}"
        done
        if yum list | grep "libc-client-devel" > /dev/null 2>&1; then
            install_package "yum -y install libc-client-devel"
        elif yum list | grep "uw-imap-devel" > /dev/null 2>&1; then
            install_package "yum -y install uw-imap-devel"
        else
            _error "There is no rpm package libc-client-devel or uw-imap-devel, please check it and try again."
        fi
        _install_libzip
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(
            autoconf patch m4 bison libbz2-dev libgmp-dev libicu-dev libldb-dev libpam0g-dev
            libldap-2.4-2 libldap2-dev libsasl2-dev libsasl2-modules-ldap libc-client2007e-dev libkrb5-dev
            autoconf2.13 pkg-config libxslt1-dev libtool unixodbc-dev libtidy-dev
            libjpeg-dev libpng-dev libfreetype6-dev libpspell-dev libmhash-dev libenchant-dev libmcrypt-dev
            libcurl4-gnutls-dev libwebp-dev libxpm-dev libvpx-dev libreadline-dev snmp libsnmp-dev libzip-dev
            libsqlite3-dev libiodbc2-dev php-odbc libssl-dev re2c mcrypt libpcre3-dev zlib1g-dev
        )
        for depend in ${apt_depends[@]}
        do
            install_package "apt-get -y install ${depend}"
        done
        if is_64bit; then
            if [ ! -d /usr/lib64 ] && [ -d /usr/lib ]; then
                ln -sf /usr/lib /usr/lib64
            fi

            if [ -f /usr/include/gmp-x86_64.h ]; then
                ln -sf /usr/include/gmp-x86_64.h /usr/include/
            elif [ -f /usr/include/x86_64-linux-gnu/gmp.h ]; then
                ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/
            fi

            ln -sf /usr/lib/x86_64-linux-gnu/libldap* /usr/lib64/
            ln -sf /usr/lib/x86_64-linux-gnu/liblber* /usr/lib64/

            if [ -d /usr/include/x86_64-linux-gnu/curl ] && [ ! -d /usr/include/curl ]; then
                ln -sf /usr/include/x86_64-linux-gnu/curl /usr/include/
            fi

            create_lib_link libc-client.a
            create_lib_link libc-client.so
        else
            if [ -f /usr/include/gmp-i386.h ]; then
                ln -sf /usr/include/gmp-i386.h /usr/include/
            elif [ -f /usr/include/i386-linux-gnu/gmp.h ]; then
                ln -sf /usr/include/i386-linux-gnu/gmp.h /usr/include/
            fi

            ln -sf /usr/lib/i386-linux-gnu/libldap* /usr/lib/
            ln -sf /usr/lib/i386-linux-gnu/liblber* /usr/lib/

            if [ -d /usr/include/i386-linux-gnu/curl ] && [ ! -d /usr/include/curl ]; then
                ln -sf /usr/include/i386-linux-gnu/curl /usr/include/
            fi
        fi
    fi
    _success "Install dependencies packages for PHP completed..."
    check_installed "_install_libiconv" "${depends_prefix}/libiconv"
    check_installed "_install_redis_server" "${redis_location}"
    # Fixed unixODBC issue
    if [ -f /usr/include/sqlext.h ] && [ ! -f /usr/local/include/sqlext.h ]; then
        ln -sf /usr/include/sqlext.h /usr/local/include/
    fi
    id -u hwswww >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U hwswww -r -d /dev/null -s /sbin/nologin
}

_install_libiconv(){
    if [ ! -e "/usr/local/bin/iconv" ]; then
        cd ${cur_dir}/software/
        _info "${libiconv_filename} install start..."
        download_file  "${libiconv_filename}.tar.gz" "${libiconv_filename_url}"
        rm -fr ${libiconv_filename}
        tar zxf ${libiconv_filename}.tar.gz
        download_file "${libiconv_patch}.tar.gz" "${libiconv_patch_url}"
        rm -f ${libiconv_patch}.patch
        tar zxf ${libiconv_patch}.tar.gz
        patch -d ${libiconv_filename} -p0 < ${libiconv_patch}.patch
        cd ${libiconv_filename}
        check_error "./configure --prefix=${depends_prefix}/libiconv"
        check_error "parallel_make"
        check_error "make install"
        add_to_env "${depends_prefix}/libiconv"
        create_lib64_dir "${depends_prefix}/libiconv"
        _success "${libiconv_filename} install completed..."
    fi
}

_install_libzip(){
    if [ ! -e "/usr/lib/libzip.la" ]; then
        cd ${cur_dir}/software/
        _info "${libzip_filename} install start..."
        download_file "${libzip_filename}.tar.gz" "${libzip_filename_url}"
        tar zxf ${libzip_filename}.tar.gz
        cd ${libzip_filename}

        check_error "./configure --prefix=/usr"
        check_error "parallel_make"
        check_error "make install"
        ldconfig
        _info "${libzip_filename} install completed..."
    fi
}

_install_redis_server(){
    local tram=$( free -m | awk '/Mem/ {print $2}' )
    local swap=$( free -m | awk '/Swap/ {print $2}' )
    local Mem=$(expr $tram + $swap)
    cd ${cur_dir}/software/
    _info "redis-server install start..."
    download_file "${redis_filename}.tar.gz" "${redis_filename_url}"
    rm -fr ${redis_filename}
    tar zxf ${redis_filename}.tar.gz
    cd ${redis_filename}
    ! is_64bit && sed -i '1i\CFLAGS= -march=i686' src/Makefile && sed -i 's@^OPT=.*@OPT=-O2 -march=i686@' src/.make-settings
    check_error "make"
    if [ -f "src/redis-server" ]; then
        mkdir -p ${redis_location}/{bin,etc,var}
        mkdir -p ${redis_location}/var/{log,run}
        cp src/{redis-benchmark,redis-check-aof,redis-check-rdb,redis-cli,redis-sentinel,redis-server} ${redis_location}/bin/
        cp redis.conf ${redis_location}/etc/
        sed -i "s@pidfile.*@pidfile ${redis_location}/var/run/redis.pid@" ${redis_location}/etc/redis.conf
        sed -i "s@logfile.*@logfile ${redis_location}/var/log/redis.log@" ${redis_location}/etc/redis.conf
        sed -i "s@^dir.*@dir ${redis_location}/var@" ${redis_location}/etc/redis.conf
        sed -i 's@daemonize no@daemonize yes@' ${redis_location}/etc/redis.conf
        sed -i "s@port 6379@port ${redis_port}@" ${redis_location}/etc/redis.conf
        sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_location}/etc/redis.conf
        [ -z "$(grep ^maxmemory ${redis_location}/etc/redis.conf)" ] && sed -i "s@maxmemory <bytes>@maxmemory <bytes>\nmaxmemory $(expr ${Mem} / 8)000000@" ${redis_location}/etc/redis.conf
        ${redis_location}/bin/redis-server ${redis_location}/etc/redis.conf
        sqlite3 ${install_prefix}/hwslinuxmaster.db <<EOF
PRAGMA foreign_keys = ON;
INSERT INTO hws_cacheserver (path, name, version, port, servertype) VALUES ("${redis_location}", "${redis_filename}", "${redis_version}", ${redis_port}, 1);
UPDATE hws_sysconfig SET value="${redis_filename}" WHERE key="CurrentCacheServer";
EOF
        cat >> ${install_prefix}/install.result <<EOF
Redis Install Path: ${redis_location}

EOF
        _success "redis-server install completed!"
    else
        is_it_installed_redis=0
        _warn "redis-server install failed."
    fi
}

_install_php_redis(){
    if [ "${is_it_installed_redis}" != 0 ]; then
        local phpConfig="${php_location}/bin/php-config"
        local php_extension_dir=$(${phpConfig} --extension-dir)
        cd ${cur_dir}/software/
        _info "PHP extension redis install start..."
        if [[ "${1}" == "${php53_filename}" || "${1}" == "${php54_filename}" || "${1}" == "${php55_filename}" || "${1}" == "${php56_filename}" ]]; then
            download_file  "${php_redis_filename}.tgz" "${php_redis_filename_url}"
            rm -fr ${php_redis_filename}
            tar zxf ${php_redis_filename}.tgz
            cd ${php_redis_filename}
        else
            download_file  "${php_redis_filename2}.tgz" "${php_redis_filename2_url}"
            rm -fr ${php_redis_filename2}
            tar zxf ${php_redis_filename2}.tgz
            cd ${php_redis_filename2}
        fi

        check_error "${php_location}/bin/phpize"
        check_error "./configure --enable-redis --with-php-config=${phpConfig}"
        check_error "make"
        check_error "make install"
    
        if [ ! -f ${php_location}/php.d/redis.ini ]; then
            _warn "PHP extension redis configuration file not found, create it!"
            cat > ${php_location}/php.d/redis.ini<<EOF
[redis]
extension = ${php_extension_dir}/redis.so
EOF
        fi
        kill -USR2 `cat ${php_location}/var/run/default.pid`
        _success "PHP extension redis install completed..."
    fi
}

install_phpmyadmin(){
    if [ ! -d "${default_site_dir}/pma" ]; then
        cd ${cur_dir}/software
        _info "${phpmyadmin49_filename} install start..."
        download_file "${phpmyadmin49_filename}.tar.gz" "${phpmyadmin49_url}"
        rm -fr ${phpmyadmin49_filename}
        tar zxf ${phpmyadmin49_filename}.tar.gz
        mv ${phpmyadmin49_filename} ${default_site_dir}/pma
        wget --no-check-certificate -cv -t3 -T60 "https://d.hws.com/free/hwslinuxmaster/conf/phpmyadmin-conf.tar.gz"
        tar zxf phpmyadmin-conf.tar.gz
        cp -f conf/config.inc.php ${default_site_dir}/pma/config.inc.php
        mkdir -p ${default_site_dir}/pma/{upload,save}
        chown -R hwswww:hwswww ${default_site_dir}/pma
        _info "${phpmyadmin49_filename} install completed..."
    fi
}

_make_php(){
    local php_ver=$(echo ${1} | sed 's/[^0-9.]//g' | cut -d. -f1-2)
    _info "Make Install ${1}..."
    [ "${1}" == "${php53_filename}" ] && php_location=${php53_location}
    [ "${1}" == "${php54_filename}" ] && php_location=${php54_location}
    [ "${1}" == "${php55_filename}" ] && php_location=${php55_location}
    [ "${1}" == "${php56_filename}" ] && php_location=${php56_location}
    [ "${1}" == "${php70_filename}" ] && php_location=${php70_location}
    [ "${1}" == "${php71_filename}" ] && php_location=${php71_location}
    [ "${1}" == "${php72_filename}" ] && php_location=${php72_location}
    [ "${1}" == "${php73_filename}" ] && php_location=${php73_location}
    [ "${1}" == "${php74_filename}" ] && php_location=${php74_location} 
    if [ "${1}" == "${php53_filename}" ]; then
        with_gd="--with-gd --with-jpeg-dir --with-png-dir --with-xpm-dir --with-freetype-dir"
        with_libmbfl="--with-libmbfl"
        other_options="--with-mcrypt --enable-gd-native-ttf"
    elif [[ "${1}" == "${php54_filename}" || "${1}" == "${php55_filename}" || "${1}" == "${php56_filename}" ]]; then
        with_gd="--with-gd --with-vpx-dir --with-jpeg-dir --with-png-dir --with-xpm-dir --with-freetype-dir"
        with_libmbfl="--with-libmbfl"
        other_options="--with-mcrypt --enable-gd-native-ttf"
    elif [[ "${1}" == "${php70_filename}" || "${1}" == "${php71_filename}" ]]; then
        with_gd="--with-gd --with-webp-dir --with-jpeg-dir --with-png-dir --with-xpm-dir --with-freetype-dir"
        with_libmbfl="--with-libmbfl"
        other_options="--with-mcrypt --enable-gd-native-ttf"
    elif [ "${1}" == "${php72_filename}" ]; then
        with_gd="--with-gd --with-webp-dir --with-jpeg-dir --with-png-dir --with-xpm-dir --with-freetype-dir"
        with_libmbfl="--with-libmbfl"
        other_options=""
    elif [ "${1}" == "${php73_filename}" ]; then
        with_gd="--with-gd --with-webp-dir --with-jpeg-dir --with-png-dir --with-xpm-dir --with-freetype-dir"
        with_libmbfl=""
        other_options=""
    elif [ "${1}" == "${php74_filename}" ]; then
        with_gd="--enable-gd --with-webp-dir --with-jpeg-dir --with-png-dir --with-xpm-dir --with-freetype-dir"
        with_libmbfl=""
        other_options="--with-iodbc"
    fi
    is_64bit && with_libdir="--with-libdir=lib64" || with_libdir=""
    php_configure_args="--prefix=${php_location} \
    --with-config-file-path=${php_location}/etc \
    --with-config-file-scan-dir=${php_location}/php.d \
    --with-imap \
    --with-kerberos \
    --with-imap-ssl \
    --with-libxml-dir \
    --with-openssl \
    --with-snmp \
    ${with_libdir} \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-mysql-sock=/tmp/mysql.sock \
    --with-pdo-mysql=mysqlnd \
    ${with_gd} \
    --with-zlib \
    --with-bz2 \
    --with-curl=/usr \
    --with-gettext \
    --with-gmp \
    --with-mhash \
    --with-icu-dir=/usr \
    --with-ldap \
    --with-ldap-sasl \
    ${with_libmbfl} \
    --with-onig \
    --with-unixODBC \
    --with-pspell=/usr \
    --with-enchant=/usr \
    --with-readline \
    --with-tidy=/usr \
    --with-xmlrpc \
    --with-xsl \
    --with-fpm-user=hwswww \
    --with-fpm-group=hwswww \
    --without-pear \
    ${other_options} \
    --enable-mysqlnd \
    --enable-fastcgi \
    --enable-fpm \
    --enable-bcmath \
    --enable-calendar \
    --enable-dba \
    --enable-exif \
    --enable-ftp \
    --enable-gd-jis-conv \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-wddx \
    --enable-zip \
    ${disable_fileinfo}"

    check_error "./configure ${php_configure_args}"
    # fix php53 libstdc++ bug
    if [ "${1}" == "${php53_filename}" ]; then
        sed -i '/^BUILD_/ s/\$(CC)/\$(CXX)/g' Makefile
    fi
    check_error "parallel_make ZEND_EXTRA_LIBS='-liconv'"
    check_error "make install"
    sqlite3 "${install_prefix}/hwslinuxmaster.db" <<EOF
PRAGMA foreign_keys = ON;
INSERT INTO hws_php (path, name, version) VALUES ("${php_location}", "${1}", "${php_ver}");
EOF
    _info "Config php..."
    _config_php ${1}
    _install_php_redis ${1}
}

_config_php(){
    # php.ini
    mkdir -p ${php_location}/{etc,php.d}
    cp -f php.ini-production ${php_location}/etc/php.ini
    php_disable_functions=`grep "^disable_functions" ${php_location}/etc/php.ini |wc -l`
    if [[ ${php_disable_functions} -eq 0 ]];then
        echo "disable_functions = system, passthru, exec, chroot, chgrp, chown, proc_get, shell_exec, popen, escapeshellarg, escapeshellcmd, proc_close, proc_open, dl, proc_get_status, ini_alter, ini_alter, ini_restore" >> ${php_location}/etc/php.ini
    else
        sed -i '/^disable_functions/ s/.*/disable_functions = system, passthru, exec, chroot, chgrp, chown, proc_get, shell_exec, popen, escapeshellarg, escapeshellcmd, proc_close, proc_open, dl, proc_get_status, ini_alter, ini_alter, ini_restore/' ${php_location}/etc/php.ini
    fi
    if [[ -d "${mysql_data_location}" ]]; then
        sock_location=/tmp/mysql.sock
        sed -i "s#mysql.default_socket.*#mysql.default_socket = ${sock_location}#" ${php_location}/etc/php.ini
        sed -i "s#mysqli.default_socket.*#mysqli.default_socket = ${sock_location}#" ${php_location}/etc/php.ini
        sed -i "s#pdo_mysql.default_socket.*#pdo_mysql.default_socket = ${sock_location}#" ${php_location}/etc/php.ini
    fi

    # opcache
    extension_dir=$(${php_location}/bin/php-config --extension-dir)
    if [[ "${1}" != "${php53_filename}" && "${1}" != "${php54_filename}" ]]; then
        cat > ${php_location}/php.d/opcache.ini<<EOF
[opcache]
zend_extension=${extension_dir}/opcache.so
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.save_comments=0
EOF
    fi

    # php-fpm
    cat > ${php_location}/etc/default.conf<<EOF
[global]
    pid = ${php_location}/var/run/default.pid
    error_log = ${php_location}/var/log/default.log
[default]
    listen = /run/php-fpm/${1}-default.sock
    listen.owner = hwswww
    listen.group = hwswww
    listen.mode = 0660
    listen.allowed_clients = 127.0.0.1
    user = hwswww
    group = hwswww
    pm = dynamic
    pm.max_children = 5
    pm.start_servers = 2
    pm.min_spare_servers = 1
    pm.max_spare_servers = 3
EOF
    mkdir -p /run/php-fpm
    mkdir -p ${php_location}/var/run
    mkdir -p ${php_location}/var/log
    ${php_location}/sbin/php-fpm -y ${php_location}/etc/default.conf

    # Apache setting
    if [[ -d "${apache_location}" ]]; then
        sed -i "s@AddType\(.*\)Z@AddType\1Z\n    AddType application/x-httpd-php .php .phtml\n    AddType appication/x-httpd-php-source .phps@" ${apache_location}/conf/httpd.conf
        if [[ "${1}" == "${php53_filename}" || "${1}" == ${php54_filename} ]]; then
            cat > ${apache_location}/conf/vhost/default.conf<<EOF
<VirtualHost _default_:80>
ServerName localhost
DocumentRoot ${default_site_dir}
<Directory ${default_site_dir}>
    SetOutputFilter DEFLATE
    Options FollowSymLinks
    AllowOverride All
    Order Deny,Allow
    Require all granted
    DirectoryIndex index.php default.php index.html index.htm
</Directory>
ProxyPassMatch ^/(.*\.php(/.*)?)\$ unix:/run/php-fpm/${php55_filename}-default.sock|fcgi://localhost${default_site_dir}/
</VirtualHost>
EOF
        else
            cat > ${apache_location}/conf/vhost/default.conf<<EOF
<VirtualHost _default_:80>
ServerName localhost
DocumentRoot ${default_site_dir}
<Directory ${default_site_dir}>
    SetOutputFilter DEFLATE
    Options FollowSymLinks
    AllowOverride All
    Order Deny,Allow
    Require all granted
    DirectoryIndex index.php default.php index.html index.htm
</Directory>
ProxyPassMatch ^/(.*\.php(/.*)?)\$ unix:/run/php-fpm/${1}-default.sock|fcgi://localhost${default_site_dir}/
</VirtualHost>
EOF
        fi
        _info "Restart Apache"
        ${apache_location}/bin/httpd -t
        ${apache_location}/bin/apachectl restart
    fi

    # Nginx setting
    if [[ -d "${nginx_location}" ]]; then
        if [[ "${1}" == "${php53_filename}" || "${1}" == ${php54_filename} ]]; then
            cat > ${nginx_location}/etc/vhost/default.conf<<EOF
server {
    listen 80;
    server_name 0.0.0.0;
    root ${default_site_dir};
    index index.php default.php index.html index.htm;

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php-fpm/${php55_filename}-default.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
        else
            cat > ${nginx_location}/etc/vhost/default.conf<<EOF
server {
    listen 80;
    server_name 0.0.0.0;
    root ${default_site_dir};
    index index.php default.php index.html index.htm;

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php-fpm/${1}-default.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
        fi
        _info "Restart Nginx"
        ${nginx_location}/sbin/nginx -t
        ${nginx_location}/sbin/nginx
        ${nginx_location}/sbin/nginx -s reload
    fi

    # php tz
    if [ ! -f "${default_site_dir}/index.php" ]; then
        wget --no-check-certificate -cv -t3 -T60 "https://d.hws.com/free/hwslinuxmaster/conf/tz.tar.gz"
        tar zxf tz.tar.gz
        cp -f tz.php ${default_site_dir}/index.php
        chown -R hwswww:hwswww ${default_site_dir}
    fi
}

install_php53(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php53_filename} files..."
    download_file  "${php53_filename}.tar.gz" "${php53_url}"
    rm -fr ${php53_filename}
    tar zxf ${php53_filename}.tar.gz
    cd ${php53_filename}
    _make_php ${php53_filename}
    cat >> ${install_prefix}/install.result <<EOF
php53 Install Path: ${php53_location}
EOF
}

install_php54(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php54_filename} files..."
    download_file  "${php54_filename}.tar.gz" "${php54_url}"
    rm -fr ${php54_filename}
    tar zxf ${php54_filename}.tar.gz
    cd ${php54_filename}
    _make_php ${php54_filename}
    cat >> ${install_prefix}/install.result <<EOF
php54 Install Path: ${php54_location}
EOF
}

install_php55(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php55_filename} files..."
    download_file  "${php55_filename}.tar.gz" "${php55_url}"
    rm -fr ${php55_filename}
    tar zxf ${php55_filename}.tar.gz
    cd ${php55_filename}
    _make_php ${php55_filename}
    cat >> ${install_prefix}/install.result <<EOF
php55 Install Path: ${php55_location}
EOF
}

install_php56(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php56_filename} files..."
    download_file  "${php56_filename}.tar.gz" "${php56_url}"
    rm -fr ${php56_filename}
    tar zxf ${php56_filename}.tar.gz
    cd ${php56_filename}
    _make_php ${php56_filename}
    cat >> ${install_prefix}/install.result <<EOF
php56 Install Path: ${php56_location}
EOF
}

install_php70(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php70_filename} files..."
    download_file  "${php70_filename}.tar.gz" "${php70_url}"
    rm -fr ${php70_filename}
    tar zxf ${php70_filename}.tar.gz
    cd ${php70_filename}
    _make_php ${php70_filename}
    cat >> ${install_prefix}/install.result <<EOF
php70 Install Path: ${php70_location}
EOF
}

install_php71(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php71_filename} files..."
    download_file  "${php71_filename}.tar.gz" "${php71_url}"
    rm -fr ${php71_filename}
    tar zxf ${php71_filename}.tar.gz
    cd ${php71_filename}
    _make_php ${php71_filename}
    cat >> ${install_prefix}/install.result <<EOF
php71 Install Path: ${php71_location}
EOF
}

install_php72(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php72_filename} files..."
    download_file  "${php72_filename}.tar.gz" "${php72_url}"
    rm -fr ${php72_filename}
    tar zxf ${php72_filename}.tar.gz
    cd ${php72_filename}
    _make_php ${php72_filename}
    cat >> ${install_prefix}/install.result <<EOF
php72 Install Path: ${php72_location}
EOF
}

install_php73(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php73_filename} files..."
    download_file  "${php73_filename}.tar.gz" "${php73_url}"
    rm -fr ${php73_filename}
    tar zxf ${php73_filename}.tar.gz
    cd ${php73_filename}
    _make_php ${php73_filename}
    cat >> ${install_prefix}/install.result <<EOF
php73 Install Path: ${php73_location}
EOF
}

install_php74(){
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${php74_filename} files..."
    download_file  "${php74_filename}.tar.gz" "${php74_url}"
    rm -fr ${php74_filename}
    tar zxf ${php74_filename}.tar.gz
    cd ${php74_filename}
    _make_php ${php74_filename}
    cat >> ${install_prefix}/install.result <<EOF
php74 Install Path: ${php74_location}
EOF
}

install_php(){
    _install_php_depend
    if [ "${php}" == "${php53_filename}" ]; then
        check_installed "install_php55" "${php55_location}"
        check_installed "install_php53" "${php53_location}"
    elif [ "${php}" == "${php54_filename}" ]; then
        check_installed "install_php55" "${php55_location}"
        check_installed "install_php54" "${php54_location}"
    elif [ "${php}" == "${php55_filename}" ]; then
        check_installed "install_php55" "${php55_location}"
    elif [ "${php}" == "${php56_filename}" ]; then
        check_installed "install_php56" "${php56_location}"
    elif [ "${php}" == "${php70_filename}" ]; then
        check_installed "install_php70" "${php70_location}"
    elif [ "${php}" == "${php71_filename}" ]; then
        check_installed "install_php71" "${php71_location}"
    elif [ "${php}" == "${php72_filename}" ]; then
        check_installed "install_php72" "${php72_location}"
    elif [ "${php}" == "${php73_filename}" ]; then
        check_installed "install_php73" "${php73_location}"
    elif [ "${php}" == "${php74_filename}" ]; then
        check_installed "install_php74" "${php74_location}"
    fi
    install_phpmyadmin
}
