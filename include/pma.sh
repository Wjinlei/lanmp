install_pma(){
    [ "$#" -lt 1 ] && echo "Missing parameters,Please specify the installation path" && exit 1
    if [ ! -d "${1}" ]; then
        mkdir -p "${1}"
        if [ "$?" -ne 0 ]; then
            echo "Create directory failed: ${1}" && exit 1
        fi
    else
        if [ ! -d "${1}/phpMyAdmin" ]; then
            cd /tmp
            _info "${phpmyadmin49_filename} install start..."
            DownloadFile "${phpmyadmin49_filename}.tar.gz" "${phpmyadmin49_download_url}"
            rm -fr ${phpmyadmin49_filename}
            tar zxf ${phpmyadmin49_filename}.tar.gz
            mv ${phpmyadmin49_filename} ${1}/phpMyAdmin
            wget --no-check-certificate -cv -t3 -T60 "https://d.hws.com/free/hwslinuxmaster/conf/phpmyadmin-conf.tar.gz"
            rm -f /tmp/config.inc.php
            tar zxf phpmyadmin-conf.tar.gz
            cp -f config.inc.php ${1}/phpMyAdmin/config.inc.php
            mkdir -p ${1}/phpMyAdmin/{upload,save}
            local tmpUser=$(ls -ld ${1}|awk '{print $3}')
            local tmpGroup=$(ls -ld ${1}|awk '{print $4}')
            chown -R ${tmpUser}:${tmpGroup} ${1}/phpMyAdmin
            _success "${phpmyadmin49_filename} install completed..."
            rm -f /tmp/config.inc.php
        else
            echo "${1}/phpMyAdmin Directory already exists" && exit 1
        fi
    fi
}
