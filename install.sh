#!/usr/bin/env bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

cur_dir=$(pwd)

include(){
    local include=${1}
    if [[ -s ${cur_dir}/include/${include}.sh ]];then
        . ${cur_dir}/include/${include}.sh
    else
        wget -P include https://d.hws.com/free/hwslinuxmaster/script/include/${include}.sh >/dev/null 2>&1
        if [ "$?" -ne 0 ]; then
            echo "Error: ${cur_dir}/include/${include}.sh not found, shell can not be executed."
            exit 1
        fi
        . ${cur_dir}/include/${include}.sh
    fi
}

main(){
    case "$1" in
        -h|--help)
            printf "Usage: $0 [Options] [Install Path]
Options:
-h, --help                  Print this help text and exit
--install-apache24          Install apache2.4       Default Path: /hwslinuxmaster/soft/apache24
--install-nginx             Install nginx           Default Path: /hwslinuxmaster/soft/nginx
--install-mysql55           Install mysql5.5        Default Path: /hwslinuxmaster/soft/mysql55
--install-mysql56           Install mysql5.6        Default Path: /hwslinuxmaster/soft/mysql56
--install-mysql57           Install mysql5.7        Default Path: /hwslinuxmaster/soft/mysql57
--install-mysql80           Install mysql8.0        Default Path: /hwslinuxmaster/soft/mysql80
--install-php53             Install php5.3          Default Path: /hwslinuxmaster/soft/php/php53
--install-php54             Install php5.4          Default Path: /hwslinuxmaster/soft/php/php54
--install-php55             Install php5.5          Default Path: /hwslinuxmaster/soft/php/php55
--install-php56             Install php5.6          Default Path: /hwslinuxmaster/soft/php/php56
--install-php70             Install php7.0          Default Path: /hwslinuxmaster/soft/php/php70
--install-php71             Install php7.1          Default Path: /hwslinuxmaster/soft/php/php71
--install-php72             Install php7.2          Default Path: /hwslinuxmaster/soft/php/php72
--install-php73             Install php7.3          Default Path: /hwslinuxmaster/soft/php/php73
--install-pureftpd          Install pureftpd        Default Path: /hwslinuxmaster/soft/pure-ftpd
--install-redis             Install redis-server    Default Path: /hwslinuxmaster/soft/redis-server
--install-pma49             Install pma4.9          Default Path: Not Default
"
            ;;
        --install-apache24)
            InstallPreSetting
            include apache24
            if [ $# -ge 2 ]; then
                wwwroot_dir=${2}/www
                apache24_install_path_name=${2##*/}
                apache24_location=${2}
            fi
            install_apache24
            ;;
        --install-nginx)
            InstallPreSetting
            include nginx
            if [ $# -ge 2 ]; then
                wwwroot_dir=${2}/www
                nginx_install_path_name=${2##*/}
                nginx_location=${2}
            fi
            install_nginx
            ;;
        --install-mysql55)
            InstallPreSetting
            include mysql55
            if [ $# -ge 2 ]; then
                mysql_data_location=${2}/mysql_data
                mysql55_location=${2}
            fi
            install_mysql55
            ;;
        --install-mysql56)
            InstallPreSetting
            include mysql56
            if [ $# -ge 2 ]; then
                mysql_data_location=${2}/mysql_data
                mysql56_location=${2}
            fi
            install_mysql56
            ;;
        --install-mysql57)
            InstallPreSetting
            include mysql57
            if [ $# -ge 2 ]; then
                mysql_data_location=${2}/mysql_data
                mysql57_location=${2}
            fi
            install_mysql57
            ;;
        --install-mysql80)
            InstallPreSetting
            include mysql80
            if [ $# -ge 2 ]; then
                mysql_data_location=${2}/mysql_data
                mysql80_location=${2}
            fi
            install_mysql80
            ;;
        --install-php53)
            InstallPreSetting
            include php53
            if [ $# -ge 2 ]; then
                php53_install_path_name=${2##*/}
                php53_location=${2}
            fi
            install_php53
            ;;
        --install-php54)
            InstallPreSetting
            include php54
            if [ $# -ge 2 ]; then 
                php54_install_path_name=${2##*/}
                php54_location=${2}
            fi
            install_php54
            ;;
        --install-php55)
            InstallPreSetting
            include php55
            if [ $# -ge 2 ]; then 
                php55_install_path_name=${2##*/}
                php55_location=${2}
            fi
            install_php55
            ;;
        --install-php56)
            InstallPreSetting
            include php56
            if [ $# -ge 2 ]; then 
                php56_install_path_name=${2##*/}
                php56_location=${2}
            fi
            install_php56
            ;;
        --install-php70)
            InstallPreSetting
            include php70
            if [ $# -ge 2 ]; then 
                php70_install_path_name=${2##*/}
                php70_location=${2}
            fi
            install_php70
            ;;
        --install-php71)
            InstallPreSetting
            include php71
            if [ $# -ge 2 ]; then 
                php71_install_path_name=${2##*/}
                php71_location=${2}
            fi
            install_php71
            ;;
        --install-php72)
            InstallPreSetting
            include php72
            if [ $# -ge 2 ]; then 
                php72_install_path_name=${2##*/}
                php72_location=${2}
            fi
            install_php72
            ;;
        --install-php73)
            InstallPreSetting
            include php73
            if [ $# -ge 2 ]; then 
                php73_install_path_name=${2##*/}
                php73_location=${2}
            fi
            install_php73
            ;;
        --install-pureftpd)
            InstallPreSetting
            include pureftpd
            if [ $# -ge 2 ]; then 
                pureftpd_install_path_name=${2##*/}
                pureftpd_location=${2}
            fi
            install_pureftpd
            ;;
        --install-redis)
            InstallPreSetting
            include redis
            if [ $# -ge 2 ]; then 
                redis_install_path_name=${2##*/}
                redis_location=${2}
            fi
            install_redis
            ;;
        --install-pma49)
            if [ $# -ge 2 ]; then
                InstallPreSetting
                include pma49
                install_pma49 ${2}
            else
                echo "Please specify the installation path" && exit 1
            fi
            ;;
        *)
            echo "Please Usage: $0 -h, Show Help"
            ;;
    esac
}

include config
include public
load_config
IsRoot
main "$@" 2>&1 | tee /tmp/install.log
