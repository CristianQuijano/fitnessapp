import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_db.dart';

final dbProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});
