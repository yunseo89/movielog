import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/movie_list_screen.dart';
import '../view_models/movie_list_view_model.dart';
import '../data/services/tmdb_movie_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget?> _pages = [
    const HomeScreen(),
    null,
    const ProfileScreen(),
  ];

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return ChangeNotifierProvider<MovieListViewModel>(
          create: (context) =>
              MovieListViewModel(context.read<TmdbMovieService>())
                ..loadInitial(),
          child: const MovieListScreen(),
        );
      case 2:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _selectPage(int index) {
    setState(() {
      _currentIndex = index;
      _pages[index] ??= _pageForIndex(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(
          _pages.length,
          (index) => _pages[index] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: '영화',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}