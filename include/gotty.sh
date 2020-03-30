_install_gotty_depend(){
    mkdir -p ${gotty_location}
}

install_gotty(){
    _install_gotty_depend
    pkill -9 gotty > /dev/null 2>&1
    Is64bit && sys_bit=x86_64 || sys_bit=i686
    cd /tmp
    if [ "${sys_bit}" == "x86_64" ]; then
        gotty_filename=${gotty_x86_64_filename}
        _info "Downloading and Extracting ${gotty_filename} files..."
        DownloadFile "${gotty_filename}.tar.gz" ${gotty_x86_64_download_url}
        rm -f gotty
        tar zxf ${gotty_filename}.tar.gz
    elif [ "${sys_bit}" == "i686" ]; then
        gotty_filename=${gotty_i686_filename}
        _info "Downloading and Extracting ${gotty_filename} files..."
        DownloadFile "${gotty_filename}.tar.gz" ${gotty_i686_download_url}
        rm -f gotty
        tar zxf ${gotty_filename}.tar.gz
    fi
        rm -f ${gotty_location}/gotty
        mv gotty ${gotty_location}
    _success "Install ${gotty_filename} completed..."
}
