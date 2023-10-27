#!/bin/bash

sleep 10
current_config=""
while true; do
    nginx_conf="/etc/nginx/conf.d/default.conf"
    default_cert_path="/tmp/default.crt"
    default_key_path="/tmp/default.key"
    new_config=""
    containers=$(docker ps -qa)
    changes_detected=false
    for i in $containers; do
        server_name=$(docker inspect "${i}" | jq -r '.[0].Config.Labels."ingress-host" // "N/A"')
        cert_name=$(docker inspect "${i}" | jq -r '.[0].Config.Labels."cert-name" // "default"')
        www_redirect=$(docker inspect "${i}" | jq -r '.[0].Config.Labels."www_redirect" // "false"')
        additional_non_www_ingress_host=$(docker inspect "${i}" | jq -r '.[0].Config.Labels."additional_non_www_ingress_host" // "N/A"')
        additional_non_www_cert_name=$(docker inspect "${i}" | jq -r '.[0].Config.Labels."additional_non_www_cert_name" // "default"')
        additional_non_www_service_name=$(docker inspect "${i}" | jq -r '.[0].Config.Labels."additional_non_www_service_name" // "N/A"')
        additional_non_www_container_port=$(docker inspect "${i}" | jq -r '.[0].Config.Labels."additional_non_www_container_port" // "N/A"')
        if [ "$server_name" != "N/A" ]; then
            container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${i}")
            container_port=$(docker inspect "${i}" | jq -r '.[0].NetworkSettings.Ports | to_entries[] | .key | split("/") | .[0] // "N/A"')
            cert_path="/etc/nginx/certs/${cert_name}.crt"
            key_path="/etc/nginx/certs/${cert_name}.key"
            first_part=$(echo "$server_name" | cut -d ' ' -f 1)
            if [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
                echo "Cert and/or key not found, using default for ${server_name}"
                cert_path="$default_cert_path"
                key_path="$default_key_path"
            fi
            if [ "$container_port" != "N/A" ]; then
                if [ "$www_redirect" == "true" ]; then
                    new_config="${new_config}$(cat <<EOF
# BEGIN GENERATED CONFIG
server {
    listen 80;
    server_name ${server_name};
    return 301 https://${first_part}\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${server_name};
    ssl_certificate ${cert_path};
    ssl_certificate_key ${key_path};
    return 301 https://www.${first_part}\$request_uri;
}

server {
    listen 443;
    server_name www.${first_part} ssl;
    ssl_certificate ${cert_path};
    ssl_certificate_key ${key_path};
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    location / {
        resolver 127.0.0.11 valid=1s;
        set \$upstream http://${container_ip}:${container_port};
        proxy_pass \$upstream;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_http_version 1.1;
        proxy_set_header X-Request-ID \$request_id;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Scheme     \$scheme;
        proxy_set_header X-Scheme               \$scheme;
        proxy_set_header X-Original-Forwarded-For \$http_x_forwarded_for;
        proxy_set_header Proxy                  "";
        proxy_connect_timeout                   5s;
        proxy_send_timeout                      60s;
        proxy_read_timeout                      60s;
        proxy_buffering                         off;
        proxy_buffer_size                       4k;
        proxy_buffers                           4 4k;
        proxy_max_temp_file_size                1024m;
        proxy_request_buffering                 on;
        proxy_cookie_domain                     off;
        proxy_cookie_path                       off;
        proxy_next_upstream                     error timeout;
        proxy_next_upstream_timeout             0;
        proxy_next_upstream_tries               3;
        proxy_redirect                          off;

    }
    location = /robots.txt {
        add_header Content-Type text/plain;
        return 200 "User-agent: *\nDisallow: /recaptcha\nDisallow: /tag/\nSitemap: https://www.${first_part}\n";
    }    
}
# END GENERATED CONFIG
EOF
)"
                else
                    new_config="${new_config}$(cat <<EOF
# BEGIN GENERATED CONFIG
server {
    listen 80;
    server_name ${server_name};
    return 301 https://${first_part}\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${server_name} ssl;
    ssl_certificate ${cert_path};
    ssl_certificate_key ${key_path};
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    location / {
        resolver 127.0.0.11 valid=1s;
        set \$upstream http://${container_ip}:${container_port};
        proxy_pass \$upstream;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_http_version 1.1;
        proxy_set_header X-Request-ID \$request_id;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Scheme     \$scheme;
        proxy_set_header X-Scheme               \$scheme;
        proxy_set_header X-Original-Forwarded-For \$http_x_forwarded_for;
        proxy_set_header Proxy                  "";
        proxy_connect_timeout                   5s;
        proxy_send_timeout                      60s;
        proxy_read_timeout                      60s;
        proxy_buffering                         off;
        proxy_buffer_size                       4k;
        proxy_buffers                           4 4k;
        proxy_max_temp_file_size                1024m;
        proxy_request_buffering                 on;
        proxy_cookie_domain                     off;
        proxy_cookie_path                       off;
        proxy_next_upstream                     error timeout;
        proxy_next_upstream_timeout             0;
        proxy_next_upstream_tries               3;
        proxy_redirect                          off;    
    }
    location = /robots.txt {
        add_header Content-Type text/plain;
        return 200 "User-agent: *\nDisallow: /recaptcha\nDisallow: /tag/\nSitemap: https://${server_name}\n";
    }     
}
# END GENERATED CONFIG
EOF
)"
                fi
                changes_detected=true
            else
                echo "Port information not available for ${server_name}"
                new_config="${new_config}$(cat <<EOF
# BEGIN GENERATED CONFIG
server {
    listen 80;
    server_name ${server_name};
    return 301 https://${first_part}\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${server_name};
    ssl_certificate ${cert_path};
    ssl_certificate_key ${key_path};
    return 404;
}
# END GENERATED CONFIG
EOF
)"
                changes_detected=true
            fi
        fi
    if [ "$additional_non_www_ingress_host" != "N/A" ]; then
        cert_path="/etc/nginx/certs/${additional_non_www_cert_name}.crt"
        key_path="/etc/nginx/certs/${additional_non_www_cert_name}.key"
        if [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
            echo "Cert and/or key not found, using default for ${additional_non_www_ingress_host}"
            cert_path="$default_cert_path"
            key_path="$default_key_path"
        fi
        new_config="${new_config}$(cat <<EOF
# BEGIN GENERATED CONFIG
server {
    listen 80;
    server_name ${additional_non_www_ingress_host};
    return 301 https://${additional_non_www_ingress_host}\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${additional_non_www_ingress_host} ssl;
    ssl_certificate ${cert_path};
    ssl_certificate_key ${key_path};
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    location / {
        resolver 127.0.0.11 valid=1s;
        set \$upstream http://${additional_non_www_service_name}:${additional_non_www_container_port};
        proxy_pass \$upstream;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_http_version 1.1;
        proxy_set_header X-Request-ID \$request_id;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Scheme     \$scheme;
        proxy_set_header X-Scheme               \$scheme;
        proxy_set_header X-Original-Forwarded-For \$http_x_forwarded_for;
        proxy_set_header Proxy                  "";
        proxy_connect_timeout                   5s;
        proxy_send_timeout                      60s;
        proxy_read_timeout                      60s;
        proxy_buffering                         off;
        proxy_buffer_size                       4k;
        proxy_buffers                           4 4k;
        proxy_max_temp_file_size                1024m;
        proxy_request_buffering                 on;
        proxy_cookie_domain                     off;
        proxy_cookie_path                       off;
        proxy_next_upstream                     error timeout;
        proxy_next_upstream_timeout             0;
        proxy_next_upstream_tries               3;
        proxy_redirect                          off;
    }
    location = /robots.txt {
        add_header Content-Type text/plain;
        return 200 "User-agent: *\nDisallow: /recaptcha\nDisallow: /tag/\nSitemap: https://${additional_non_www_ingress_host}\n";
    }     
}
# END GENERATED CONFIG
EOF
)"
        changes_detected=true
    fi
    done
    if [ "$new_config" != "$current_config" ]; then
        current_config="$new_config"
        echo "$new_config" > "$nginx_conf"
        # Reload NGINX
        nginx -s reload > /dev/null 2>&1
        if [ "$changes_detected" = true ]; then
            echo "Found new configuration for $server_name : $container_ip:$container_port, www_redirection: $www_redirect, cert_path: ${cert_path}, key_path: ${key_path}"
            sleep 2
            echo "Configuration applied, reloading NGINX!"
            sleep 2
            echo "NGINX reloaded!"
        fi
    fi
    sleep 10
done
