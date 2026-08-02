import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/content_item.dart';
import '../repositories/library_repository.dart';

class GetContentsUseCase {
  final LibraryRepository _repository;
  GetContentsUseCase(this._repository);

  TaskEither<Failure, List<ContentItem>> call({String? type, String? search}) {
    return _repository.getContents(type: type, search: search);
  }
}