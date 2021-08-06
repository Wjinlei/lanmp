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

IsRoot(){
    if [[ ${EUID} -ne 0 ]]; then
        _error "This script must be run as root"
    fi
}

DownloadFile(){
    local cur_dir=$(pwd)
    if [ -s "$1" ]; then
        _info "$1 [found]"
    else
        _info "$1 not found, download now..."
        wget --no-check-certificate -cv -t3 -T60 -O ${1} ${download_root_url}/${1}
        if [ $? -eq 0 ]; then
            _success "$1 download completed..."
        else
            rm -f ${1}
            _warn "$1 download failed, retrying download from secondary url..."
            wget --no-check-certificate -cv -t3 -T60 -O $1 ${2}
            if [ $? -eq 0 ]; then
                _success "$1 download completed..."
            else
                _error "Failed to download $1, please download it to ${cur_dir} directory manually and try again."
            fi
        fi
    fi
}

DownloadUrl(){
    local cur_dir=$(pwd)
    if [ -s "$1" ]; then
        _info "$1 [found]"
    else
        _info "$1 not found, download now..."
        wget --no-check-certificate -cv -t3 -T60 -O $1 ${2}
        if [ $? -eq 0 ]; then
            _success "$1 download completed..."
        else
            _error "Failed to download $1, please download it to ${cur_dir} directory manually and try again."
        fi
    fi
}

_get_package_manager(){
    yum >/dev/null 2>&1
    if [ "$?" -ne 127 ]; then
        PM="yum"
    else
        apt-get >/dev/null 2>&1
        if [ "$?" -ne 127 ]; then
            PM="apt-get"
        else
            _error "Get Package Manager Failed!"
        fi
    fi
}

_GetRPMArch() {
    RPMArch="el7"
    rpm -qa bash|grep el8 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        RPMArch="el8"
    fi
}


Is64bit(){
    if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ]; then
        return 0
    else
        return 1
    fi
}


InstallPack(){
    local command="$1"
    local depend=$(echo "$1" | awk '{print $4}')
    _info "Starting to install package ${depend}"
    ${command} > /dev/null
    if [ $? -ne 0 ]; then
        _error "
+------------------+
|  ERROR DETECTED  |
+------------------+
Installation package ${depend} failed."
    fi
}


CheckError(){
    local command="$1"
    if [[ $2 == "noOutput" ]]; then
        ${command} >/dev/null 2>&1
    else
        ${command}
    fi
    if [ $? -ne 0 ]; then
        _error "
+------------------+
|  ERROR DETECTED  |
+------------------+"
    fi
}

wait_for_pid () {
    try=0
    while test $try -lt 35 ; do
        case "$1" in
            'created')
            if [ -f "$2" ] ; then
                try=''
                break
            fi
            ;;
            'removed')
            if [ ! -f "$2" ] ; then
                try=''
                break
            fi
            ;;
        esac
        echo -n .
        try=`expr $try + 1`
        sleep 1
    done
}

_disable_selinux(){
    if [ -s /etc/selinux/config ]; then
        selinux=`grep "SELINUX=enforcing" /etc/selinux/config |wc -l`
        if [[ ${selinux} -ne 0 ]];then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
        fi
    fi
}

_set_envs() {
    cat >envs<<EOF
#!bin/bash
umask 022
EOF
    source envs
}

_set_timezone() {
    _info "Starting set to timezone..."
    rm -f /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    _success "Set timezone completed..."
}

_sync_time() {
    _set_timezone
    _info "Starting to sync time..."
    ntpdate -u 0.asia.pool.ntp.org >/dev/null 2>&1
    chronyc -a makestep >/dev/null 2>&1
    hwclock -w >/dev/null 2>&1
    _success "Sync time completed..."

    StartDate=$(date "+%Y-%m-%d %H:%M:%S")
    StartDateSecond=$(date +%s)
    _info "Start time: ${StartDate}"
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

GetOsInfo(){
    #cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    #cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    #freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    tram=$( free -m | awk '/Mem/ {print $2}' )
    swap=$( free -m | awk '/Swap/ {print $2}' )
    #up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
    #load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    #opsy=$( GetRelease )
    #arch=$( uname -m )
    #lbit=$( getconf LONG_BIT )
    #host=$( hostname )
    #kern=$( uname -r )
    ramsum=$( expr $tram + $swap )
}

_check_ram(){
    GetOsInfo
    if [ ${ramsum} -lt 480 ]; then
        _error "Not enough memory. The installation needs memory: ${tram}MB*RAM + ${swap}MB*SWAP >= 480MB"
    fi
    [ ${ramsum} -lt 1024 ] && disable_fileinfo="--disable-fileinfo" || disable_fileinfo=""
}

AddToEnv(){
    local location="$1"
    cd ${location} && [ ! -d lib ] && [ -d lib64 ] && ln -s lib64 lib
    [ -d "${location}/bin" ] && export PATH=${location}/bin:${PATH}
    if [ -d "${location}/lib" ]; then
        export LD_LIBRARY_PATH="${location}/lib:${LD_LIBRARY_PATH}"
    fi
    if [ -d "${location}/include" ]; then
        export CPPFLAGS="-I${location}/include $CPPFLAGS"
    fi
}

CreateLibLink(){
    local lib="$1"
    if [ ! -s "/usr/lib64/$lib" ] && [ ! -s "/usr/lib/$lib" ]; then
        libdir=$(find /usr/lib /usr/lib64 -name "$lib" | awk 'NR==1{print}')
        if [ "$libdir" != "" ]; then
            if Is64bit; then
                [ ! -d /usr/lib64 ] && mkdir /usr/lib64
                ln -s ${libdir} /usr/lib64/${lib}
                ln -s ${libdir} /usr/lib/${lib}
            else
                ln -s ${libdir} /usr/lib/${lib}
            fi
        fi
    fi
}

CreateLib64Dir(){
    local dir="$1"
    if Is64bit; then
        if [ -s "$dir/lib/" ] && [ ! -s  "$dir/lib64/" ]; then
            cd ${dir}
            ln -s lib lib64
        fi
    fi
}

GenPassWord(){
    cat /dev/urandom | head -1 | md5sum | head -c 16
}

GetRelease(){
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

GetIp(){
    local ipv4=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
    egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z "${ipv4}" ] && ipv4=$( wget -qO- -t1 -T2 ip.hws.com/getip.asp )
    [ -z "${ipv4}" ] && ipv4=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z "${ipv4}" ] && ipv4=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    if [ "${ipv4}" == "" ]; then
        ipv4='127.0.0.1'
    fi
    printf -- "%s" "${ipv4}"
}

CheckInstalled(){
    local cmd="$1"
    local location="$2"
    if [ -d "${location}" ]; then
        _warn "${location} already exists, skipped the installation."
        export PKG_CONFIG_PATH=${location}/lib/pkgconfig:$PKG_CONFIG_PATH
        AddToEnv "${location}"
        CreateLib64Dir "${location}"
    else
        ${cmd}
    fi
}

InstallPreSetting(){
    _set_envs
    _disable_selinux
    _get_package_manager
    _check_ram
    _sync_time
}
