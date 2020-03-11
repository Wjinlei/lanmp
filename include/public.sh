_red(){
    printf '\033[1;31;31m%b\033[0m' "$1"
}

_info(){
    printf '\033[1;31;36m%b\033[0m' "$1"
    printf "\n"
}

_success(){
    printf '\033[1;31;32m%b\033[0m' "$1"
    printf "\n"
}

_warn(){
    printf '\033[1;31;33m%b\033[0m' "$1"
    printf "\n"
}

_error(){
    printf '\033[1;31;31m%b\033[0m' "$1"
    printf "\n"
    exit 1
}

rootness(){
    if [[ ${EUID} -ne 0 ]]; then
        _error "This script must be run as root"
    fi
}

version_lt(){
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"
}

version_gt(){
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

version_le(){
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"
}

version_ge(){
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

# Download a file
# $1: file name
# $2: secondary url
download_file(){
    local cur_dir=$(pwd)
    if [ -s "$1" ]; then
        _info "$1 [found]"
    else
        _warn "$1 not found, download now..."
        wget --no-check-certificate -cv -t3 -T60 -O ${1} ${download_root_url}${1}
        if [ $? -eq 0 ]; then
            _success "$1 download completed..."
        else
            rm -f "$1"
            _warn "$1 download failed, retrying download from secondary url..."
            wget --no-check-certificate -cv -t3 -T60 -O "$1" "${2}"
            if [ $? -eq 0 ]; then
                _success "$1 download completed..."
            else
                _error "Failed to download $1, please download it to ${cur_dir} directory manually and try again."
            fi
        fi
    fi
}

set_package_manager(){
	if [ -f "/usr/bin/yum" ]; then
		PM="yum"
	elif [ -f "/usr/bin/apt-get" ]; then
		PM="apt-get"
	fi
}


is_64bit(){
    if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ]; then
        return 0
    else
        return 1
    fi
}


install_package(){
    local command="$1"
    local depend=$(echo "$1" | awk '{print $4}')
    _info "Starting to install package ${depend}"
    ${command} > /dev/null 2>/tmp/install_package.log
    if [ $? -ne 0 ]; then
        _error "
+------------------+
|  ERROR DETECTED  |
+------------------+
Installation package ${depend} failed.
Error Log is available at /tmp/install_package.log"
    fi
}


check_error(){
    local command="$1"
    ${command}
    if [ $? -ne 0 ]; then
        _error "
+------------------+
|  ERROR DETECTED  |
+------------------+
An error occurred,The Full Log is available at /tmp/install.log"
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

install_tools(){
    _info "Starting to install development tools..."
    if [ "${PM}" = "yum" ];then
        if [[ $(rpm -q yum | grep el6) != "" ]]; then
            install_package "yum -y install epel-release"
        elif [[ $(rpm -q yum |grep el7) != "" ]]; then
            install_package "yum -y install epel-release"
        elif [[ $(rpm -q yum |grep el8) != "" ]]; then
            install_package "yum -y install epel-release"
        fi
        yum_depends=(
            gcc
            gcc-c++
            make
            perl
            ntpdate
            wget
            net-tools
            openssl
            zlib
            pcre
            automake
            psmisc
            zip
            unzip
        )
        for depend in ${yum_depends[@]}
        do
            install_package "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        apt_depends=(
            gcc
            g++
            make
            perl
            ntpdate
            wget
            net-tools
            openssl
            zlib1g
            pcre3
            automake
            psmisc
            zip
            unzip
        )
        for depend in ${apt_depends[@]}
        do
            install_package "apt-get -y install ${depend}"
        done
    fi
    _info "Install development tools completed..."

    check_command_exist "gcc"
    check_command_exist "g++"
    check_command_exist "make"
    check_command_exist "wget"
    check_command_exist "perl"
    check_command_exist "netstat"
    check_command_exist "ntpdate"
    check_command_exist "openssl"
    check_command_exist "automake"
    check_command_exist "killall"
    check_command_exist "zip"
    check_command_exist "unzip"
}

generate_password(){
    cat /dev/urandom | head -1 | md5sum | head -c 16
}

check_command_exist(){
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "$cmd" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "$cmd" > /dev/null 2>&1
    else
        which "$cmd" > /dev/null 2>&1
    fi
    rt=$?
    if [ ${rt} -ne 0 ]; then
        _error "$cmd is not installed, please install it and try again."
    fi
}

sync_time(){
    _info "Starting to sync time..."
    ntpdate -bv cn.pool.ntp.org
    rm -f /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    _info "Sync time completed..."

    StartDate=$(date "+%Y-%m-%d %H:%M:%S")
    StartDateSecond=$(date +%s)
    _info "Start time: ${StartDate}"
}

get_os_info(){
    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    tram=$( free -m | awk '/Mem/ {print $2}' )
    swap=$( free -m | awk '/Swap/ {print $2}' )
    up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
    load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    opsy=$( get_opsy )
    arch=$( uname -m )
    lbit=$( getconf LONG_BIT )
    host=$( hostname )
    kern=$( uname -r )
    ramsum=$( expr $tram + $swap )
}

check_ram(){
    get_os_info
    if [ ${ramsum} -lt 480 ]; then
        _error "Not enough memory. needs memory: ${tram}MB*RAM + ${swap}MB*SWAP >= 480MB"
    fi
    [ ${ramsum} -lt 600 ] && disable_fileinfo="--disable-fileinfo" || disable_fileinfo=""
}

display_os_info(){
    clear
    echo
    echo "+----------------------------------------------------------------------"
    echo "| Hws-LinuxMaster 1.0 FOR CentOS/Ubuntu/Debian"
    echo "+----------------------------------------------------------------------"
    echo "| Copyright © 2004-2099 HWS(https://www.hws.com) All rights reserved."
    echo "+----------------------------------------------------------------------"
    echo "| The Panel URL will be http://SERVER_IP:6588 when installed."
    echo "+----------------------------------------------------------------------"
    echo
    echo "------------------------- System Information --------------------------"
    echo
    echo "CPU model            : ${cname}"
    echo "Number of cores      : ${cores}"
    echo "CPU frequency        : ${freq} MHz"
    echo "Total amount of ram  : ${tram} MB"
    echo "Total amount of swap : ${swap} MB"
    echo "System uptime        : ${up}"
    echo "Load average         : ${load}"
    echo "OS                   : ${opsy}"
    echo "Arch                 : ${arch} (${lbit} Bit)"
    echo "Kernel               : ${kern}"
    echo "Hostname             : ${host}"
    echo "IPv4 address         : $(get_ip)"
    echo
    echo "-----------------------------------------------------------------------"
}

parallel_make(){
    local para="$1"
    cpunum=$(cat /proc/cpuinfo | grep 'processor' | wc -l)

    if [ ${parallel_compile} -eq 0 ]; then
        cpunum=1
    fi

    if [ ${cpunum} -eq 1 ]; then
        [ "${para}" == "" ] && make || make "${para}"
    else
        [ "${para}" == "" ] && make -j${cpunum} || make -j${cpunum} "${para}"
    fi
}

add_to_env(){
    local location="$1"
    cd ${location} && [ ! -d lib ] && [ -d lib64 ] && ln -s lib64 lib
    [ -d "${location}/bin" ] && export PATH=${location}/bin:${PATH}
    if [ -d "${location}/lib" ]; then
        export LD_LIBRARY_PATH="${location}/lib:${LD_LIBRARY_PATH}"
    fi
    if [ -d "${location}/include" ]; then 
        export CPPFLAGS="-I${location}/include $CPPFLAGS"
        export CFLAGS="-I${location}/include $CFLAGS"
    fi
}

create_lib_link(){
    local lib="$1"
    if [ ! -s "/usr/lib64/$lib" ] && [ ! -s "/usr/lib/$lib" ]; then
        libdir=$(find /usr/lib /usr/lib64 -name "$lib" | awk 'NR==1{print}')
        if [ "$libdir" != "" ]; then
            if is_64bit; then
                [ ! -d /usr/lib64 ] && mkdir /usr/lib64
                ln -s ${libdir} /usr/lib64/${lib}
                ln -s ${libdir} /usr/lib/${lib}
            else
                ln -s ${libdir} /usr/lib/${lib}
            fi
        fi
    fi
}

create_lib64_dir(){
    local dir="$1"
    if is_64bit; then
        if [ -s "$dir/lib/" ] && [ ! -s  "$dir/lib64/" ]; then
            cd ${dir}
            ln -s lib lib64
        fi
    fi
}

get_ip(){
    local ipv4=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
    egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z "${ipv4}" ] && ipv4=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z "${ipv4}" ] && ipv4=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    if [ "${ipv4}" == "" ]; then
        ipv4='127.0.0.1'
    fi
    printf -- "%s" "${ipv4}"
}

get_opsy(){
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

get_char(){
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty ${SAVEDSTTY}
}

start_install(){
    echo "Press any key to start...or Press Ctrl+C to cancel"
    echo
    char=$(get_char)
}

check_installed(){
    local cmd="$1"
    local location="$2"
    if [ -d "${location}" ]; then
        _warn "${location} already exists, skipped the installation."
        add_to_env "${location}"
    else
        ${cmd}
    fi
}

install_finally(){
    _info "Starting clean up..."
    cd ${cur_dir}
    rm -rf ${cur_dir}/software
    rm -fr ${cur_dir}/include
    _info "Clean up completed..."

    sleep 1
    netstat -tunlp
    echo
    _info "Start time     : ${StartDate}"
    _info "Completion time: $(date "+%Y-%m-%d %H:%M:%S") (Use:$(_red $[($(date +%s)-StartDateSecond)/60]) minutes)"
    echo
    cat > ${install_prefix}/uninstall.sh <<EOF
#!/usr/bin/env bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

killall -9 mysqld >/dev/null 2>&1
killall -9 httpd >/dev/null 2>&1
killall -9 nginx >/dev/null 2>&1
killall -9 pure-ftpd >/dev/null 2>&1
killall -9 php-fpm >/dev/null 2>&1
killall -9 redis-server >/dev/null 2>&1

rm -fr ${soft_location}
rm -f ${install_prefix}/install.result
ls ${install_prefix}
netstat -tunlp
echo
echo "uninstall completed!"
EOF
    chmod +x ${install_prefix}/uninstall.sh
    [ -f "${install_prefix}/install.result" ] && cat ${install_prefix}/install.result
    _success "install completed! See ${install_prefix}/install.result"

    exit 0
}

is_digit(){
    local input="$1"
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

display_webserver_menu(){
    local arr_len=${#webserver_arr[@]}
    local default
    ((default=${arr_len}-2))
    while :
    do
        echo
        echo ------------------------------ WebServer -------------------------------
        for (( i=1; i<=${arr_len}; i++ )); do
            echo ${i}. ${webserver_arr[${i}-1]}
        done
        echo
        echo -n "Input your select (default ${webserver_arr[${default}]}): "
        read webserver_select
        if [ "${webserver_select}" == "" ]; then
            webserver=${webserver_arr[${default}]}
        else
            if ! is_digit "${webserver_select}"; then
                _warn "Input error, please only input a number: "
                continue
            fi
            if [[ "${webserver_select}" -lt 1 || "${webserver_select}" -gt ${#webserver_arr[@]} ]]; then
                _warn "Input error, please input a number between 1 and ${#webserver_arr[@]}: "
                continue
            fi
            webserver=${webserver_arr[${webserver_select}-1]}
        fi
        echo "your selection: ${webserver}"
        echo
        break
    done
}

display_mysql_menu(){
    local arr_len=${#mysql_arr[@]}
    local default
    ((default=${arr_len}-3))
    while :
    do
        echo
        echo ------------------------------- MySQL ---------------------------------
        for (( i=1; i<=${arr_len}; i++ )); do
            echo ${i}. ${mysql_arr[${i}-1]}
        done
        echo
        echo -n "Input your select (default ${mysql_arr[${default}]}): "
        read mysql_select
        if [ "${mysql_select}" == "" ]; then
            mysql=${mysql_arr[${default}]}
        else
            if ! is_digit "${mysql_select}"; then
                _warn "Input error, please only input a number: "
                continue
            fi 
            if [[ "${mysql_select}" -lt 1 || "${mysql_select}" -gt ${#mysql_arr[@]} ]]; then
                _warn "Input error, please input a number between 1 and ${#mysql_arr[@]}: "
                continue
            fi
            mysql=${mysql_arr[${mysql_select}-1]}
        fi
        echo "your selection: ${mysql}"
        echo
        break
    done
}

display_php_menu(){
    local arr_len=${#php_arr[@]}
    local default
    ((default=${arr_len}-3))
    while :
    do
        echo -------------------------------- PHP ----------------------------------
        for (( i=1; i<=${arr_len}; i++ )); do
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

display_ftpd_menu(){
    local arr_len=${#ftpd_arr[@]}
    local default
    ((default=${arr_len}-2))
    while :
    do
        echo
        echo ------------------------------- Ftp ---------------------------------
        for (( i=1; i<=${arr_len}; i++ )); do
            echo ${i}. ${ftpd_arr[${i}-1]}
        done
        echo
        echo -n "Input your select (default ${ftpd_arr[${default}]}): "
        read ftpd_select
        if [ "${ftpd_select}" == "" ]; then
            ftpd=${ftpd_arr[${default}]}
        else
            if ! is_digit "${ftpd_select}"; then
                _warn "Input error, please only input a number: "
                continue
            fi
            if [[ "${ftpd_select}" -lt 1 || "${ftpd_select}" -gt ${#ftpd_arr[@]} ]]; then
                _warn "Input error, please input a number between 1 and ${#ftpd_arr[@]}: "
                continue
            fi
            ftpd=${ftpd_arr[${ftpd_select}-1]}
        fi
        echo "your selection: ${ftpd}"
        echo
        break
    done
}

display_menu(){
    local arr_len=${#menu_arr[@]}
    local default
    ((default=${arr_len}-3))
    while :
    do
        echo
        echo ----------------------------- Main Menu -------------------------------
        for (( i=1; i<=${arr_len}; i++ )); do
            echo ${i}. ${menu_arr[${i}-1]}
        done
        echo
        echo -n "Input your select (default ${menu_arr[${default}]}): "
        read menu_select
        if [ "${menu_select}" == "" ]; then
            menu=${menu_arr[${default}]}
        else
            if ! is_digit "${menu_select}"; then
                _warn "Input error, please only input a number: "
                continue
            fi
            if [[ "${menu_select}" -lt 1 || "${menu_select}" -gt ${#menu_arr[@]} ]]; then
                _warn "Input error, please input a number between 1 and ${#menu_arr[@]}: "
                continue
            fi
            menu=${menu_arr[${menu_select}-1]}
        fi
        echo "your selection: ${menu}"
        echo
        if [ "${menu}" == "lamp(Linux + ${apache_filename} + ${mysql57_filename} + ${php55_filename} + ${pureftpd_filename})" ]; then
            webserver=${apache_filename}
            mysql=${mysql57_filename}
            php=${php55_filename}
            ftpd=${pureftpd_filename}
        elif [ "${menu}" == "lnmp(Linux + ${nginx_filename} + ${mysql57_filename} + ${php55_filename} + ${pureftpd_filename})" ]; then
            webserver=${nginx_filename}
            mysql=${mysql57_filename}
            php=${php55_filename}
            ftpd=${pureftpd_filename}
        elif [ "${menu}" == "customize" ]; then
            display_webserver_menu
            display_mysql_menu
            display_php_menu
            display_ftpd_menu
        fi
        break
    done
}

install_webserver(){
    if [ "${webserver}" == ${apache_filename} ]; then
        check_installed "install_apache" "${apache_location}"
    elif [ "${webserver}" == ${nginx_filename} ]; then
        check_installed "install_nginx" "${nginx_location}"
    fi
}

begin_install(){
    display_menu
    if [ "${menu}" != "do_not_install" ]; then
        start_install
        [ ! -d "${depends_prefix}" ] && mkdir -p ${depends_prefix}
        [ ! -d "${cur_dir}/software" ] && mkdir -p ${cur_dir}/software
        [ ! -d "${default_site_dir}" ] && mkdir -p ${default_site_dir} && chmod -R 755 ${default_site_dir}
        mkdir -p ${install_prefix}/Backup/Database
        mkdir -p ${install_prefix}/Tmps
        disable_selinux
        set_package_manager
        install_tools
        sync_time
        [ "${webserver}" != "do_not_install" ] && install_webserver
        [ "${mysql}" != "do_not_install" ] && check_installed "install_mysql" "${mysql_location}"
        [ "${php}" != "do_not_install" ] && install_php
        [ "${ftpd}" != "do_not_install" ] && check_installed "install_pureftpd" "${pureftpd_location}"
        install_finally
    fi
}
