#!/bin/sh

if [ "$(cat /etc/os-release | grep ^ID= | cut -c 4-)" = "flatcar" ]; then
    NODE_IP=$(ip -o -4 addr show dev eth0 | awk '{print $4}' | cut -d '/' -f 1)
else
    NODE_IP=$(hostname -I | awk '{print $1}')
fi

PUBLIC_SETTINGS_PATH="/etc/node-exporter.d/public-settings.json"
TLS_CONFIG_PATH="/etc/node-exporter.d/web-config.yml"

# specify tls config path, if it exists
if [ -f $PUBLIC_SETTINGS_PATH ]
then
    TLS_ENABLED=$(jq -r '."node-exporter-tls"' $PUBLIC_SETTINGS_PATH)
    if [ "$TLS_ENABLED" = "true" ]
    then
        TLS_CONFIG=$TLS_CONFIG_PATH
    fi
fi

exec node-exporter \
    --web.listen-address=${NODE_IP}:19100 \
    --web.config.file=${TLS_CONFIG} \
    --no-collector.wifi \
    --no-collector.hwmon \
    --collector.cpu.info \
    --collector.filesystem.mount-points-exclude="^/(dev|proc|sys|run/containerd/.+|var/lib/docker/.+|var/lib/kubelet/.+)($|/)" \
    --collector.netclass.ignored-devices="^(azv.*|veth.*|[a-f0-9]{15})$" \
    --collector.netclass.netlink \
    --collector.netdev.device-exclude="^(azv.*|veth.*|[a-f0-9]{15})$" \
    --no-collector.arp.netlink
