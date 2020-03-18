install_pma49(){
    mkdir -p ${1}
    rm -fr ${1}/pma
    cd /tmp
    _info "${phpmyadmin49_filename} install start..."
    DownloadFile "${phpmyadmin49_filename}.tar.gz" "${phpmyadmin49_download_url}"
    rm -fr ${phpmyadmin49_filename}
    tar zxf ${phpmyadmin49_filename}.tar.gz
    mv ${phpmyadmin49_filename} ${1}/pma
    wget --no-check-certificate -cv -t3 -T60 "https://d.hws.com/free/hwslinuxmaster/conf/phpmyadmin-conf.tar.gz"
    rm -f /tmp/config.inc.php
    tar zxf phpmyadmin-conf.tar.gz
    cp -f config.inc.php ${1}/pma/config.inc.php
    mkdir -p ${1}/pma/{upload,save}
    local tmpUser=$(ls -ld ${1}|awk '{print $3}')
    local tmpGroup=$(ls -ld ${1}|awk '{print $4}')
    chown -R ${tmpUser}:${tmpGroup} ${1}/pma
    _success "${phpmyadmin49_filename} install completed..."
    rm -f /tmp/${phpmyadmin49_filename}.tar.gz
    rm -f /tmp/phpmyadmin-conf.tar.gz
    rm -f /tmp/config.inc.php
}
