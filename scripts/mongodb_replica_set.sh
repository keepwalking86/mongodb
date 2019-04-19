#!/bin/bash
#Script for installing and setting replica set mongodb on centos 7
#Script for setting 03 mongodb servers: 01 primary, 01 secondary & 01 arbiter

#Define variables
MONGO01_IP=192.168.1.131
MONGO02_IP=192.168.1.132
MONGO03_IP=192.168.1.133 #Arbiter
MONGO_PORT=27017
MONGO_VER=3.6
MONGO_ID=mongoshake
NETWORK=192.168.1.0/24
IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')

#Create repo
cat >/etc/yum.repos.d/mongo.repo<<EOF
[mongodb-org-${MONGO_VER}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/${MONGO_VER}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-${MONGO_VER}.asc
EOF

#Installing MongoDB
yum install mongodb-org -y

#Allow access mongodb server from any IP addresses
sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf

#Setup Firewall
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="${NETWORK}" port port="${MONGO_PORT}" protocol="tcp" accept'
firewall-cmd --reload

#Start mongod
systemctl start mongod.service
systemctl enable mongod.service

# Setup Replica set
echo "Deploy Replica set MongoDB"
sleep 3
#Enable replication
cat >>/etc/mongod.conf <<EOF
replication:
    #replica set id
    replSetName: $MONGO_ID
EOF
#Restart mongod
systemctl restart mongod
#Setup hostname
cat >>/etc/hosts <<EOF
$MONGO01_IP   mongo01
$MONGO02_IP   mongo02
$MONGO03_IP   mongo03
EOF

if [ $IP == $MONGO01_IP ]; then
    #Setup replica set
    #initiate
    cfg='{
        _id: "mongoshake",
        members: [
            { _id: 0, host: "mongo01:'$MONGO_PORT'", priority: 2 },
            { _id: 1, host: "mongo02:'$MONGO_PORT'", priority: 1 },
            { _id: 2, host: "mongo03:'$MONGO_PORT'", "arbiterOnly": true }
        ]
    }'
    mongo mongo01:$MONGO_PORT --eval "JSON.stringify(db.adminCommand({'replSetInitiate' : $cfg}))"
fi