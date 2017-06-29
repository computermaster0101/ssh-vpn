<h3>Summary</h3>
<pre>
This script is used to tunnel to a remote network, not just a remote machine.
Development and testing was done on Ubuntu 16.04 desktop with an Ubuntu 16.04 server. 
</pre>
<pre>
There must be a cert provided for connection however, it can be embeded directoy into
the script (see the below information for more details). When executed, this script will
generate a server configuration script, send it to the server for execution, create the 
local routes and adapters, then establish the tunnel. Once the tunnel is broken using 
ctrl+c the script will reverse server configurations, delete the server configuration 
file, and delete the tun adapters. 
</pre>
<pre>
Other than a private certificate to access the server, there should be 
no addtional setup to make this virtual private network tunnel work*.
</pre>

<h3>Syntax</h3>
<pre>
tunClient.sh (presented with defaults)
                             (-s | --server "DEFAULT")?
                             (-p | --port "DEFAULT")?
                             (-u | --username "DEFAULT")?
                             (-i | --identity_file "DEFAULT")?
                             (-l | --local_address "DEFAULT")?
                             (-r | --remote_address "DEFAULT")?
                             (-c | --cidr_blocks "DEFAULT")?
</pre>
<pre>
-s | --server         : The ip address or DNS address of the remote server.
-p | --port           : The port listening for ssh connections on the remote server.
-u | --username       : The username used for logging in and for sudo access on the remote server.
-i | --identity_file  : The private key used to connect to the remote server.
-l | --local_address  : The ip address assigned to the local tun adapter.
-r | --remote_address : The ip address assigned to the remote tun adapter.
-c | --cidr_blocks    : The comma seperated list of cidr blocks to route through the tun adapter.
</pre>

<h3>Additional Details</h3>
<pre>
If default vaules are desired, they can be set on lines 40 - 65 of the script. 
The default defaults are displayed below. Additionally, a private certificate 
can be embeded into the script on lines 80-90.
</pre>
<pre>
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
</pre>
<pre>
function tunKeyWrite {
if [ ! -f ${cert} ]; then
echo "-----BEGIN RSA PRIVATE KEY-----
INSERT PRIVATE KEY HERE
-----END RSA PRIVATE KEY-----" | tee ${cert} > /dev/null 2>&1
tunKeyWritten=yes
fi
}
</pre>
<pre>
The ssh command establishing the tunnel is below for convieniance. This is executed
acter the adapters and routes have been setup on both the server and the client.

ssh -C -n -w 0:0 -i ${cert} -p ${port} ${user}@${serv}
</pre>

<pre>
*(depending on linux distro)
</pre>
