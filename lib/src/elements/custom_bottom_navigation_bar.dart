import 'package:event_app/src/constants.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  /// NavigationBar in main pages
  CustomBottomNavigationBar({Key? key, required this.selectedIndex})
      : super(key: key);
  final int selectedIndex;

  final list = ["/explorePage", "/myEvents", "/settings"];

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: Colors.white.withOpacity(0.1),
      ),
      child: NavigationBar(
        backgroundColor: Constants.backgroundColor,
        animationDuration: const Duration(seconds: 1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 60,
        selectedIndex: selectedIndex,
        onDestinationSelected: (int newIndex) {
          if (selectedIndex != newIndex) {
            Navigator.pushReplacementNamed(context, list[newIndex]);
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(
                Icons.gps_fixed_outlined,
                color: Constants.themeColor,
              ),
              selectedIcon: Icon(
                Icons.gps_fixed,
                color: Constants.themeColor,
              ),
              label: "Explore"),
          NavigationDestination(
              icon: Icon(
                Icons.event_outlined,
                color: Constants.themeColor,
              ),
              selectedIcon: Icon(
                Icons.event,
                color: Constants.themeColor,
              ),
              label: "Events"),
          NavigationDestination(
              icon: Icon(
                Icons.settings_outlined,
                color: Constants.themeColor,
              ),
              selectedIcon: Icon(
                Icons.settings,
                color: Constants.themeColor,
              ),
              label: "Settings"),
        ],
      ),
    );
  }
}
