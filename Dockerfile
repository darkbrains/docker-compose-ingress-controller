FROM nginx:latest

RUN apt-get update -y && apt-get upgrade -y

RUN apt-get install jq docker.io -y

WORKDIR /app

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
