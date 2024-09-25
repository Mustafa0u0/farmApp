import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
// import 'package:collection/collection.dart';

// import '../../models/tabs.dart';

// class TabsScreen extends StatefulWidget {
//   const TabsScreen({super.key});

//   @override
//   State<TabsScreen> createState() => _TabsScreenState();
// }

// class _TabsScreenState extends State<TabsScreen> {
//   int _currentIndex = 0;
//   PageController pageController = PageController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Expanded(
//             child: PageView.builder(
//               itemBuilder: (_, i) {
//                 return activeScreen(Tabs.values[i]);
//               },
//               itemCount: Tabs.values.length,
//               controller: pageController,
//               onPageChanged: (i) {
//                 setState(() {
//                   _currentIndex = i;
//                 });
//               },
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: StylishBottomBar(
//         items: Tabs.values
//             .mapIndexed((index, value) => _tab(value: value, index: index))
//             .toList(),
//         option: AnimatedBarOptions(iconSize: 20, iconStyle: IconStyle.Default),
//         hasNotch: true,
//         currentIndex: _currentIndex,
//         onTap: nextIndex,
//       ),
//       resizeToAvoidBottomInset: false,
//     );
//   }

//   BottomBarItem _tab({required Tabs value, required int index}) {
//     return BottomBarItem(
//         icon: SvgPicture.asset(
//           _currentIndex == index ? value.activeIcon : value.icon,
//           // value.icon,
//           height: 25,
//         ),
//         selectedColor: AppColors.mainColor,
//         backgroundColor: Colors.transparent,
//         title: const Text(''));
//   }

//   Widget activeScreen(Tabs tab) {
//     switch (tab) {
//       case Tabs.home:
//         return const HomePage();
//       case Tabs.facilities:
//         return const MyBookingsPage();
//       case Tabs.myBookings:
//         return const NotificationsPage();
//       case Tabs.profile:
//         return const SettingsScreen();
//     }
//   }

//   void nextIndex(int? next) {
//     if (next == null || next < 0 || next >= Tabs.values.length) return;
//     pageController.animateToPage(next,
//         duration: const Duration(milliseconds: 100), curve: Curves.elasticOut);
//   }
// }
