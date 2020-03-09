/*
Run count_total_documents.js on mongodb server
mongodb -u <username> -p <password> <server:port> count_total_documents.js
*/
conn = new Mongo();
//replace example by your database
db = conn.getDB("example");
totals = 0;
db.getCollectionNames().forEach(function(collection) {
   documents = db[collection].count();
   totals += this.documents;
});
print("Total documents:" + totals)