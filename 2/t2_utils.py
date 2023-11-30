import numpy as np
import pandas as pd
from numpy.linalg import norm

def random_baseline(info: pd.DataFrame, title: str, artist: str, n: int) -> pd.DataFrame:
    return info.sample(n=n)[["id","artist","song"]]

def cos_sim(query: [int], target: [int]) -> int:
    return np.dot(query,target)/(norm(query)*norm(target))

def euc_sim(query: [int], target: [int]) -> int:
    return 1/(1+norm(query-target))

def song_retrieval(info: pd.DataFrame, feature: pd.DataFrame, title: str, artist: str, n: int, sim_func = cos_sim, filter = []) -> pd.DataFrame:
    feature_no_id = feature.drop(columns="id") # drop id column for similarity measurement
    query_id = info[(info["artist"] == artist) & (info["song"] == title)]["id"].values[0] # search for query song in info
    query = feature[feature["id"]==query_id].drop(columns="id").values[0] # get feature vector for query song
    feature["sim"] = feature_no_id.apply(lambda target: sim_func(query, target.values), axis=1) # compute and add similiarity column to feature
    info_feature = pd.merge(info, feature[["id", "sim"]], on="id") # merge feature with info by id
    info_feature_sorted = info_feature.sort_values(by=["sim"], ascending=False) # sort by similiartiy in descending order
    info_feature_sorted = info_feature_sorted if filter == [] else info_feature_sorted[filter] 
    return info_feature_sorted[1:n+1] # skips the first row, because it is the query track