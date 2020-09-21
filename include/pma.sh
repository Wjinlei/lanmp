install_pma(){
    mkdir -p ${var}/default/pma
    cd /tmp
    _info "${phpmyadmin_filename} install start..."
    DownloadFile "${phpmyadmin_filename}.tar.gz" "${phpmyadmin_download_url}"
    rm -fr ${phpmyadmin_filename} 
    rm -fr ${var}/default/pma
    tar zxf ${phpmyadmin_filename}.tar.gz && \
        mv ${phpmyadmin_filename} ${var}/default/pma && \
        rm -fr ${var}/default/pma/setup && \
        mkdir -p ${var}/default/pma/{upload,save}

    # 下载配置文件
    CheckError "wget --no-check-certificate -cv -t3 -T60 https://d.hws.com/linux/master/conf/phpmyadmin-conf.tar.gz"
    tar zxf phpmyadmin-conf.tar.gz && cp -f config.inc.php ${var}/default/pma/config.inc.php

    chown -R www:www ${var}/default/pma

    _success "${phpmyadmin_filename} install completed..."
    rm -f /tmp/config.inc.php
}
