import 'package:flutter/material.dart';

import '../../home/presentation/home_page.dart';
import '../../modules/presentation/modules_page.dart';
import '../../profile/presentation/profile_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  void _onDestinationSelected(int index) {
    if (index == 0 && _currentIndex == 0) {
      _homePageKey.currentState?.goToMainTab();
      return;
    }

    setState(() => _currentIndex = index);

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _homePageKey.currentState?.goToMainTab();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        key: _homePageKey,
        onOpenModules: () {
          setState(() => _currentIndex = 1);
        },
        onOpenPersonal: () {
          setState(() => _currentIndex = 2);
        },
      ),
      const ModulesPage(),
      const ProfilePage(),
    ];

    final titles = const [
      'Munzur Mobil',
      'Hızlı Erişim',
      'Bana Özel',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Hızlı Erişim',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            selectedIcon: Icon(Icons.person),
            label: 'Bana Özel',
          ),
        ],
      ),
    );
  }
}