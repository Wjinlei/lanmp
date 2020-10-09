load_config(){

# data
var=/var/hwsmaster

# download Url
download_root_url="https://d.hws.com/linux/master/soft/"
download_sysv_url="https://d.hws.com/linux/debug/script/init.d/"

# parallel compile option,1:enable,0:disable
parallel_compile=1

# apache
apache_filename="httpd-2.4.41"
apache_download_url="http://ftp.jaist.ac.jp/pub/apache/httpd/httpd-2.4.41.tar.gz"

# nginx
nginx_filename="nginx-1.16.1"
nginx_download_url="http://nginx.org/download/nginx-1.16.1.tar.gz"

# pureftpd_filename
pureftpd_filename="pure-ftpd-1.0.49"
pureftpd_download_url="https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.49.tar.gz"

# redis
redis_filename="redis-5.0.6"
redis_download_url="http://download.redis.io/releases/redis-5.0.6.tar.gz"

# php-redis
php_redis4_filename="redis-4.3.0"
php_redis4_download_url="https://pecl.php.net/get/redis-4.3.0.tgz"
php_redis5_filename="redis-5.1.1"
php_redis5_download_url="https://pecl.php.net/get/redis-5.1.1.tgz"

# mysql
mysql55_i686_filename="mysql-5.5.62-linux-glibc2.12-i686"
mysql55_i686_download_url="https://cdn.mysql.com/Downloads/MySQL-5.5/${mysql55_i686_filename}.tar.gz"
mysql55_x86_64_filename="mysql-5.5.62-linux-glibc2.12-x86_64"
mysql55_x86_64_download_url="https://cdn.mysql.com/Downloads/MySQL-5.5/${mysql55_x86_64_filename}.tar.gz"
mysql56_i686_filename="mysql-5.6.47-linux-glibc2.12-i686"
mysql56_i686_download_url="https://cdn.mysql.com/Downloads/MySQL-5.6/${mysql56_i686_filename}.tar.gz"
mysql56_x86_64_filename="mysql-5.6.47-linux-glibc2.12-x86_64"
mysql56_x86_64_download_url="https://cdn.mysql.com/Downloads/MySQL-5.6/${mysql56_x86_64_filename}.tar.gz"
mysql57_i686_filename="mysql-5.7.29-linux-glibc2.12-i686"
mysql57_i686_download_url="https://cdn.mysql.com/Downloads/MySQL-5.7/${mysql57_i686_filename}.tar.gz"
mysql57_x86_64_filename="mysql-5.7.29-linux-glibc2.12-x86_64"
mysql57_x86_64_download_url="https://cdn.mysql.com/Downloads/MySQL-5.7/${mysql57_x86_64_filename}.tar.gz"
mysql80_i686_filename="mysql-8.0.19-linux-glibc2.12-i686"
mysql80_i686_download_url="https://cdn.mysql.com/Downloads/MySQL-8.0/${mysql80_i686_filename}.tar.xz"
mysql80_x86_64_filename="mysql-8.0.19-linux-glibc2.12-x86_64"
mysql80_x86_64_download_url="https://cdn.mysql.com/Downloads/MySQL-8.0/${mysql80_x86_64_filename}.tar.xz"

# php
php52_filename="php-5.2.17"
php52_download_url="http://museum.php.net/php5/php-5.2.17.tar.gz"
php53_filename="php-5.3.29"
php53_download_url="https://www.php.net/distributions/php-5.3.29.tar.gz"
php54_filename="php-5.4.45"
php54_download_url="https://www.php.net/distributions/php-5.4.45.tar.gz"
php55_filename="php-5.5.38"
php55_download_url="https://www.php.net/distributions/php-5.5.38.tar.gz"
php56_filename="php-5.6.40"
php56_download_url="https://www.php.net/distributions/php-5.6.40.tar.gz"
php70_filename="php-7.0.33"
php70_download_url="https://www.php.net/distributions/php-7.0.33.tar.gz"
php71_filename="php-7.1.33"
php71_download_url="https://www.php.net/distributions/php-7.1.33.tar.gz"
php72_filename="php-7.2.27"
php72_download_url="https://www.php.net/distributions/php-7.2.27.tar.gz"
php73_filename="php-7.3.14"
php73_download_url="https://www.php.net/distributions/php-7.3.14.tar.gz"
php74_filename="php-7.4.3"
php74_download_url="https://www.php.net/distributions/php-7.4.3.tar.gz"

# libiconv
libiconv_filename="libiconv-1.16"
libiconv_download_url="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz"
libiconv_patch_filename="libiconv-glibc-2.16"
libiconv_patch_download_url="${download_root_url}libiconv-glibc-2.16.tar.gz"

# re2c
re2c_filename="re2c-1.3"
re2c_download_url="https://github.com/skvadrik/re2c/releases/download/1.3/re2c-1.3.tar.xz"

# mhash
mhash_filename="mhash-0.9.9.9"
mhash_download_url="https://sourceforge.net/projects/mhash/files/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz/download"

# mcrypt
mcrypt_filename="mcrypt-2.6.8"
mcrypt_download_url="https://sourceforge.net/projects/mcrypt/files/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz/download"

#libmcrypt
libmcrypt_filename="libmcrypt-2.5.8"
libmcrypt_download_url="https://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz/download"

# libzip
libzip_filename="libzip-1.3.2"
libzip_download_url="https://libzip.org/download/libzip-1.3.2.tar.gz"

# phpmyadmin
phpmyadmin_filename="phpMyAdmin-4.6.6-all-languages"
phpmyadmin_download_url="https://files.phpmyadmin.net/phpMyAdmin/4.6.6/phpMyAdmin-4.6.6-all-languages.tar.gz"

# depends
# pcre
pcre_location=/usr/local/pcre
pcre_filename="pcre-8.43"
pcre_download_url="https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz"

# openssl
openssl_location=/usr/local/openssl111
openssl_filename="openssl-1.1.1d"
openssl_download_url="https://www.openssl.org/source/openssl-1.1.1d.tar.gz"
openssl102_location=/usr/local/openssl102
openssl102_filename="openssl-1.0.2u"
openssl102_download_url="https://www.openssl.org/source/old/1.0.2/openssl-1.0.2u.tar.gz"

#curl
curl_location=/usr/local/curl
curl_filename="curl-7.29.0"
curl_download_url="https://curl.haxx.se/download/curl-7.29.0.tar.gz"

#icu4c
icu4c_location=/usr/local/icu4c
icu4c_dirname="icu"
icu4c_filename="icu4c-50_2-src"
icu4c_download_url="https://github.com/unicode-org/icu/releases/download/release-50-2/icu4c-50_2-src.tgz"

#libxml2
libxml2_location=/usr/local/libxml2
libxml2_filename="libxml2-2.9.4"
libxml2_download_url="ftp://xmlsoft.org/libxml2/libxml2-2.9.4.tar.gz"

#freetype2
freetype_location=/usr/local/freetype2
freetype_filename="freetype-2.8.1"
freetype_download_url="https://download.savannah.gnu.org/releases/freetype/freetype-2.8.1.tar.gz"

# nghttp2
nghttp2_location=/usr/local/nghttp2
nghttp2_filename="nghttp2-1.40.0"
nghttp2_download_url="https://github.com/nghttp2/nghttp2/releases/download/v1.40.0/nghttp2-1.40.0.tar.gz"

# apr
apr_filename="apr-1.7.0"
apr_download_url="http://ftp.jaist.ac.jp/pub/apache/apr/apr-1.7.0.tar.gz"

# apr-util
apr_util_filename="apr-util-1.6.1"
apr_util_download_url="http://ftp.jaist.ac.jp/pub/apache/apr/apr-util-1.6.1.tar.gz"

# Other
mysql_port=3306
redis_port=6379
ftp_port=21
apache_port=80
nginx_port=80
}
