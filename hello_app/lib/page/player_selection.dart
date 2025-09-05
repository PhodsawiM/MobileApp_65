import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'team_controller.dart';

class PlayerSelection extends StatelessWidget {
  final String title;
  const PlayerSelection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeamController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.currentTeam['name'] ?? 'New Team')),
        actions: [
          IconButton(
            tooltip: 'Edit Team Name',
            icon: const Icon(Icons.edit),
            onPressed: () {
              final textCtrl = TextEditingController(text: controller.currentTeam['name']);
              Get.defaultDialog(
                title: 'Edit Team Name',
                content: TextField(
                  controller: textCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) {
                    controller.setTeamName(v);
                    Get.back();
                  },
                  decoration: const InputDecoration(hintText: 'Enter new name'),
                ),
                confirm: FilledButton(
                  onPressed: () {
                    controller.setTeamName(textCtrl.text);
                    Get.back();
                  },
                  child: const Text('Save'),
                ),
                cancel: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Reset Team',
            icon: const Icon(Icons.refresh),
            onPressed: controller.resetTeam,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

        return Column(
          children: [
            // Dropdown เลือกทีม
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: controller.currentTeamIndex.value,
                      items: controller.teams
                          .asMap()
                          .entries
                          .map((entry) => DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value['name']),
                              ))
                          .toList(),
                      onChanged: (v) => controller.selectTeam(v!),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Add New Team',
                        content: TextField(
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'Team name'),
                          onSubmitted: (v) {
                            controller.addTeam(v);
                            Get.back();
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => controller.deleteTeam(controller.currentTeamIndex.value),
                  ),
                ],
              ),
            ),
            // แถวโชว์ Pokémon ที่เลือกแล้ว
            Container(
              height: 110,
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: controller.selectedPokemons.map((p) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Chip(
                      avatar: CircleAvatar(backgroundImage: NetworkImage(p['image'])),
                      label: Text(p['name']),
                      onDeleted: () => controller.togglePokemon(p),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Grid รายชื่อ Pokémon
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: .9,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: controller.pokemons.length,
                itemBuilder: (context, index) {
                  final p = controller.pokemons[index];
                  final isSelected =
                      controller.selectedPokemons.any((e) => e['id'] == p['id']);

                  return GestureDetector(
                    onTap: () => controller.togglePokemon(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          width: 2,
                          color: isSelected ? Colors.green : Colors.grey.shade300,
                        ),
                        color: isSelected ? Colors.green.withOpacity(0.15) : Colors.white,
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                              color: Colors.green.withOpacity(0.15),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: isSelected ? 1.1 : 1.0,
                            child: Image.network(
                              p['image'],
                              height: 60,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(p['name'], style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1 : 0,
                            child: const Icon(Icons.check_circle, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
