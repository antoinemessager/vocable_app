import 'package:flutter/material.dart';

class SettingsHelpCenterScreen extends StatelessWidget {
  const SettingsHelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Comment l\'apprentissage fonctionne',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'La recherche montre que pour mémoriser efficacement de nouveaux mots, tu dois t\'en rappeler avec succès 5 fois à des intervalles spécifiques :',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineItem('Première révision', 'immédiatement'),
                  _buildTimelineItem('Deuxième révision', '1 heure plus tard'),
                  _buildTimelineItem('Troisième révision', '1 jour plus tard'),
                  _buildTimelineItem('Quatrième révision', '3 jours plus tard'),
                  _buildTimelineItem('Cinquième révision', '7 jours plus tard'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Le système de compteur',
              content: Text(
                'Le compteur en haut de chaque carte indique ta progression à travers ces 5 révisions. Chaque fois que tu te souviens correctement d\'un mot, le compteur augmente. Si tu ne parviens pas à te souvenir d\'un mot, le compteur revient à 0. Dès que tu as 5 révisions correctes, le mot est marqué comme connu.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Interface de la carte',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chaque carte comporte trois boutons :',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildButtonInfo(
                    icon: Icons.check,
                    iconColor: Colors.green,
                    backgroundColor:
                        Colors.green[50] ?? Colors.green.withOpacity(0.1),
                    title: 'Correct',
                    description:
                        'Appuie ici lorsque tu te souviens correctement du mot. Cela augmente ton compteur.',
                  ),
                  const SizedBox(height: 16),
                  _buildButtonInfo(
                    icon: Icons.close,
                    iconColor: Colors.red,
                    backgroundColor:
                        Colors.red[50] ?? Colors.red.withOpacity(0.1),
                    title: 'Incorrect',
                    description:
                        'Appuie ici lorsque tu ne te souviens pas du mot. Cela réinitialise ton compteur à 0 et te permettra de revoir le mot plus souvent.',
                  ),
                  const SizedBox(height: 16),
                  _buildButtonInfo(
                    icon: Icons.double_arrow,
                    iconColor: Colors.grey[700] ?? Colors.grey,
                    backgroundColor:
                        Colors.grey[100] ?? Colors.grey.withOpacity(0.1),
                    title: 'Déjà Vu',
                    description:
                        'Appuie ici si tu es sur de connaître le mot. Cela déplace le mot vers le niveau le plus haut et tu ne le verras plus. Il n\'est pas comptabilisé dans ta progression puisque tu le connaissais déjà.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonInfo({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
