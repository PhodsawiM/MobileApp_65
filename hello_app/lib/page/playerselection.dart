import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlayerSelection extends StatefulWidget {
  final String title;
  const PlayerSelection({super.key, required this.title});

  @override
  State<PlayerSelection> createState() => _PlayerSelectionState();
}

class _PlayerSelectionState extends State<PlayerSelection> {
  List<Map<String, dynamic>> players = [];
  final Set<String> selectedPlayers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon() async {
    final response = await http
        .get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50')); // ดึง 50 ตัว
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      setState(() {
        players = results.asMap().entries.map((entry) {
          final index = entry.key + 1; // id เริ่มจาก 1
          final name = entry.value['name'];
          return {
            "id": index,
            "name": name[0].toUpperCase() + name.substring(1), // Capitalize
          };
        }).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load Pokémon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // โปเกมอนที่เลือกแล้ว
                Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: selectedPlayers
                        .map(
                          (player) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Chip(
                              avatar: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${players.firstWhere((p) => p['name'] == player)['id']}.png",
                                ),
                              ),
                              label: Text(player),
                              onDeleted: () {
                                setState(() {
                                  selectedPlayers.remove(player);
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                // Grid โปเกมอนทั้งหมด
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 ตัวต่อแถว
                      childAspectRatio: 0.9,
                    ),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final isSelected =
                          selectedPlayers.contains(player['name']);
                      return Card(
                        margin: const EdgeInsets.all(6),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedPlayers.remove(player['name']);
                              } else {
                                if (selectedPlayers.length < 3) {
                                  selectedPlayers.add(player['name']);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You can only select up to 3 players.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${player['id']}.png",
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(player['name'],
                                  style: const TextStyle(fontSize: 14)),
                              if (isSelected)
                                const Icon(Icons.check, color: Colors.green),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
