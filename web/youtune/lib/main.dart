import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtune/AtlasApi.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_webview/fwfh_webview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AtlasApi().authenticate();
  runApp(YoutuneApp());
}

class YoutuneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youtune',
      theme: ThemeData.dark(),
      home: SearchBrowser(),
    );
  }
}

class SearchBrowser extends StatefulWidget {
  @override
  _SearchBrowserState createState() => _SearchBrowserState();
}

class _SearchBrowserState extends State<SearchBrowser> {
  String _selectedFeature = 'random';
  Song? _selectedSong;
  String? _searchQuery;
  List<Song> _result = [];
  late Iterable<Widget> _lastOptions = <Widget>[];
  final key1 =  GlobalKey();
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'images/youtune.png',
            width: 200,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 0.5 * screenWidth,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                      height: screenHeight * 0.9,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Song Recommendation System',
                            style: GoogleFonts.roboto(
                                fontSize: 36, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'discover new songs that are similar to your query song',
                            style: GoogleFonts.roboto(fontSize: 24),
                          ),
                          const SizedBox(height: 20),
                          SearchAnchor(
                              viewBackgroundColor:
                                  Theme.of(context).primaryColor,
                              viewSurfaceTintColor: Colors.transparent,
                              viewElevation: 0,
                              viewShape: RoundedRectangleBorder(
                                  side: const BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(16)),
                              builder: (BuildContext context,
                                  SearchController controller) {
                                return SearchBar(
                                  controller: controller,
                                  padding: const MaterialStatePropertyAll<
                                          EdgeInsets>(
                                      EdgeInsets.symmetric(horizontal: 16.0)),
                                  hintText: 'Search...',
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  overlayColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  surfaceTintColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                          side: const BorderSide(
                                              color: Colors.white),
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  onTap: () {
                                    controller.openView();
                                  },
                                  onChanged: (_) {
                                    controller.openView();
                                  },
                                  leading: const Icon(Icons.search),
                                  trailing: <Widget>[
                                    const SizedBox(
                                      height: 30,
                                      width: 40,
                                      child: VerticalDivider(
                                        width: 1,
                                        thickness: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: _selectedFeature,
                                      underline: const SizedBox(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedFeature =
                                              newValue ?? _selectedFeature;
                                        });
                                        if (_selectedSong != null) {
                                          AtlasApi()
                                              .retrieveSimilar(_selectedSong!,
                                                  _selectedFeature)
                                              .then((value) {
                                            setState(() {
                                              _result = value;
                                            });
                                            return value;
                                          });
                                        }
                                      },
                                      items: _features
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    )
                                  ],
                                );
                              },
                              suggestionsBuilder: (BuildContext context,
                                  SearchController controller) async {
                                _searchQuery = controller.text;
                                final List<Song> songOptions =
                                    (await AtlasApi().search(_searchQuery!))
                                        .toList();
                                // If another search happened after this one, throw away these options.
                                // Use the previous options instead and wait for the newer request to
                                // finish.
                                if (_searchQuery != controller.text) {
                                  return _lastOptions;
                                }

                                _lastOptions = List<ListTile>.generate(
                                    songOptions.length, (int index) {
                                  final Song song = songOptions[index];
                                  final String item =
                                      '${songOptions[index].title} • ${songOptions[index].artist}';
                                  return ListTile(
                                    title: Text(item),
                                    onTap: () async {
                                      AtlasApi()
                                          .retrieveSimilar(
                                              song, _selectedFeature)
                                          .then((value) {
                                        setState(() {
                                          _result = value;
                                          controller.closeView(item);
                                          _selectedSong = song;
                                        });
                                      }).then((value) =>
                                              Scrollable.ensureVisible(key1.currentContext!, duration: const Duration(seconds: 2), curve: Curves.easeIn));
                                    },
                                  );
                                });

                                return _lastOptions;
                              }),
                        ],
                      )),
                  SizedBox(
                    height: screenHeight*0.1,
                  ),
                  Container(
                    key: key1,
                    constraints: 
                    BoxConstraints(minHeight: screenHeight),
                    child: Column(
                      children: [
                      if (_selectedSong != null) ...[
                        BigSongCard(
                          song: _selectedSong!,
                        ),
                        const SizedBox(height: 20),
                        Row(mainAxisSize: MainAxisSize.max, children: [
                          Text('Top 10 Results',
                              style: GoogleFonts.roboto(
                                  fontSize: 24, fontWeight: FontWeight.w700))
                        ]),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _result.length,
                          itemBuilder: (context, index) {
                            return SmallSongCard(song: _result[index], height: screenHeight*0.1);
                          },
                          separatorBuilder: (context, index) => SizedBox(
                            height: 20,
                          ),
                        )
                      ]
                      ]),)
                      
                    ]),
                  ),
                
          ),
        ),
      );
  }
}

class BigSongCard extends StatefulWidget {
  final Song song;

  BigSongCard({
    super.key,
    required this.song,
  });

  @override
  State<BigSongCard> createState() => _BigSongCardState();
}

class _BigSongCardState extends State<BigSongCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SimpleHtmlYoutubeIframe(youtubeId: widget.song.youtubeId),
        const SizedBox(height: 10),
        Text(widget.song.title,
            style:
                GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w700)),
        Row(
          children: [
            Flexible(
                child: Text(widget.song.artist,
                    style: GoogleFonts.roboto(
                        fontSize: 18, fontWeight: FontWeight.w400),
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(
              width: 10,
            ),
            Text(
              widget.song.youtubeViews,
              style:
                  GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w400),
              softWrap: false,
              maxLines: 1,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(runSpacing: 10, spacing: 10, children: [
          ...widget.song.genres
              .map((e) => Chip(
                  backgroundColor: Color(0x3647E5),
                  label: Text(
                    e,
                    style: GoogleFonts.roboto(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  )))
              .toList()
        ])
      ],
    );
  }
}

class SmallSongCard extends StatefulWidget {
  final Song song;
  final double height;

  SmallSongCard({
    super.key,
    required this.song,
    required this.height
  });

  @override
  State<SmallSongCard> createState() => _SmallSongCardState();
}

class _SmallSongCardState extends State<SmallSongCard> {
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 0,
                constraints: BoxConstraints(minHeight: widget.height),
                  child: SimpleHtmlYoutubeIframe(
                      youtubeId: widget.song.youtubeId)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(widget.song.title,
                      style: GoogleFonts.roboto(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Text(widget.song.artist,
                          style: GoogleFonts.roboto(
                              fontSize: 18, fontWeight: FontWeight.w400),
                          softWrap: false,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        widget.song.youtubeViews,
                        style: GoogleFonts.roboto(
                            fontSize: 18, fontWeight: FontWeight.w400),
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ],
                  ),
                 
                ],
              ),
            ],
          ),
           const SizedBox(height: 10),
           Wrap(runSpacing: 10, spacing: 10, children: [
          ...widget.song.genres
              .map((e) => Chip(
                  backgroundColor: const Color(0x3647E5),
                  label: Text(
                    e,
                    style: GoogleFonts.roboto(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  )))
              .toList()
        ])
        ],
      ),
    );
  }
}

class SimpleHtmlYoutubeIframe extends StatefulWidget {
  final String youtubeId;

  const SimpleHtmlYoutubeIframe({
    super.key,
    required this.youtubeId,
  });

  @override
  State<SimpleHtmlYoutubeIframe> createState() =>
      _SimpleHtmlYoutubeIframeState();
}

class _SimpleHtmlYoutubeIframeState extends State<SimpleHtmlYoutubeIframe> {
  @override
  Widget build(BuildContext context) {
    String content =
        '<iframe src="https://www.youtube.com/embed/${widget.youtubeId}"></iframe>';
    return SizedBox(
      child: HtmlWidget(
        content,
        factoryBuilder: () => _YoutubeIframeWidgetFactory(),
        enableCaching: false,
        key: Key(widget.youtubeId),
      ),
    );
  }
}

class _YoutubeIframeWidgetFactory extends WidgetFactory with WebViewFactory {
  @override
  bool get webViewMediaPlaybackAlwaysAllow => true;
  @override
  String? get webViewUserAgent => 'Lang Learning';
}
