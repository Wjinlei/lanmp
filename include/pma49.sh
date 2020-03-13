install_pma49(){
    if [ ! -d "${default_site_dir}/pma" ]; then
        cd /tmp
        _info "${phpmyadmin49_filename} install start..."
        DownloadFile "${phpmyadmin49_filename}.tar.gz" "${phpmyadmin49_download_url}"
        rm -fr ${phpmyadmin49_filename}
        tar zxf ${phpmyadmin49_filename}.tar.gz
        mv ${phpmyadmin49_filename} ${default_site_dir}/pma
        wget --no-check-certificate -cv -t3 -T60 "https://d.hws.com/free/hwslinuxmaster/conf/phpmyadmin-conf.tar.gz"
        rm -f /tmp/config.inc.php
        tar zxf phpmyadmin-conf.tar.gz
        cp -f config.inc.php ${default_site_dir}/pma/config.inc.php
        mkdir -p ${default_site_dir}/pma/{upload,save}
        chown -R www:www ${default_site_dir}/pma
        _success "${phpmyadmin49_filename} install completed..."
        rm -f /tmp/${phpmyadmin49_filename}.tar.gz
        rm -f /tmp/phpmyadmin-conf.tar.gz
        rm -f /tmp/config.inc.php
    fi
}
