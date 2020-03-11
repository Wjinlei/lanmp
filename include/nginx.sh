_install_nginx_depend(){
    _info "Starting to install dependencies packages for Nginx..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(pcre-devel openssl-devel zlib-devel)
        for depend in ${yum_depends[@]}
        do
            install_package "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(libpcre3-dev libssl-dev zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            install_package "apt -y install ${depend}"
        done
    fi
    id -u hwswww >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U hwswww -r -d /dev/null -s /sbin/nologin
    _success "Install dependencies packages for Nginx completed..."
}

_install_nginx(){
    _install_nginx_depend
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${nginx_filename} files..."
    download_file "${nginx_filename}.tar.gz" ${nginx_url}
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
    --user=hwswww \
    --group=hwswww \
    --with-threads \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_stub_status_module"
    _info "Make Install ${nginx_filename}..."
    check_error "./configure ${nginx_configure_args}"
    check_error "parallel_make"
    check_error "make install"
    sqlite3 "${install_prefix}/hwslinuxmaster.db" <<EOF
PRAGMA foreign_keys = ON;
INSERT INTO hws_webserver (path, name, version, servertype) VALUES ("${nginx_location}", "${nginx_filename}", "${nginx_version}", 2);
UPDATE hws_sysconfig SET value="${nginx_filename}" WHERE key="CurrentWebServer";
EOF
    _info "Config ${nginx_filename}"
    _config_nginx
    _info "Start ${nginx_filename}"
    ${nginx_location}/sbin/nginx -t
    ${nginx_location}/sbin/nginx
    cat >> ${install_prefix}/install.result <<EOF
Nginx Install Path: ${nginx_location}
Web Root: ${web_root_dir}
Default Site Path: ${default_site_dir}

EOF
    _success "Install ${nginx_filename} completed..."
}

_config_nginx(){
    mkdir -p ${nginx_location}/var/{log,run,lock,tmp}
    mkdir -p ${nginx_location}/var/tmp/{client,proxy,fastcgi,uwsgi}
    mkdir -p ${nginx_location}/etc/vhost
    [ -f "${nginx_location}/etc/nginx.conf" ] && mv ${nginx_location}/etc/nginx.conf ${nginx_location}/etc/nginx.conf-$(date +%Y%m%d%H%M%S).bak
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
}

install_nginx(){
    _install_nginx
}
