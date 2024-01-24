// Mimics a remote API.
class FakeAPI {
  static const List<String> _songOptions = [
    "We As Human - Take The Bullets Away (feat. Lacey Sturm)",
    "The Notorious B.I.G. - Somebody's Gotta Die",
    "Against the Current - Chasing Ghosts	In Our Bones",
    "Barthezz	Infected Trance - The Early Years (1997-2002)",
    "Laura Pausini - Tra Te E Il Mar",
    "Shakira - Costume Makes the Clown",
    "NeYo - Miss Independent",
    "Jawbreaker	- Jinx",
    "Michael Bublé - That's All	Michael Bublé (US Version)",
    "Rhye -	Please"
  ];

  // Searches the options, but injects a fake "network" delay.
  static Future<Iterable<String>> search(String query) async {
    await Future<void>.delayed(Duration(seconds: 1)); // Fake 1 second delay.
    if (query == '') {
      return const Iterable<String>.empty();
    }
    return _songOptions.where((String option) {
      return option.toLowerCase().contains(query.toLowerCase());
    });
  }

  static Future<List<String>> retrieveSimilar(String song) async {
    await Future<void>.delayed(Duration(seconds: 1)); // Fake 1 second delay.
    if (song == '') {
      return List<String>.empty();
    }
    return _songOptions;
  }
}
