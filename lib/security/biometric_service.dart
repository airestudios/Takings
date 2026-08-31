import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? authentication})
    : authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication authentication;

  Future<bool> enable() async {
    final supported = await authentication.isDeviceSupported();
    final available = await authentication.canCheckBiometrics;
    if (!supported || !available) return false;
    return authentication.authenticate(
      localizedReason: 'Confirm your identity to protect ProfitTrack',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }
}
