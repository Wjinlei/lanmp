#!/usr/bin/env bash

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

cur_dir=$(pwd)
rm -fr ${cur_dir}/include

include(){
    local include=${1}
    if [[ -s ${cur_dir}/include/${include}.sh ]];then
        . ${cur_dir}/include/${include}.sh
    else
        wget -P include https://d.hws.com/linux/debug/script/include/${include}.sh >/dev/null 2>&1
        if [ "$?" -ne 0 ]; then
            echo "Error: ${cur_dir}/include/${include}.sh not found, shell can not be executed."
            exit 1
        fi
        . ${cur_dir}/include/${include}.sh
    fi
}

go(){
    case "$1" in
        -h|--help)
            printf "Usage: $0 <Options> [Parameter...]
Options:
-h, --help  Print this help text and exit

--install-apache
--install-nginx
--install-mysql55
--install-mysql56
--install-mysql57
--install-mysql80
--install-php53
--install-php54
--install-php55
--install-php56
--install-php70
--install-php71
--install-php72
--install-php73
--install-pma
--install-pureftpd
--install-redis
"
            ;;
        --install-apache)
            include apache
            install_apache ${2}
            ;;
        --install-nginx)
            include nginx
            install_nginx ${2}
            ;;
        --install-mysql55)
            include mysql55
            install_mysql55 ${2} ${3} ${4}
            ;;
        --install-mysql56)
            include mysql56
            install_mysql56 ${2} ${3} ${4}
            ;;
        --install-mysql57)
            include mysql57
            install_mysql57 ${2} ${3} ${4}
            ;;
        --install-mysql80)
            include mysql80
            install_mysql80 ${2} ${3} ${4}
            ;;
        --install-php53)
            include php53
            install_php53 ${2}
            ;;
        --install-php54)
            include php54
            install_php54 ${2}
            ;;
        --install-php55)
            include php55
            install_php55 ${2}
            ;;
        --install-php56)
            include php56
            install_php56 ${2}
            ;;
        --install-php70)
            include php70
            install_php70 ${2}
            ;;
        --install-php71)
            include php71
            install_php71 ${2}
            ;;
        --install-php72)
            include php72
            install_php72 ${2}
            ;;
        --install-php73)
            include php73
            install_php73 ${2}
            ;;
        --install-pureftpd)
            include pure-ftpd
            install_pure-ftpd ${2} ${3}
            ;;
        --install-redis)
            include redis
            install_redis ${2} ${3}
            ;;
        --install-pma)
            include pma
            install_pma ${2}
            ;;
        *)
            echo "Missing parameters,Please Usage: $0 -h, Show Help" && exit 1
            ;;
    esac
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    go "$@"
}
echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
main "$@" > /tmp/install.log 2>&1
