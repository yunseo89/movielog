import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.currentIndex, required this.child});
  final int currentIndex;
  final Widget child;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().loadMember();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: widget.currentIndex,
      onDestinationSelected: (i) =>
          context.go(const ['/home', '/movies', '/my'][i]),
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
