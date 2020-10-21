install_pma(){
    cd /tmp
    CheckError "rm -fr ${phpmyadmin_filename}"
    CheckError "rm -fr ${var}/pma"

    _info "${phpmyadmin_filename} install start..."
    DownloadFile "${phpmyadmin_filename}.tar.gz" "${phpmyadmin_download_url}"

    CheckError "tar zxf ${phpmyadmin_filename}.tar.gz"
    CheckError "mv ${phpmyadmin_filename} ${var}/pma"
    CheckError "mkdir -p ${var}/pma/upload"
    CheckError "mkdir -p ${var}/pma/save"
    CheckError "rm -fr ${var}/pma/setup"

    # 下载配置文件
    DownloadUrl "phpMyAdmin.conf.tar.gz" "https://d.hws.com/linux/debug/conf/phpMyAdmin.conf.tar.gz"
    CheckError "tar zxf phpMyAdmin.conf.tar.gz"
    CheckError "rm -f ${var}/pma/config.inc.php"
    CheckError "mv config.inc.php ${var}/pma/config.inc.php"

    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -r -d /dev/null -s /sbin/nologin
    chown -R www:www ${var}/pma >/dev/null 2>&1

    # 写入配置文件
    write_apache
    write_nginx

    _success "${phpmyadmin_filename} install completed..."
}

write_apache() {
    # 写入phpMyAdmin配置文件
    mkdir -p ${var}/default/conf/apache
    cat > ${var}/default/conf/apache/pma.conf <<EOF
Listen 999
<VirtualHost *:999>
    ServerAdmin webmaster@example.com
    DocumentRoot ${var}/pma
    ServerName phpMyAdmin.999
    ServerAlias localhost
    #errorDocument 404 /404.html
    ErrorLog "${var}/pma/pma-error.log"
    CustomLog "${var}/pma/pma-access.log" combined

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
    <Directory ${var}/pma>
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
}

write_nginx() {
    # 写入phpMyAdmin配置文件
    mkdir -p ${var}/default/conf/nginx
    cat > ${var}/default/conf/nginx/pma.conf <<EOF
server {
   listen 999;
   server_name localhost;
   root ${var}/pma;
   index index.php default.php index.html index.htm default.html default.htm;
   error_log "${var}/pma/pma-error.log";
   access_log "${var}/pma/pma-access.log";

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
}
