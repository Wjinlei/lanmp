_install_php_depend(){
    _info "Starting to install dependencies packages for PHP..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(
            autoconf patch m4 bison bzip2-devel pam-devel gmp-devel libicu-devel
            curl-devel pcre-devel libtool-libs libtool-ltdl-devel libwebp-devel libXpm-devel
            libvpx-devel libjpeg-devel libpng-devel freetype-devel oniguruma-devel
            aspell-devel enchant-devel readline-devel unixODBC-devel libtidy-devel
            openldap-devel libxslt-devel net-snmp net-snmp-devel krb5-devel sqlite-devel
            libiodbc-devel php-odbc zlib-devel libxml2-devel openssl-devel
        )
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
        if yum list | grep "libc-client-devel" > /dev/null 2>&1; then
            InstallPack "yum -y install libc-client-devel"
        elif yum list | grep "uw-imap-devel" > /dev/null 2>&1; then
            InstallPack "yum -y install uw-imap-devel"
        else
            _error "There is no rpm package libc-client-devel or uw-imap-devel, please check it and try again."
        fi
        _install_mhash
        _install_libmcrypt
        _install_mcrypt
        _install_libzip
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(
            autoconf patch m4 bison libbz2-dev libgmp-dev libicu-dev libldb-dev libpam0g-dev
            libldap-2.4-2 libldap2-dev libsasl2-dev libsasl2-modules-ldap libc-client2007e-dev libkrb5-dev
            autoconf2.13 pkg-config libxslt1-dev zlib1g-dev libpcre3-dev libtool unixodbc-dev libtidy-dev
            libjpeg-dev libpng-dev libfreetype6-dev libpspell-dev libmhash-dev libenchant-dev libmcrypt-dev
            libcurl4-gnutls-dev libwebp-dev libxpm-dev libvpx-dev libreadline-dev snmp libsnmp-dev libzip-dev
            libxml2-dev libssl-dev
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

            ln -sf /usr/lib/x86_64-linux-gnu/libldap* /usr/lib64/
            ln -sf /usr/lib/x86_64-linux-gnu/liblber* /usr/lib64/

            if [ -d /usr/include/x86_64-linux-gnu/curl ] && [ ! -d /usr/include/curl ]; then
                ln -sf /usr/include/x86_64-linux-gnu/curl /usr/include/
            fi

            CreateLibLink libc-client.a
            CreateLibLink libc-client.so
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
    _install_pcre
    _install_libiconv
    _install_re2c
    _success "Install dependencies packages for PHP completed..."
    # Fixed unixODBC issue
    if [ -f /usr/include/sqlext.h ] && [ ! -f /usr/local/include/sqlext.h ]; then
        ln -sf /usr/include/sqlext.h /usr/local/include/
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
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
    mkdir -p ${php55_location}/{etc,php.d}
    cp -f php.ini-production ${php55_location}/etc/php.ini

    # disable_functions
    php_disable_functions=`grep "^disable_functions" ${php55_location}/etc/php.ini |wc -l`
    if [[ ${php_disable_functions} -eq 0 ]];then
        echo "disable_functions = system, passthru, exec, chroot, chgrp, chown, proc_get, shell_exec, popen, escapeshellarg, escapeshellcmd, proc_close, proc_open, dl, proc_get_status, ini_alter, ini_alter, ini_restore" >> ${php55_location}/etc/php.ini
    else
        sed -i '/^disable_functions/ s/.*/disable_functions = system, passthru, exec, chroot, chgrp, chown, proc_get, shell_exec, popen, escapeshellarg, escapeshellcmd, proc_close, proc_open, dl, proc_get_status, ini_alter, ini_alter, ini_restore/' ${php55_location}/etc/php.ini
    fi

    # mysqld
    if [[ -d "${mysql_data_location}" ]]; then
        sock_location=/tmp/mysql.sock
        sed -i "s#mysql.default_socket.*#mysql.default_socket = ${sock_location}#" ${php55_location}/etc/php.ini
        sed -i "s#mysqli.default_socket.*#mysqli.default_socket = ${sock_location}#" ${php55_location}/etc/php.ini
        sed -i "s#pdo_mysql.default_socket.*#pdo_mysql.default_socket = ${sock_location}#" ${php55_location}/etc/php.ini
    fi

    # default_charset
    php_default_charset=`grep "^default_charset" ${php55_location}/etc/php.ini |wc -l`
    if [[ ${php_default_charset} -eq 0 ]];then
        echo 'default_charset = "UTF-8"' >> ${php55_location}/etc/php.ini
    else
        sed -i 's/^default_charset.*/default_charset = "UTF-8"/g' ${php55_location}/etc/php.ini
    fi

    # short_open_tag
    short_open_tag=`grep "^short_open_tag" ${php55_location}/etc/php.ini |wc -l`
    if [[ ${short_open_tag} -eq 0 ]];then
        echo 'short_open_tag = On' >> ${php55_location}/etc/php.ini
    else
        sed -i 's/^short_open_tag.*/short_open_tag = On/g' ${php55_location}/etc/php.ini
    fi

    extension_dir=$(${php55_location}/bin/php-config --extension-dir)
    cat > ${php55_location}/php.d/opcache.ini<<EOF
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

    # php-fpm
    cat > ${php55_location}/etc/default.conf<<EOF
[global]
    pid = ${php55_location}/var/run/default.pid
    error_log = ${php55_location}/var/log/default.log
[default]
    security.limit_extensions = .php .php3 .php4 .php5 .php7
    listen = /tmp/${php55_filename}-default.sock
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
    mkdir -p ${php55_location}/var/run
    mkdir -p ${php55_location}/var/log
    ${php55_location}/sbin/php-fpm -y ${php55_location}/etc/default.conf >/dev/null 2>&1

    _warn "Please add the following two lines to your httpd.conf"
    echo AddType application/x-httpd-php .php .phtml
    echo AddType application/x-httpd-php-source .phps
}

install_php55(){
    mkdir -p ${backup_dir}
    if [ -d "${php55_location}" ]; then 
        for pidfile in `ls ${php55_location}/var/run/`
        do
            kill -INT `cat ${php55_location}/var/run/${pidfile}`
        done
        if [ -d "${backup_dir}/${php55_install_path_name}" ]; then
            mv ${backup_dir}/${php55_install_path_name} ${backup_dir}/${php55_install_path_name}-$(date +%Y-%m-%d_%H:%M:%S).bak
        fi
        mv ${php55_location} ${backup_dir}
    fi
    _install_php_depend
    cd /tmp
    _info "Downloading and Extracting ${php55_filename} files..."
    DownloadFile  "${php55_filename}.tar.gz" "${php55_download_url}"
    rm -fr ${php55_filename}
    tar zxf ${php55_filename}.tar.gz
    cd ${php55_filename}
    _info "Install ${php55_filename} ..."
    Is64bit && with_libdir="--with-libdir=lib64" || with_libdir=""
    php_configure_args="--prefix=${php55_location} \
    --with-config-file-path=${php55_location}/etc \
    --with-config-file-scan-dir=${php55_location}/php.d \
    --with-imap \
    --with-kerberos \
    --with-imap-ssl \
    --with-libxml-dir \
    --with-pcre-dir=${pcre_location} \
    --with-openssl \
    --with-snmp \
    ${with_libdir} \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-mysql-sock=/tmp/mysql.sock \
    --with-pdo-mysql=mysqlnd \
    --with-gd \
    --with-vpx-dir \
    --with-jpeg-dir \
    --with-png-dir \
    --with-xpm-dir \
    --with-freetype-dir \
    --with-zlib \
    --with-bz2 \
    --with-curl=/usr \
    --with-gettext \
    --with-gmp \
    --with-mhash \
    --with-icu-dir=/usr \
    --with-ldap \
    --with-ldap-sasl \
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
    #if [ -d "${backup_dir}/${php55_install_path_name}" ]; then
        #if [ -d "${backup_dir}/${php55_install_path_name}/etc" ]; then
            #rm -fr ${php55_location}/etc
            #cp -fr ${backup_dir}/${php55_install_path_name}/etc ${php55_location}
        #fi
        #if [ -d "${backup_dir}/${php55_install_path_name}/php.d" ]; then
            #rm -fr ${php55_location}/php.d
            #cp -fr ${backup_dir}/${php55_install_path_name}/php.d ${php55_location}
        #fi
        #if [ -d "${backup_dir}/${php55_install_path_name}/lib" ]; then
            #rm -fr ${php55_location}/lib
            #cp -fr ${backup_dir}/${php55_install_path_name}/lib ${php55_location}
        #fi
    #else
        _info "Config ${php55_filename}..."
        _config_php
    #fi
    cat >> ${prefix}/install.result <<EOF
php55 Install Path:${php55_location}

EOF
    _success "${php55_filename} install completed..."
    rm -fr /tmp/${php55_filename}
}
