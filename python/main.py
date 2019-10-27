import mongo
import gov_api
from getpass import getpass


def url_constructor():
    user = input("input mongo user")
    password = getpass()
    url = f"mongodb+srv://{user}:{password}@james-cluster-bfs0h.gcp.mongodb.net"
    return url



if __name__ == "__main__":
    url = url_constructor()
    mongo_collection = mongo.MongoCollection(url, db_name="test_db", collection_name="carpark")
    mongo.test_db(mongo_collection)
    start_time = mongo.get_start_time(start_mode = "continue", mongo_collection=mongo_collection)
    executor = mongo.TimedExecutor(query=gov_api.carpark_request_data,
                            callback=mongo_collection.update_db,
                            start_time = start_time,
                            interval = 60)
    executor.execute()