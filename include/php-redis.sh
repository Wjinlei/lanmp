_install_php_redis4(){
    local php_extension_dir=$(${1} --extension-dir)
    local phpBin=$(${1} --php-binary)
    local phpPrefix=$(${1} --prefix)
    local phpScanDIr=$(${phpBin} -r "echo PHP_CONFIG_FILE_SCAN_DIR;")
    cd /tmp
    _info "PHP extension redis install start..."
    DownloadFile  "${php_redis4_filename}.tgz" "${php_redis4_download_url}"
    rm -fr ${php_redis4_filename}
    tar zxf ${php_redis4_filename}.tgz
    cd ${php_redis4_filename}
    CheckError "${2}"
    CheckError "./configure --enable-redis --with-php-config=${1}"
    CheckError "make"
    CheckError "make install"
    if [ ! -f ${phpScanDIr}/redis.ini ]; then
        _info "PHP extension redis configuration file not found, create it!"
        cat > ${phpScanDIr}/redis.ini<<EOF
[redis]
extension = ${php_extension_dir}/redis.so
EOF
    fi
    rm -f ${php_redis4_filename}.tgz
    rm -fr ${php_redis4_filename}
    _success "PHP extension redis install completed!"
    _info "Plase Restart Php..."
}

_install_php_redis5(){
    local php_extension_dir=$(${1} --extension-dir)
    local phpBin=$(${1} --php-binary)
    local phpPrefix=$(${1} --prefix)
    local phpScanDIr=$(${phpBin} -r "echo PHP_CONFIG_FILE_SCAN_DIR;")
    cd /tmp
    _info "PHP extension redis install start..."
    DownloadFile  "${php_redis5_filename}.tgz" "${php_redis5_download_url}"
    rm -fr ${php_redis5_filename}
    tar zxf ${php_redis5_filename}.tgz
    cd ${php_redis5_filename}
    CheckError "${2}"
    CheckError "./configure --enable-redis --with-php-config=${1}"
    CheckError "make"
    CheckError "make install"
    if [ ! -f ${phpScanDIr}/redis.ini ]; then
        _info "PHP extension redis configuration file not found, create it!"
        cat > ${phpScanDIr}/redis.ini<<EOF
[redis]
extension = ${php_extension_dir}/redis.so
EOF
    fi
    rm -f ${php_redis5_filename}.tgz
    rm -fr ${php_redis5_filename}
    _success "PHP extension redis install completed!"
    _info "Plase Restart Php..."
}

install_php_redis(){
    if [ "$#" -lt 2 ]; then
        echo "Missing parameters,Please Usage: $0 -h, Show Help"
        exit 1
    fi
    ${1} --version > /dev/null 2>&1
    if [ "$?" -ne 0 ]; then
        echo "php-config does not exist or php-config error"
        exit 1
    fi
    local phpVersion=$(${1} --version)
    php5=$(echo ${phpVersion} |grep ^5)
    php7=$(echo ${phpVersion} |grep ^7)
    if [ "${php5}" != "" ]; then
        _install_php_redis4 ${1} ${2}
    elif [ "${php7}" != "" ]; then
        _install_php_redis5 ${1} ${2}
    else
        echo "Php Version not support!"
        exit 1
    fi
}
