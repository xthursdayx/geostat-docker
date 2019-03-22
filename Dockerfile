# set base os
FROM lsiobase/alpine.python:3.9

# set version label
ARG BUILD_DATE
ARG VERSION
ARG user=nobody
ARG group=users
LABEL build_version="Docker version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="xthursdayx"

# https://github.com/maxmind/libmaxminddb/releases
ENV LIBMAXMINDDB_VERSION 1.3.2

# set user and group
RUN \
 usermod -u 99 nobody && \
 usermod -g 100 nobody && \
 usermod -d /home nobody && \
 chown -R nobody:users /home

# base system packages
RUN \
 echo "**** install system packages ****" && \
 apk add --no-cache \
	git \
        libmaxminddb \
	libmaxminddb-dev && \
 apk del .build-deps && \
 echo "**** install pip packages ****" && \
 pip install --no-cache-dir -U \
	configparser==3.5.0 \
	influxdb==5.2.0 \
	Geohash==1.0 \
	geoip2==2.9.0 \
	tzlocal

# Download MaxMind GeoLite2 databases
# https://github.com/leev/ngx_http_geoip2_module
# http://www.treselle.com/blog/nginx-with-geoip2-maxmind-database-to-fetch-user-geo-location-data/
# https://dev.maxmind.com/geoip/geoip2/geolite2/

RUN \
    echo "**** install geolite2 databases ****" && \
    mkdir -p /app/geostat && \
    mkdir -p /tmp/geoip2 && \
    cd /tmp/geoip2 && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
         http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz && \
    tar -xvzf GeoLite2-City.tar.gz --strip-components=1 && \
    tar -xvzf GeoLite2-Country.tar.gz --strip-components=1 && \
    find . -name "*.mmdb" -type f -exec mv {} /app/geostat && \
    cd /app/geostat && /     
    echo "**** cleanup ****" && \
    rm -rf \
        /root/.cache \
        /tmp/geoip2 \
        /tmp/*
:browse confirm saveas

# add local files
RUN \
    echo "**** install app ****"

COPY \ 
    settings.ini.back /config/settings.ini && \
    geoparser.py /app/geostat

# change perms
RUN chown -R ${user}:${group} /app && \
    chmod -R +x /app/geostat/geoparser.py 

# ports and volumes
VOLUME /config /nginx_logs
EXPOSE 9000

CMD ["python", "-u", "/app/geoparser.py"]
