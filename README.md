This README file contains information on the contents of the meta-cmf-vcpe layer.


# References

https://wiki.rdkcentral.com/pages/viewpage.action?spaceKey=ASP&title=Infosys+vCPE+tech+evaluations

https://www.vcpe.dev/docs/install.html


# 1 Build Virtual CPE


```
repo init -u https://code.rdkcentral.com/r/manifests -m rdkb-extsrc.xml -b kirkstone
repo sync -j8 --no-clone-bundle
git clone https://github.com/robvogelaar/meta-cmf-vcpe.git
MACHINE=vcpex86broadband source meta-cmf-vcpe/setup-environment
bitbake rdk-generic-broadband-vcpe-image
```

# 2 Create Virtual End to End Environment

## 2.1 Instal LXD
```
snap install lxd --channel=6.1
lxd init #select all defaults
```
## 2.2 Install Virtual End to End Scripts
```
mkdir $HOME/git
cd $HOME/git
git clone https://github.com/robvogelaar/meta-cmf-vcpe.git
export PATH="$HOME/git/meta-cmf-vcpe/gen:$PATH"
export PATH="$HOME/git/meta-cmf-vcpe/probes/scripts:$PATH"
```
## 2.3 Create Bridges
```
bridges.sh
```
## 2.4 Create BNG Container
```
bng-base.sh
bng.sh 7
```
## 2.5 Create WebPA Server Container
```
webpa.sh
```
## 2.6 Create vCPE Container
```
vcpe-rdkb.sh user@host:/path-to-rdk-generic-broadband-vcpe-image-vcpex86broadband.lxc.tar.bz2
```
## 2.7 Create LAN Client Container
```
client-alpine.sh vcpe-p1
```
## 2.8 List Containers
```
lxc list
+-------------------+---------+---------------------------+-----------------------------------------------+-----------+-----------+
|       NAME        |  STATE  |           IPV4            |                     IPV6                      |   TYPE    | SNAPSHOTS |
+-------------------+---------+---------------------------+-----------------------------------------------+-----------+-----------+
| bng-7             | RUNNING | 10.107.201.1 (eth2)       | 2001:dbf:0:1::107 (eth0)                      | CONTAINER | 0         |
|                   |         | 10.107.200.1 (eth1)       | 2001:daf:7:1::129 (eth2)                      |           |           |
|                   |         | 10.10.10.107 (eth0)       | 2001:dae:7:1::129 (eth1)                      |           |           |
+-------------------+---------+---------------------------+-----------------------------------------------+-----------+-----------+
| client-vcpe-p1    | RUNNING | 10.0.0.67 (eth0)          | 3001:dae:0:f000:216:3eff:fe60:f2e3 (eth0)     | CONTAINER | 0         |
+-------------------+---------+---------------------------+-----------------------------------------------+-----------+-----------+
| vcpe              | RUNNING | 192.168.245.1 (br403)     | 3001:dae:0:f000:216:3eff:fed0:d42 (brlan0)    | CONTAINER | 0         |
|                   |         | 192.168.106.1 (br106)     | 2001:dae:7:1::254 (erouter0)                  |           |           |
|                   |         | 192.168.101.3 (br0)       |                                               |           |           |
|                   |         | 10.107.200.101 (erouter0) |                                               |           |           |
|                   |         | 10.0.0.1 (brlan0)         |                                               |           |           |
+-------------------+---------+---------------------------+-----------------------------------------------+-----------+-----------+
| webpa             | RUNNING | 10.10.10.210 (eth0)       | 2001:dbf:0:1::210 (eth0)                      | CONTAINER | 0         |
+-------------------+---------+---------------------------+-----------------------------------------------+-----------+-----------+
```
