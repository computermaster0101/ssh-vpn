#!/usr/bin/env bash
# Calls a function of the same name for each needed variable.
function global {
  for arg in "$@"
  do [[ ${!arg+isset} ]] || eval "$arg="'"$('"$arg"')"'
  done
}

function -h {
cat <<USAGE
USAGE: sshvpn.sh (presented with defaults)
                             (-s | --server "DEFAULT")?
                             (-p | --port "DEFAULT")?
                             (-u | --username "DEFAULT")?
                             (-i | --identity_file "DEFAULT")?
                             (-l | --local_address "DEFAULT")?
                             (-r | --remote_address "DEFAULT")?
                             (-c | --cidr_blocks "DEFAULT")?
USAGE
}; function --help { -h ;}

function options {
  while [[ ${1:+isset} ]]
  do
    case "$1" in
      -s|--server)          serv="$2"               ; shift ;;
      -p|--port)            port="$2"               ; shift ;;
      -u|--username)        user="$2"               ; shift ;;
      -i|--identity_file)   cert="$2"               ; shift ;;
      -l|--local_address)   addr="$2"               ; shift ;;
      -r|--remote_address)  peer="$2"               ; shift ;;
      -c|--cidr_blocks)     frwd="$2"               ; shift ;;
      --*)         err "No such option: $1" ;;
    esac
    shift
  done
}

function validate {
    if [ -z ${user+x} ]; then
      user="user"
      echo "INFO --> Option --username was not specified defaulting to ${user}."
    fi
    if [ -z ${serv+x} ]; then
      serv="example.com"
      echo "INFO --> Option --server was not specified defaulting to ${serv}."
    fi
    if [ -z ${port+x} ]; then
      port="22"
      echo "INFO --> Option --port was not specified defaulting to ${port}."
    fi
    if [ -z ${cert+x} ]; then
      cert=".tunKey"
      echo "INFO --> Option --identity_file was not specified defaulting to ${cert}."
    fi
    if [ -z ${addr+x} ]; then
      addr="1.1.1.2"
      echo "INFO --> Option --local_address was not specified defaulting to ${addr}."
    fi
    if [ -z ${peer+x} ]; then
      peer="1.1.1.1"
      echo "INFO --> Option --remote_address was not specified defaulting to ${peer}."
    fi
    if [ -z ${frwd+x} ]; then
      frwd="192.168.0.0/24,192.168.1.0/24"
      echo "INFO --> Option --cidr_blocks was not specified defaulting to ${frwd}."
    fi
}

function validateSudoAccess {
    echo "Local sudo access required"
    echo -n Enter Password:
    read -s localSudoPass
    echo
    echo "Remote sudo access required"
    echo -n Enter Password:
    read -s remoteSudoPass
    echo
}

function tunKeyWrite {
if [ ! -f ${cert} ]; then
echo "-----BEGIN RSA PRIVATE KEY-----
INSERT PRIVATE KEY HERE
-----END RSA PRIVATE KEY-----" | tee ${cert} > /dev/null 2>&1
tunKeyWritten=yes
fi
}

function tunServerWrite {
echo "
if [[ \"\$(sudo ip link show | grep tun0)\" == \"\" ]]; then
  echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
  echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward_use_pmtu
  sudo ip tuntap add mode tun tun0
  sudo ip link set tun0 up
  sudo ip addr add ${peer} peer ${addr} dev tun0
  sudo iptables -t nat -A POSTROUTING -j MASQUERADE
  sudo iptables -P FORWARD ACCEPT
  sudo ufw allow proto any from ${addr}
  sudo set -i '/PermitTunnel/d' /etc/ssh/sshd_config
  echo PermitTunnel yes | sudo tee -a /etc/ssh/sshd_config
  sudo systemctl restart sshd.service > /dev/null
else
  echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward
  echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward_use_pmtu
  sudo iptables -P FORWARD DROP
  sudo ufw delete allow proto any from ${addr}
  sudo sed -i '/PermitTunnel/d' /etc/ssh/sshd_config
  echo PermitTunnel no | sudo tee -a /etc/ssh/sshd_config
  sudo ip link delete tun0
  sudo rm ~/tunServer
fi" | tee .tunServer > /dev/null 2>&1
}

function process {
  echo ${localSudoPass} | sudo -S chmod 400 ${cert} > /dev/null 2>&1
  echo Configuring Server
  scp -P ${port} -i ${cert} .tunServer ${user}@${serv}:~/tunServer > /dev/null 2>&1
  echo Enabling Server
  ssh -i ${cert} -p ${port} -n ${user}@${serv} "
if [[ \"\$(ip link show | grep tun0)\" == \"\" ]]
then echo ${remoteSudoPass} | sudo -S bash ~/tunServer > /dev/null 2>&1
echo Server Enabled
else 
echo Server Already Enabled
fi"
  echo Configuring Client
  if [[ "$(ip link show | grep tun0)" == "" ]]; then
    echo ${localSudoPass} | sudo -S ls > /dev/null 2>&1
    sudo ip tuntap add mode tun tun0
    sudo ip link set tun0 up
    sudo ip addr add ${addr} peer ${peer} dev tun0
    cidrBlocks=(${frwd//,/ })
    for cidrBlock in ${cidrBlocks[@]} 
    do
      sudo ip route add ${cidrBlock} via ${addr}
    done
  else
    echo Already Configured
  fi
  echo Establishing Connection
  ssh -C -n -w 0:0 -i ${cert} -p ${port} ${user}@${serv} 'echo Connection Established' || echo
  echo Terminating Connection
  echo Disabling Server
  ssh -i ${cert} -p ${port} -n ${user}@${serv} "
if [[ \"\$(ip link show | grep tun0)\" == \"\" ]]; then 
echo Server Already Disabled
else
echo ${remoteSudoPass} | sudo -S bash ~/tunServer > /dev/null 2>&1 
echo Server Disabled 
fi"
  echo Destroying Adapter
  if [[ "$(ip link show | grep tun0)" == "" ]]; then
    echo Adapter Already Destroyed
  else
    echo ${localSudoPass} | sudo -S ls > /dev/null 2>&1
    sudo ip tuntap del mode tun tun0
    echo Adapter Destroyed
  fi
  if [[ "${tunKeyWritten}" == "yes" ]]; then
    sudo rm ${cert}
  fi
  sudo rm .tunServer
  echo Session Terminated
}

function main {
    options "$@"
    validate
    validateSudoAccess
    tunKeyWrite
    tunServerWrite
    process
}


if [[ ${1:-} ]] && declare -F | cut -d' ' -f3 | fgrep -qx -- "${1:-}"
then "$@"
else main "$@"
fi
