#!/usr/bin/env bash

# SETTINGS BLOCK START
SSH_USER=""
SSH_HOST=""
SSH_PORT=""
SOCKS_PORT=""
# SETTINGS BLOCK END

TUN_DEV="tun0"
TUN_IP="198.18.0.1/15"
TUN_NET="198.18.0.1"
METRIC_VPN="1"
METRIC_FALLBACK="10"

check_requirements() {
    local missing_tools=()

    # tun2socks
    if ! command -v tun2socks &>/dev/null; then
        missing_tools+=("tun2socks")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "Error: the following utilities are not found in PATH:"
        printf '  - %s\n' "${missing_tools[@]}"
        exit 1
    fi
}

detect_network() {
    INTERFACE=$(ip route show default 2>/dev/null | awk '{print $5}' | head -1)
    GATEWAY=$(ip route show default 2>/dev/null | awk '{print $3}' | head -1)

    if [ -z "$INTERFACE" ] || [ -z "$GATEWAY" ]; then
        echo "Error: cannot detect default network interface or gateway"
        echo "Please check your network connection"
        exit 1
    fi
}

setup() {
    detect_network

    ssh -D $SOCKS_PORT -N -f $SSH_USER@$SSH_HOST -p $SSH_PORT
    sudo $(which tun2socks) --device tun://$TUN_DEV --proxy socks5://127.0.0.1:$SOCKS_PORT --interface $INTERFACE > /dev/null 2>&1 &
    sleep 5
    sudo ip addr add $TUN_IP dev $TUN_DEV
    sudo ip link set $TUN_DEV up
    sudo ip route add $SSH_HOST/32 via $GATEWAY dev $INTERFACE
    sudo ip route del default
    sudo ip route add default via $TUN_NET dev $TUN_DEV metric $METRIC_VPN
    sudo ip route add default via $GATEWAY dev $INTERFACE metric $METRIC_FALLBACK
}

restore() {
    detect_network

    sudo ip route del default via $TUN_NET dev $TUN_DEV 2>/dev/null
    sudo ip route del default via $GATEWAY dev $INTERFACE 2>/dev/null
    sudo ip route add default via $GATEWAY dev $INTERFACE 2>/dev/null
    sudo ip route del $SSH_HOST/32 via $GATEWAY dev $INTERFACE 2>/dev/null
    sudo ip link set $TUN_DEV down 2>/dev/null
    sudo ip addr del $TUN_IP dev $TUN_DEV 2>/dev/null
    pkill -f "ssh.*-D 1080"
    sudo pkill -f "tun2socks.*tun0"
}

status() {
    if ip link show $TUN_DEV 2>/dev/null | grep -q "UP"; then
        echo "TUN interface: UP"
    else
        echo "TUN interface: DOWN"
    fi

    echo "$(ip route show default)"

    if ps aux | grep -v grep | grep -q "ssh -D $SOCKS_PORT"; then
        echo "SSH tunnel: RUNNING"
    else
        echo "SSH tunnel: DOWN"
    fi

    if ps aux | grep -v grep | grep -q "tun2socks"; then
        echo "tun2socks: RUNNING"
    else
        echo "tun2socks: DOWN"
    fi
}

check_requirements

case "$1" in
    start)
        setup
        ;;
    stop)
        restore
        ;;
    status)
        status
        ;;
    *)
        echo "Options: {start|stop|status}"
        exit 1
        ;;
esac
