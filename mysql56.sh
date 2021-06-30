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

_install_mysql_depend(){
    _info "Starting to install dependencies packages for MySQL..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(ncurses*-libs ncurses-devel cmake m4 bison libaio libaio-devel numactl-devel libevent)
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
        if Is64bit; then
            local perl_data_dumper_url="${download_root_url}/perl-Data-Dumper-2.125-1.el6.rf.x86_64.rpm"
        else
            local perl_data_dumper_url="${download_root_url}/perl-Data-Dumper-2.125-1.el6.rf.i686.rpm"
        fi
        if [[ $(rpm -q yum | grep el6) != "" ]]; then
            rpm -q perl-Data-Dumper > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                _info "Starting to install package perl-Data-Dumper"
                rpm -Uvh ${perl_data_dumper_url} > /dev/null 2>&1
                [ $? -ne 0 ] && _error "Install package perl-Data-Dumper failed"
            fi
        else
            InstallPack "yum -y install perl-Data-Dumper"
        fi
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(libncurses5-dev libncurses5 cmake m4 bison libaio1 libaio-dev numactl)
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt-get -y install ${depend}"
        done
    fi
    if echo $(GetRelease) | grep -Eqi "fedora"; then
        InstallPack "yum -y install ncurses-compat-libs"
    fi
    id -u mysql >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U mysql -r -d /dev/null -s /sbin/nologin
    _info "Install dependencies packages for MySQL completed..."
}

_create_sysv_script() {
    cat > /etc/init.d/mysqld << 'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: mysql service script

### BEGIN INIT INFO
# Provides:          mysql
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: mysql
# Description:       mysql service script
### END INIT INFO

prefix={mysql_location}

NAME=mysql
PID_FILE=$prefix/mysql_data/$NAME.pid
BIN=$prefix/bin/mysqld_safe
CONFIG_FILE=$prefix/my.cnf

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
    $BIN --defaults-file=$CONFIG_FILE >/dev/null 2>&1 &
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    fi
    wait_for_pid created $PID_FILE
    if [ -n "$try" ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

skip-grant-tables-start()
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
    $BIN --defaults-file=$CONFIG_FILE --skip-grant-tables >/dev/null 2>&1 &
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    fi
    wait_for_pid created $PID_FILE
    if [ -n "$try" ] ; then
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
    kill `cat $PID_FILE`
    wait_for_pid removed $PID_FILE
    if [ -n "$try" ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

restart(){
    $0 stop
    $0 start
}

reload() {
    echo -n "Reload service $NAME... "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            kill -HUP `cat $PID_FILE`
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

set-root-password(){
    $0 stop
    $0 skip-grant-tables-start
    $prefix/bin/mysql -uroot -S /tmp/mysql.sock <<AAA
FLUSH PRIVILEGES;
ALTER USER root@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '$1';
ALTER USER root@'localhost' IDENTIFIED WITH mysql_native_password BY '$1';
FLUSH PRIVILEGES;
AAA
    $0 restart
}

case "$1" in
    start)
        start
        ;;
    skip-grant-tables-start)
        skip-grant-tables-start
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
    set-root-password)
        set-root-password $2
        ;;
    *)
        echo "Usage: $0 {start|skip-grant-tables-start|stop|restart|reload|status|set-root-password}"
esac
EOF
    sed -i "s|^prefix={mysql_location}$|prefix=${mysql_location}|g" /etc/init.d/mysqld
}


_config_mysql(){
    _create_sysv_script
    chmod +x /etc/init.d/mysqld
    update-rc.d -f mysqld defaults > /dev/null 2>&1
    chkconfig --add mysqld > /dev/null 2>&1
    /etc/init.d/mysqld start
    ${mysql_location}/bin/mysql -uroot -S /tmp/mysql.sock \
        -e "GRANT ALL PRIVILEGES ON *.* to root@'127.0.0.1' IDENTIFIED BY \"${mysql_pass}\" WITH GRANT OPTION;"
    ${mysql_location}/bin/mysql -uroot -S /tmp/mysql.sock \
        -e "GRANT ALL PRIVILEGES ON *.* to root@'localhost' IDENTIFIED BY \"${mysql_pass}\" WITH GRANT OPTION;"
    ${mysql_location}/bin/mysql -uroot -p${mysql_pass} -S /tmp/mysql.sock <<EOF
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.user WHERE NOT (user='root');
    DELETE FROM mysql.db WHERE user='';
    DELETE FROM mysql.user WHERE user="root" AND host="%";
    FLUSH PRIVILEGES;
EOF
    /etc/init.d/mysqld restart
}


_create_mysql_config(){
    local totalMemory=$(awk 'NR==1{print $2}' /proc/meminfo)
    if [[ ${totalMemory} -lt 393216 ]]; then
        memory=256M
    elif [[ ${totalMemory} -lt 786432 ]]; then
        memory=512M
    elif [[ ${totalMemory} -lt 1572864 ]]; then
        memory=1G
    elif [[ ${totalMemory} -lt 3145728 ]]; then
        memory=2G
    elif [[ ${totalMemory} -lt 6291456 ]]; then
        memory=4G
    elif [[ ${totalMemory} -lt 12582912 ]]; then
        memory=8G
    elif [[ ${totalMemory} -lt 25165824 ]]; then
        memory=16G
    else
        memory=32G
    fi

    case ${memory} in
        256M)innodb_log_file_size=32M;innodb_buffer_pool_size=64M;open_files_limit=512;table_open_cache=200;max_connections=64;;
        512M)innodb_log_file_size=32M;innodb_buffer_pool_size=128M;open_files_limit=512;table_open_cache=200;max_connections=128;;
        1G)innodb_log_file_size=64M;innodb_buffer_pool_size=256M;open_files_limit=1024;table_open_cache=400;max_connections=256;;
        2G)innodb_log_file_size=64M;innodb_buffer_pool_size=512M;open_files_limit=1024;table_open_cache=400;max_connections=300;;
        4G)innodb_log_file_size=128M;innodb_buffer_pool_size=1G;open_files_limit=2048;table_open_cache=800;max_connections=400;;
        8G)innodb_log_file_size=256M;innodb_buffer_pool_size=2G;open_files_limit=4096;table_open_cache=1600;max_connections=400;;
        16G)innodb_log_file_size=512M;innodb_buffer_pool_size=4G;open_files_limit=8192;table_open_cache=2000;max_connections=512;;
        32G)innodb_log_file_size=512M;innodb_buffer_pool_size=8G;open_files_limit=65535;table_open_cache=2048;max_connections=1024;;
        *)innodb_log_file_size=64M;innodb_buffer_pool_size=256M;open_files_limit=1024;table_open_cache=400;max_connections=256;;
    esac
    [ -f "/etc/my.cnf" ] && mv /etc/my.cnf /etc/my.cnf-$(date +%Y-%m-%d_%H:%M:%S).bak
    [ -d "/etc/mysql" ] && mv /etc/mysql /etc/mysql-$(date +%Y-%m-%d_%H:%M:%S).bak
    _info "Create ${mysql_location}/my.cnf file..."
    cat >${mysql_location}/my.cnf <<EOF
[client]
port                           = ${mysql_port}
socket                         = /tmp/mysql.sock
max-allowed-packet             = 10240M

[mysqld]
basedir                        = ${mysql_location}
datadir                        = ${mysql_location}/mysql_data
user                           = mysql
port                           = ${mysql_port}
socket                         = /tmp/mysql.sock
default-storage-engine         = InnoDB
pid-file                       = ${mysql_location}/mysql_data/mysql.pid
character-set-server           = utf8mb4
collation-server               = utf8mb4_unicode_ci
skip_name_resolve
skip-external-locking
log-error                      = ${mysql_location}/mysql_data/mysql-error.log

# INNODB #
innodb-log-files-in-group      = 2
innodb-log-file-size           = ${innodb_log_file_size}
innodb-flush-log-at-trx-commit = 2
innodb-file-per-table          = 1
innodb-buffer-pool-size        = ${innodb_buffer_pool_size}

# CACHES AND LIMITS #
tmp-table-size                 = 32M
max-heap-table-size            = 32M
max-connections                = ${max_connections}
thread-cache-size              = 50
open-files-limit               = ${open_files_limit}
table-open-cache               = ${table_open_cache}

# SAFETY #
max-allowed-packet             = 10240M
max-connect-errors             = 1000000

# BINLOG
log-bin                        = mysql-bin
log-bin-index                  = mysql-bin.index
sync-binlog                    = 1
expire-logs-days               = 3

# REPLICATION
relay-log                      = relay-bin
relay-log-index                = relay-bin.index

# SYNC
server-id                      = 1
slave-net-timeout              = 60
EOF
}

install_mysql56(){
    if [ $# -lt 2 ]; then
        echo "[Parameter Error]: mysql_location password [default_port]"
        exit 1
    fi
    mysql_location=${1}
    mysql_pass=${2}

    if [ $# -lt 3 ]; then
        mysql_port=3306
    else
        mysql_port=${3}
    fi

    _install_mysql_depend

    CheckError "rm -fr ${mysql_location}"
    Is64bit && sys_bit=x86_64 || sys_bit=i686
    cd /tmp
    if [ "${sys_bit}" == "x86_64" ]; then
        mysql56_filename=${mysql56_x86_64_filename}
        _info "Downloading and Extracting ${mysql56_filename} files..."
        DownloadFile "${mysql56_filename}.tar.gz" ${mysql56_x86_64_download_url}
        CheckError "rm -fr ${mysql56_filename}"
        tar zxf ${mysql56_filename}.tar.gz
    elif [ "${sys_bit}" == "i686" ]; then
        mysql56_filename=${mysql56_i686_filename}
        _info "Downloading and Extracting ${mysql56_filename} files..."
        DownloadFile "${mysql56_filename}.tar.gz" ${mysql56_i686_download_url}
        CheckError "rm -fr ${mysql56_filename}"
        tar zxf ${mysql56_filename}.tar.gz
    fi
    _info "Moving ${mysql56_filename} files..."
    CheckError "mv ${mysql56_filename} ${mysql_location}"
    _create_mysql_config
    CheckError "chown -R mysql:mysql ${mysql_location}"
    _info "Init MySQL..."
    CheckError "${mysql_location}/scripts/mysql_install_db \
        --basedir=${mysql_location} \
        --datadir=${mysql_location}/mysql_data --user=mysql"
    _config_mysql
    AddToEnv "${mysql_location}"
    CreateLib64Dir "${mysql_location}"
    echo $mysql_location > /tmp/mysql.info
    echo "Root password:${mysql_pass}, Please keep it safe."
    # Clean
    rm -fr /tmp/${mysql56_filename}
    _success "Install ${mysql56_filename} completed..."
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    install_mysql56 ${1} ${2} ${3}
}

echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
