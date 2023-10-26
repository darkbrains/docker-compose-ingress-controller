FROM nginx:latest

RUN apt-get update -y && apt-get upgrade -y

RUN apt-get install jq docker.io procps -y

RUN apt-get clean -y

WORKDIR /app

RUN curl -o GeoIP.dat.gz https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoIP.dat.gz

RUN mkdir /usr/share/GeoIP/

RUN gunzip Geo*.gz

RUN cp Geo*.dat /usr/share/GeoIP/

COPY default.crt /tmp/default.crt

COPY default.key /tmp/default.key

COPY script.sh /app/script.sh

RUN chmod +x /app/script.sh

COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
