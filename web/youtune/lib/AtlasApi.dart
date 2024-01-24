import 'package:dio/dio.dart';
import 'dart:convert';
import 'env/env.dart';

final List<String> _features = [
    'random',
    'word2vec euc-sim',
    'tfidf cos-sim',
    'bert cos-sim',
    'mfcc_bow cos-sim',
    'musicnn cos-sim',
    'ivec_256 cos-sim',
    'logfluc cos-sim',
    'resnet cos-sim',
    'early fusion cos-sim',
    'late fusion cos-sim'
  ];
class Song {
  String id;
  String artist;
  String title;
  String youtubeId;
  String youtubeViews;
  List<String> genres = List.empty();
  Map<String, List<String>> featureRes = {};
  Song(
      {required this.id,
      required this.artist,
      required this.title,
      required this.youtubeId,
      required this.youtubeViews,
      required this.genres, required this.featureRes});
  factory Song.fromJson(Map<String, dynamic> json) {
    var map1 = <String, List<String>>{};
    _features.forEach((element) {
       map1[element] = (json[element] as List).map((e) => e['id'] as String).toList();
      });
    return Song(
      id: json['id'],
      artist: json['artist'],
      title: json['song'],
      youtubeId: json['yt_id'],
      youtubeViews: json['yt_view_count'],
      genres: (json['genre'] as List).map((item) => item as String).toList(),
      featureRes: map1
    );
  }
}

class AtlasApi {
  final dio = Dio();
  final String _dataSource = "Cluster0";
  final String _database = "youtune";
  final String _collection = "songs";
  final String _endpoint = 
      "https://eu-central-1.aws.data.mongodb-api.com/app/data-uloos/endpoint/data/v1";
  final String _clientUrl = "https://eu-central-1.aws.services.cloud.mongodb.com/api/client/v2.0/app/data-uloos/auth/providers/api-key/login" ;
  static const _apiKey = Env.atlasApiKey;

  var authHeader = {"content-type": "application/json"};
  String accessToken = "";

  static final AtlasApi _instance = AtlasApi._internal();
 
  // using a factory is important
  // because it promises to return _an_ object of this type
  // but it doesn't promise to make a new one.
  factory AtlasApi() {
    return _instance;
  }
  
  // This named constructor is the "real" constructor
  // It'll be called exactly once, by the static property assignment above
  // it's also private, so it can only be called in this class
  AtlasApi._internal() {
    // initialization logic 
  }

  Future<void> authenticate() async {
       var response = await dio.post(
      _clientUrl,
      options: Options(headers: authHeader),
      data: jsonEncode({"key": _apiKey},
      ),
    );
    accessToken = response.data["access_token"];
   
  }

  Future<Iterable<Song>> search(String query) async {
    if (query == '') {
      return const Iterable<Song>.empty();
    }
    if (accessToken.isEmpty) {
      await authenticate();
    }
    var headers = {
      "content-type": "application/json",
      "authorization": "Bearer $accessToken",
    };
    var response = await dio.post(
      "$_endpoint/action/find",
      options: Options(headers: headers),
      data: jsonEncode(
        {
          "dataSource": _dataSource,
          "database": _database,
          "collection": _collection,
          "filter": {
            r'$or': [
              {
                "song": {r'$regex': query, r'$options': "i"}
              },
              {
                "artist": {r'$regex': query, r'$options': "i"}
              }
            ]
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var respList = response.data['documents'] as List;
      var songList = respList.map((json) => Song.fromJson(json)).toList();
      return songList;
    } else {
      throw Exception('Error getting songs');
    }
  }

  Future<List<Song>> retrieveSimilar(Song item, String feature) async {
    var ids = item.featureRes[feature];
      var headers = {
      "content-type": "application/json",
      "authorization": "Bearer $accessToken",
    };
     var response = await dio.post(
      "$_endpoint/action/find",
      options: Options(headers: headers),
      data: jsonEncode(
        {
          "dataSource": _dataSource,
          "database": _database,
          "collection": _collection,
          "filter": {
            "id": {r'$in' : ids}
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var respList = response.data['documents'] as List;
      var songList = respList.map((json) => Song.fromJson(json)).toList();
      return songList;
    } else {
      throw Exception('Error getting songs');
    }
  }
}
