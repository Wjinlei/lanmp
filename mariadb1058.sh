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
    _info "Starting to install dependencies packages for MariaDB..."
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
    [ $? -ne 0 ] && useradd -M -U mysql -d /home/mysql -s /sbin/nologin
    _info "Install dependencies packages for MariaDB completed..."
}

_config_mysql(){
    DownloadUrl "/etc/init.d/mysqld" "${download_sysv_url}/mysqld"
    sed -i "s|^prefix={mysql_location}$|prefix=${mysql_location}|g" /etc/init.d/mysqld
    CheckError "chmod +x /etc/init.d/mysqld"
    update-rc.d -f mysqld defaults > /dev/null 2>&1
    chkconfig --add mysqld > /dev/null 2>&1
    /etc/init.d/mysqld start
    ${mysql_location}/bin/mysql -uroot -S /tmp/mysql.sock \
        -e "CREATE USER root@'127.0.0.1' IDENTIFIED BY \"${mysql_pass}\";"
    ${mysql_location}/bin/mysql -uroot -S /tmp/mysql.sock \
        -e "ALTER USER root@'localhost' IDENTIFIED BY \"${mysql_pass}\";"
    ${mysql_location}/bin/mysql -uroot -p${mysql_pass} -S /tmp/mysql.sock \
        -e "GRANT ALL PRIVILEGES ON *.* to root@'127.0.0.1' WITH GRANT OPTION;" >/dev/null 2>&1
    ${mysql_location}/bin/mysql -uroot -p${mysql_pass} -S /tmp/mysql.sock \
        -e "GRANT ALL PRIVILEGES ON *.* to root@'localhost' WITH GRANT OPTION;" >/dev/null 2>&1
    ${mysql_location}/bin/mysql -uroot -p${mysql_pass} -S /tmp/mysql.sock <<EOF
    DROP DATABASE IF EXISTS test;
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

install_mariadb1058(){
    if [ $# -lt 2 ]; then
        echo "[Parameter Error]: mysql_location password [default_port]"
        exit 1
    fi
    mysql_location=${1}
    mysql_pass=${2}

    # 如果存在第三个参数
    if [ $# -ge 3 ]; then
        mysql_port=${3}
    fi

    _install_mysql_depend

    CheckError "rm -fr ${mysql_location}"
    Is64bit && sys_bit=x86_64 || sys_bit=i686
    cd /tmp
    if [ "${sys_bit}" == "x86_64" ]; then
        mariadb1058_filename=${mariadb1058_x86_64_filename}
        _info "Downloading and Extracting ${mariadb1058_filename} files..."
        DownloadFile "${mariadb1058_filename}.tar.gz" ${mariadb1058_x86_64_download_url}
        CheckError "rm -fr ${mariadb1058_filename}"
        tar zxf ${mariadb1058_filename}.tar.gz
    elif [ "${sys_bit}" == "i686" ]; then
        mariadb1058_filename=${mariadb1058_i686_filename}
        _info "Downloading and Extracting ${mariadb1058_filename} files..."
        DownloadFile "${mariadb1058_filename}.tar.gz" ${mariadb1058_i686_download_url}
        CheckError "rm -fr ${mariadb1058_filename}"
        tar zxf ${mariadb1058_filename}.tar.gz
    fi
    _info "Moving ${mariadb1058_filename} files..."
    CheckError "mv ${mariadb1058_filename} ${mysql_location}"
    _create_mysql_config
    CheckError "chown -R mysql:mysql ${mysql_location}"
    _info "Init MariaDB..."
    CheckError "${mysql_location}/scripts/mysql_install_db \
        --basedir=${mysql_location} \
        --datadir=${mysql_location}/mysql_data --user=mysql"
    _config_mysql
    AddToEnv "${mysql_location}"
    CreateLib64Dir "${mysql_location}"
    echo $mysql_location > /tmp/mysql.info
    echo "Root password:${mysql_pass}, Please keep it safe."
    _success "Install ${mariadb1058_filename} completed..."
    rm -fr /tmp/${mariadb1058_filename}
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    install_mariadb1058 ${1} ${2} ${3}
}
echo "The installation log will be written to /tmp/install.log"
echo "Use tail -f /tmp/install.log to view dynamically"
rm -fr ${cur_dir}/tmps
main "$@" > /tmp/install.log 2>&1
rm -fr ${cur_dir}/tmps
