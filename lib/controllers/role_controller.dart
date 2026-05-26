import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';

class RoleController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var userRole = 'user'.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        fetchUserRole();
      } else {
        isLoading.value = false;
      }
    });
  }

  Future<void> fetchUserRole() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;
      if (user != null) {
        // In production, fetch from Firestore or custom claims
        // For demo, we'll check a simple field
        userRole.value = 'user'; // Default
      }
    } finally {
      isLoading.value = false;
    }
  }

  void navigateByRole() {
    if (_auth.currentUser == null) {
      Get.offAll(() => const LoginScreen());
      return;
    }

    switch (userRole.value) {
      case 'admin':
        // Get.offAll(() => const AdminPanelScreen());
        break;
      case 'creator':
        // Get.offAll(() => const CreatorDashboardScreen());
        break;
      default:
        Get.offAll(() => HomeScreen());
    }
  }
}