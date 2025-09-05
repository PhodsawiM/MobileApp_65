import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class TeamController extends GetxController {
  final box = GetStorage();

  final pokemons = <Map<String, dynamic>>[].obs;
  final teams = <Map<String, dynamic>>[].obs; // ทุกทีม
  final currentTeamIndex = 0.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadTeams();
    fetchPokemons();
  }

  Future<void> fetchPokemons({int limit = 60}) async {
    try {
      isLoading.value = true;
      final res = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$limit'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List results = data['results'];

        pokemons.value = results.asMap().entries.map((entry) {
          final id = entry.key + 1;
          final name = (entry.value['name'] as String);
          return {
            'id': id,
            'name': name[0].toUpperCase() + name.substring(1),
            'image': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
          };
        }).toList();
      } else {
        Get.snackbar('Error', 'Failed to load Pokémon (${res.statusCode})');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load Pokémon');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> get currentTeam => teams.isNotEmpty ? teams[currentTeamIndex.value] : {'name':'New Team','pokemons':[]};

  List<Map<String, dynamic>> get selectedPokemons {
    return List<Map<String, dynamic>>.from(currentTeam['pokemons'] ?? []);
  }

  void togglePokemon(Map<String, dynamic> pokemon) {
    final id = pokemon['id'] as int;
    List<Map<String, dynamic>> selected = selectedPokemons;

    if (selected.any((p) => p['id'] == id)) {
      selected.removeWhere((p) => p['id'] == id);
    } else {
      if (selected.length < 3) {
        selected.add({
          'id': pokemon['id'],
          'name': pokemon['name'],
          'image': pokemon['image'],
        });
      } else {
        Get.snackbar('Limit', 'You can only select up to 3 Pokémon!');
      }
    }
    currentTeam['pokemons'] = selected;
    saveTeams();
    teams.refresh();
  }

  void setTeamName(String name) {
    currentTeam['name'] = name.trim().isEmpty ? 'New Team' : name.trim();
    saveTeams();
    teams.refresh();
  }

  void addTeam(String name) {
    teams.add({'name': name.trim().isEmpty ? 'New Team' : name.trim(), 'pokemons': []});
    currentTeamIndex.value = teams.length - 1;
    saveTeams();
  }

  void deleteTeam(int index) {
    if (index < 0 || index >= teams.length) return;
    teams.removeAt(index);
    if (teams.isEmpty) {
      addTeam('New Team');
      currentTeamIndex.value = 0;
    } else if (currentTeamIndex.value >= teams.length) {
      currentTeamIndex.value = teams.length - 1;
    }
    saveTeams();
  }

  void resetTeam() {
    currentTeam['pokemons'] = [];
    saveTeams();
    teams.refresh();
    Get.snackbar('Reset', 'Team cleared');
  }

  void saveTeams() {
    box.write('teams', teams.toList());
  }

  void loadTeams() {
    final saved = box.read('teams');
    if (saved is List) {
      teams.value =
          List<Map<String, dynamic>>.from(saved.map((e) => Map<String, dynamic>.from(e)));
    }
    if (teams.isEmpty) {
      addTeam('My Team');
    }
  }

  void selectTeam(int index) {
    if (index < 0 || index >= teams.length) return;
    currentTeamIndex.value = index;
    teams.refresh();
  }
}
