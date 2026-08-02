import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/content_item.dart';

abstract class LibraryRepository {
  TaskEither<Failure, List<ContentItem>> getContents({
    String? type,
    String? search,
  });
}