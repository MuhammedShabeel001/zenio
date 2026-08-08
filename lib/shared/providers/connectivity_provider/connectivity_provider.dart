import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityUtility {
  static bool checkConnectivity(List<ConnectivityResult> result) {
    final connectedResult = [
      ConnectivityResult.wifi,
      ConnectivityResult.ethernet,
      ConnectivityResult.mobile,
    ];
    return connectedResult.toSet().intersection(result.toSet()).isNotEmpty;
  }
}

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map(ConnectivityUtility.checkConnectivity);
});
