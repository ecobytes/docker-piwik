FROM phusion/baseimage:0.9.22
MAINTAINER Brian Prodoehl <bprodoehl@connectify.me>, Jon Richter <post@jonrichter.de>

ENV HOME /root

RUN apt-get update && apt-get -y dist-upgrade

RUN add-apt-repository universe && add-apt-repository multiverse
RUN apt-get update -q && \
    apt-get install -qy mysql-client nginx-full php7.0-cli php7.0-gd php7.0-fpm php7.0-json \
                        php7.0-mysql php7.0-curl php-xml php7.0-mbstring wget && \
    apt-get clean


RUN cd /usr/share/nginx/html && \
    export PIWIK_VERSION=3.2.0 && \
    wget http://builds.piwik.org/piwik-${PIWIK_VERSION}.tar.gz && \
    tar -xzf piwik-${PIWIK_VERSION}.tar.gz && \
    rm piwik-${PIWIK_VERSION}.tar.gz && \
    mv piwik/* . && \
    rm -r piwik && \
    chown -R www-data:www-data /usr/share/nginx/html && \
    chmod 0770 /usr/share/nginx/html/tmp && \
    chmod 0770 /usr/share/nginx/html/config && \
    chmod 0600 /usr/share/nginx/html/config/* && \
    rm /usr/share/nginx/html/index.html

# Install MaxMind GeoCity Lite database
RUN cd /usr/share/nginx/html/misc && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && \
    gunzip GeoLiteCity.dat.gz && \
    chown www-data:www-data GeoLiteCity.dat && \
	mv GeoLiteCity.dat GeoIPCity.dat

ADD config/php.ini /etc/php/7.0/fpm/php.ini

RUN mkdir /etc/service/nginx
ADD runit/nginx.sh /etc/service/nginx/run

RUN mkdir /etc/service/php7-fpm
ADD runit/php7-fpm.sh /etc/service/php7-fpm/run
RUN mkdir /run/php && touch /run/php/php7.0-fpm.sock && \
     chown www-data:www-data /run/php/php7.0-fpm.sock

ADD config/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx-default.conf /etc/nginx/sites-available/default

ADD config/piwik-schema.sql /usr/share/nginx/html/config/base-schema.sql

ADD scripts/init-piwik.sh /etc/my_init.d/10-piwik.sh

RUN touch /etc/service/sshd/down
CMD ["/sbin/my_init"]
EXPOSE 80
