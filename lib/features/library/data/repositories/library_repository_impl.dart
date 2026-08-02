import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/content_item.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/content_remote_datasource.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final ContentRemoteDataSource _remoteDataSource;

  LibraryRepositoryImpl(this._remoteDataSource);

  @override
  TaskEither<Failure, List<ContentItem>> getContents({
    String? type,
    String? search,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getContents(type: type, search: search);
        return result;
      },
      (error, stackTrace) => handleError(error),
    );
  }
}