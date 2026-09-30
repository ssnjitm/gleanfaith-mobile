import '../../../../core/services/database_service.dart';

/// Language-agnostic book codes used by the backend (e.g. `MAT`).
///
/// The list itself now lives in `database_service.dart` as
/// [kjvCanonicalBookCodes], aligned index-for-index with [kjvCanonicalBooks], so
/// the USFM ↔ KJV correspondence exists in exactly one place and is shared with
/// the free remote Bible endpoint. These wrappers keep the call sites in this
/// feature unchanged.
String bookCodeForName(String bookName) => kjvBookCodeForName(bookName);

/// Map a backend book code (e.g. `'MAT'`) back to a canonical display name
/// (e.g. `'Matthew'`). Falls back to the raw code when unknown.
String bookNameForCode(String bookCode) => kjvBookNameForCode(bookCode);
