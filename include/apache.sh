_install_apache_depend(){
    _info "Starting to install dependencies packages for Apache..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(libnghttp2-devel libxml2-devel expat-devel pcre-devel openssl-devel zlib-devel)
        for depend in ${yum_depends[@]}
        do
            install_package "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(libnghttp2-dev libxml2-dev libexpat1-dev libpcre3-dev libssl-dev zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            install_package "apt -y install ${depend}"
        done
    fi

    id -u hwswww >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U hwswww -r -d /dev/null -s /sbin/nologin
    _success "Install dependencies packages for Apache completed..."
}

_install_apache(){
    _install_apache_depend 
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${apache_filename} files..."
    download_file "${apache_filename}.tar.gz" ${apache_url}
    rm -fr ${apache_filename}
    tar zxf ${apache_filename}.tar.gz
    _info "Downloading and Extracting ${apr_filename} files..."
    download_file "${apr_filename}.tar.gz" ${apr_url}
    rm -fr ${apr_filename}
    tar zxf ${apr_filename}.tar.gz
    _info "Downloading and Extracting ${apr_util_filename} files..."
    download_file "${apr_util_filename}.tar.gz" ${apr_util_url}
    rm -fr ${apr_util_filename}
    tar zxf ${apr_util_filename}.tar.gz
    cd ${apache_filename}
    mv ${cur_dir}/software/${apr_filename} srclib/apr
    mv ${cur_dir}/software/${apr_util_filename} srclib/apr-util
    _info "Make Install ${apache_filename}..."
    apache_configure_args="--prefix=${apache_location} \
    --bindir=${apache_location}/bin \
    --sbindir=${apache_location}/bin \
    --sysconfdir=${apache_location}/conf \
    --libexecdir=${apache_location}/modules \
    --with-mpm=event \
    --with-included-apr \
    --with-ssl \
    --with-nghttp2 \
    --enable-modules=reallyall \
    --enable-mods-shared=reallyall"
    check_error "./configure ${apache_configure_args}"
    check_error "parallel_make"
    check_error "make install"
    # 写数据库
    sqlite3 "${install_prefix}/hwslinuxmaster.db" <<EOF
PRAGMA foreign_keys = ON;
INSERT INTO hws_webserver (path, name, version, servertype) VALUES ("${apache_location}", "${apache_filename}", "${apache_version}", 1);
UPDATE hws_sysconfig SET value="${apache_filename}" WHERE key="CurrentWebServer";
EOF
    _info "Config ${apache_filename}"
    _config_apache
    ${apache_location}/bin/httpd -t
    _info "Start ${apache_filename}"
    ${apache_location}/bin/apachectl restart > /dev/null 2>&1
    cat >> ${install_prefix}/install.result <<EOF
Apache Install Path: ${apache_location}
Web Root: ${web_root_dir}
Default Site Path: ${default_site_dir}

EOF
    _success "Install ${apache_filename} completed..."
}

_config_apache(){
    [ -f "${apache_location}/conf/httpd.conf" ] && cp -f ${apache_location}/conf/httpd.conf ${apache_location}/conf/httpd.conf.bak
    [ -f "${apache_location}/conf/extra/httpd-vhosts.conf" ] && cp -f ${apache_location}/conf/extra/httpd-vhosts.conf ${apache_location}/conf/extra/httpd-vhosts.conf.bak
    # httpd.conf
    grep -qE "^\s*#\s*Include conf/extra/httpd-vhosts.conf" ${apache_location}/conf/httpd.conf && \
    sed -i 's#^\s*\#\s*Include conf/extra/httpd-vhosts.conf#Include conf/extra/httpd-vhosts.conf#' ${apache_location}/conf/httpd.conf || \
    sed -i '$aInclude conf/extra/httpd-vhosts.conf' ${apache_location}/conf/httpd.conf
    sed -i 's/^User.*/User hwswww/i' ${apache_location}/conf/httpd.conf
    sed -i 's/^Group.*/Group hwswww/i' ${apache_location}/conf/httpd.conf
    sed -i 's/^ServerAdmin you@example.com/ServerAdmin admin@localhost/' ${apache_location}/conf/httpd.conf
    sed -i 's/^#ServerName www.example.com:80/ServerName 0.0.0.0:80/' ${apache_location}/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-info.conf@Include conf/extra/httpd-info.conf@' ${apache_location}/conf/httpd.conf
    #sed -i 's@^#Include conf/extra/httpd-ssl.conf@Include conf/extra/httpd-ssl.conf@' ${apache_location}/conf/httpd.conf
    sed -i 's@DirectoryIndex index.html@DirectoryIndex index.html index.php@' ${apache_location}/conf/httpd.conf
    sed -i "s@^DocumentRoot.*@DocumentRoot \"${default_site_dir}\"@" ${apache_location}/conf/httpd.conf
    sed -i "s@^<Directory \"${apache_location}/htdocs\">@<Directory \"${default_site_dir}\">@" ${apache_location}/conf/httpd.conf
    echo "ServerTokens ProductOnly" >> ${apache_location}/conf/httpd.conf
    echo "ProtocolsHonorOrder On" >> ${apache_location}/conf/httpd.conf
    echo "Protocols h2 http/1.1" >> ${apache_location}/conf/httpd.conf
    cat > /etc/logrotate.d/httpd <<EOF
${apache_location}/logs/*log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${apache_location}/logs/httpd.pid ] || kill -USR1 \`cat ${apache_location}/logs/httpd.pid\`
    endscript
}
EOF
    cat > ${apache_location}/conf/extra/httpd-vhosts.conf <<EOF
IncludeOptional ${apache_location}/conf/vhost/*.conf
EOF
    mkdir -p ${apache_location}/conf/vhost/

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
    # add mod_md to httpd.conf
    if [[ $(grep -Ec "^\s*LoadModule md_module modules/mod_md.so" ${apache_location}/conf/httpd.conf) -eq 0 ]]; then
        if [ -f "${apache_location}/modules/mod_md.so" ]; then
            lnum=$(sed -n '/LoadModule/=' ${apache_location}/conf/httpd.conf | tail -1)
            sed -i "${lnum}aLoadModule md_module modules/mod_md.so" ${apache_location}/conf/httpd.conf
        fi
    fi

    sed -i 's/Require host .example.com/Require host localhost/g' ${apache_location}/conf/extra/httpd-info.conf

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
    chown -R hwswww:hwswww ${web_root_dir}
}

install_apache(){
    _install_apache
}
