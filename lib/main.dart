import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyCard extends StatefulWidget {
  const MyCard({super.key, required this.title, required this.body, this.image});

  final String title;
  final List<Widget> body;
  final Widget? image;

  @override
  State<MyCard> createState() => _MyCardState();
}

class _MyCardState extends State<MyCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!)
      ),
      width: double.maxFinite,
      height: 350,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.image ?? Center(
                heightFactor: 2,
                child: HeroIcon(HeroIcons.photo, size: 100, color: Colors.grey[900])
              )
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(widget.title, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[900]))),
            ),
            ...widget.body
          ]
        )
      )
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[50]!),
        useMaterial3: false
      ),
      home: const MyHomePage(title: 'Anime API')
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Anime {
  final int id;
  final String title;
  final String imageUrl;
  final String synopsis;

  const Anime({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.synopsis = ''
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['mal_id'],
      title: json['titles'][0]['title'],
      imageUrl: json['images']?['jpg']?['large_image_url'] ?? '',
      synopsis: json['synopsis'] ?? ''
    );
  }
}

Future<Anime> fetchAnime(int id) async {
  final response = await http.get(Uri.parse('https://api.jikan.moe/v4/anime/$id'));

  if (response.statusCode == 200) {
    return Anime.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load anime');
  }
}

Future<List<Anime>> searchAnime(String query) async {
  final response = await http.get(Uri.parse('https://api.jikan.moe/v4/anime?q=$query'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body)['data'];
    return data.map((anime) => Anime.fromJson(anime as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load anime');
  }
}

class SearchField extends StatefulWidget {
  final Function(String) onSearch;

  const SearchField({super.key, required this.onSearch});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(width: 1.0, color: Colors.grey[300]!)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(width: 1.0, color: Colors.grey[300]!)
        ),
        contentPadding: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        suffixIcon: HeroIcon(HeroIcons.magnifyingGlass, color: Colors.grey[500]),
        label: Text('Search', style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 16, color: Colors.grey[500])))
      ),
      onSubmitted: widget.onSearch
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Anime>> futureAnimeList;

  @override
  void initState() {
    super.initState();
    futureAnimeList = searchAnime('');
  }

  void _handleSearch(String query) {
    setState(() {
      futureAnimeList = searchAnime(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title, style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[900])))
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: SearchField(
                onSearch: _handleSearch
              )
            ),
            FutureBuilder<List<Anime>>(
              future: futureAnimeList,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        Anime anime = snapshot.data![index];
                        return Container(
                          margin: EdgeInsets.only(bottom: index == snapshot.data!.length - 1 ? 0 : 16),
                          child: MyCard(
                            title: anime.title,
                            body: <Widget>[
                              Text(anime.synopsis, overflow: TextOverflow.ellipsis, maxLines: 3, style: GoogleFonts.getFont('DM Sans')),
                            ],
                            image: Image.network(
                              anime.imageUrl,
                              fit: BoxFit.cover,
                              width: double.maxFinite,
                              height: 200,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  width: double.maxFinite,
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator()
                                  )
                                );
                              }
                            )
                          )
                        );
                      },
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const Center(child: CircularProgressIndicator());
              },
            )
          ]
        )
      )
    );
  }
}
