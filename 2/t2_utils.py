import numpy as np
import pandas as pd
from numpy.linalg import norm

def random_baseline(info: pd.DataFrame, title: str, artist: str, n: int) -> pd.DataFrame:
    return info.sample(n=n)[["id","artist","song"]]

def cos_sim(query: [int], target: [int]) -> int:
    return np.dot(query,target)/(norm(query)*norm(target))

def euc_sim(query: [int], target: [int]) -> int:
    return 1/(1+norm(query-target))

def idcg(row, df_genre: pd.DataFrame) -> int:
    genre = row["genre"]
    df_new_genre = df_genre[df_genre["id"] != row ["id"]] # exclude the query song from the dataset
    result_array = df_new_genre["genre"].apply(lambda x: relevance(x, genre)).values
    top_ten_results = np.sort(result_array)[-10:]
    return dcg(top_ten_results)
    
def relevance(query_genre: [str], track_genre: [str]) -> int:
    t0_genres = set(track_genre)
    t1_genres = set(query_genre)
    return 2 * len(t0_genres.intersection(t1_genres)) / (len(t0_genres) + len(t1_genres))

# https://wikimedia.org/api/rest_v1/media/math/render/svg/3efe45491d555db398ed663107460f81d6ecaf1e
def dcg(top_rel: [int]) -> int:
    dcg = 0
    for i in range(1, len(top_rel)+1):
        dcg += top_rel[i-1] / np.log2(i + 1)
    return dcg

def shannons_entropy(dist: [int]) -> int:
    return (-1)*sum(i * np.log2(i) for i in dist if i != 0)

def get_rel_song_count(genre,df_genres):
    songs_with_common_genre = df_genres.apply(lambda x: any(np.intersect1d(genre, x)))
    return sum(songs_with_common_genre)-1 # minus one because it should not include the song itself

def song_retrieval(df_info: pd.DataFrame, df_feature: pd.DataFrame, title: str, artist: str, n: int, sim_func, filter = [], random = False) -> pd.DataFrame:
    if random:
        samples = df_info.sample(n=n)
        return samples if filter == [] else samples[filter]
    feature_no_id = df_feature.drop(columns="id") # drop id column for similarity measurement
    query_id = df_info[(df_info["artist"] == artist) & (df_info["song"] == title)]["id"].values[0] # search for query song in info
    query = df_feature[df_feature["id"]==query_id].drop(columns="id").values[0] # get feature vector for query song
    df_feature["sim"] = feature_no_id.apply(lambda target: sim_func(query, target.values), axis=1) # compute and add similiarity column to feature
    info_feature = pd.merge(df_info, df_feature[["id", "sim"]], on="id") # merge feature with info by id
    info_feature_sorted = info_feature.sort_values(by=["sim"], ascending=False) # sort by similiartiy in descending order
    info_feature_sorted = info_feature_sorted if filter == [] else info_feature_sorted[filter] 
    return info_feature_sorted[1:n+1] # skips the first row, because it is the query track

def evaluation_pipeline(df_info: pd.DataFrame, df_feature: pd.DataFrame, sim_func, k:int, random = False):
    genres = df_info.explode("genre")["genre"].values
    unique_genres = set(genres) # get all the unique genres of the dataset
    metrics = df_info.apply(calc_metrics, axis=1, args=(df_info, df_feature, unique_genres, k, sim_func, random))
    
    avg_precision_list = np.mean([items[0] for items in metrics], axis=0) # computes each average precision from 0 to 100
    avg_precision = avg_precision_list[k-1]
    avg_recall_list = np.mean([items[1] for items in metrics], axis=0) # computes each average recall from 0 to 100
    avg_recall = avg_recall_list[k-1]
    avg_ndcg = np.mean([items[2] for items in metrics])
    avg_genre_diversity = np.mean([items[3] for items in metrics])
    retr_uniq_genres = set().union(*[items[4] for items in metrics]) # combines the genres from the retrieved songs into a single set to keep the unique ones
    genre_coverage = len(retr_uniq_genres)/len(unique_genres)
    return [avg_precision_list, avg_recall_list, avg_precision, avg_recall, avg_ndcg, avg_genre_diversity, genre_coverage]

def calc_metrics(row, df_info: pd.DataFrame, df_feature: pd.DataFrame, unique_genres: [str], k: int, sim_func, random = False):
    song_id = row["id"]
    song_artist = row["artist"]
    song_title = row["song"]
    song_idcg = row["idcg_value"]
    song_genre = row["genre"]
    rel_count = row["rel_count"]
    
    if song_id == "XWfDJYP0AIVHgsrk":
        print("nearly half")
    
    df_retr_songs = song_retrieval(df_info, df_feature, song_title, song_artist, 100, sim_func = sim_func, random = random)
 
    # compute precision and recall
    rel_songs_mask = df_retr_songs["genre"].apply(lambda x: any(np.intersect1d(song_genre, x))) # first get a vector of 0 and 1 where 1 means that the song in the df is relevant to the query song
    rel_cumsum = np.cumsum(rel_songs_mask) # do cumulative sum to compute precision and recall for intervall [0, 100]
    precision_list = rel_cumsum/range(1, len(rel_cumsum)+1)  # divide every entry by their index in the array to get the precision
    recall_list = rel_cumsum/rel_count # divide every entry by the total relevance count to get the recall
    
    df_retr_songs = df_retr_songs[:k] # select the first k elements for further processing

    # compute ndcg
    retr_rel = df_retr_songs["genre"].apply(lambda x: relevance(x, song_genre)).values
    song_ndcg = dcg(retr_rel) / song_idcg
    
    # compute genre diversity
    df_genre = pd.DataFrame(np.zeros((1, len(unique_genres))), columns = unique_genres) # create df with a column for each genre to compute genre distribution
    retr_genres = df_retr_songs["genre"].values
 
    for genre in retr_genres:
        df_genre[genre] += 1/len(genre)
    norm_genre_dist = df_genre.iloc[0].values / k # normalize the genre distribution
    genre_diversity = shannons_entropy(norm_genre_dist)
    
    return [precision_list, recall_list, song_ndcg, genre_diversity, set(np.concatenate(retr_genres, axis=None))]