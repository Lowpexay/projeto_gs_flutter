import 'package:flutter/material.dart';
import 'alerts_page.dart'; 
import 'history_page.dart';


class ChatbotPage extends StatelessWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Chatbot sobre clima e alertas'));
  }
}

class MapPage extends StatelessWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Mapa do mundo com clima atual'));
  }
}

class ReportPage extends StatelessWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Página para reportar alertas'));
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoramento Climático',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    AlertsPage(),
    ChatbotPage(),
    HistoryPage(),
    ReportPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento Climático'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
  backgroundColor: Colors.blueGrey[900], // cor escura
  selectedItemColor: Colors.orange,
  unselectedItemColor: const Color.fromARGB(179, 182, 106, 51),
  currentIndex: _selectedIndex,
  onTap: _onItemTapped,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.warning),
      label: 'Alertas',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Chatbot',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.public),
      label: 'Mapa',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.report),
      label: 'Reportar',
    ),
  ],
),
    );
  }
}