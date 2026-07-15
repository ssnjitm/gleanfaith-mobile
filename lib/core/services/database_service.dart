import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  Future<void> init() async {
    if (!kIsWeb) {
      try {
        await getApplicationDocumentsDirectory();
        // TODO: Initialize ObjectBox store with generated code
        // store = await openStore(directory: '${dir.path}/objectbox');
      } catch (_) {}
    }
  }

  void dispose() {
    // store.close();
  }
}
