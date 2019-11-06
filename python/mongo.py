import pymongo
from pymongo import MongoClient
import datetime
import math
import time
import gov_api

# class IntervalTimer:
#     def __init__(self,unit_interval = {"second":1}, *args, **kwargs):
#         super().__init__(*args, **kwargs)
#         self.unit = unit
#         self.interval_unit = interval_unit
#     def get_time(self):
#         time_now=datetime.datetime.now().replace(microsecond=0)
#         time_now = time_now.replace(second = math.floor(time_now.second/interval)*interval)


#     def 



def get_time(interval=1):
    """
    MAYBEDEPRECATED IN PLACE OF TIMER
    Gets current time with seconds floored to specified interval
    
    Parameters
    -----
    interval: int
        interval e.g. every 10 seconds, every 30 seconds, every 60 seconds
    
    Returns
    -----
    str
        time floored to specified interval in datetime
    
    >>>> time_interval(10)
    '2019-10-06T02:34:50'
    >>>> time_interval(1)
    '2019-10-06T02:35:18'
    >>>> time_interval(60)
    '2019-10-06T02:35:00'
    
    """
    time_now=datetime.datetime.now().replace(microsecond=0)
    time_now = time_now.replace(second = math.floor(time_now.second/interval)*interval)
    return time_now

def get_latest_time(collection):
    latest_time = collection.find({},{ "_id": 0, "time": 1},limit=1).sort("time", -1)
    return next(latest_time)["time"]



class MongoCollection:
    def __init__(self,url, db_name="test_db", collection_name="carpark"):
        self.url = url
        self.db_name = db_name
        self.collection_name = collection_name
        self.collection = self.initiate_connection() #returns mongo collection
    
    def initiate_connection(self):
        cluster = MongoClient(self.url)
        db = cluster[self.db_name]
        return db[self.collection_name]

    def update_db(self, bson_data):
        self.collection.insert_one(bson_data)


def test_db(mongo_collection):
    try:
        mongo_collection.collection.find_one()
        print("Mongo connection successful")
    except:
        raise

    

def get_start_time(start_mode = "continue", mongo_collection=None):
    if start_mode == "continue":
        #query collection to get latest time
        return get_latest_time(mongo_collection.collection)
    elif start_mode == "now":
        return get_time()
    elif start_mode == "7daysago":
        return get_time() - datetime.timedelta(days=7)
    else:
        raise ValueError("start_mode params: continue, now, 7daysago")

    


class TimedExecutor:
    """
    Executes 2 method / function every interval time and handles time drift with
    start_time
    calls query function, then pass query result to callback

    """
    def __init__(self, query, callback, start_time, interval=60, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.query = query
        self.callback = callback
        self.start_time = start_time
        self.interval = interval


    def execute(self):
        query_time = self.start_time + datetime.timedelta(seconds=self.interval)
        now_time = get_time(interval= self.interval)

        while True:
            #if the certain time has passed, query  
            if now_time >= query_time :
                print(f"Querying {query_time}")
                data = self.query(query_time)
                #push to mongodb
                self.callback(data)
                #increment the next time period to be queried
                query_time = query_time + datetime.timedelta(seconds=self.interval)
                

            else:
                print(f"Query time {query_time} has not happened yet")
                #sleep for time_difference
                time_difference = (query_time - now_time).total_seconds()
                print(f"Faster than current time, sleeping for {time_difference} seconds")
                time.sleep(time_difference)
                #Update the current time
                now_time = get_time(interval= self.interval)


    


