from pymongo import MongoClient

# Create a client
#client = MongoClient('mongodb://fctagent:111111@127.0.0.1:27017/myrun0')
# get server ip by:ip addr show | grep "global bond0"
client = MongoClient('mongodb://fctagent:111111@10.180.48.11:27017/myrun0')
#client = MongoClient('mongodb://127.0.0.1:27017')

# Access the 'mydatabase' database
db = client['myrun0']
collection = db['myrun0']
doc = {"name":"John","age":30,"city":"New York"}
collection.insert_one(doc)
for x in collection.find():
    print(x)
