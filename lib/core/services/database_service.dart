import 'package:path_provider/path_provider.dart';

class DatabaseService {
  Future<void> init() async {
    await getApplicationDocumentsDirectory();
    // TODO: Initialize ObjectBox store with generated code
    // store = await openStore(directory: '${dir.path}/objectbox');
  }

  void dispose() {
    // store.close();
  }
}
