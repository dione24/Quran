// Service Firebase - À implémenter dans les versions futures
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Stub pour compilation
  Future<void> initialize() async {
    // TODO: Implémenter Firebase
  }
}
