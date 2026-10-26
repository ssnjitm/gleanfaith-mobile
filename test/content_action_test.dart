import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/services/content_action_service.dart';

void main() {
  group('formatVerseForSharing', () {
    test('wraps the verse text in quotes and appends the reference', () {
      expect(
        formatVerseForSharing(text: 'For God so loved', reference: 'John 3:16'),
        '"For God so loved" — John 3:16',
      );
    });

    test('trims surrounding whitespace from both parts', () {
      expect(
        formatVerseForSharing(
          text: '  The Lord is my shepherd  ',
          reference: '  Psalms 23:1  ',
        ),
        '"The Lord is my shepherd" — Psalms 23:1',
      );
    });

    test('returns only the reference when the text is empty', () {
      expect(
        formatVerseForSharing(text: '   ', reference: 'John 3:16'),
        'John 3:16',
      );
    });

    test('returns only the text when the reference is empty', () {
      expect(
        formatVerseForSharing(text: 'Be still', reference: ''),
        'Be still',
      );
    });

    test('returns an empty string when both parts are empty', () {
      expect(formatVerseForSharing(text: '', reference: ''), '');
    });
  });
}
