import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../meetings/meetings_view.dart';
import '../profile/profile_view.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Create PageController with initial page
    final PageController pageController = PageController(
      initialPage: controller.currentIndex.value,
    );
    
    // Listen for controller index changes to update PageView
    ever(controller.currentIndex, (index) {
      if (pageController.hasClients && index != 1) {
        pageController.animateToPage(
          index == 2 ? 1 : 0, // Map index 2 to page 1
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
    
    return Scaffold(
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          MeetingsView(),      // page 0 (index 0)
          ProfileView(),       // page 1 (index 2)
        ],
      ),
      bottomNavigationBar: GetBuilder<HomeController>(
        builder: (controller) => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.changePage,
          animationDuration: const Duration(milliseconds: 300),
          elevation: 8,
          surfaceTintColor: Theme.of(context).colorScheme.primary,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: 'Meetings',
              tooltip: 'View all meetings',
            ),
            NavigationDestination(
              icon: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              selectedIcon: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              label: 'New',
              tooltip: 'Start new meeting',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'View profile',
            ),
          ],
        ),
      ),
    );
  }
}