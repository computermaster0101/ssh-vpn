This script is used to tunnel to a remote network, not just a remote machine. It was creating using Ubuntu 16.04. There must be a cert provided for connection, either embeded in the script or on the filesystem.

tunClient.sh (presented with defaults)
                             (-s | --server "DEFAULT")?
                             (-p | --port "DEFAULT")?
                             (-u | --username "DEFAULT")?
                             (-i | --identity_file "DEFAULT")?
                             (-l | --local_address "DEFAULT")?
                             (-r | --remote_address "DEFAULT")?
                             (-c | --cidr_blocks "DEFAULT")?




-s | --server         : The ip address or DNS address of the remote server.
-p | --port           : The port listening for ssh connections on the remote server.
-u | --username       : The username used for logging in and for sudo access on the remote server.
-i | --identity_file  : The private key used to connect to the remote server.
-l | --local_address  : The ip address assigned to the local tun adapter.
-r | --remote_address : The ip address assigned to the remote tun adapter.
-c | --cidr_blocks    : The comma seperated list of cidr blocks to route through the tun adapter.


If default vaules are desired, they can be set on lines 40 - 65 of the script. The default defaults are displayed below. Additionally, a private certificate can be embeded into the script on lines 80-90


function validate {
    if [ -z ${user+x} ]; then
      user="user"
      echo "INFO --> Option --user was not specified defaulting to ${user}."
    fi
    if [ -z ${serv+x} ]; then
      serv="example.com"
      echo "INFO --> Option --serv was not specified defaulting to ${serv}."
    fi
    if [ -z ${port+x} ]; then
      port="22"
      echo "INFO --> Option --port was not specified defaulting to ${port}."
    fi
    if [ -z ${cert+x} ]; then
      cert=".tunKey"
      echo "INFO --> Option --cert was not specified defaulting to ${cert}."
    fi
    if [ -z ${addr+x} ]; then
      addr="1.1.1.2"
      echo "INFO --> Option --addr was not specified defaulting to ${addr}."
    fi
    if [ -z ${peer+x} ]; then
      peer="1.1.1.1"
      echo "INFO --> Option --peer was not specified defaulting to ${peer}."
    fi
    if [ -z ${frwd+x} ]; then
      frwd="192.168.0.0/24,192.168.1.0/24"
      echo "INFO --> Option --frwd was not specified defaulting to ${frwd}."
    fi
}



function tunKeyWrite {
if [ ! -f ${cert} ]; then
echo "-----BEGIN RSA PRIVATE KEY-----
INSERT PRIVATE KEY HERE
-----END RSA PRIVATE KEY-----" | tee ${cert} > /dev/null 2>&1
tunKeyWritten=yes
fi
}
