module backend.db;


import vibe.db.mongo.mongo;

public MongoClient client; 
public MongoCollection bulletin; 

shared static this()
{
    client = connectMongoDB("127.0.0.1");
    bulletin = client.getCollection("mood.bulletin");
    /*
        > mongo
        > use mood
        > db.createCollection("bulletin");
    */
}
