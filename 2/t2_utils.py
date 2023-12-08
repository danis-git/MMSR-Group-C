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
    df_new_genre = df_genre[df_genre["id"] != row ["id"]]
    result_array = df_new_genre["genre"].apply(lambda x: relevance(x, genre)).values
    top_ten_results = np.sort(result_array)[-10:]
    return dcg(top_ten_results)
    
def relevance(query_genre: [str], track_genre: [str]) -> int:
    t0_genres = set(track_genre)
    t1_genres = set(query_genre)
    return 2 * len(t0_genres.intersection(t1_genres)) / (len(t0_genres) + len(t1_genres))

# https://wikimedia.org/api/rest_v1/media/math/render/svg/3efe45491d555db398ed663107460f81d6ecaf1e
def dcg(top_rel: [int]) -> int:
    dcg = top_rel[0]
    for i in range(1, len(top_rel)):
        dcg += top_rel[i] / np.log2(i + 1)
    return dcg

def shannons_entropy(dist: [int]) -> int:
    return (-1)*sum(i * np.log2(i) for i in dist if i != 0)

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

def evaluation_pipeline(df_info: pd.DataFrame, df_feature: pd.DataFrame, sim_func, random = False):
    genres = df_info.explode("genre")["genre"].values
    unique_genres = set(genres)
    metrics = df_info.apply(calc_metrics, axis=1, args=(df_info, df_feature, unique_genres, sim_func, random))
    
    retr_uniq_genres = set().union(*[items[2] for items in metrics])
  
    avg_ndcg = np.mean([items[0] for items in metrics])
    avg_genre_diversity = np.mean([items[1] for items in metrics])
    genre_coverage = len(retr_uniq_genres)/len(unique_genres)
    return [avg_ndcg, avg_genre_diversity, genre_coverage]

def calc_metrics(row, df_info: pd.DataFrame, df_feature: pd.DataFrame, unique_genres: [str], sim_func, random = False):
    song_id = row["id"]
    song_artist = row["artist"]
    song_title = row["song"]
    song_idcg = row["idcg_value"]
    song_genre = row["genre"]
    
    if song_id == "XWfDJYP0AIVHgsrk":
        print("nearly half")
    
    df_retr_songs = song_retrieval(df_info, df_feature, song_title, song_artist, 10, sim_func = sim_func, random = random)
    retr_genres = df_retr_songs["genre"].values
 
    # compute ndcg
    retr_rel = df_retr_songs["genre"].apply(lambda x: relevance(x, song_genre)).values
    song_ndcg = dcg(retr_rel) / song_idcg
    
    # compute genre diversity
    df_genre = pd.DataFrame(np.zeros((1, len(unique_genres))), columns = unique_genres)
    for genre in retr_genres:
        df_genre[genre] += 1/len(genre)
    norm_genre_dist = df_genre.iloc[0].values / 10
    genre_diversity = shannons_entropy(norm_genre_dist)
    
    return [song_ndcg, genre_diversity, set(np.concatenate(retr_genres, axis=None))]