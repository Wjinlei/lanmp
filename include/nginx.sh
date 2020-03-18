_install_nginx_depend(){
    _info "Starting to install dependencies packages for Nginx..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(zlib-devel)
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt-get -y install ${depend}"
        done
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    mkdir -p ${wwwroot_dir}
    _success "Install dependencies packages for Nginx completed..."
}

install_nginx(){
    killall nginx > /dev/null 2>&1
    mkdir -p ${backup_dir}
    if [ -d "${nginx_location}" ]; then 
        if [ -d "${backup_dir}/${nginx_install_path_name}" ]; then
            mv ${backup_dir}/${nginx_install_path_name} ${backup_dir}/${nginx_install_path_name}-$(date +%Y-%m-%d_%H:%M:%S).bak
        fi
        mv ${nginx_location} ${backup_dir}
    fi
    _install_nginx_depend
    cd /tmp
    _info "Downloading and Extracting ${pcre_filename} files..."
    DownloadFile "${pcre_filename}.tar.gz" ${pcre_download_url}
    rm -fr ${pcre_filename}
    tar zxf ${pcre_filename}.tar.gz
    _info "Downloading and Extracting ${openssl_filename} files..."
    DownloadFile "${openssl_filename}.tar.gz" ${openssl_download_url}
    rm -fr ${openssl_filename}
    tar zxf ${openssl_filename}.tar.gz
    _info "Downloading and Extracting ${nginx_filename} files..."
    DownloadFile "${nginx_filename}.tar.gz" ${nginx_download_url}
    rm -fr ${nginx_filename}
    tar zxf ${nginx_filename}.tar.gz
    cd ${nginx_filename}
    nginx_configure_args="--prefix=${nginx_location} \
    --conf-path=${nginx_location}/etc/nginx.conf \
    --error-log-path=${nginx_location}/var/log/error.log \
    --pid-path=${nginx_location}/var/run/nginx.pid \
    --lock-path=${nginx_location}/var/lock/nginx.lock \
    --http-log-path=${nginx_location}/var/log/access.log \
    --http-client-body-temp-path=${nginx_location}/var/tmp/client \
    --http-proxy-temp-path=${nginx_location}/var/tmp/proxy \
    --http-fastcgi-temp-path=${nginx_location}/var/tmp/fastcgi \
    --http-uwsgi-temp-path=${nginx_location}/var/tmp/uwsgi \
    --http-scgi-temp-path=${nginx_location}/var/tmp/scgi \
    --with-pcre=/tmp/${pcre_filename} \
    --with-openssl=/tmp/${openssl_filename} \
    --user=www \
    --group=www \
    --with-threads \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_stub_status_module"
    _info "Make Install ${nginx_filename}..."
    CheckError "./configure ${nginx_configure_args}"
    CheckError "parallel_make"
    CheckError "make install"
    if [ -d "${backup_dir}/${nginx_install_path_name}" ]; then
        if [ -d "${backup_dir}/${nginx_install_path_name}/etc" ]; then
            rm -fr ${nginx_location}/etc
            cp -fr ${backup_dir}/${nginx_install_path_name}/etc ${nginx_location}
        fi
    else
        _info "Config ${nginx_filename}"
        _config_nginx
    fi
    _info "Start ${nginx_filename}"
    ${nginx_location}/sbin/nginx -t
    ${nginx_location}/sbin/nginx >/dev/null 2>&1
    _success "${nginx_filename} install completed..."
    cat >> ${prefix}/install.result <<EOF
Install Time: $(date +%Y-%m-%d_%H:%M:%S)
Nginx Install Path:${nginx_location}
Nginx Www Root Dir:${wwwroot_dir}

EOF
    rm -f /tmp/${pcre_filename}.tar.gz
    rm -f /tmp/${openssl_filename}.tar.gz
    rm -f /tmp/${nginx_filename}.tar.gz
    rm -fr /tmp/${pcre_filename}
    rm -fr /tmp/${openssl_filename}
    rm -fr /tmp/${nginx_filename}
}

_config_nginx(){
    mkdir -p ${nginx_location}/var/{log,run,lock,tmp}
    mkdir -p ${nginx_location}/var/tmp/{client,proxy,fastcgi,uwsgi}
    mkdir -p ${nginx_location}/etc/vhost
    [ -f "${nginx_location}/etc/nginx.conf" ] && mv ${nginx_location}/etc/nginx.conf ${nginx_location}/etc/nginx.conf-$(date +%Y-%m-%d_%H:%M:%S).bak
    cat > ${nginx_location}/etc/nginx.conf <<EOF
worker_processes 2;

events {
    use epoll;
    worker_connections 2048;
}

http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    # include virtual host config
    include vhost/*.conf;

    # gzip
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/javascript application/json application/javascript application/x-javascript application/xml;
    gzip_vary on;

    # http_proxy
    client_max_body_size 10m;
    client_body_buffer_size 128k;
    proxy_connect_timeout 75;
    proxy_send_timeout 75;
    proxy_read_timeout 75;
    proxy_buffer_size 4k;
    proxy_buffers 4 32k;
    proxy_busy_buffers_size 64k;
    proxy_temp_file_write_size 64k;

    # hidden version
    server_tokens off;
}
EOF
    cat > /etc/logrotate.d/hws_nginx_log <<EOF
${nginx_location}/logs/*log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${nginx_location}/var/run/nginx.pid ] || kill -USR1 \`cat ${nginx_location}/var/run/nginx.pid\`
    endscript
}
EOF
    cat > /etc/logrotate.d/hws_nginx_site_log <<EOF
${wwwroot_dir}/*/log/*log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${nginx_location}/var/run/nginx.pid ] || kill -USR1 \`cat ${nginx_location}/var/run/nginx.pid\`
    endscript
}
EOF
    chown -R www:www ${wwwroot_dir}
}
