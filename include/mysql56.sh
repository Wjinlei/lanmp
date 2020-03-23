_install_mysql_depend(){
    _info "Starting to install dependencies packages for MySQL..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(ncurses-devel cmake m4 bison libaio libaio-devel numactl-devel libevent)
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
        local apt_depends=(libncurses5-dev cmake m4 bison libaio1 libaio-dev numactl)
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
    mkdir -p ${mysql56_location}
    _info "Install dependencies packages for MySQL completed..."
}

_config_mysql(){
    chown -R mysql:mysql ${mysql56_location} ${mysql_data_location}
    sed -i "s:^basedir=.*:basedir=${mysql56_location}:g" ${mysql56_location}/support-files/mysql.server
    sed -i "s:^datadir=.*:datadir=${mysql_data_location}:g" ${mysql56_location}/support-files/mysql.server
    _info "Starting MySQL..."
    ${mysql56_location}/support-files/mysql.server start > /dev/null 2>&1
    ${mysql56_location}/bin/mysql -e "GRANT ALL PRIVILEGES ON *.* to root@'127.0.0.1' IDENTIFIED BY \"${mysql_pass}\" WITH GRANT OPTION;"
    ${mysql56_location}/bin/mysql -e "GRANT ALL PRIVILEGES ON *.* to root@'localhost' IDENTIFIED BY \"${mysql_pass}\" WITH GRANT OPTION;"
    ${mysql56_location}/bin/mysql -uroot -p${mysql_pass} > /dev/null 2>&1 <<EOF
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.user WHERE NOT (user='root');
    DELETE FROM mysql.db WHERE user='';
    DELETE FROM mysql.user WHERE user="root" AND host="%";
    FLUSH PRIVILEGES;
EOF
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
    _info "Create /etc/my.cnf file..."
    cat >/etc/my.cnf <<EOF
[mysql]
port                           = ${mysql_port}
socket                         = /tmp/mysql.sock

[mysqld]
basedir                        = ${mysql56_location}
datadir                        = ${mysql_data_location}
user                           = mysql
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
    killall mysqld > /dev/null 2>&1
    [ -d "${mysql_data_location}" ] && mv ${mysql_data_location} ${mysql_data_location}-$(date +%Y-%m-%d_%H:%M:%S).bak
    _install_mysql_depend
    Is64bit && sys_bit=x86_64 || sys_bit=i686
    cd /tmp
    if [ "${sys_bit}" == "x86_64" ]; then
        mysql56_filename=${mysql56_x86_64_filename}
        _info "Downloading and Extracting ${mysql56_filename} files..."
        DownloadFile "${mysql56_filename}.tar.gz" ${mysql56_x86_64_download_url}
        rm -fr ${mysql56_filename}
        tar zxf ${mysql56_filename}.tar.gz
    elif [ "${sys_bit}" == "i686" ]; then
        mysql56_filename=${mysql56_i686_filename}
        _info "Downloading and Extracting ${mysql56_filename} files..."
        DownloadFile "${mysql56_filename}.tar.gz" ${mysql56_i686_download_url}
        rm -fr ${mysql56_filename}
        tar zxf ${mysql56_filename}.tar.gz
    fi
    _info "Moving ${mysql56_filename} files..."
    mv ${mysql56_filename}/* ${mysql56_location}
    _create_mysql_config
    _info "Init MySQL..."
    ${mysql56_location}/scripts/mysql_install_db --basedir=${mysql56_location} --datadir=${mysql_data_location} --user=mysql
    _config_mysql
    _info "Restart MySQL..."
    ${mysql56_location}/support-files/mysql.server restart >/dev/null 2>&1
    cat >> ${prefix}/install.result <<EOF
Install Time: $(date +%Y-%m-%d_%H:%M:%S)
MySQL56 Install Path:${mysql56_location}
MySQL56 Data Path:${mysql_data_location}
MySQL56 Root PassWord:${mysql_pass}
MySQL Config File: /etc/my.cnf

EOF
    _success "Install ${mysql56_filename} completed..."
    rm -fr /tmp/${mysql56_filename}
}
