// // import 'package:flutter/material.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:get/get.dart';
// // import 'controllers/role_controller.dart';
// // import 'screens/splash_screen.dart';
// //
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Firebase.initializeApp();
// //   runApp(const AllInOneSocialApp());
// // }
// //
// // class AllInOneSocialApp extends StatelessWidget {
// //   const AllInOneSocialApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return GetMaterialApp(
// //       title: 'All-In-One Social',
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(
// //         primarySwatch: Colors.blue,
// //         useMaterial3: true,
// //         brightness: Brightness.light,
// //         scaffoldBackgroundColor: Colors.grey[50],
// //       ),
// //       darkTheme: ThemeData(
// //         primarySwatch: Colors.blue,
// //         useMaterial3: true,
// //         brightness: Brightness.dark,
// //         scaffoldBackgroundColor: Colors.black,
// //       ),
// //       initialBinding: BindingsBuilder(() {
// //         Get.put(RoleController(), permanent: true);
// //       }),
// //       home: const SplashScreen(),
// //     );
// //   }
// // }
//
//
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:get/get.dart';
// import 'package:socialmedia/screens/chat_screen.dart';
// import 'package:socialmedia/screens/friends_list_screen.dart';
// import 'controllers/role_controller.dart';
// import 'screens/splash_screen.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//
//   // await FirebaseAppCheck.instance.activate(
//   //   androidProvider: AndroidProvider.playIntegrity,
//   //   appleProvider: AppleProvider.deviceCheck,
//   // );
//
//   runApp(const AllInOneSocialApp());
// }
//
// class AllInOneSocialApp extends StatelessWidget {
//   const AllInOneSocialApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'All-In-One Social',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//         brightness: Brightness.light,
//         scaffoldBackgroundColor: Colors.grey[50],
//       ),
//       darkTheme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: Colors.black,
//       ),
//       initialBinding: BindingsBuilder(() {
//         Get.put(RoleController(), permanent: true);
//       }),
//
//       // ADD THIS: Define your routes here
//       getPages: [
//         GetPage(
//           name: '/',
//           page: () => const SplashScreen(),
//         ),
//         GetPage(
//           name: '/friends',
//           page: () => FriendsListScreen(),
//         ),
//         GetPage(
//           name: '/chat',
//           page: () => ChatScreen(),
//         ),
//         // Add more routes as needed
//       ],
//
//       home: const SplashScreen(),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:socialmedia/screens/chat_screen.dart';
import 'package:socialmedia/screens/friends_list_screen.dart';
import 'package:socialmedia/screens/profile_screen.dart';
import 'package:socialmedia/screens/search_users_screen.dart';
import 'controllers/role_controller.dart';
import 'controllers/create_reel_controller.dart';
import 'controllers/reels_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/create_reel_screen.dart';
import 'screens/create_reel_preview_screen.dart'; // ← NEW
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AllInOneSocialApp());
}

class AllInOneSocialApp extends StatelessWidget {
  const AllInOneSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'All-In-One Social',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(RoleController(), permanent: true);
      }),
      getPages: [
        GetPage(
          name: '/',
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
        ),
        GetPage(
          name: '/create-reel',
          page: () => CreateReelScreen(),
          transition: Transition.rightToLeft,
        ),
        // ✅ NEW — preview/edit screen between video selection and upload
        GetPage(
          name: '/create-reel-preview',
          page: () => const CreateReelPreviewScreen(),
          transition: Transition.downToUp,
        ),
        GetPage(name: '/profile', page: () => ProfileScreen()),
        GetPage(
          name: '/search-users',
          page: () => SearchUsersScreen(),
        ),
        GetPage(name: '/friend', page: () => FriendsListScreen())
      ],
      home: const SplashScreen(),
    );
  }
}