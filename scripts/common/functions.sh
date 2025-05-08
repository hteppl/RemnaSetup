#!/bin/bash

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_remnanode() {
    if sudo docker ps -q --filter "name=remnanode" | grep -q .; then
        return 0
    else
        return 1
    fi
}

check_caddy() {
    if systemctl is-active --quiet caddy; then
        return 0
    fi

    if sudo docker ps -q --filter "name=caddy" | grep -q . || sudo docker ps -q --filter "name=remnawave-caddy" | grep -q .; then
        return 0
    fi
    
    return 1
}

check_tblocker() {
    if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
        return 0
    else
        return 1
    fi
}

check_warp() {
    if pgrep -f wireproxy >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_bbr() {
    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        return 0
    else
        return 1
    fi
}

setup_crontab() {
    crontab -l > /tmp/crontab_tmp 2>/dev/null || true
    echo "0 * * * * truncate -s 0 /var/lib/toblock/access.log" >> /tmp/crontab_tmp
    echo "0 * * * * truncate -s 0 /var/lib/toblock/error.log" >> /tmp/crontab_tmp
    crontab /tmp/crontab_tmp
    rm /tmp/crontab_tmp
} 
