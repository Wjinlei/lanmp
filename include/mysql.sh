_install_mysql_depend(){
    _info "Starting to install dependencies packages for MySQL..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(ncurses-devel cmake m4 bison libaio libaio-devel numactl-devel libevent)
        for depend in ${yum_depends[@]}
        do
            install_package "yum -y install ${depend}"
        done
        if is_64bit; then
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
            install_package "yum -y install perl-Data-Dumper"
        fi
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(libncurses5-dev cmake m4 bison libaio1 libaio-dev numactl)
        for depend in ${apt_depends[@]}
        do
            install_package "apt-get -y install ${depend}"
        done
    fi
    if echo $(get_opsy) | grep -Eqi "fedora"; then
        install_package "yum -y install ncurses-compat-libs"
    fi
    id -u hwsmysql >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U hwsmysql -r -d /dev/null -s /sbin/nologin
    _info "Install dependencies packages for MySQL completed..."
}

_config_mysql(){
    chown -R hwsmysql:hwsmysql ${mysql_location} ${mysql_data_location}
    sed -i "s:^basedir=.*:basedir=${mysql_location}:g" ${mysql_location}/support-files/mysql.server
    sed -i "s:^datadir=.*:datadir=${mysql_data_location}:g" ${mysql_location}/support-files/mysql.server
    _info "Starting MySQL..."
    ${mysql_location}/support-files/mysql.server start > /dev/null 2>&1
    if [ "${mysql}" == "${mysql80_filename}" ]; then
        ${mysql_location}/bin/mysql -uroot -hlocalhost -e "CREATE USER root@'127.0.0.1' IDENTIFIED BY \"${mysql_pass}\";"
        ${mysql_location}/bin/mysql -uroot -hlocalhost -e "GRANT ALL PRIVILEGES ON *.* to root@'127.0.0.1' WITH GRANT OPTION;"
        ${mysql_location}/bin/mysql -uroot -hlocalhost -e "GRANT ALL PRIVILEGES ON *.* to root@'localhost' WITH GRANT OPTION;"
        ${mysql_location}/bin/mysql -uroot -hlocalhost -e "ALTER USER root@'localhost' IDENTIFIED BY \"${mysql_pass}\";"
    else
        ${mysql_location}/bin/mysql -e "GRANT ALL PRIVILEGES ON *.* to root@'127.0.0.1' IDENTIFIED BY \"${mysql_pass}\" WITH GRANT OPTION;"
        ${mysql_location}/bin/mysql -e "GRANT ALL PRIVILEGES ON *.* to root@'localhost' IDENTIFIED BY \"${mysql_pass}\" WITH GRANT OPTION;"
        ${mysql_location}/bin/mysql -uroot -p${mysql_pass} > /dev/null 2>&1 <<EOF
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.user WHERE NOT (user='root');
    DELETE FROM mysql.db WHERE user='';
    DELETE FROM mysql.user WHERE user="root" AND host="%";
    FLUSH PRIVILEGES;
EOF
    fi
    _info "Restart MySQL..."
    ${mysql_location}/support-files/mysql.server restart >/dev/null 2>&1
    sqlite3 "${install_prefix}/hwslinuxmaster.db" <<EOF
PRAGMA foreign_keys = ON;
INSERT INTO hws_dbserver (path, name, version, port, password, servertype) VALUES ("${mysql_location}", "${mysql_filename}", "${mysql_ver}", ${mysql_port}, "${mysql_pass}", 1);
UPDATE hws_sysconfig SET value="${mysql_filename}" WHERE key="CurrentDbServer";
EOF
    cat >> ${install_prefix}/install.result <<EOF
MySQL Install Path: ${mysql_location}
MySQL Data Path: ${mysql_data_location}
MySQL Root PassWord: ${mysql_pass}
MySQL Config File: /etc/my.cnf

EOF
    _success "Install ${mysql} completed..."
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
    [ -f "/etc/my.cnf" ] && mv /etc/my.cnf /etc/my.cnf-$(date +%Y%m%d%H%M%S).bak
    [ -d "/etc/mysql" ] && mv /etc/mysql /etc/mysql-$(date +%Y%m%d%H%M%S).bak
    _info "Create /etc/my.cnf file..."
    cat >/etc/my.cnf <<EOF
[mysql]
port                           = ${mysql_port}
socket                         = /tmp/mysql.sock

[mysqld]
basedir                        = ${mysql_location}
datadir                        = ${mysql_data_location}
user                           = hwsmysql
port                           = 3306
socket                         = /tmp/mysql.sock
default-storage-engine         = InnoDB
pid-file                       = ${mysql_data_location}/mysql.pid
character-set-server           = utf8mb4
collation-server               = utf8mb4_unicode_ci
skip_name_resolve
skip-external-locking
log-error                      = ${mysql_data_location}/mysql-error.log

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
max-allowed-packet             = 16M
max-connect-errors             = 1000000

# BINLOG
log-bin                        = mysql-bin
log-bin-index                  = mysql-bin.index
sync-binlog                    = 1
expire-logs-days               = 15

# REPLICATION
relay-log                      = relay-bin
relay-log-index                = relay-bin.index

# SYNC
server-id                      = 1
slave-net-timeout              = 60
EOF
}

_install_mysql(){
    _install_mysql_depend
    is_64bit && sys_bit=x86_64 || sys_bit=i686
    local mysql_ver=$(echo ${mysql} | sed 's/[^0-9.]//g' | cut -d. -f1-2)
    local mysql_pass=$(generate_password)
    cd ${cur_dir}/software
    _info "Downloading and Extracting ${mysql} files..."

    mysql_filename="${mysql}-linux-glibc2.12-${sys_bit}"
    if [ "${mysql_ver}" == "8.0" ]; then
        mysql_url="https://cdn.mysql.com/Downloads/MySQL-${mysql_ver}/${mysql_filename}.tar.xz"
        download_file "${mysql_filename}.tar.xz" "${mysql_url}"
        rm -fr ${mysql_filename}
        tar Jxf ${mysql_filename}.tar.xz
    else
        mysql_url="https://cdn.mysql.com/Downloads/MySQL-${mysql_ver}/${mysql_filename}.tar.gz"
        download_file "${mysql_filename}.tar.gz" "${mysql_url}"
        rm -fr ${mysql_filename}
        tar zxf ${mysql_filename}.tar.gz
    fi
    _info "Moving ${mysql} files..."
    mv ${mysql_filename} ${mysql_location}
    _create_mysql_config
    _info "Init MySQL..."
    if [ "${mysql_ver}" == "8.0" ]; then
        echo "default_authentication_plugin  = mysql_native_password" >> /etc/my.cnf
    fi
    if [ "${mysql_ver}" == "5.5" ] || [ "${mysql_ver}" == "5.6" ]; then
        ${mysql_location}/scripts/mysql_install_db --basedir=${mysql_location} --datadir=${mysql_data_location} --user=hwsmysql
    elif [ "${mysql_ver}" == "5.7" ] || [ "${mysql_ver}" == "8.0" ]; then
        ${mysql_location}/bin/mysqld --initialize-insecure --basedir=${mysql_location} --datadir=${mysql_data_location} --user=hwsmysql
    fi
    _config_mysql
}

install_mysql(){
    _install_mysql
}
