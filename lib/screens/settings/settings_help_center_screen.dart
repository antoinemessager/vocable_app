import 'package:flutter/material.dart';

class SettingsHelpCenterScreen extends StatelessWidget {
  const SettingsHelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comment l\'apprentissage fonctionne',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'La recherche montre que pour mémoriser efficacement de nouveaux mots, tu dois t\'en rappeler avec succès 5 fois à des intervalles spécifiques :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Première révision : immédiatement'),
                  Text('• Deuxième révision : 1 heure plus tard'),
                  Text('• Troisième révision : 1 jour plus tard'),
                  Text('• Quatrième révision : 3 jours plus tard'),
                  Text('• Cinquième révision : 7 jours plus tard'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Le système de compteur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Le compteur en haut de chaque carte indique ta progression à travers ces 5 révisions. Chaque fois que tu te souviens correctement d\'un mot, le compteur augmente. Si tu ne parviens pas à te souvenir d\'un mot, le compteur revient à 0. Dès que tu as 5 révisions correctes, le mot est marqué comme connu.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Interface de la carte',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chaque carte comporte trois boutons :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Correct : Appuie ici lorsque tu te souviens correctement du mot. Cela augmente ton compteur.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Incorrect : Appuie ici lorsque tu ne te souviens pas du mot. Cela réinitialise ton compteur à 0. Il faudra le avoir juste à nouveau 5 fois de suite pour le mettre dans la case connue.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.double_arrow,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Trop facile : Appuie ici si tu es sur de connaître le mot. Cela déplace le mot vers le niveau le plus haut et tu ne le verras plus.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
