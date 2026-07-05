# vos.sh

VPN tunnel via SSH SOCKS5 proxy using
[tun2socks](https://github.com/xjasonlyu/tun2socks)

## Requirements

`tun2socks` in PATH, `sudo` access

## Installation

1. Download `tun2socks` and place it in PATH
2. Make `vos.sh` executable

## Configuration

Edit the settings block at the top of the script:

```
SSH_USER=""
SSH_HOST=""
SSH_PORT=""
SOCKS_PORT=""
```

## Usage

```
./vos.sh start      Start VPN tunnel
./vos.sh stop       Stop VPN tunnel
./vos.sh status     Show tunnel status
```

## How it works

1. All traffic routes through **TUN interface -> tun2socks -> local
   SOCKS5 -> SSH tunnel**
2. Traffic to the SSH server itself bypasses the tunnel to keep the
   connection alive
3. Two default routes: VPN via TUN (metric 1) and fallback via
   physical gateway (metric 10)
