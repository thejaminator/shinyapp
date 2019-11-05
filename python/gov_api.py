import requests
import json
import datetime
import math
import time
def keep_trying(func):
    """
    decorator to keep trying the wrapped function until status code 200 meaning success
    """
    def wrapper(*args, **kwargs):
        while True:
            result = func(*args, **kwargs)
            if result.status_code == 200:
#                 print("success!")
                return result
            else:
                print("Did not get response 200")
                time.sleep(5)
    return wrapper

@keep_trying
def get_request(date_time):
    """
    This function is seperate from carpark_request_data 
    because we use a decorator to keep_trying for repsonse 200
    queries carpark avability for given datetime
    in python datetime format.
    
    NOTE: Api has some bug where if you query for midnight it won't worked i.e '2019-10-03T00:00:00'

    Parameters
    ----
    date_time: datetime object
    
    returns
    -----
    raw json of carpark avail
    
    e.g. get_request(date_time=date_time).json()["items"][0]["carpark_data"]
    """
    #convert to iso for api
    date_time = date_time.isoformat()
    # print("Querying...", date_time)
    url="https://api.data.gov.sg/v1/transport/carpark-availability"
    response = requests.get(url, {"date_time": date_time})
    return response

def api_debugger(date_time):
    #minus a minute if it is midnight
    if date_time.minute == 0 and date_time.hour == 0:
        date_time = date_time - datetime.timedelta(minutes=1)
    return date_time

def carpark_request_data(date_time):
    """
    queries carpark avability for given datetime
    in format"YYYY-MM-DD[T]HH:mm:ss (SGT)"
    
    
    returns: raw json of carpark avail with query_timestamp set in format of date in mongo
    """
    
    #querying 00:00 is bugged so need to check add a minute if it is midnight
    
    data = get_request(date_time=api_debugger(date_time))
    data = data.json()["items"][0]["carpark_data"]
    
    #Reshape data into something like
    #{'HE12': {''lots_available': '19'}}
    carpark_name = [carpark["carpark_number"] for carpark in data]
    carpark_type = [carpark["carpark_info"][0]["lot_type"] for carpark in data]
    lots_available = [int(carpark["carpark_info"][0]["lots_available"]) for carpark in data]
#     total_lots = [carpark["total_lots"][0]["lot_type"] for carpark in data]

    
    output_dict={}
    #some carparks have more than one lot type so we append the lot type behind
    for idx, carpark in enumerate(carpark_name):
        output_dict[carpark+"_"+carpark_type[idx]] = lots_available[idx]
        
        
    #add timestamp
    output_dict["time"] = date_time
    
    #For debugging
    #check if output is equal to the number of carparks
#     if len(output_dict) != (len(carpark_name)-1):
#         print(f"Number of carparks {len(carpark_name)}", f"Output length {len(output_dict)}")
        
    return output_dict

def api_test():
    return carpark_request_data(datetime.datetime.now())