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

install_pma(){
    if [ $# -lt 1 ]; then
        echo "[Parameter Error]: pma_location"
        exit 1
    fi
    pma_location=${1}
    cd /tmp
    CheckError "rm -fr ${phpmyadmin_filename}"
    CheckError "rm -fr ${pma_location}"

    _info "${phpmyadmin_filename} install start..."
    DownloadFile "${phpmyadmin_filename}.tar.gz" "${phpmyadmin_download_url}"

    CheckError "tar zxf ${phpmyadmin_filename}.tar.gz"
    CheckError "mv ${phpmyadmin_filename} ${pma_location}"
    CheckError "mkdir -p ${pma_location}/upload"
    CheckError "mkdir -p ${pma_location}/save"
    CheckError "rm -fr ${pma_location}/setup"

    # 下载配置文件
    DownloadUrl "phpMyAdmin.conf.tar.gz" "${phpmyadmin_conf_download_url}"
    CheckError "tar zxf phpMyAdmin.conf.tar.gz"
    CheckError "rm -f ${pma_location}/config.inc.php"
    CheckError "mv config.inc.php ${pma_location}/config.inc.php"

    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    chown -R www:www ${pma_location} >/dev/null 2>&1

    # 写入配置文件
    write_nginx
    write_apache

    _success "${phpmyadmin_filename} install completed..."
}

write_apache() {
    # 写入phpMyAdmin配置文件
    mkdir -p ${var}/default/wwwlogs/apache
    mkdir -p ${var}/default/wwwconf/apache
    cat > ${var}/default/wwwconf/apache/pma.conf <<EOF
Listen 999
<VirtualHost *:999>
    ServerAdmin webmaster@example.com
    DocumentRoot ${pma_location}
    ServerName phpMyAdmin.999
    ServerAlias localhost
    #errorDocument 404 /404.html
    ErrorLog "${var}/default/wwwlogs/pma-error.log"
    CustomLog "${var}/default/wwwlogs/pma-access.log" combined

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
    <Directory ${pma_location}>
        SetOutputFilter DEFLATE
        Options FollowSymLinks
        AllowOverride All
        <RequireAll>
            Require all granted
        </RequireAll>
        DirectoryIndex index.php default.php index.html index.htm default.html default.htm
    </Directory>
</VirtualHost>
EOF
    /etc/init.d/httpd restart >/dev/null 2>&1
}

write_nginx() {
    # 写入phpMyAdmin配置文件
    mkdir -p ${var}/default/wwwlogs/nginx
    mkdir -p ${var}/default/wwwconf/nginx
    cat > ${var}/default/wwwconf/nginx/pma.conf <<EOF
server {
   listen 999;
   server_name localhost;
   root ${pma_location};
   index index.php default.php index.html index.htm default.html default.htm;
   error_log "${var}/default/wwwlogs/pma-error.log";
   access_log "${var}/default/wwwlogs/pma-access.log";

   #DENY FILES
   location ~ ^/(\.user.ini|\.sql|\.zip|\.gz|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md)
   {
       return 404;
   }

   #PHP
   location ~ \.php\$ {
       fastcgi_pass unix:/tmp/php-5.6.40-default.sock;
       fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
       include fastcgi_params;
   }
}
EOF
    /etc/init.d/nginx restart >/dev/null 2>&1
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    install_pma ${1}
}
echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
