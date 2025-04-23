// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocable/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

  {
    'A1': [
      {'french': 'aussi', 'spanish': 'también', 'rank': '53'},
      {'french': 'jour', 'spanish': 'día', 'rank': '71'},
      {'french': 'mettre', 'spanish': 'poner', 'rank': '77'},
      {'french': 'rester', 'spanish': 'quedar', 'rank': '89'},
      {'french': 'porter', 'spanish': 'llevar', 'rank': '93'},
      {'french': 'rien', 'spanish': 'nada', 'rank': '95'},
      {'french': 'appeler', 'spanish': 'llamar', 'rank': '104'},
      {'french': 'prendre', 'spanish': 'tomar', 'rank': '122'},
      {'french': 'femme', 'spanish': 'mujer', 'rank': '127'},
      {'french': 'ensuite', 'spanish': 'luego', 'rank': '132'},
    ],
    'A2': [
      {'french': 'face à', 'spanish': 'frente', 'rank': '260'},
      {'french': 'entendre', 'spanish': 'oír', 'rank': '263'},
      {'french': 'dont', 'spanish': 'cuyo', 'rank': '264'},
      {'french': 'terminer', 'spanish': 'acabar', 'rank': '266'},
      {'french': 'aussi', 'spanish': 'tampoco', 'rank': '279'},
      {'french': 'encore', 'spanish': 'aún', 'rank': '282'},
      {'french': 'sujet', 'spanish': 'tema', 'rank': '283'},
      {'french': 'argent', 'spanish': 'dinero', 'rank': '291'},
      {'french': 'même', 'spanish': 'incluso', 'rank': '294'},
      {'french': 'domaine', 'spanish': 'campo', 'rank': '295'},
    ],
    'B1': [
      {'french': 'objectif', 'spanish': 'propósito', 'rank': '752'},
      {'french': 'attention', 'spanish': 'cuidado', 'rank': '754'},
      {'french': 'niveau', 'spanish': 'grado', 'rank': '756'},
      {'french': 'vaste', 'spanish': 'amplio', 'rank': '763'},
      {'french': 'répondre', 'spanish': 'contestar', 'rank': '764'},
      {'french': 'journal', 'spanish': 'periódico', 'rank': '765'},
      {'french': 'inquiéter', 'spanish': 'preocupar', 'rank': '766'},
      {'french': 'tableau', 'spanish': 'cuadro', 'rank': '779'},
      {'french': 'poste', 'spanish': 'cargo', 'rank': '791'},
      {'french': 'étage', 'spanish': 'piso', 'rank': '797'},
    ],
    'B2': [
      {'french': 'forêt', 'spanish': 'bosque', 'rank': '1506'},
      {'french': 'brûler', 'spanish': 'quemar', 'rank': '1509'},
      {'french': 'appel', 'spanish': 'llamado', 'rank': '1510'},
      {'french': 'attente', 'spanish': 'espera', 'rank': '1525'},
      {'french': 'dépenser', 'spanish': 'gastar', 'rank': '1526'},
      {'french': 'offrir', 'spanish': 'regalar', 'rank': '1528'},
      {'french': 'plaindre', 'spanish': 'quejar', 'rank': '1530'},
      {'french': 'nettoyer', 'spanish': 'limpiar', 'rank': '1537'},
      {'french': 'rapport', 'spanish': 'informe', 'rank': '1548'},
      {'french': 'puissant', 'spanish': 'poderoso', 'rank': '1560'},
    ],
    'C1': [
      {'french': 'récolte', 'spanish': 'cosecha', 'rank': '2780'},
      {'french': 'mou', 'spanish': 'blando', 'rank': '2785'},
      {'french': 'maître', 'spanish': 'amo', 'rank': '2789'},
      {'french': 'engagée', 'spanish': 'comprometido', 'rank': '2805'},
      {'french': 'ennuyeux', 'spanish': 'aburrido', 'rank': '2815'},
      {'french': 'boisson', 'spanish': 'bebida', 'rank': '2830'},
      {'french': 'discussion', 'spanish': 'charla', 'rank': '2832'},
      {'french': 'pomme', 'spanish': 'manzana', 'rank': '2855'},
      {'french': 'morceau', 'spanish': 'pedazo', 'rank': '2857'},
      {'french': 'épuisé', 'spanish': 'agotado', 'rank': '2863'},
    ],
  };