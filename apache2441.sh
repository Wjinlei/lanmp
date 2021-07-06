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
    CheckInstalled "_install_openssl102" ${openssl102_location}
    CheckInstalled "_install_nghttp2" ${nghttp2_location}
    CheckInstalled "_install_icu4c" ${icu4c_location}
    CheckInstalled "_install_libxml2" ${libxml2_location}
    CheckInstalled "_install_curl" ${curl102_location}

    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    mkdir -p ${apache_location} > /dev/null 2>&1
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
    if ! grep -qE "^${openssl102_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${openssl102_location}/lib" > /etc/ld.so.conf.d/openssl102.conf
    fi
    ldconfig

    _success "${openssl102_filename} install completed..."
    rm -f /tmp/${openssl102_filename}.tar.gz
    rm -fr /tmp/${openssl102_filename}
}

_install_nghttp2(){
    cd /tmp
    _info "${nghttp2_filename} install start..."
    rm -fr ${nghttp2_filename}
    DownloadFile "${nghttp2_filename}.tar.gz" "${nghttp2_download_url}"
    tar zxf ${nghttp2_filename}.tar.gz
    cd ${nghttp2_filename}
    if [ -d "${openssl102_location}" ]; then
        export OPENSSL_CFLAGS="-I${openssl102_location}/include"
        export OPENSSL_LIBS="-L${openssl102_location}/lib -lssl -lcrypto"
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

_create_logrotate_file(){
    # 定期清理日志
    cat > /etc/logrotate.d/apache-logs <<EOF
${apache_location}/logs/*.log {
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
    cat > /etc/logrotate.d/apache-wwwlogs <<EOF
${var}/default/wwwlogs/*.log {
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

${var}/default/wwwlogs/apache/*.log {
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

${var}/wwwlogs/*.log {
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
}

_create_sysv_script(){
    cat > /etc/init.d/httpd <<'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: apache service script

### BEGIN INIT INFO
# Provides:          apache
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: apache
# Description:       apache service script
### END INIT INFO

prefix={apache_location}

NAME=httpd
PID_FILE=$prefix/logs/$NAME.pid
BIN=$prefix/bin/$NAME
CONFIG_FILE=$prefix/conf/$NAME.conf
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:{openssl_location_lib}

start()
{
    echo -n "Starting $NAME..."
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid `pidof $NAME`) already running."
            exit 1
        fi
    fi
    $BIN -k start
    if [ "$?" != 0 ] ; then
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
    $BIN -k stop
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

restart(){
    echo -n "Restarting $NAME..."
    $BIN -k restart
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

reload() {
    echo -n "Reload service $NAME... "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            $BIN -k graceful
            echo " done"
        else
            echo "$NAME is not running, can't reload."
            exit 1
        fi
    else
        echo "$NAME is not running, can't reload."
        exit 1
    fi
}

status(){
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid `pidof $NAME`) is running."
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

configtest() {
    echo "Test $NAME configure files... "
    $BIN -t
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
    test)
        configtest
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status|test}"
esac
EOF
    sed -i "s|^prefix={apache_location}$|prefix=${apache_location}|g" /etc/init.d/httpd
    sed -i "s|{openssl102_location_lib}|${openssl102_location}/lib|g" /etc/init.d/httpd
}

_config_apache(){
    [ -f "${apache_location}/conf/httpd.conf" ] && cp -f ${apache_location}/conf/httpd.conf ${apache_location}/conf/httpd.conf.bak
    [ -f "${apache_location}/conf/extra/httpd-vhosts.conf" ] && cp -f ${apache_location}/conf/extra/httpd-vhosts.conf ${apache_location}/conf/extra/httpd-vhosts.conf.bak
    # httpd.conf
    grep -qE "^\s*#\s*Include conf/extra/httpd-vhosts.conf" ${apache_location}/conf/httpd.conf && \
    sed -i 's#^\s*\#\s*Include conf/extra/httpd-vhosts.conf#Include conf/extra/httpd-vhosts.conf#' ${apache_location}/conf/httpd.conf || \
    sed -i '$aInclude conf/extra/httpd-vhosts.conf' ${apache_location}/conf/httpd.conf
    sed -i 's/^User.*/User www/g' ${apache_location}/conf/httpd.conf
    sed -i 's/^Group.*/Group www/g' ${apache_location}/conf/httpd.conf
    sed -i 's/^ServerAdmin you@example.com/ServerAdmin admin@localhost/' ${apache_location}/conf/httpd.conf
    sed -i "s/^#ServerName www.example.com:80/ServerName 0.0.0.0:80/g" ${apache_location}/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-default.conf@Include conf/extra/httpd-default.conf@' ${apache_location}/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-info.conf@Include conf/extra/httpd-info.conf@' ${apache_location}/conf/httpd.conf
    sed -i 's@DirectoryIndex index.html@DirectoryIndex index.php default.php index.html index.htm default.html default.htm@' ${apache_location}/conf/httpd.conf
    sed -i 's/Require all granted/Require all denied/g' ${apache_location}/conf/httpd.conf
    sed -i 's/Require host .example.com/Require host localhost/g' ${apache_location}/conf/extra/httpd-info.conf
    sed -i "s@AddType\(.*\)Z@AddType\1Z\n    AddType application/x-httpd-php .php .phtml\n    AddType application/x-httpd-php-source .phps@" ${apache_location}/conf/httpd.conf
    sed -i "s@^export LD_LIBRARY_PATH.*@export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${openssl102_location}/lib@" ${apache_location}/bin/envvars
    mkdir -p ${apache_location}/conf/vhost/
    #cat > ${apache_location}/conf/extra/httpd-ssl.conf <<EOF
#Listen 443
#AddType application/x-x509-ca-cert .crt
#AddType application/x-pkcs7-crl .crl
#SSLPassPhraseDialog  builtin
#SSLSessionCache  "shmcb:logs/ssl_scache(512000)"
#SSLSessionCacheTimeout  300
#SSLUseStapling On
#SSLStaplingCache "shmcb:logs/ssl_stapling(512000)"
#SSLProtocol -All +TLSv1.2 +TLSv1.3
#SSLProxyProtocol -All +TLSv1.2 +TLSv1.3
#SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!CAMELLIA:!AES128
#SSLProxyCipherSuite HIGH:!aNULL:!MD5:!3DES:!CAMELLIA:!AES128
#SSLHonorCipherOrder on
#SSLCompression off
#Mutex sysvsem default
#SSLStrictSNIVHostCheck on
#EOF

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

    # 写入默认配置文件
    cat > ${apache_location}/conf/extra/httpd-vhosts.conf <<EOF
IncludeOptional ${apache_location}/conf/vhost/*.conf
IncludeOptional ${var}/default/wwwconf/apache/*.conf
IncludeOptional ${var}/wwwconf/apache/*.conf

# 对默认端口,防止范解析攻击
<VirtualHost *:80>
    ServerAlias *
    <Location />
        Require all denied
    </Location>
</VirtualHost>
EOF
    # 授权
    mkdir -p ${var}/wwwlogs
    mkdir -p ${var}/wwwconf/apache
    mkdir -p ${var}/default/wwwlogs
    mkdir -p ${var}/default/wwwconf/apache
    chown -R www:www ${apache_location}
}

install_apache2441(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: apache_location"
        exit 1
    fi
    apache_location=${1}

    _install_apache_depend

    CheckError "rm -fr ${apache_location}"
    cd /tmp
    _info "Downloading and Extracting ${apache2441_filename} files..."
    DownloadFile "${apache2441_filename}.tar.gz" ${apache2441_download_url}
    rm -fr ${apache2441_filename}
    tar zxf ${apache2441_filename}.tar.gz
    _info "Downloading and Extracting ${apr_filename} files..."
    DownloadFile "${apr_filename}.tar.gz" ${apr_download_url}
    rm -fr ${apr_filename}
    tar zxf ${apr_filename}.tar.gz
    _info "Downloading and Extracting ${apr_util_filename} files..."
    DownloadFile "${apr_util_filename}.tar.gz" ${apr_util_download_url}
    rm -fr ${apr_util_filename}
    tar zxf ${apr_util_filename}.tar.gz
    cd ${apache2441_filename}
    mv /tmp/${apr_filename} srclib/apr
    mv /tmp/${apr_util_filename} srclib/apr-util
    _info "Make Install ${apache2441_filename}..."
    apache_configure_args="--prefix=${apache_location} \
    --bindir=${apache_location}/bin \
    --sbindir=${apache_location}/bin \
    --sysconfdir=${apache_location}/conf \
    --libexecdir=${apache_location}/modules \
    --with-pcre=${pcre_location} \
    --with-ssl=${openssl102_location} \
    --with-nghttp2=${nghttp2_location} \
    --with-libxml2=${libxml2_location} \
    --with-curl=${curl102_location} \
    --with-mpm=event \
    --with-included-apr \
    --enable-modules=reallyall \
    --enable-mods-shared=reallyall"
    LDFLAGS=-ldl
    CheckError "./configure ${apache_configure_args}"
    CheckError "parallel_make"
    CheckError "make install"
    unset LDFLAGS
    # Config
    _info "Config ${apache2441_filename}"
    _create_logrotate_file
    _config_apache
    # Start
    _create_sysv_script
    chmod +x /etc/init.d/httpd
    update-rc.d -f httpd defaults > /dev/null 2>&1
    chkconfig --add httpd > /dev/null 2>&1
    /etc/init.d/httpd start
    # Clean
    rm -fr /tmp/${apache2441_filename}
    _success "${apache2441_filename} install completed..."
}

rpminstall_apache2441(){
    _GetRPMArch
    rpm_package_name="httpd-2.4.41-1.${RPMArch}.x86_64.rpm"
    apache_location=/hws.com/hwsmaster/server/apache-2_4_41
    _install_apache_depend
    DownloadUrl ${rpm_package_name} ${download_root_url}/rpms/${rpm_package_name}
    CheckError "rpm -ivh ${rpm_package_name} --force --nodeps"
    _config_apache
    /etc/init.d/httpd restart
}

debinstall_apache2441(){
    deb_package_name="httpd-2.4.41-linux-amd64.deb"
    _install_apache_depend
    DownloadUrl ${deb_package_name} ${download_root_url}/debs/${deb_package_name}
    CheckError "dpkg --force-depends -i ${deb_package_name}"
    mkdir -p ${var}/wwwlogs
    mkdir -p ${var}/wwwconf/apache
    mkdir -p ${var}/default/wwwlogs
    mkdir -p ${var}/default/wwwconf/apache
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
            install_apache2441 ${2}
            ;;
        -pm|--pm-install)
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
            if [ ${PM} == "yum" ]; then
                rpminstall_apache2441
            else
                debinstall_apache2441
            fi
            ;;
        *)
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
            install_apache2441 ${1}
            ;;
    esac
}

echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
