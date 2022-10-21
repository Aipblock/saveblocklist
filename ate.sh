#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#颜色文字
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}
#Tengine支持CentOS7/Debian10/11一键安装
function install_tengine() {
	if [[ "${release}" == "centos" ]]; then
        yum update -y
        yum install epel-release -y
        yum install gcc gcc-c++ autoconf automake -y
        yum install pcre-devel -y
        yum install openssl-devel -y
        yum install libmcrypt libmcrypt-devel mcrypt mhash -y
		yum install kernel-headers kernel-devel make -y
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        apt-get update -y
	apt-get upgrade -y
        apt-get install build-essential -y
        #PCRE
        apt-get install libpcre3 libpcre3-dev -y
        apt-get install zlib1g-dev -y
        apt-get install openssl libssl-dev -y
        apt-get install gcc make -y
        apt-get install iperf3 vim -y
	fi
		cd /root
		wget http://tengine.taobao.org/download/tengine-2.3.3.tar.gz
		tar zxvf tengine-2.3.3.tar.gz
        cd /root/tengine-2.3.3/
		./configure --with-http_realip_module --without-http_upstream_keepalive_module --with-stream --with-stream_ssl_module --with-stream_sni --add-module=modules/ngx_http_upstream_* --add-module=modules/ngx_debug_* --add-module=modules/ngx_http_slice_module --add-module=modules/ngx_http_user_agent_module --add-module=modules/ngx_http_reqstat_module --add-module=modules/ngx_http_proxy_connect_module --add-module=modules/ngx_http_footer_filter_module
        make
        make install
	ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx
        echo "user  root;
worker_processes auto;
worker_rlimit_nofile 51200;
pid        /usr/local/nginx/logs/nginx.pid;
events
    {
        use epoll;
        worker_connections 51200;
        multi_accept on;
    }
stream {
    include /usr/local/nginx/mytcp/*.conf;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  120;
    keepalive_requests 10000;
    check_shm_size 50m;
    #rewrite
    include /usr/local/nginx/meip/*.conf;
}">/usr/local/nginx/conf/nginx.conf
	cd /lib/systemd/system/
	rm nginx.service
	wget https://raw.githubusercontent.com/Aipblock/Atengineuse/main/nginx.service
        systemctl daemon-reload
        systemctl enable nginx
         systemctl stop nginx
        echo -e "${Green}done!${Font}"
}
function get_conf() {
	mkdir /usr/local/nginx/mytcp
	mkdir /usr/local/nginx/meip
}
function reip_conf() {
myip=$(curl ip.qaros.com | awk 'NR==1')
if [ ! -z ${myip} ]; then
echo "server {
        listen 80;
        server_name "${myip}";
        location / {
            root   html;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }">/usr/local/nginx/meip/reip.conf
    echo "${myip}"
    echo "写入成功"
    systemctl start nginx
    nginx -s reload
    echo "热重启成功"
else
	echo "执行失败"
fi
}

check_sys
install_tengine
get_conf
reip_conf
