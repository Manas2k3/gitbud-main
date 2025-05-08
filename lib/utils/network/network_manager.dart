import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkManager extends GetxController {
  // Rx variable to store connection status
  var connectionStatus = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initial connection status check
    _checkConnectionStatus();
  }

  // Method to update connection status
  void _updateConnectionStatus() {
    // Check the internet connection
    InternetConnectionChecker().onStatusChange.listen((status) {
      connectionStatus.value = status == InternetConnectionStatus.connected;

      if (connectionStatus.value) {
        print("Connected to the internet!");
      } else {
        // Show a warning when no internet connection is detected
        print("No Internet! Please check your internet connection.");
      }
    });
  }

  // Method to check the internet connection status manually
  Future<void> _checkConnectionStatus() async {
    connectionStatus.value = await InternetConnectionChecker().hasConnection;
    if (connectionStatus.value) {
      print("Initial check: Connected to the internet!");
    } else {
      print("Initial check: No Internet! Please check your internet connection.");
    }

    // Start listening to connection status changes
    _updateConnectionStatus();
  }
}
