_install_apache_depend(){
    _info "Starting to install dependencies packages for Apache..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(libxml2-devel expat-devel zlib-devel)
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(libxml2-dev libexpat1-dev zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt-get -y install ${depend}"
        done
    fi
    CheckInstalled "_install_pcre" ${pcre_location}
    CheckInstalled "_install_openssl" ${openssl_location}
    _install_nghttp2

    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin

    mkdir -p ${default_site_dir}
    _success "Install dependencies packages for Apache completed..."
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
    if ! grep -qE "^${openssl_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${openssl_location}/lib" > /etc/ld.so.conf.d/openssl111.conf
    fi
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


install_apache24(){ 
    killall httpd > /dev/null 2>&1
    mkdir -p ${backup_dir}
    if [ -d "${apache24_location}" ]; then 
        if [ -d "${backup_dir}/${apache24_install_path_name}" ]; then
            mv ${backup_dir}/${apache24_install_path_name} ${backup_dir}/${apache24_install_path_name}-$(date +%Y-%m-%d_%H:%M:%S).bak
        fi
        mv ${apache24_location} ${backup_dir}
    fi
    _install_apache_depend 
    cd /tmp
    _info "Downloading and Extracting ${apache24_filename} files..."
    DownloadFile "${apache24_filename}.tar.gz" ${apache24_download_url}
    rm -fr ${apache24_filename}
    tar zxf ${apache24_filename}.tar.gz
    _info "Downloading and Extracting ${apr_filename} files..."
    DownloadFile "${apr_filename}.tar.gz" ${apr_download_url}
    rm -fr ${apr_filename}
    tar zxf ${apr_filename}.tar.gz
    _info "Downloading and Extracting ${apr_util_filename} files..."
    DownloadFile "${apr_util_filename}.tar.gz" ${apr_util_download_url}
    rm -fr ${apr_util_filename}
    tar zxf ${apr_util_filename}.tar.gz
    cd ${apache24_filename}
    mv /tmp/${apr_filename} srclib/apr
    mv /tmp/${apr_util_filename} srclib/apr-util
    _info "Make Install ${apache24_filename}..."
    apache_configure_args="--prefix=${apache24_location} \
    --bindir=${apache24_location}/bin \
    --sbindir=${apache24_location}/bin \
    --sysconfdir=${apache24_location}/conf \
    --libexecdir=${apache24_location}/modules \
    --with-pcre=${pcre_location} \
    --with-ssl=${openssl_location} \
    --with-nghttp2=${nghttp2_location} \
    --with-mpm=event \
    --with-included-apr \
    --enable-modules=reallyall \
    --enable-mods-shared=reallyall"
    LDFLAGS=-ldl
    CheckError "./configure ${apache_configure_args}"
    CheckError "parallel_make"
    CheckError "make install"
    unset LDFLAGS
    if [ -d "${backup_dir}/${apache24_install_path_name}" ]; then
        if [ -d "${backup_dir}/${apache24_install_path_name}/conf" ]; then
            rm -fr ${apache24_location}/conf
            cp -fr ${backup_dir}/${apache24_install_path_name}/conf ${apache24_location}
        fi
    else
        _info "Config ${apache24_filename}"
        _config_apache
    fi
    ${apache24_location}/bin/httpd -t
    _info "Start ${apache24_filename}"
    ${apache24_location}/bin/apachectl restart > /dev/null 2>&1
    _success "${apache24_filename} install completed..."
    cat >> ${prefix}/install.result <<EOF
Install Time: $(date +%Y-%m-%d_%H:%M:%S)
Apache24 Install Path:${apache24_location}
WwwRootDir:${wwwroot_dir}

EOF
    rm -f /tmp/${apr_filename}.tar.gz
    rm -f /tmp/${apr_util_filename}.tar.gz
    rm -f /tmp/${apache24_filename}.tar.gz
    rm -fr /tmp/${apache24_filename}
}

_config_apache(){
    [ -f "${apache24_location}/conf/httpd.conf" ] && cp -f ${apache24_location}/conf/httpd.conf ${apache24_location}/conf/httpd.conf.bak
    [ -f "${apache24_location}/conf/extra/httpd-vhosts.conf" ] && cp -f ${apache24_location}/conf/extra/httpd-vhosts.conf ${apache24_location}/conf/extra/httpd-vhosts.conf.bak
    # httpd.conf
    grep -qE "^\s*#\s*Include conf/extra/httpd-vhosts.conf" ${apache24_location}/conf/httpd.conf && \
    sed -i 's#^\s*\#\s*Include conf/extra/httpd-vhosts.conf#Include conf/extra/httpd-vhosts.conf#' ${apache24_location}/conf/httpd.conf || \
    sed -i '$aInclude conf/extra/httpd-vhosts.conf' ${apache24_location}/conf/httpd.conf
    sed -i 's/^User.*/User www/i' ${apache24_location}/conf/httpd.conf
    sed -i 's/^Group.*/Group www/i' ${apache24_location}/conf/httpd.conf
    sed -i 's/^ServerAdmin you@example.com/ServerAdmin admin@localhost/' ${apache24_location}/conf/httpd.conf
    sed -i 's/^#ServerName www.example.com:80/ServerName 0.0.0.0:80/' ${apache24_location}/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-info.conf@Include conf/extra/httpd-info.conf@' ${apache24_location}/conf/httpd.conf
    sed -i 's@DirectoryIndex index.html@DirectoryIndex index.html index.php@' ${apache24_location}/conf/httpd.conf
    sed -i "s@^DocumentRoot.*@DocumentRoot \"${default_site_dir}\"@" ${apache24_location}/conf/httpd.conf
    sed -i "s@^<Directory \"${apache24_location}/htdocs\">@<Directory \"${default_site_dir}\">@" ${apache24_location}/conf/httpd.conf
    echo "ServerTokens ProductOnly" >> ${apache24_location}/conf/httpd.conf
    echo "ProtocolsHonorOrder On" >> ${apache24_location}/conf/httpd.conf
    echo "Protocols h2 http/1.1" >> ${apache24_location}/conf/httpd.conf
    sed -i 's/Require host .example.com/Require host localhost/g' ${apache24_location}/conf/extra/httpd-info.conf
    sed -i "s@AddType\(.*\)Z@AddType\1Z\n    AddType application/x-httpd-php .php .phtml\n    AddType application/x-httpd-php-source .phps@" ${apache24_location}/conf/httpd.conf
    sed -i "s@^export LD_LIBRARY_PATH.*@export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${openssl_location}/lib@" ${apache24_location}/bin/envvars
    cat > ${apache24_location}/conf/extra/httpd-vhosts.conf <<EOF
IncludeOptional ${apache24_location}/conf/vhost/*.conf
EOF
    mkdir -p ${apache24_location}/conf/vhost/
    cat > ${apache24_location}/conf/extra/httpd-ssl.conf <<EOF
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
        if [ -s "${apache24_location}/modules/${mod}" ]; then
            sed -i -r "s/^#(.*${mod})/\1/" ${apache24_location}/conf/httpd.conf
        fi
    done
    chown -R www:www ${wwwroot_dir}
}
