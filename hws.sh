#!/usr/bin/env bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

apache24_location=$(cat /hwslinuxmaster/install.result 2>/dev/null|grep "Apache24 Install Path" |cut -d: -f2|tail -n 1 2>/dev/null)
apache24_www_root=$(cat /hwslinuxmaster/install.result 2>/dev/null|grep "Apache24 Www Root Dir" |cut -d: -f2|tail -n 1 2>/dev/null)
nginx_location=$(cat /hwslinuxmaster/install.result 2>/dev/null|grep "Nginx Install Path" |cut -d: -f2|tail -n 1 2>/dev/null)
nginx_www_root=$(cat /hwslinuxmaster/install.result 2>/dev/null|grep "Nginx Www Root Dir" |cut -d: -f2|tail -n 1 2>/dev/null)
pureftpd_location=$(cat /hwslinuxmaster/install.result 2>/dev/null|grep "Pureftpd Install Path" |cut -d: -f2|tail -n 1 2>/dev/null)
mysql_location=$(cat /hwslinuxmaster/install.result 2>/dev/null|grep -E "MySQL.*Install.*Path" |cut -d: -f2|tail -n 1 2>/dev/null)
mysqlroot_passwd=$(cat /hwslinuxmaster/install.result 2>/dev/null|grep -E "MySQL.*Root.*PassWord" |cut -d: -f2|tail -n 1 2>/dev/null)

php_arr=(
$(ls -l /tmp/*-default.sock 2>/dev/null|awk -F' ' '{print $NF}')
)
php_arr_len=${#php_arr[@]}

vhost_add(){
    # Apache
    if [ "${apache24_location}" != "" ]; then
        while :
        do
            read -p "Do you want to create a configuration file for apache? [y/n]:" apache_create
            case ${apache_create} in
            y|Y)
                apache_count=$(ls -l `find /proc/ -iname exe` 2>/dev/null|grep -c "${apache24_location}/bin/httpd")
                if [ ${apache_count} -eq 0 ]; then
                    echo "Info: Apache looks like not running, Try to starting Apache..."
                    ${apache24_location}/bin/apachectl start > /dev/null 2>&1
                    if [ $? -ne 0 ]; then
                        echo -e "\033[31mError:\033[0m Apache starting failed!"
                        exit 1
                    fi
                fi
                read -p "Please enter domain names (for example: hws.com www.hws.com): " apache24_domain_names
                for i in ${apache24_domain_names}; do
                    if apache_vhost_is_exist ${i}; then
                        echo -e "\033[31mError:\033[0m virtual host [${i}] is existed, please check it and try again."
                        break
                    fi
                    break 2
                done
                apache_create="y"
                break
                ;;
            n|N)
                echo "Do not create a configuration file for apache"
                echo
                apache_create="n"
                break
                ;;
            *) echo "Please enter only y or n"
            esac
        done
    fi

    # Nginx
    if [ "${nginx_location}" != "" ]; then
        while :
        do
            read -p "Do you want to create a configuration file for nginx? [y/n]:" nginx_create
            case ${nginx_create} in
            y|Y)
                nginx_count=$(ls -l `find /proc/ -iname exe` 2>/dev/null|grep -c "${nginx_location}/sbin/nginx")
                if [ ${nginx_count} -eq 0 ]; then
                    echo "Info: Nginx looks like not running, Try to starting Nginx..."
                    ${nginx_location}/sbin/nginx
                    if [ $? -ne 0 ]; then
                        echo -e "\033[31mError:\033[0m Nginx starting failed!"
                        exit 1
                    fi
                fi
                read -p "Please enter domain names (for example: hws.com www.hws.com): " nginx_domain_names
                for i in ${nginx_domain_names}; do
                    if nginx_vhost_is_exist ${i}; then
                        echo -e "\033[31mError:\033[0m virtual host [${i}] is existed, please check it and try again."
                        break
                    fi
                    break 2
                done
                nginx_create="y"
                break
                ;;
            n|N)
                echo "Do not create a configuration file for nginx"
                echo
                nginx_create="n"
                break
                ;;
            *) echo "Please enter only y or n"
            esac
        done
    fi

    # Php
    if [[ "${apache_create}" = "y" || "${nginx_create}" = "y" ]]; then
        if [ "${php_arr_len}" != 0 ]; then
            display_php_menu
        else
            echo -e "\033[31mError:\033[0m /tmp without php sock." && exit 1
        fi
    fi

    # MySQL
    if [ "${mysql_location}" != "" ]; then
        while :
        do
            read -p "Do you want to create a database and mysql user with same name? [y/n]:" mysql_create
            case ${mysql_create} in
            y|Y)
                mysql_count=$(ls -l `find /proc/ -iname exe` 2>/dev/null|grep -c "${mysql_location}/bin/mysqld")
                if [ ${mysql_count} -eq 0 ]; then
                    echo "Info: MySQL looks like not running, Try to starting MySQL..."
                    ${mysql_location}/support-files/mysql.server start > /dev/null 2>&1
                    if [ $? -ne 0 ]; then
                        echo -e "\033[31mError:\033[0m MySQL starting failed!"
                        exit 1
                    fi
                fi
                read -p "Please enter the database name:" dbname
                [ -z ${dbname} ] && echo -e "\033[31mError:\033[0m database name can not be empty." && exit 1
                read -p "Please set the password for user ${dbname}:" dbpass
                echo
                [ -z ${dbpass} ] && echo -e "\033[31mError:\033[0m user password can not be empty." && exit 1
                mysql_create="y"
                break
                ;;
            n|N)
                echo "Do not create a database"
                echo
                mysql_create="n"
                break
                ;;
            *) echo "Please enter only y or n"
            esac
        done
    fi

    # Pureftpd
    if [ "${pureftpd_location}" != "" ]; then
        if [[ "${apache_create}" = "y" || "${nginx_create}" = "y" ]]; then
            while :
            do
                read -p "Do you want to create a ftp user with same name? [y/n]:" ftp_create
                case ${ftp_create} in
                y|Y)
                    pureftpd_count=$(ls -l `find /proc/ -iname exe` 2>/dev/null|grep -c "${pureftpd_location}/sbin/pure-ftpd")
                    if [ ${pureftpd_count} -eq 0 ]; then
                        echo "Info: Pureftpd looks like not running, Try to starting pureftpd..."
                        ${pureftpd_location}/sbin/pure-ftpd  ${pureftpd_location}/etc/pure-ftpd.conf
                        if [ $? -ne 0 ]; then
                            echo -e "\033[31mError:\033[0m Pureftpd starting failed!"
                            exit 1
                        fi
                    fi
                    ftp_create="y"
                    break
                    ;;
                n|N)
                    echo "Do not create a ftp user"
                    echo
                    ftp_create="n"
                    break
                    ;;
                *) echo "Please enter only y or n"
                esac
            done
        fi
    fi

    # Create apache config
    if [ "${apache_create}" = "y" ]; then
        local website_root=${apache24_www_root}/${apache24_domain_names%% *}
        mkdir -p ${website_root}/web
        mkdir -p ${website_root}/log
        mkdir -p ${website_root}/other
        if [ ${php_arr_len} != 0 ]; then
            cat > ${apache24_location}/conf/vhost/${apache24_domain_names%% *}.conf << EOF
<VirtualHost *:80>
    ServerName ${apache24_domain_names%% *}
    ServerAlias ${apache24_domain_names}
    DocumentRoot ${website_root}/web

    ErrorLog "${website_root}/log/${apache24_domain_names%% *}-error.log"
    CustomLog "${website_root}/log/${apache24_domain_names%% *}-access.log" combined

    #DENY FILES
    <Files ~ (\\.user.ini|\\.htaccess|\\.git|\\.svn|\\.project|LICENSE|README.md)\$>
        Order allow,deny
        Deny from all
    </Files>

    <Directory ${website_root}/web>
        SetOutputFilter DEFLATE
        Options FollowSymLinks
        AllowOverride All
        Order Deny,Allow
        Require all granted
        DirectoryIndex index.php default.php index.html index.htm default.html default.htm
        <FilesMatch \\.php\$>
            SetHandler "proxy:unix:${php}|fcgi://localhost"
        </FilesMatch>
    </Directory>
</VirtualHost>
EOF
        else
            echo -e "\033[31mError:\033[0m /tmp without php sock." && exit 1
        fi
        # Restart apache
        echo "Reloading the apache config file..."
        if ${apache24_location}/bin/apachectl -t; then
            ${apache24_location}/bin/apachectl restart >/dev/null 2>&1
            echo "Reload succeed"
            echo
        else
            echo -e "\033[31mError:\033[0m Reload failed. Apache config file had an error, please fix it and try again."
            exit 1
        fi
        chown -R www:www ${website_root}
        # Create Ftp User
        if [ "$ftp_create" = "y" ]; then
            echo "Create Ftp User [${apache24_domain_names%% *}]"
            ${pureftpd_location}/bin/pure-pw useradd ${apache24_domain_names%% *} -u www -d ${website_root}
            ${pureftpd_location}/bin/pure-pw mkdb
            ${pureftpd_location}/bin/pure-pw list
        fi
        echo "Virtual host [${apache24_domain_names%% *}] has been created"
        echo "Website root directory is: ${website_root}"
        echo
    fi
    # Create nginx config
    if [ "${nginx_create}" = "y" ]; then
        if [ ${php_arr_len} != 0 ]; then
            local website_root=${nginx_www_root}/${nginx_domain_names%% *}
            mkdir -p ${website_root}/web
            mkdir -p ${website_root}/log
            mkdir -p ${website_root}/other
            if [ ${php_arr_len} != 0 ]; then
                cat > ${nginx_location}/etc/vhost/${nginx_domain_names%% *}.conf<<EOF
server {
    listen 80;
    server_name ${nginx_domain_names};
    root ${website_root}/web;
    index index.php default.php index.html index.htm default.html default.htm;
    error_log "${website_root}/log/${apache24_domain_names%% *}-error.log";
    access_log "${website_root}/log/${apache24_domain_names%% *}-access.log" combined;

    location ~ \.php\$ {
        fastcgi_pass unix:${php};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
            fi
        else
            echo -e "\033[31mError:\033[0m /tmp without php sock." && exit 1
        fi
        # Restart nginx
        echo "Reloading the nginx config file..."
        if ${nginx_location}/sbin/nginx -t; then
            ${nginx_location}/sbin/nginx -s reload >/dev/null 2>&1
            echo "Reload succeed"
            echo
        else
            echo -e "\033[31mError:\033[0m Reload failed. Nginx config file had an error, please fix it and try again."
            exit 1
        fi
        chown -R www:www ${website_root}
        # Create Ftp User
        if [ "$ftp_create" = "y" ]; then
            echo "Create Ftp User [${nginx_domain_names%% *}]"
            ${pureftpd_location}/bin/pure-pw useradd ${nginx_domain_names%% *} -u www -d ${website_root}
            ${pureftpd_location}/bin/pure-pw mkdb
            ${pureftpd_location}/bin/pure-pw list
        fi
        echo "Virtual host [${nginx_domain_names%% *}] has been created"
        echo "Website root directory is: ${website_root}"
        echo
    fi

    # Create MySQL and MySQL User
    if [ "$mysql_create" = "y" ]; then
        ${mysql_location}/bin/mysql -uroot -p${mysqlroot_passwd} >/dev/null 2>&1 <<EOF
CREATE DATABASE IF NOT EXISTS \`${dbname}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER '${dbname}'@'%' IDENTIFIED BY '${dbpass}';
GRANT ALL PRIVILEGES ON \`${dbname}\`.* TO '${dbname}'@'%';
FLUSH PRIVILEGES;
EOF
        echo "Database [${dbname}] and mysql user [${dbname}] has been created"
    fi
    echo "All done"
}

vhost_list(){
    if [ $(ls ${apache24_location}/conf/vhost/ 2>/dev/null| grep ".conf$" | grep -v "none" | grep -v "default" | wc -l) -gt 0 ]; then
        echo "Apache Server Name"
        echo "------------"
    fi
    ls ${apache24_location}/conf/vhost/ 2>/dev/null| grep ".conf$" | grep -v "none" | grep -v "default" | sed 's/.conf//g'
    echo
    if [ $(ls ${nginx_location}/etc/vhost/ 2>/dev/null| grep ".conf$" | grep -v "none" | grep -v "default" | wc -l) -gt 0 ]; then
        echo "Nginx Server Name"
        echo "------------"
    fi
    ls ${nginx_location}/etc/vhost/ 2>/dev/null| grep ".conf$" | grep -v "none" | grep -v "default" | sed 's/.conf//g'
}

vhost_del(){
    if [ "${apache24_location}" != "" ]; then
        while :
        do
            read -p "Do you want to delete a configuration file for apache? [y/n]:" apache_delete
            case ${apache_delete} in
            y|Y)
                if [ "${apache24_location}" != "" ]; then
                    read -p "Please enter a domain you want to delete it (for example: www.hws.com): " domain
                    if apache_vhost_is_exist "${domain}"; then
                        rm -f ${apache24_location}/conf/vhost/${domain}.conf
                        echo "Virtual host [${domain}] has been deleted, and website files will not be deleted."
                        echo "You need to delete the website files by manually if necessary."
                        echo "Reloading the apache config file..."
                        if ${apache24_location}/bin/apachectl -t; then
                            ${apache24_location}/bin/apachectl restart >/dev/null 2>&1
                            echo "Reload succeed"
                            echo
                        else
                            echo -e "\033[31mError:\033[0m Reload failed. Apache config file had an error, please fix it and try again"
                            exit 1
                        fi
                    fi
                fi
                break
                ;;
            n|N)
                echo "Do not delete a configuration file for apache"
                echo
                break
                ;;
            *) echo "Please enter only y or n"
            esac
        done
    fi
    if [ "${nginx_location}" != "" ]; then
        while :
        do
            read -p "Do you want to delete a configuration file for nginx? [y/n]:" nginx_delete
            case ${nginx_delete} in
            y|Y)
                if [ "${nginx_location}" != "" ]; then
                    read -p "Please enter a domain you want to delete it (for example: www.hws.com): " domain
                    if nginx_vhost_is_exist "${domain}"; then
                        rm -f ${nginx_location}/etc/vhost/${domain}.conf
                        echo "Virtual host [${domain}] has been deleted, and website files will not be deleted."
                        echo "You need to delete the website files by manually if necessary."
                        echo "Reloading the apache config file..."
                        if ${nginx_location}/sbin/nginx -t; then
                            ${nginx_location}/sbin/nginx -s reload >/dev/null 2>&1
                            echo "Reload succeed"
                            echo
                        else
                            echo -e "\033[31mError:\033[0m Reload failed. Nginx config file had an error, please fix it and try again"
                            exit 1
                        fi
                    fi
                fi
                break
            ;;
            n|N)
                echo "Do not delete a configuration file for nginx"
                echo
                break
                ;;
            *) echo "Please enter only y or n"
            esac
        done
    fi
}

display_php_menu(){
    local default
    ((default=${php_arr_len}-1))
    while :
    do
        echo -------------------------------- PHP ----------------------------------
        for (( i=1; i<=${php_arr_len}; i++ )); do
            echo ${i}. ${php_arr[${i}-1]}
        done
        echo
        echo -n "Input your select (default ${php_arr[${default}]}): "
        read php_select
        if [ "${php_select}" == "" ]; then
            php=${php_arr[${default}]}
        else
            if ! is_digit "${php_select}"; then
                _warn "Input error, please only input a number: "
                continue
            fi
            if [[ "${php_select}" -lt 1 || "${php_select}" -gt ${#php_arr[@]} ]]; then
                _warn "Input error, please input a number between 1 and ${#php_arr[@]}: "
                continue
            fi
            php=${php_arr[${php_select}-1]}
        fi
        echo "your selection: ${php}"
        echo
        break
    done
}

apache_vhost_is_exist(){
    local conf_file="${apache24_location}/conf/vhost/$1.conf"
    if [ -f "${conf_file}" ]; then
        return 0
    else
        return 1
    fi
}

nginx_vhost_is_exist(){
    local conf_file="${nginx_location}/etc/vhost/$1.conf"
    if [ -f "${conf_file}" ]; then
        return 0
    else
        return 1
    fi
}

_warn(){
    printf '\033[1;31;33m%b\033[0m' "$1"
    printf "\n"
}

is_digit(){
    local input="$1"
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

IsRoot(){
    if [[ ${EUID} -ne 0 ]]; then
        echo -e "\033[31mError:\033[0m This script must be run as root." && exit 1
    fi
}

display_usage(){
printf "
Usage: `basename $0` [ add | del | list ]
add     Create a new virtual host
del     Delete a virtual host
list    List all of virtual hosts

"
}

#Run it
IsRoot
if [ $# -ne 1 ]; then
    display_usage
    exit 1
fi

action=$1
case ${action} in
    add)  vhost_add ;;
    list) vhost_list;;
    del)  vhost_del;;
    *)    display_usage   ;;
esac
