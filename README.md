## 关于脚本
L(Linux) + A(Apache) + N(Nginx) + M(MySQL) + P(PHP) 安装脚本<br/>

一开始脚本本是为护卫神Linux大师而编写,但为了方便后期扩展和通用性考虑,脚本已和面板拆分,<br/>
现在已经可以独立运行,你可不必安装护卫神Linux大师面板程序.<br/>
脚本参考了开源项目: https://github.com/teddysun/lamp 进行了大量精简,修改和增强,在此感谢原作者 teddysun<br/>

### 支持的软件
- Apache2.4 (包含http/2模块: nghttp2)
- MySQL5.5, MySQL5.6, MySQL5.7, MySQL8.0
- PHP-5.3, PHP-5.4, PHP-5.5, PHP-5.6, PHP-7.0, PHP-7.1, PHP-7.2, PHP-7.3 (全部采用php-fpm方式)
- Pure-ftpd
- Nginx
- Redis
- PhpMyadmin
- PHP 扩展: Zend OPcache, redis

### 软件版本
|软件名|版本|
|---|---|
|httpd|2.4.41|
|apr|1.7.0|
|apr-util|1.6.1|
|nghttp2|1.40.0|
|openssl|1.1.1d|
|MySQL|5.5.62, 5.6.47, 5.7.29, 8.0.19|
|PHP|5.3.29, 5.4.45, 5.5.38, 5.6.40, 7.0.33, 7.1.33, 7.2.27, 7.3.14|
|Redis|5.0.6|
|pure-ftpd|1.0.49|
|nginx|1.16.1|
|phpmyadmin|4.9.4|

|PHP扩展|版本|
|---|---|
|redis(PHP5)|4.3.0|
|redis(PHP7)|5.1.1|

### 支持的操作系统
- CentOS-6.x
- CentOS-7.x (recommend)
- CentOS-8.x (theoretically support)
- Fedora-29
- Debian-8.x
- Debian-9.x (recommend)
- Ubuntu-16.x
- Ubuntu-18.x (recommend)

### 使用方法
```
# 查看帮助
./install.sh --help

example:
# 安装apache到默认位置(/linuxmaster)
./install.sh --install-apache

# 安装apache到/www/apache目录
./install.sh --install-apache /www/apache

PS:参数以空格分隔,第一个参数表示要执行的功能,第二参数表示要安装的位置,如果指定,则默认安装到/linuxmaster


# 用于给php安装扩展(目前只支持安装php-redis扩展,更多扩展安装功能开发中...)
./php-tools.sh --help

example:
./php-tools.sh --install-php-redis /www/php/php73/bin/php-config /www/php/php73/bin/phpize
PS:参数以空格分隔,第一个参数表示要执行的功能,第二个参数指定php-config的位置,第三个参数指定phpize的位置


写在最后:
环境安装后,会固定生成/linuxmaster/install.result文件,里面记录了软件的相关信息
/linuxmaster 目录可以自己根据自身情况选择删除
软件位置可以重复安装,重复安装不会造成配置丢失,脚本会自动备份配置并还原
```
