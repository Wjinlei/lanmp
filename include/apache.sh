_install_apache_depend(){
    _info "Starting to install dependencies packages for Apache..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(python2-devel expat-devel zlib-devel)
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(python-dev libexpat1-dev zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt-get -y install ${depend}"
        done
    fi
    CheckInstalled "_install_pcre" ${pcre_location}
    CheckInstalled "_install_openssl" ${openssl_location}
    _install_nghttp2
    _install_icu4c
    _install_libxml2
    _install_curl

    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    mkdir -p ${wwwroot_dir}
    _success "Install dependencies packages for Apache completed..."
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
    CheckError "./configure --prefix=${curl_location} --with-ssl=${openssl_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${curl_location}"
    CreateLib64Dir "${curl_location}"
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
    _info "${openssl_filename} install start..."
    rm -fr ${openssl_filename}
    DownloadFile "${openssl_filename}.tar.gz" "${openssl_download_url}"
    tar zxf ${openssl_filename}.tar.gz
    cd ${openssl_filename}
    CheckError "./config --prefix=${openssl_location} -fPIC shared zlib"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${openssl_location}"
    CreateLib64Dir "${openssl_location}"
    ldconfig
    _success "${openssl_filename} install completed..."
    rm -f /tmp/${openssl_filename}.tar.gz
    rm -fr /tmp/${openssl_filename}
}

_install_nghttp2(){
    cd /tmp
    _info "${nghttp2_filename} install start..."
    rm -fr ${nghttp2_filename}
    DownloadFile "${nghttp2_filename}.tar.gz" "${nghttp2_download_url}"
    tar zxf ${nghttp2_filename}.tar.gz
    cd ${nghttp2_filename}
    if [ -d "${openssl_location}" ]; then
        export OPENSSL_CFLAGS="-I${openssl_location}/include"
        export OPENSSL_LIBS="-L${openssl_location}/lib -lssl -lcrypto"
    fi
    CheckError "./configure --prefix=${nghttp2_location} --enable-lib-only"
    CheckError "parallel_make"
    CheckError "make install"
    unset OPENSSL_CFLAGS OPENSSL_LIBS
    AddToEnv "${nghttp2_location}"
    CreateLib64Dir "${nghttp2_location}"
    if ! grep -qE "^${nghttp2_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${nghttp2_location}/lib" > /etc/ld.so.conf.d/nghttp2.conf
    fi
    ldconfig
    _success "${nghttp2_filename} install completed..."
    rm -f /tmp/${nghttp2_filename}.tar.gz
    rm -fr /tmp/${nghttp2_filename}
}


install_apache(){
    if [ $# -lt 2 ]; then
        echo "[ERROR]: Missing parameters: [apache_location] [wwwroot_dir]"
        exit 1
    fi
    apache_location=${1}
    wwwroot_dir=${2}
    service httpd stop > /dev/null 2>&1
    mkdir -p ${backup_dir}
    mv -f ${apache_location} ${backup_dir}/apache-$(date +%Y-%m-%d_%H:%M:%S).bak

    _install_apache_depend
    cd /tmp
    _info "Downloading and Extracting ${apache_filename} files..."
    DownloadFile "${apache_filename}.tar.gz" ${apache_download_url}
    rm -fr ${apache_filename}
    tar zxf ${apache_filename}.tar.gz
    _info "Downloading and Extracting ${apr_filename} files..."
    DownloadFile "${apr_filename}.tar.gz" ${apr_download_url}
    rm -fr ${apr_filename}
    tar zxf ${apr_filename}.tar.gz
    _info "Downloading and Extracting ${apr_util_filename} files..."
    DownloadFile "${apr_util_filename}.tar.gz" ${apr_util_download_url}
    rm -fr ${apr_util_filename}
    tar zxf ${apr_util_filename}.tar.gz
    cd ${apache_filename}
    mv /tmp/${apr_filename} srclib/apr
    mv /tmp/${apr_util_filename} srclib/apr-util
    _info "Make Install ${apache_filename}..."
    apache_configure_args="--prefix=${apache_location} \
    --bindir=${apache_location}/bin \
    --sbindir=${apache_location}/bin \
    --sysconfdir=${apache_location}/conf \
    --libexecdir=${apache_location}/modules \
    --with-pcre=${pcre_location} \
    --with-ssl=${openssl_location} \
    --with-nghttp2=${nghttp2_location} \
    --with-libxml2=${libxml2_location} \
    --with-curl=${curl_location} \
    --with-mpm=event \
    --with-included-apr \
    --enable-modules=reallyall \
    --enable-mods-shared=reallyall"
    LDFLAGS=-ldl
    CheckError "./configure ${apache_configure_args}"
    CheckError "parallel_make"
    CheckError "make install"
    unset LDFLAGS
    _info "Config ${apache_filename}"
    _config_apache

    # 下载服务脚本
    wget --no-check-certificate -cv -t3 -T60 -O /etc/init.d/httpd ${download_sysv_url}/httpd
    if [ "$?" == 0 ]; then
        sed -i "s|^prefix={apache_location}$|prefix=${apache_location}|i" /etc/init.d/httpd
        sed -i "s|{openssl_location_lib}|${openssl_location}/lib|i" /etc/init.d/httpd
        chmod +x /etc/init.d/httpd
        chkconfig --add httpd > /dev/null 2>&1
        update-rc.d -f httpd defaults > /dev/null 2>&1
        service httpd start
    else
        _info "Start ${apache_filename}"
        ${apache_location}/bin/apachectl start
    fi

    _success "${apache_filename} install completed..."
    cat >> ${prefix}/install.result <<EOF
Install Time: $(date +%Y-%m-%d_%H:%M:%S)
Apache Install Path:${apache_location}
Apache Www Root Dir:${wwwroot_dir}

EOF
    rm -fr /tmp/${apache_filename}
}

_config_apache(){
    [ -f "${apache_location}/conf/httpd.conf" ] && cp -f ${apache_location}/conf/httpd.conf ${apache_location}/conf/httpd.conf.bak
    [ -f "${apache_location}/conf/extra/httpd-vhosts.conf" ] && cp -f ${apache_location}/conf/extra/httpd-vhosts.conf ${apache_location}/conf/extra/httpd-vhosts.conf.bak
    # httpd.conf
    grep -qE "^\s*#\s*Include conf/extra/httpd-vhosts.conf" ${apache_location}/conf/httpd.conf && \
    sed -i 's#^\s*\#\s*Include conf/extra/httpd-vhosts.conf#Include conf/extra/httpd-vhosts.conf#' ${apache_location}/conf/httpd.conf || \
    sed -i '$aInclude conf/extra/httpd-vhosts.conf' ${apache_location}/conf/httpd.conf
    sed -i 's/^User.*/User www/i' ${apache_location}/conf/httpd.conf
    sed -i 's/^Group.*/Group www/i' ${apache_location}/conf/httpd.conf
    sed -i 's/^ServerAdmin you@example.com/ServerAdmin admin@localhost/' ${apache_location}/conf/httpd.conf
    sed -i 's/^#ServerName www.example.com:80/ServerName 0.0.0.0:80/' ${apache_location}/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-default.conf@Include conf/extra/httpd-default.conf@' ${apache_location}/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-info.conf@Include conf/extra/httpd-info.conf@' ${apache_location}/conf/httpd.conf
    sed -i 's@DirectoryIndex index.html@DirectoryIndex index.php default.php index.html index.htm default.html default.htm@' ${apache_location}/conf/httpd.conf
    sed -i 's/Require all granted/Require all denied/g' ${apache_location}/conf/httpd.conf
    #echo "ServerTokens ProductOnly" >> ${apache_location}/conf/httpd.conf
    #echo "ProtocolsHonorOrder On" >> ${apache_location}/conf/httpd.conf
    #echo "Protocols h2 http/1.1" >> ${apache_location}/conf/httpd.conf
    sed -i 's/Require host .example.com/Require host localhost/g' ${apache_location}/conf/extra/httpd-info.conf
    sed -i "s@AddType\(.*\)Z@AddType\1Z\n    AddType application/x-httpd-php .php .phtml\n    AddType application/x-httpd-php-source .phps@" ${apache_location}/conf/httpd.conf
    sed -i "s@^export LD_LIBRARY_PATH.*@export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${openssl_location}/lib@" ${apache_location}/bin/envvars
    mkdir -p ${apache_location}/conf/vhost/
    cat > ${apache_location}/conf/extra/httpd-ssl.conf <<EOF
Listen 443
AddType application/x-x509-ca-cert .crt
AddType application/x-pkcs7-crl .crl
SSLPassPhraseDialog  builtin
SSLSessionCache  "shmcb:logs/ssl_scache(512000)"
SSLSessionCacheTimeout  300
SSLUseStapling On
SSLStaplingCache "shmcb:logs/ssl_stapling(512000)"
SSLProtocol -All +TLSv1.2 +TLSv1.3
SSLProxyProtocol -All +TLSv1.2 +TLSv1.3
SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!CAMELLIA:!AES128
SSLProxyCipherSuite HIGH:!aNULL:!MD5:!3DES:!CAMELLIA:!AES128
SSLHonorCipherOrder on
SSLCompression off
Mutex sysvsem default
SSLStrictSNIVHostCheck on
EOF
    cat > /etc/logrotate.d/hws_apache_log <<EOF
${apache_location}/logs/*log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${apache_location}/logs/httpd.pid ] || kill -USR1 \`cat ${apache_location}/logs/httpd.pid\`
    endscript
}
EOF
    cat > /etc/logrotate.d/hws_apache_site_log <<EOF
${wwwroot_dir}/*/log/*log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${apache_location}/logs/httpd.pid ] || kill -USR1 \`cat ${apache_location}/logs/httpd.pid\`
    endscript
}
EOF
# httpd modules array
httpd_mod_list=(
mod_actions.so
mod_auth_digest.so
mod_auth_form.so
mod_authn_anon.so
mod_authn_dbd.so
mod_authn_dbm.so
mod_authn_socache.so
mod_authnz_fcgi.so
mod_authz_dbd.so
mod_authz_dbm.so
mod_authz_owner.so
mod_buffer.so
mod_cache.so
mod_cache_socache.so
mod_case_filter.so
mod_case_filter_in.so
mod_charset_lite.so
mod_data.so
mod_dav.so
mod_dav_fs.so
mod_dav_lock.so
mod_deflate.so
mod_echo.so
mod_expires.so
mod_ext_filter.so
mod_http2.so
mod_include.so
mod_info.so
mod_proxy.so
mod_proxy_connect.so
mod_proxy_fcgi.so
mod_proxy_ftp.so
mod_proxy_html.so
mod_proxy_http.so
mod_proxy_http2.so
mod_proxy_scgi.so
mod_ratelimit.so
mod_reflector.so
mod_request.so
mod_rewrite.so
mod_sed.so
mod_session.so
mod_session_cookie.so
mod_socache_dbm.so
mod_socache_memcache.so
mod_socache_shmcb.so
mod_speling.so
mod_ssl.so
mod_substitute.so
mod_suexec.so
mod_unique_id.so
mod_userdir.so
mod_vhost_alias.so
mod_xml2enc.so
)
    # enable some modules by default
    for mod in ${httpd_mod_list[@]}; do
        if [ -s "${apache_location}/modules/${mod}" ]; then
            sed -i -r "s/^#(.*${mod})/\1/" ${apache_location}/conf/httpd.conf
        fi
    done

    # 写入phpMyAdmin配置文件
    cat > ${apache_location}/conf/extra/httpd-vhosts.conf <<EOF
Listen 999
<VirtualHost *:999>
    ServerAdmin webmaster@example.com
    DocumentRoot ${prefix}/default/pma
    ServerName phpMyAdmin.999
    ServerAlias localhost
    #errorDocument 404 /404.html
    ErrorLog "${prefix}/default/pma/pma-error.log"
    CustomLog "${prefix}/default/pma/pma-access.log" combined

    #DENY FILES
    <Files ~ (\.user.ini|\.sql|\.zip|\.gz|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md)\$>
        Order allow,deny
        Deny from all
    </Files>

    #PHP
    <FilesMatch \.php\$>
        SetHandler "proxy:unix:/tmp/php-5.6.40-default.sock|fcgi://localhost"
    </FilesMatch>

    #PATH
    <Directory ${prefix}/default/pma>
        SetOutputFilter DEFLATE
        Options FollowSymLinks
        AllowOverride All
        <RequireAll>
            Require all granted
        </RequireAll>
        DirectoryIndex index.php default.php index.html index.htm default.html default.htm
    </Directory>
</VirtualHost>

IncludeOptional ${apache_location}/conf/vhost/*.conf

<VirtualHost *:80>
    ServerAlias *
    <Location />
        Require all denied
    </Location>
</VirtualHost>
EOF
    mkdir -p ${prefix}/default/pma
    cat > ${prefix}/default/pma/index.html <<EOF
<h1>尚未安装phpMyAdmin，请先返回安装<h1>
EOF
    chown -R www:www ${prefix}/default
    chown -R www:www ${wwwroot_dir}
    chown -R www:www ${apache_location}
}
