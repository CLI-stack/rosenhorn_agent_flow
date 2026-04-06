#  module load mongodb/4.4.9
ip addr show | grep "global bond0"
source /tools/aticad/1.0/src/zoo/PD_agent/tile/env.csh
module load mongodb/4.4.9
echo "net:" > mongod.config
echo "  port: 27017" >> mongod.config
echo "  bindIp: 0.0.0.0" >> mongod.config
mongod --dbpath ./ --config mongod.config

# create db manually
# mongo -host 127.0.0.1 --port 27017
# use myDatabase
# db.createCollection("myCollection")
# db.myCollection.insert({name:"John",age:30 , city: "New York"})
# db.myCollection.find()

# create user in local machine
# mongo -host 127.0.0.1 --port 27017
# python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/mongodb_create_user.py
