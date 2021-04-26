# I. Requirement

>=05 server centos 7

- 01 server mongoshake (192.168.10.110), go-1.9+, govendor, git

- 02+ server replicaset 01 (replicate set id: mongoshake1) (192.168.10.111-112)

- 02+ server replicaset 02 (replicate set id: mongoshake2) (192.168.10.113-114)

# II. Setup replica set

## 1. Install mongodb 3 on mongo servers

**Step1: Create repo**

```
cat >/etc/yum.repos.d/mongo.repo<<EOF
[mongodb-org-3.6]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.6/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc
EOF
```

**Step2: Install mongodb 3**

- Install

`yum install mongodb-org -y`

- Allow access mongodb server from any IP addresses

`sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf`

**Step3: Setup firewall**

```
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.10.0/24" port port="27017" protocol="tcp" accept'
firewall-cmd --reload
```

**Step4: Start mongodb 3**

```
systemctl start mongod.service
systemctl enable mongod.service
```

## 2. Replicate set mongodb3 for mongoshake1

**Step1: Enable replication on MongoDB servers**

- Edit mongod file

```
cat >>/etc/mongod.conf <<EOF
replication:
    #replica set id
    replSetName: mongoshake1
EOF
```

- Restart mongod

`systemctl restart mongod`

**Step2: setup hostname on 02 servers**

```
cat >>/etc/hosts <<EOF
192.168.10.111    mongo01
192.168.10.112    mongo02
EOF
```

**Step3: Initial MongoDB replica set on mongo01**

```
mongo
>rs.initiate( { _id: "mongoshake1", members: [ { _id: 0, host: "mongo01:27017", priority: 2 } ] } )
>rs.add({ _id:2,host:"mongo02:27017",priority:1 })
```

## 3. Replicate set mongodb3 for mongoshake2

**Step1: Enable replication on MongoDB servers**

- Edit mongod file

```
cat >>/etc/mongod.conf <<EOF
replication:
    #replica set id
    replSetName: mongoshake2
EOF
```

- Restart mongod

`systemctl restart mongod`

**Step2: setup hostname on 02 servers**

```
cat >>/etc/hosts <<EOF
192.168.10.113    mongo03
192.168.10.114    mongo04
EOF
```

**Step3: Initial MongoDB replica set on mongo03**

```
mongo
>rs.initiate( { _id: "mongoshake2", members: [ { _id: 0, host: "mongo03:27017", priority: 2 } ] } )
>rs.add({ _id:2,host:"mongo04:27017",priority:1 })
```

# III. Setup mongoshake

## 1. Install go language

- Download go language

Download go at: [https://golang.org/dl/](https://golang.org/dl/)

```
curl -O https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz
tar -C /usr/local -xzvf go1.12.4.linux-amd64.tar.gz
```

- Set environments

```
cat >>~/.bashrc<<EOF
export GOPATH=/root/mongo-shake
export GOROOT=/usr/local/go
export PATH=$PATH:/usr/local/go/bin
EOF
```

- Logout and login

## 2. Install govendor

```
yum install git gcc -y
go get -u github.com/kardianos/govendor
cp  mongo-shake/bin/govendor /usr/local/go/bin/
rm -rf /root/mongo-shake
```

## 3. Setup mongo-shake

- Download mongo-shake

```
cd /root
git clone https://github.com/aliyun/mongo-shake.git
```

- pull all dependencies & build collector

```
cd /root/mongo-shake/src
govendor sync
cd /root/mongo-shake
./build.sh
```

- Edit collector configuration file

Edit conf/collector.conf with the following content:

```
mongo_urls = mongodb://192.168.10.111:27017,192.168.10.112:27017
tunnel.address = mongodb://192.168.10.113:27017,192.168.10.114:27017
```

- Usage mongo-shake

`./bin/collector -conf=conf/collector.conf`
