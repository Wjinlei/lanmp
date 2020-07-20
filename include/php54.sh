_install_php_depend(){
    _info "Starting to install dependencies packages for PHP..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(
            autoconf patch m4 bison bzip2-devel pam-devel gmp-devel libicu-devel
            pcre-devel libtool-libs libtool-ltdl-devel libwebp-devel libXpm-devel
            libvpx-devel libjpeg-devel libpng-devel freetype-devel oniguruma-devel
            aspell-devel enchant-devel readline-devel unixODBC-devel libtidy-devel
            libxslt-devel sqlite-devel libiodbc-devel php-odbc zlib-devel libxml2-devel
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
            autoconf patch m4 bison libbz2-dev libgmp-dev libicu-dev libldb-dev libpam0g-dev
            autoconf2.13 pkg-config libxslt1-dev zlib1g-dev libpcre3-dev libtool unixodbc-dev libtidy-dev
            libjpeg-dev libpng-dev libfreetype6-dev libpspell-dev libmhash-dev libenchant-dev libmcrypt-dev
            libwebp-dev libxpm-dev libvpx-dev libreadline-dev libzip-dev libxml2-dev
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

            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.a ] && [ ! -f /usr/lib/libXpm.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.a /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.so ] && [ ! -f /usr/lib/libXpm.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.so /usr/lib
            fi
        else
            if [ -f /usr/include/gmp-i386.h ]; then
                ln -sf /usr/include/gmp-i386.h /usr/include/
            elif [ -f /usr/include/i386-linux-gnu/gmp.h ]; then
                ln -sf /usr/include/i386-linux-gnu/gmp.h /usr/include/
            fi

            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.a ] && [ ! -f /usr/lib/libXpm.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.a /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.so ] && [ ! -f /usr/lib/libXpm.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.so /usr/lib
            fi
        fi
    fi
    _install_openssl
    _install_pcre
    _install_libiconv
    _install_re2c
    _install_curl
    _success "Install dependencies packages for PHP completed..."
    # Fixed unixODBC issue
    if [ -f /usr/include/sqlext.h ] && [ ! -f /usr/local/include/sqlext.h ]; then
        ln -sf /usr/include/sqlext.h /usr/local/include/
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
}

_install_curl(){
    cd /tmp
    _info "${curl_filename} install start..."
    rm -fr ${curl_filename}
    DownloadFile "${curl_filename}.tar.gz" "${curl_download_url}"
    tar zxf ${curl_filename}.tar.gz
    cd ${curl_filename}
    unset CFLAGS
    CheckError "./configure --prefix=${curl_location} --with-ssl=${openssl102_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${curl_location}"
    CreateLib64Dir "${curl_location}"
    #if ! grep -qE "^${curl_location}/lib" /etc/ld.so.conf.d/*.conf; then
        #echo "${curl_location}/lib" > /etc/ld.so.conf.d/curl.conf
    #fi
    ldconfig
    _success "${curl_filename} install completed..."
    rm -f /tmp/${curl_filename}.tar.gz
    rm -fr /tmp/${curl_filename}
}

_install_pcre(){
    cd /tmp
    _info "${pcre_filename} install start..."
    rm -fr ${pcre_filename}
    DownloadFile "${pcre_filename}.tar.gz" "${pcre_download_url}"
    tar zxf ${pcre_filename}.tar.gz
    cd ${pcre_filename}
    CheckError "./configure --prefix=${pcre_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${pcre_location}"
    CreateLib64Dir "${pcre_location}"
    if ! grep -qE "^${pcre_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${pcre_location}/lib" > /etc/ld.so.conf.d/pcre.conf
    fi
    ldconfig
    _success "${pcre_filename} install completed..."
    rm -f /tmp/${pcre_filename}.tar.gz
    rm -fr /tmp/${pcre_filename}
}

_install_openssl(){
    cd /tmp
    _info "${openssl102_filename} install start..."
    rm -fr ${openssl102_filename}
    DownloadFile "${openssl102_filename}.tar.gz" "${openssl102_download_url}"
    tar zxf ${openssl102_filename}.tar.gz
    cd ${openssl102_filename}
    CheckError "./config --prefix=${openssl102_location} -fPIC shared zlib"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${openssl102_location}"
    CreateLib64Dir "${openssl102_location}"
    #if ! grep -qE "^${openssl_location}/lib" /etc/ld.so.conf.d/*.conf; then
        #echo "${openssl_location}/lib" > /etc/ld.so.conf.d/openssl111.conf
    #fi
    ldconfig
    _success "${openssl102_filename} install completed..."
    rm -f /tmp/${openssl102_filename}.tar.gz
    rm -fr /tmp/${openssl102_filename}
}

_install_libiconv(){
    if [ ! -e "/usr/local/bin/iconv" ]; then
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
        CheckError "./configure"
        CheckError "parallel_make"
        CheckError "make install"
        ldconfig
        _success "${libiconv_filename} install completed..."
        rm -f /tmp/${libiconv_filename}.tar.gz
        rm -f /tmp/${libiconv_patch_filename}.tar.gz
        rm -f /tmp/${libiconv_patch_filename}.patch
        rm -fr /tmp/${libiconv_filename}
    fi
}

_install_re2c(){
    if [ ! -e "/usr/local/bin/re2c" ]; then
        cd /tmp
        _info "${re2c_filename} install start..."
        DownloadFile "${re2c_filename}.tar.xz" "${re2c_download_url}"
        tar Jxf ${re2c_filename}.tar.xz
        cd ${re2c_filename}
        CheckError "./configure"
        CheckError "make"
        CheckError "make install"
        ldconfig
        _success "${re2c_filename} install completed..."
        rm -f /tmp/${re2c_filename}.tar.xz
        rm -fr /tmp/${re2c_filename}
    fi
}

_install_mhash(){
    if [ ! -e "/usr/local/lib/libmhash.a" ]; then
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
    fi
}

_install_mcrypt(){
    if [ ! -e "/usr/local/bin/mcrypt" ]; then
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
    fi
}

_install_libmcrypt(){
    if [ ! -e "/usr/local/lib/libmcrypt.la" ]; then
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
    fi
}

_install_libzip(){
    if [ ! -e "/usr/lib/libzip.la" ]; then
        cd /tmp
        _info "${libzip_filename} install start..."
        DownloadFile "${libzip_filename}.tar.gz" "${libzip_download_url}"
        tar zxf ${libzip_filename}.tar.gz
        cd ${libzip_filename}
        CheckError "./configure --prefix=/usr"
        CheckError "parallel_make"
        CheckError "make install"
        ldconfig
        _success "${libzip_filename} install completed..."
        rm -f /tmp/${libzip_filename}.tar.gz
        rm -fr /tmp/${libzip_filename}
    fi
}

_config_php(){
    # php.ini
    mkdir -p ${php54_location}/{etc,php.d}
    cp -f php.ini-production ${php54_location}/etc/php.ini

    # disable_functions
    php_disable_functions=`grep "^disable_functions" ${php54_location}/etc/php.ini |wc -l`
    if [[ ${php_disable_functions} -eq 0 ]];then
        echo "disable_functions = system, passthru, exec, chroot, chgrp, chown, proc_get, shell_exec, popen, escapeshellarg, escapeshellcmd, proc_close, proc_open, dl, proc_get_status, ini_alter, ini_alter, ini_restore" >> ${php54_location}/etc/php.ini
    else
        sed -i '/^disable_functions/ s/.*/disable_functions = system, passthru, exec, chroot, chgrp, chown, proc_get, shell_exec, popen, escapeshellarg, escapeshellcmd, proc_close, proc_open, dl, proc_get_status, ini_alter, ini_alter, ini_restore/' ${php54_location}/etc/php.ini
    fi

    # mysqld
    if [[ -d "${mysql_data_location}" ]]; then
        sock_location=/tmp/mysql.sock
        sed -i "s#mysql.default_socket.*#mysql.default_socket = ${sock_location}#" ${php54_location}/etc/php.ini
        sed -i "s#mysqli.default_socket.*#mysqli.default_socket = ${sock_location}#" ${php54_location}/etc/php.ini
        sed -i "s#pdo_mysql.default_socket.*#pdo_mysql.default_socket = ${sock_location}#" ${php54_location}/etc/php.ini
    fi

    # default_charset
    php_default_charset=`grep "^default_charset" ${php54_location}/etc/php.ini |wc -l`
    if [[ ${php_default_charset} -eq 0 ]];then
        echo 'default_charset = "UTF-8"' >> ${php54_location}/etc/php.ini
    else
        sed -i 's/^default_charset.*/default_charset = "UTF-8"/g' ${php54_location}/etc/php.ini
    fi

    # short_open_tag
    short_open_tag=`grep "^short_open_tag" ${php54_location}/etc/php.ini |wc -l`
    if [[ ${short_open_tag} -eq 0 ]];then
        echo 'short_open_tag = On' >> ${php54_location}/etc/php.ini
    else
        sed -i 's/^short_open_tag.*/short_open_tag = On/g' ${php54_location}/etc/php.ini
    fi

    # php-fpm
    cat > ${php54_location}/etc/default.conf<<EOF
[global]
    pid = ${php54_location}/var/run/default.pid
    error_log = ${php54_location}/var/log/default.log
[default]
    security.limit_extensions = .php .php3 .php4 .php5 .php7
    listen = /tmp/${php54_filename}-default.sock
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
    mkdir -p ${php54_location}/var/run
    mkdir -p ${php54_location}/var/log
    ${php54_location}/sbin/php-fpm -y ${php54_location}/etc/default.conf >/dev/null 2>&1

    _warn "Please add the following two lines to your httpd.conf"
    echo AddType application/x-httpd-php .php .phtml
    echo AddType application/x-httpd-php-source .phps
}

install_php54(){
    mkdir -p ${backup_dir}
    if [ -d "${php54_location}" ]; then 
        for pidfile in `ls ${php54_location}/var/run/`
        do
            kill -INT `cat ${php54_location}/var/run/${pidfile}`
        done
        if [ -d "${backup_dir}/${php54_install_path_name}" ]; then
            mv ${backup_dir}/${php54_install_path_name} ${backup_dir}/${php54_install_path_name}-$(date +%Y-%m-%d_%H:%M:%S).bak
        fi
        mv ${php54_location} ${backup_dir}
    fi
    _install_php_depend
    cd /tmp
    _info "Downloading and Extracting ${php54_filename} files..."
    DownloadFile  "${php54_filename}.tar.gz" "${php54_download_url}"
    rm -fr ${php54_filename}
    tar zxf ${php54_filename}.tar.gz
    cd ${php54_filename}
    _info "Install ${php54_filename} ..."
    Is64bit && with_libdir="--with-libdir=lib64" || with_libdir=""
    php_configure_args="--prefix=${php54_location} \
    --with-config-file-path=${php54_location}/etc \
    --with-config-file-scan-dir=${php54_location}/php.d \
    --with-libxml-dir \
    --with-pcre-dir=${pcre_location} \
    --with-openssl=${openssl102_location} \
    ${with_libdir} \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-mysql-sock=/tmp/mysql.sock \
    --with-pdo-mysql=mysqlnd \
    --with-gd \
    --with-jpeg-dir \
    --with-png-dir \
    --with-xpm-dir \
    --with-freetype-dir \
    --with-zlib \
    --with-bz2 \
    --with-curl=${curl_location} \
    --with-gettext \
    --with-gmp \
    --with-mhash \
    --with-icu-dir=/usr \
    --with-libmbfl \
    --with-onig \
    --with-unixODBC \
    --with-pspell=/usr \
    --with-enchant=/usr \
    --with-readline \
    --with-tidy=/usr \
    --with-xmlrpc \
    --with-xsl \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --without-pear \
    --with-mcrypt \
    --enable-gd-native-ttf \
    --enable-mysqlnd \
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
    unset LD_LIBRARY_PATH
    unset CPPFLAGS
    ldconfig
    CheckError "./configure ${php_configure_args}"
    CheckError "parallel_make ZEND_EXTRA_LIBS='-liconv'"
    CheckError "make install"
    #if [ -d "${backup_dir}/${php54_install_path_name}" ]; then
        #if [ -d "${backup_dir}/${php54_install_path_name}/etc" ]; then
            #rm -fr ${php54_location}/etc
            #cp -fr ${backup_dir}/${php54_install_path_name}/etc ${php54_location}
        #fi
        #if [ -d "${backup_dir}/${php54_install_path_name}/php.d" ]; then
            #rm -fr ${php54_location}/php.d
            #cp -fr ${backup_dir}/${php54_install_path_name}/php.d ${php54_location}
        #fi
        #if [ -d "${backup_dir}/${php54_install_path_name}/lib" ]; then
            #rm -fr ${php54_location}/lib
            #cp -fr ${backup_dir}/${php54_install_path_name}/lib ${php54_location}
        #fi
    #else
        _info "Config ${php54_filename}..."
        _config_php
    #fi
    cat >> ${prefix}/install.result <<EOF
php54 Install Path:${php54_location}

EOF
    _success "${php54_filename} install completed..."
    rm -fr /tmp/${php54_filename}
}
