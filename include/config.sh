load_config(){
# Download Url
download_root_url="https://d.hws.com/free/hwslinuxmaster/soft/"

# Install Path
soft_location=${install_prefix}/soft
nginx_location=${soft_location}/nginx
php53_location=${soft_location}/php/php53
php54_location=${soft_location}/php/php54
php55_location=${soft_location}/php/php55
php56_location=${soft_location}/php/php56
php70_location=${soft_location}/php/php70
php71_location=${soft_location}/php/php71
php72_location=${soft_location}/php/php72
php73_location=${soft_location}/php/php73
php74_location=${soft_location}/php/php74
redis_location=${soft_location}/redis
mysql_location=${soft_location}/mysql
apache_location=${soft_location}/apache
pureftpd_location=${soft_location}/pure-ftpd

#MySQL Data Path
mysql_data_location=${install_prefix}/mysql_data

#Web root location
web_root_dir=${install_prefix}/www
default_site_dir=${install_prefix}/www/default

#Install depends location
depends_prefix=${soft_location}/depends

#parallel compile option,1:enable,0:disable
parallel_compile=1

#Software
#apr
apr_filename="apr-1.7.0"
apr_url="http://ftp.jaist.ac.jp/pub/apache//apr/apr-1.7.0.tar.gz"
#apr-util
apr_util_filename="apr-util-1.6.1"
apr_util_url="http://ftp.jaist.ac.jp/pub/apache//apr/apr-util-1.6.1.tar.gz"
#apache2.4
apache_filename="httpd-2.4.41"
apache_url="http://ftp.jaist.ac.jp/pub/apache//httpd/httpd-2.4.41.tar.gz"
apache_version="2.4.41"
#nginx
nginx_filename="nginx-1.16.1"
nginx_url="http://nginx.org/download/nginx-1.16.1.tar.gz"
nginx_version="1.16.1"
#mysql
mysql55_filename="mysql-5.5.62"
mysql56_filename="mysql-5.6.47"
mysql57_filename="mysql-5.7.29"
mysql80_filename="mysql-8.0.19"
mysql_port="3306"
#libzip
libzip_filename="libzip-1.3.2"
libzip_filename_url="https://libzip.org/download/libzip-1.3.2.tar.gz"
#libiconv
libiconv_filename="libiconv-1.16"
libiconv_filename_url="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz"
libiconv_patch="libiconv-glibc-2.16"
libiconv_patch_url="https://d.hws.com/free/hwslinuxmaster/soft/libiconv-glibc-2.16.tar.gz"
#phpMyAdmin PHP 5.5 to 7.4 and MySQL 5.5 and newer
phpmyadmin49_filename="phpMyAdmin-4.9.4-all-languages"
phpmyadmin49_url="https://files.phpmyadmin.net/phpMyAdmin/4.9.4/phpMyAdmin-4.9.4-all-languages.tar.gz"
#redis
redis_filename="redis-5.0.6"
redis_filename_url="http://download.redis.io/releases/redis-5.0.6.tar.gz"
redis_version="5.0.6"
redis_port="6379"
#php-redis
php_redis_filename="redis-4.3.0"
php_redis_filename_url="https://pecl.php.net/get/redis-4.3.0.tgz"
php_redis_filename2="redis-5.1.1"
php_redis_filename2_url="https://pecl.php.net/get/redis-5.1.1.tgz"
#pure-ftpd
pureftpd_filename="pure-ftpd-1.0.49"
pureftpd_filename_url="https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.49.tar.gz"
pureftpd_version="1.0.49"
pureftpd_port="21"

#php
php53_filename="php-5.3.29"
php53_url="https://www.php.net/distributions/php-5.3.29.tar.gz"
php54_filename="php-5.4.45"
php54_url="https://www.php.net/distributions/php-5.4.45.tar.gz"
php55_filename="php-5.5.38"
php55_url="https://www.php.net/distributions/php-5.5.38.tar.gz"
php56_filename="php-5.6.40"
php56_url="https://www.php.net/distributions/php-5.6.40.tar.gz"
php70_filename="php-7.0.33"
php70_url="https://www.php.net/distributions/php-7.0.33.tar.gz"
php71_filename="php-7.1.33"
php71_url="https://www.php.net/distributions/php-7.1.33.tar.gz"
php72_filename="php-7.2.27"
php72_url="https://www.php.net/distributions/php-7.2.27.tar.gz"
php73_filename="php-7.3.14"
php73_url="https://www.php.net/distributions/php-7.3.14.tar.gz"
php74_filename="php-7.4.2"
php74_url="https://www.php.net/distributions/php-7.4.2.tar.gz"

menu_arr=(
"lamp(Linux + ${apache_filename} + ${mysql57_filename} + ${php55_filename} + ${pureftpd_filename})"
"lnmp(Linux + ${nginx_filename} + ${mysql57_filename} + ${php55_filename} + ${pureftpd_filename})"
customize
do_not_install
)

webserver_arr=(
${apache_filename}
${nginx_filename}
do_not_install
)

mysql_arr=(
${mysql55_filename}
${mysql56_filename}
${mysql57_filename}
${mysql80_filename}
do_not_install
)

php_arr=(
${php53_filename}
${php54_filename}
${php55_filename}
${php56_filename}
${php70_filename}
${php71_filename}
${php72_filename}
${php73_filename}
${php74_filename}
do_not_install
)

ftpd_arr=(
${pureftpd_filename}
do_not_install
)

}
