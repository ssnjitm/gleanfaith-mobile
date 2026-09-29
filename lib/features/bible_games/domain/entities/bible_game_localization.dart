/// Inline localization data for the Bible games.
///
/// Everything the games need to speak Nepali lives HERE, in code, as const
/// structures shaped exactly like JSON (`{key: {en, np}}`) — no asset file, no
/// network call, no database column. Three blocks:
///
/// 1. `bibleGameBookCatalog` — the 66 canonical books with their English and
///    Nepali names plus chapter/verse counts.
/// 2. `bibleGameVerseCatalog` — a curated seed set of verses in both languages
///    for Guess the Book. A verse NOT in this list falls back to the offline
///    KJV text from SQLite (see `BibleGameStrings.noNepaliVerse`).
/// 3. `bibleGameUiCopy` — every piece of UI and engine copy in both languages.
///
/// ### Database first, JSON as the translation layer
///
/// The offline SQLite Bible DB remains the source of truth for *data* (which
/// books exist, how many chapters/verses they really contain, the verse text).
/// This catalog only *translates* it: `BibleGameBook.displayNameFor(language)`
/// returns the DB name for English and the JSON name for Nepali, falling back
/// to the DB name whenever the JSON has no entry. Counts work the same way —
/// the JSON value is used only when the DB reports 0 (e.g. web fallback mode),
/// which keeps the games playable with no database at all.
library;

/// Languages the Bible games are presented in.
///
/// The language is derived from the device locale by `bibleGameLanguageProvider`
/// (see `presentation/providers`) — this enum is deliberately free of any
/// Flutter import so the domain layer stays pure.
enum BibleGameLanguage {
  english('en', 'English'),
  nepali('ne', 'नेपाली');

  const BibleGameLanguage(this.code, this.label);

  /// ISO 639-1 code. Nepali is `ne`; `np`/`nep`/`nepali` are accepted too.
  final String code;

  /// The language's own name (never translated into the other language).
  final String label;

  /// Tolerant parser — a device locale can be `ne`, `np`, `nep`, `nepali` or
  /// carry a region/script suffix such as `ne_NP` or `ne-Latn`. Anything not
  /// recognisably Nepali falls back to English, so an unknown locale can never
  /// blank out the games.
  static BibleGameLanguage fromCode(String? code) {
    final normalized = code?.trim().toLowerCase().replaceAll('_', '-') ?? '';
    if (normalized.isEmpty) return BibleGameLanguage.english;
    final root = normalized.split('-').first;
    switch (root) {
      case 'ne':
      case 'np':
      case 'nep':
      case 'nepali':
        return BibleGameLanguage.nepali;
      default:
        return BibleGameLanguage.english;
    }
  }
}

/// Maps ASCII digits to Devanagari digits so Nepali surfaces read natively
/// (e.g. `150` becomes `१५०`). Non-digits pass through untouched.
String toNepaliDigits(String input) {
  const digits = {
    '0': '०',
    '1': '१',
    '2': '२',
    '3': '३',
    '4': '४',
    '5': '५',
    '6': '६',
    '7': '७',
    '8': '८',
    '9': '९',
  };
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(digits[char] ?? char);
  }
  return buffer.toString();
}

/// Renders [value] with the numeral style of [language] — plain ASCII for
/// English, Devanagari for Nepali.
String formatCount(int value, BibleGameLanguage language) {
  return language == BibleGameLanguage.nepali
      ? toNepaliDigits('$value')
      : '$value';
}

/// One canonical Bible book with both names and its canonical counts.
class BibleGameBookData {
  /// Stable lookup key matching the DB `book_slug` column (`1-samuel`).
  final String slug;

  /// KJV display name as stored in the DB (also the English UI name).
  final String nameEn;

  /// Nepali name.
  final String nameNp;

  /// Number of chapters (KJV).
  final int chapters;

  /// Number of verses (KJV).
  final int verses;

  const BibleGameBookData({
    required this.slug,
    required this.nameEn,
    required this.nameNp,
    required this.chapters,
    required this.verses,
  });

  /// The name to render in [language], or null when this language has no
  /// translation on record (so callers can fall back to the DB name).
  String? nameFor(BibleGameLanguage language) {
    if (language == BibleGameLanguage.nepali) {
      return nameNp.isEmpty ? null : nameNp;
    }
    return nameEn.isEmpty ? null : nameEn;
  }
}

/// The 66 books of the Protestant canon, in canonical order.
///
/// Inline data — the equivalent of `bible_books.json`. The counts are the
/// standard KJV figures and are only consulted when the offline DB reports 0.
const List<BibleGameBookData> bibleGameBookCatalog = [
  BibleGameBookData(
      slug: 'genesis',
      nameEn: 'Genesis',
      nameNp: 'उत्पत्ति',
      chapters: 50,
      verses: 1536),
  BibleGameBookData(
      slug: 'exodus',
      nameEn: 'Exodus',
      nameNp: 'प्रस्थान',
      chapters: 40,
      verses: 1213),
  BibleGameBookData(
      slug: 'leviticus',
      nameEn: 'Leviticus',
      nameNp: 'लेवी',
      chapters: 27,
      verses: 939),
  BibleGameBookData(
      slug: 'numbers',
      nameEn: 'Numbers',
      nameNp: 'गन्ती',
      chapters: 36,
      verses: 1213),
  BibleGameBookData(
      slug: 'deuteronomy',
      nameEn: 'Deuteronomy',
      nameNp: 'व्यवस्था',
      chapters: 34,
      verses: 959),
  BibleGameBookData(
      slug: 'joshua',
      nameEn: 'Joshua',
      nameNp: 'यहोशू',
      chapters: 24,
      verses: 907),
  BibleGameBookData(
      slug: 'judges',
      nameEn: 'Judges',
      nameNp: 'न्यायकर्ता',
      chapters: 21,
      verses: 618),
  BibleGameBookData(
      slug: 'ruth',
      nameEn: 'Ruth',
      nameNp: 'रूथ',
      chapters: 4,
      verses: 85),
  BibleGameBookData(
      slug: '1-samuel',
      nameEn: '1 Samuel',
      nameNp: '१ शमूएल',
      chapters: 31,
      verses: 811),
  BibleGameBookData(
      slug: '2-samuel',
      nameEn: '2 Samuel',
      nameNp: '२ शमूएल',
      chapters: 24,
      verses: 823),
  BibleGameBookData(
      slug: '1-kings',
      nameEn: '1 Kings',
      nameNp: '१ राजा',
      chapters: 22,
      verses: 746),
  BibleGameBookData(
      slug: '2-kings',
      nameEn: '2 Kings',
      nameNp: '२ राजा',
      chapters: 25,
      verses: 722),
  BibleGameBookData(
      slug: '1-chronicles',
      nameEn: '1 Chronicles',
      nameNp: '१ इतिहास',
      chapters: 29,
      verses: 942),
  BibleGameBookData(
      slug: '2-chronicles',
      nameEn: '2 Chronicles',
      nameNp: '२ इतिहास',
      chapters: 36,
      verses: 847),
  BibleGameBookData(
      slug: 'ezra',
      nameEn: 'Ezra',
      nameNp: 'एज्रा',
      chapters: 10,
      verses: 277),
  BibleGameBookData(
      slug: 'nehemiah',
      nameEn: 'Nehemiah',
      nameNp: 'नहेम्याह',
      chapters: 13,
      verses: 406),
  BibleGameBookData(
      slug: 'esther',
      nameEn: 'Esther',
      nameNp: 'एस्तर',
      chapters: 10,
      verses: 167),
  BibleGameBookData(
      slug: 'job',
      nameEn: 'Job',
      nameNp: 'अय्यूब',
      chapters: 42,
      verses: 1070),
  BibleGameBookData(
      slug: 'psalms',
      nameEn: 'Psalms',
      nameNp: 'भजनसंग्रह',
      chapters: 150,
      verses: 1892),
  BibleGameBookData(
      slug: 'proverbs',
      nameEn: 'Proverbs',
      nameNp: 'हितोपदेश',
      chapters: 31,
      verses: 915),
  BibleGameBookData(
      slug: 'ecclesiastes',
      nameEn: 'Ecclesiastes',
      nameNp: 'उपदेशक',
      chapters: 12,
      verses: 222),
  BibleGameBookData(
      slug: 'song-of-solomon',
      nameEn: 'Song of Solomon',
      nameNp: 'श्रेष्ठगीत',
      chapters: 8,
      verses: 117),
  BibleGameBookData(
      slug: 'isaiah',
      nameEn: 'Isaiah',
      nameNp: 'यशैया',
      chapters: 66,
      verses: 1291),
  BibleGameBookData(
      slug: 'jeremiah',
      nameEn: 'Jeremiah',
      nameNp: 'यर्मिया',
      chapters: 52,
      verses: 1463),
  BibleGameBookData(
      slug: 'lamentations',
      nameEn: 'Lamentations',
      nameNp: 'विलाप',
      chapters: 5,
      verses: 154),
  BibleGameBookData(
      slug: 'ezekiel',
      nameEn: 'Ezekiel',
      nameNp: 'एजिकिएल',
      chapters: 48,
      verses: 1278),
  BibleGameBookData(
      slug: 'daniel',
      nameEn: 'Daniel',
      nameNp: 'दानिएल',
      chapters: 12,
      verses: 1218),
  BibleGameBookData(
      slug: 'hosea',
      nameEn: 'Hosea',
      nameNp: 'होशे',
      chapters: 14,
      verses: 197),
  BibleGameBookData(
      slug: 'joel',
      nameEn: 'Joel',
      nameNp: 'योएल',
      chapters: 3,
      verses: 73),
  BibleGameBookData(
      slug: 'amos',
      nameEn: 'Amos',
      nameNp: 'आमोस',
      chapters: 9,
      verses: 146),
  BibleGameBookData(
      slug: 'obadiah',
      nameEn: 'Obadiah',
      nameNp: 'ओबदिया',
      chapters: 1,
      verses: 21),
  BibleGameBookData(
      slug: 'jonah',
      nameEn: 'Jonah',
      nameNp: 'यूना',
      chapters: 4,
      verses: 17),
  BibleGameBookData(
      slug: 'micah',
      nameEn: 'Micah',
      nameNp: 'मीका',
      chapters: 7,
      verses: 207),
  BibleGameBookData(
      slug: 'nahum',
      nameEn: 'Nahum',
      nameNp: 'नहूम',
      chapters: 3,
      verses: 47),
  BibleGameBookData(
      slug: 'habakkuk',
      nameEn: 'Habakkuk',
      nameNp: 'हबकूक',
      chapters: 3,
      verses: 56),
  BibleGameBookData(
      slug: 'zephaniah',
      nameEn: 'Zephaniah',
      nameNp: 'सपन्याह',
      chapters: 3,
      verses: 53),
  BibleGameBookData(
      slug: 'haggai',
      nameEn: 'Haggai',
      nameNp: 'हाग्गै',
      chapters: 2,
      verses: 39),
  BibleGameBookData(
      slug: 'zechariah',
      nameEn: 'Zechariah',
      nameNp: 'जकरिया',
      chapters: 14,
      verses: 211),
  BibleGameBookData(
      slug: 'malachi',
      nameEn: 'Malachi',
      nameNp: 'मलाकी',
      chapters: 4,
      verses: 18),
  BibleGameBookData(
      slug: 'matthew',
      nameEn: 'Matthew',
      nameNp: 'मत्ती',
      chapters: 28,
      verses: 1071),
  BibleGameBookData(
      slug: 'mark',
      nameEn: 'Mark',
      nameNp: 'मर्कूस',
      chapters: 16,
      verses: 678),
  BibleGameBookData(
      slug: 'luke',
      nameEn: 'Luke',
      nameNp: 'लूका',
      chapters: 24,
      verses: 1151),
  BibleGameBookData(
      slug: 'john',
      nameEn: 'John',
      nameNp: 'यूहन्ना',
      chapters: 21,
      verses: 879),
  BibleGameBookData(
      slug: 'acts',
      nameEn: 'Acts',
      nameNp: 'प्रेरित',
      chapters: 28,
      verses: 1005),
  BibleGameBookData(
      slug: 'romans',
      nameEn: 'Romans',
      nameNp: 'रोमी',
      chapters: 16,
      verses: 433),
  BibleGameBookData(
      slug: '1-corinthians',
      nameEn: '1 Corinthians',
      nameNp: '१ कोरिन्थी',
      chapters: 16,
      verses: 437),
  BibleGameBookData(
      slug: '2-corinthians',
      nameEn: '2 Corinthians',
      nameNp: '२ कोरिन्थी',
      chapters: 13,
      verses: 257),
  BibleGameBookData(
      slug: 'galatians',
      nameEn: 'Galatians',
      nameNp: 'गलाती',
      chapters: 6,
      verses: 149),
  BibleGameBookData(
      slug: 'ephesians',
      nameEn: 'Ephesians',
      nameNp: 'एफिसी',
      chapters: 6,
      verses: 155),
  BibleGameBookData(
      slug: 'philippians',
      nameEn: 'Philippians',
      nameNp: 'फिलिप्पी',
      chapters: 4,
      verses: 104),
  BibleGameBookData(
      slug: 'colossians',
      nameEn: 'Colossians',
      nameNp: 'कलस्सी',
      chapters: 4,
      verses: 95),
  BibleGameBookData(
      slug: '1-thessalonians',
      nameEn: '1 Thessalonians',
      nameNp: '१ थिस्सलोनिकी',
      chapters: 5,
      verses: 89),
  BibleGameBookData(
      slug: '2-thessalonians',
      nameEn: '2 Thessalonians',
      nameNp: '२ थिस्सलोनिकी',
      chapters: 3,
      verses: 47),
  BibleGameBookData(
      slug: '1-timothy',
      nameEn: '1 Timothy',
      nameNp: '१ तिमोथी',
      chapters: 6,
      verses: 113),
  BibleGameBookData(
      slug: '2-timothy',
      nameEn: '2 Timothy',
      nameNp: '२ तिमोथी',
      chapters: 4,
      verses: 83),
  BibleGameBookData(
      slug: 'titus',
      nameEn: 'Titus',
      nameNp: 'तीतस',
      chapters: 3,
      verses: 46),
  BibleGameBookData(
      slug: 'philemon',
      nameEn: 'Philemon',
      nameNp: 'फिलेमोन',
      chapters: 1,
      verses: 25),
  BibleGameBookData(
      slug: 'hebrews',
      nameEn: 'Hebrews',
      nameNp: 'हिब्रू',
      chapters: 13,
      verses: 303),
  BibleGameBookData(
      slug: 'james',
      nameEn: 'James',
      nameNp: 'याकूब',
      chapters: 5,
      verses: 108),
  BibleGameBookData(
      slug: '1-peter',
      nameEn: '1 Peter',
      nameNp: '१ पत्रुस',
      chapters: 5,
      verses: 105),
  BibleGameBookData(
      slug: '2-peter',
      nameEn: '2 Peter',
      nameNp: '२ पत्रुस',
      chapters: 3,
      verses: 91),
  BibleGameBookData(
      slug: '1-john',
      nameEn: '1 John',
      nameNp: '१ यूहन्ना',
      chapters: 5,
      verses: 105),
  BibleGameBookData(
      slug: '2-john',
      nameEn: '2 John',
      nameNp: '२ यूहन्ना',
      chapters: 1,
      verses: 13),
  BibleGameBookData(
      slug: '3-john',
      nameEn: '3 John',
      nameNp: '३ यूहन्ना',
      chapters: 1,
      verses: 14),
  BibleGameBookData(
      slug: 'jude',
      nameEn: 'Jude',
      nameNp: 'यहूदा',
      chapters: 1,
      verses: 25),
  BibleGameBookData(
      slug: 'revelation',
      nameEn: 'Revelation',
      nameNp: 'प्रकाश',
      chapters: 22,
      verses: 404),
];

/// Slug to catalog entry. Built once, lazily.
Map<String, BibleGameBookData>? _bySlug;

/// Lower-cased English name to catalog entry, so a DB row whose `book` string
/// differs slightly (extra space, different casing) still resolves.
Map<String, BibleGameBookData>? _byName;

/// The catalog entry for a DB `book_slug` value, or null when unknown.
BibleGameBookData? bibleGameBookDataForSlug(String? slug) {
  if (slug == null || slug.isEmpty) return null;
  final lookup = _bySlug ??= {
    for (final book in bibleGameBookCatalog) book.slug: book,
  };
  return lookup[slug.trim().toLowerCase()];
}

/// The catalog entry for a DB `book` display name, or null when unknown.
BibleGameBookData? bibleGameBookDataForName(String? name) {
  if (name == null || name.isEmpty) return null;
  final lookup = _byName ??= {
    for (final book in bibleGameBookCatalog) book.nameEn.toLowerCase(): book,
  };
  return lookup[name.trim().toLowerCase()];
}

/// Resolves a catalog entry from either a slug or a display name. Slug is tried
/// first because it is the stable key.
BibleGameBookData? bibleGameBookDataFor({String? slug, String? name}) {
  return bibleGameBookDataForSlug(slug) ?? bibleGameBookDataForName(name);
}

/// A verse with text in both languages, used by Guess the Book when the
/// selected language is Nepali and the offline DB only carries KJV.
class BibleGameVerseData {
  final String bookSlug;
  final String bookEn;
  final String bookNp;
  final int chapter;
  final int verse;
  final String textEn;
  final String textNp;

  const BibleGameVerseData({
    required this.bookSlug,
    required this.bookEn,
    required this.bookNp,
    required this.chapter,
    required this.verse,
    required this.textEn,
    required this.textNp,
  });

  /// The verse text in [language], or null when there is no translation.
  String? textFor(BibleGameLanguage language) {
    final text = language == BibleGameLanguage.nepali ? textNp : textEn;
    return text.isEmpty ? null : text;
  }

  /// Whether this entry can supply the text for [language].
  bool hasTextFor(BibleGameLanguage language) {
    final text = textFor(language);
    return text != null && text.isNotEmpty;
  }

  String bookNameFor(BibleGameLanguage language) {
    final name = language == BibleGameLanguage.nepali ? bookNp : bookEn;
    return name.isEmpty ? bookEn : name;
  }

  /// e.g. `John 3:16` or `यूहन्ना ३:१६` — chapter and verse use the numeral
  /// style of [language].
  String referenceFor(BibleGameLanguage language) {
    final chapterNumber = formatCount(chapter, language);
    final verseNumber = formatCount(verse, language);
    return '${bookNameFor(language)} $chapterNumber:$verseNumber';
  }
}

/// A curated seed set of verses carrying a Nepali text.
///
/// This is deliberately SMALL and hand-picked rather than a full translation —
/// it seeds Nepali mode and documents the shape of the data. Guess the Book
/// picks from here first and falls back to the offline KJV text (with a visible
/// "no translation" hint) for any verse not listed. Extend the list as needed;
/// the engine picks up new entries with no code change.
const List<BibleGameVerseData> bibleGameVerseCatalog = [
  BibleGameVerseData(
    bookSlug: 'john',
    bookEn: 'John',
    bookNp: 'यूहन्ना',
    chapter: 3,
    verse: 16,
    textEn: 'For God so loved the world, that he gave his only begotten Son, '
        'that whosoever believeth in him should not perish, but have '
        'everlasting life.',
    textNp: 'किनभने परमेश्वरले संसारलाई यत्ति प्रेम गर्नुभयो कि आफूना एकमात्र '
        'पुत्रलाई दिनुभयो, जसले आफूमा विश्वास गर्ने हरेकलाई नष्ट हुन नदिई '
        'अनन्त जीवन पाउन दिनुभयो।',
  ),
  BibleGameVerseData(
    bookSlug: 'psalms',
    bookEn: 'Psalms',
    bookNp: 'भजनसंग्रह',
    chapter: 23,
    verse: 1,
    textEn: 'The LORD is my shepherd; I shall not want.',
    textNp: 'यहोवा मेरो हेरु हुनुहुन्छ; मैले कुनै कमीको अनुभव गरिने छैन।',
  ),
  BibleGameVerseData(
    bookSlug: 'genesis',
    bookEn: 'Genesis',
    bookNp: 'उत्पत्ति',
    chapter: 1,
    verse: 1,
    textEn: 'In the beginning God created the heaven and the earth.',
    textNp: 'सुरुमा परमेश्वरले आकाश र पृथ्वी सिर्जना गर्नुभयो।',
  ),
  BibleGameVerseData(
    bookSlug: 'proverbs',
    bookEn: 'Proverbs',
    bookNp: 'हितोपदेश',
    chapter: 3,
    verse: 5,
    textEn: 'Trust in the LORD with all thine heart; and lean not unto thine '
        'own understanding.',
    textNp: 'हृदयका सबै शक्ति लगाएर यहोवामा भरोसा गर र आफ्नै बुझाइमा नआश्रित हो।',
  ),
  BibleGameVerseData(
    bookSlug: 'matthew',
    bookEn: 'Matthew',
    bookNp: 'मत्ती',
    chapter: 5,
    verse: 14,
    textEn: 'Ye are the light of the world. A city that is set on an hill '
        'cannot be hid.',
    textNp: 'तिमीहरू संसारको उज्यालो हौ। पहाडमा राखिएको सहर लुकाउन सकिँदैन।',
  ),
  BibleGameVerseData(
    bookSlug: 'romans',
    bookEn: 'Romans',
    bookNp: 'रोमी',
    chapter: 12,
    verse: 12,
    textEn: 'Rejoicing in hope; patient in tribulation; continuing in '
        'prayer.',
    textNp: 'आशामा हर्षित हुनुहोस्; कष्टमा धैर्य राख्नुहोस्; प्रार्थनामा निरन्तर '
        'रहनुहोस्।',
  ),
  BibleGameVerseData(
    bookSlug: 'isaiah',
    bookEn: 'Isaiah',
    bookNp: 'यशैया',
    chapter: 40,
    verse: 31,
    textEn: 'But they that wait upon the LORD shall renew their strength; '
        'they shall mount up with wings as eagles.',
    textNp: 'तर यहोवाको प्रतीक्षा गर्नेहरूले आफ्नो शक्ति नवीन गर्नेछन्; तिनीहरू '
        'गरुडझैंडा दिउना उडेर चढ्नेछन्।',
  ),
  BibleGameVerseData(
    bookSlug: 'philippians',
    bookEn: 'Philippians',
    bookNp: 'फिलिप्पी',
    chapter: 4,
    verse: 13,
    textEn: 'I can do all things through Christ which strengtheneth me.',
    textNp: 'मसँग यीसो अघि गर्ने शक्ति छ, जसले मलाई बलियो पार्छ।',
  ),
  BibleGameVerseData(
    bookSlug: 'psalms',
    bookEn: 'Psalms',
    bookNp: 'भजनसंग्रह',
    chapter: 46,
    verse: 1,
    textEn: 'God is our refuge and strength, a very present help in trouble.',
    textNp: 'परमेश्वर हाम्रो शरण र शक्ति हुनुहुन्छ, कष्टमा हामीलाई धेरै नजिकको '
        'सहायता हुनुहुन्छ।',
  ),
  BibleGameVerseData(
    bookSlug: 'joshua',
    bookEn: 'Joshua',
    bookNp: 'यहोशू',
    chapter: 1,
    verse: 9,
    textEn: 'Be strong and of good courage: be not afraid, neither be thou '
        'dismayed.',
    textNp: 'बलियो बन्नुहोस् र साहस गर्नुहोस्: नडराउनुहोस्, नैतन्य हुनुहोस्।',
  ),
  BibleGameVerseData(
    bookSlug: 'jeremiah',
    bookEn: 'Jeremiah',
    bookNp: 'यर्मिया',
    chapter: 29,
    verse: 11,
    textEn: 'For I know the thoughts that I think toward you, saith the LORD, '
        'thoughts of peace, and not of evil, to give you hope and a future.',
    textNp: 'किनभने तिमीहरूप्रति मैले सोचेका विचार मलाई थाहा छ, यहोवा भन्नुहुन्छ, '
        'शान्तिका विचार, न कुनै खराबका; ताकि तिमीहरूलाई आशा र भविष्य दिन सकूँ।',
  ),
  BibleGameVerseData(
    bookSlug: '1-corinthians',
    bookEn: '1 Corinthians',
    bookNp: '१ कोरिन्थी',
    chapter: 13,
    verse: 4,
    textEn: 'Charity suffereth long, and is kind; charity envieth not; '
        'charity vaunteth not itself.',
    textNp: 'प्रेम धैर्य राख्छ, कृपालु हुन्छ; प्रेम ईर्ष्या गर्दैन, प्रेम आफूलाई '
        'घमण्ड गर्दैन।',
  ),
  BibleGameVerseData(
    bookSlug: 'ephesians',
    bookEn: 'Ephesians',
    bookNp: 'एफिसी',
    chapter: 2,
    verse: 10,
    textEn: 'For we are his workmanship, created in Christ Jesus unto good '
        'works.',
    textNp: 'किनभने हामी उहाँको सिर्जना हौँ, यीसु ख्रिस्टमा भल्लभल्लै कामका लागि '
        'सिर्जना गरिएका।',
  ),
  BibleGameVerseData(
    bookSlug: 'luke',
    bookEn: 'Luke',
    bookNp: 'लूका',
    chapter: 1,
    verse: 37,
    textEn: 'For with God nothing shall be impossible.',
    textNp: 'किनभने परमेश्वरसँग असम्भव केही छैन।',
  ),
  BibleGameVerseData(
    bookSlug: 'mark',
    bookEn: 'Mark',
    bookNp: 'मर्कूस',
    chapter: 10,
    verse: 27,
    textEn: 'With men this is impossible; but not with God: for with God all '
        'things are possible.',
    textNp: 'मानिसको लागि यो असम्भव छ; तर परमेश्वरको लागि होइन: किनभने परमेश्वरसँग '
        'सबै कुरा सम्भव छ।',
  ),
  BibleGameVerseData(
    bookSlug: 'psalms',
    bookEn: 'Psalms',
    bookNp: 'भजनसंग्रह',
    chapter: 119,
    verse: 105,
    textEn: 'Thy word is a lamp unto my feet, and a light unto my path.',
    textNp: 'तिम्रो वचन मेरो पाउको लाठी, र मेरो बाटोको उज्यालो हो।',
  ),
  BibleGameVerseData(
    bookSlug: 'matthew',
    bookEn: 'Matthew',
    bookNp: 'मत्ती',
    chapter: 6,
    verse: 33,
    textEn: 'But seek ye first the kingdom of God, and his righteousness; '
        'and all these things shall be added unto you.',
    textNp: 'तर तिमीहरूले पहिले परमेश्वरको राज्य र न्याय खोज्नुहोस्; र यी सबै '
        'कुरा तिमीहरूलाई थपिनेछन्।',
  ),
  BibleGameVerseData(
    bookSlug: 'hebrews',
    bookEn: 'Hebrews',
    bookNp: 'हिब्रू',
    chapter: 11,
    verse: 1,
    textEn: 'Now faith is the substance of things hoped for, the evidence of '
        'things not seen.',
    textNp: 'अब विश्वास आशा गरिएका कुराको तथ्य हो, नदेखिएका कुराको प्रमाण हो।',
  ),
  BibleGameVerseData(
    bookSlug: 'colossians',
    bookEn: 'Colossians',
    bookNp: 'कलस्सी',
    chapter: 3,
    verse: 23,
    textEn: 'And whatsoever ye do, do it from the heart, as working unto the '
        'Lord, and not unto men.',
    textNp: 'र तिमीहरूले जे गर्नुहुन्छ, मनैले गर्नुहोस्, मानिसका लागि होइन, यहोवाका '
        'लागि काम गर्दै हुनुहुन्छ।',
  ),
  BibleGameVerseData(
    bookSlug: 'revelation',
    bookEn: 'Revelation',
    bookNp: 'प्रकाश',
    chapter: 21,
    verse: 4,
    textEn: 'And God shall wipe away all tears from their eyes; and there '
        'shall be no more death, neither sorrow, nor crying.',
    textNp: 'र परमेश्वरले तिनीहरूको आँखाबाट सबै आँसू पुछ्नुहुनेछ; र अब मृत्यु हुनेछैन, '
        'दुःख हुनेछैन, रोदन हुनेछैन।',
  ),
  BibleGameVerseData(
    bookSlug: 'psalms',
    bookEn: 'Psalms',
    bookNp: 'भजनसंग्रह',
    chapter: 51,
    verse: 10,
    textEn: 'Create in me a clean heart, O God; and renew a right spirit '
        'within me.',
    textNp: 'हे परमेश्वर, मेरो हृदयमा शुद्ध हृदय सिर्जना गर्नुहोस्; र मेरो भित्र '
        'शुद्ध भावना नवीन गर्नुहोस्।',
  ),
  BibleGameVerseData(
    bookSlug: 'job',
    bookEn: 'Job',
    bookNp: 'अय्यूब',
    chapter: 19,
    verse: 25,
    textEn: 'For I know that my redeemer liveth, and that he shall in the '
        'latter days upon the earth.',
    textNp: 'किनभने मलाई थाहा छ मेरो छुटो विरुद्धवाला जीवित छन्, र तिनीहरूले '
        'पछिल्ला दिनहरूमा पृथ्वीमा काम गर्नेछन्।',
  ),
  BibleGameVerseData(
    bookSlug: '2-timothy',
    bookEn: '2 Timothy',
    bookNp: '२ तिमोथी',
    chapter: 3,
    verse: 16,
    textEn: 'All scripture is given by inspiration of God, and profitable for '
        'teaching, for reproof, for correction, for instruction.',
    textNp: 'सबै पवित्र लेख परमेश्वरको प्रेरणाद्वारा दिइन्छ, र शिक्षाका लागि, '
        'सवाल गर्नका लागि, सुधार्नका लागि, र सम्झाउनका लागि लाभदायक छ।',
  ),
  BibleGameVerseData(
    bookSlug: 'james',
    bookEn: 'James',
    bookNp: 'याकूब',
    chapter: 1,
    verse: 5,
    textEn: 'If any of you lack wisdom, let him ask of God, that giveth to all '
        'men liberally, and upbraideth not.',
    textNp: 'तिमीहरूमध्ये कसैलाई बुद्धि छैन भने त्यसलाई परमेश्वरसँग माग्नुहोस्, जसले '
        'सबैलाई उदारतापूर्वक दिनुहुन्छ र गुनासो गर्दैन।',
  ),
  BibleGameVerseData(
    bookSlug: '1-peter',
    bookEn: '1 Peter',
    bookNp: '१ पत्रुस',
    chapter: 5,
    verse: 7,
    textEn: 'Casting all your care upon him, for he careth for you.',
    textNp: 'आफ्नो सबै फिक्र उहाँमा राख्नुहोस्, किनभने उहाँले तिमीहरूको हेरचाह गर्नुहुन्छ।',
  ),
  BibleGameVerseData(
    bookSlug: 'numbers',
    bookEn: 'Numbers',
    bookNp: 'गन्ती',
    chapter: 6,
    verse: 24,
    textEn: 'The LORD bless thee, and keep thee: The LORD make his face shine '
        'upon thee, and be gracious unto thee.',
    textNp: 'यहोवाले तिमीलाई आशीर्वाद दिनुहोस् र जोगाउनुहोस्; यहोवाले आफ्नो अनुहार '
        'तिमीमाथि ओलटाउनुहोस् र तिमीमाथि कृपालु भइदिनुहोस्।',
  ),
  BibleGameVerseData(
    bookSlug: 'esther',
    bookEn: 'Esther',
    bookNp: 'एस्तर',
    chapter: 4,
    verse: 14,
    textEn: 'For who knoweth whether thou art come to the kingdom for such a '
        'time as this?',
    textNp: 'किनभने तिमी यो समयमा यही राज्यका लागि आएको हो कि होइन, कसलाई थाहा छ?',
  ),
  BibleGameVerseData(
    bookSlug: 'acts',
    bookEn: 'Acts',
    bookNp: 'प्रेरित',
    chapter: 20,
    verse: 35,
    textEn: 'Remember the words of the Lord Jesus, that he said, It is more '
        'blessed to give than to receive.',
    textNp: 'प्रभु येशुका वचन सम्झनुहोस्, उहाँले भन्नुभयो, दिनुभन्दा लिनु धेरै '
        'आशीर्वाद पाउने कुरा हो।',
  ),
];

/// Slug + chapter + verse to verse data. Built once, lazily.
Map<String, BibleGameVerseData>? _verseByKey;

/// The catalog verse for a DB verse, or null when the catalog has no entry.
BibleGameVerseData? bibleGameVerseDataFor({
  String? bookSlug,
  String? bookName,
  required int chapter,
  required int verse,
}) {
  final resolvedSlug = bookSlug ??
      bibleGameBookDataForName(bookName)?.slug ??
      bibleGameBookDataForSlug(bookName)?.slug;
  if (resolvedSlug == null) return null;
  final lookup = _verseByKey ??= {
    for (final entry in bibleGameVerseCatalog)
      '${entry.bookSlug} ${entry.chapter}:${entry.verse}': entry,
  };
  return lookup['$resolvedSlug $chapter:$verse'];
}

/// Every UI and engine string in both languages, keyed by `{en, np}`.
///
/// This mirrors the quiz feature's bilingual payload convention (see
/// `AGENTS.md` section 25): one key, one string per language, no
/// `if (nepali) ... else ...` branching at the call site. `{0}`, `{1}` are
/// positional placeholders substituted by [BibleGameStrings.text].
const Map<String, Map<String, String>> bibleGameUiCopy = {
  // ---- Hub ----------------------------------------------------------------
  'hubTitle': {
    'en': 'Bible Games',
    'np': 'बाइबल खेल',
  },
  'guessBookTitle': {
    'en': 'Guess the Book',
    'np': 'पुस्तक पत्ता लगाउनुहोस्',
  },
  'guessBookSubtitle': {
    'en': 'Read the opening words, pick the book',
    'np': 'सुरुवातका शब्द पढ्नुहोस्, पुस्तक छान्नुहोस्',
  },
  'higherLowerTitle': {
    'en': 'Higher / Lower',
    'np': 'बढी / कम',
  },
  'higherLowerSubtitle': {
    'en': 'Tap the book with more chapters',
    'np': 'धेरै अध्याय भएको पुस्तक थिच्नुहोस्',
  },
  'bookOrderTitle': {
    'en': 'Book Order Race',
    'np': 'क्रम प्रतियोगिता',
  },
  'bookOrderSubtitle': {
    'en': 'Tap the books in Bible order',
    'np': 'बाइबलको क्रममा पुस्तक थिच्नुहोस्',
  },
  'findChapterTitle': {
    'en': 'Find the Chapter',
    'np': 'अध्याय खोज्नुहोस्',
  },
  'findChapterSubtitle': {
    'en': 'Race the clock, tap the right chapter',
    'np': 'समय जित्नुहोस्, सही अध्याय थिच्नुहोस्',
  },

  // ---- Shared -------------------------------------------------------------
  'dataUnavailableTitle': {
    'en': 'Bible data unavailable',
    'np': 'बाइबलको डाटा उपलब्ध छैन',
  },
  'dataUnavailableBody': {
    'en': 'This game needs the offline Bible database, which is not '
        'available in this build.',
    'np': 'यो खेललाई अफलाइन बाइबल डाटाबेस चाहिन्छ, जुन यो बिल्डमा उपलब्ध छैन।',
  },
  'loadFailed': {
    'en': 'Could not load the offline Bible data.',
    'np': 'अफलाइन बाइबल डाटा लोड गर्न सकिएन।',
  },
  'neverEnding': {
    'en': 'Never-ending',
    'np': 'अनन्त',
  },
  'roundLabel': {
    'en': 'Round {0}',
    'np': 'पटक {0}',
  },
  'chaptersSuffix': {
    'en': '{0} ch',
    'np': '{0} अध्याय',
  },
  'nextRound': {
    'en': 'Next Round',
    'np': 'अर्को पटक',
  },
  'playAgain': {
    'en': 'Play Again',
    'np': 'फेरि खेल्नुहोस्',
  },
  'goHome': {
    'en': 'Home',
    'np': 'गृह',
  },
  'correctOutOf': {
    'en': 'Correct answers out of {0}',
    'np': '{0} मध्ये सही उत्तर',
  },
  'bestStreak': {
    'en': 'Best streak: {0}',
    'np': 'उत्कृष्ट लगातार: {0}',
  },
  'secondsLeft': {
    'en': '{0}s left',
    'np': '{0} सेकेन्ड बाँकी',
  },
  'noNepaliVerse': {
    'en': 'No Nepali translation for this verse — showing the English text.',
    'np': 'यस वचनको नेपाली अनुवाद छैन — अङ्ग्रेजी वचन देखाइएको छ।',
  },
  'counter': {
    'en': '{0}/{1}',
    'np': '{0}/{1}',
  },
  'gameLanguage': {
    'en': 'Game language',
    'np': 'खेलको भाषा',
  },
  'gameLanguageSystem': {
    'en': 'Following your phone language',
    'np': 'तपाईंको फोनको भाषा अनुसार',
  },
  'gameLanguageManual': {
    'en': 'Chosen by you',
    'np': 'तपाईंले छान्नुभएको',
  },
  'gameLanguageUseDevice': {
    'en': 'Follow phone language',
    'np': 'फोनको भाषा अनुसार',
  },

  // ---- Higher / Lower -----------------------------------------------------
  'higherLowerLoading': {
    'en': 'Scoring the books...',
    'np': 'पुस्तकहरू मूल्याङ्कन हुँदै...',
  },
  'higherLowerQuestion': {
    'en': 'Which book has more chapters?',
    'np': 'कुन पुस्तकमा धेरै अध्याय छन्?',
  },
  'higherLowerCorrect': {
    'en': 'More chapters: {0} ({1}).',
    'np': 'धेरै अध्याय: {0} ({1})।',
  },
  'higherLowerWrong': {
    'en': 'Streak broken! {0} wins with {1} chapters.',
    'np': 'लगातार टुट्यो! {0} को {1} अध्ययसँग जित।',
  },
  'higherLowerFooter': {
    'en': 'Chapter counts are hidden until you pick. Keep your streak alive — '
        'wrong picks reset it.',
    'np': 'तपाईंले छान्नुभएपछि अध्याय संख्या देखिन्छ। लगातार कायम राख्नुहोस् — गलत '
        'छनोटले यसलाई शून्य गर्छ।',
  },

  // ---- Guess the Book -----------------------------------------------------
  'guessBookLoading': {
    'en': 'Finding a verse...',
    'np': 'वचन खोज्दै...',
  },
  'guessBookQuestion': {
    'en': 'Which book is this?',
    'np': 'यो कुन पुस्तकको वचन हो?',
  },
  'guessBookHint': {
    'en': 'Hint: {0}',
    'np': 'सुझाव: {0}',
  },
  'guessBookChoose': {
    'en': 'Choose the book',
    'np': 'पुस्तक छान्नुहोस्',
  },
  'guessBookAnswer': {
    'en': 'Answer: {0} - {1}',
    'np': 'उत्तर: {0} - {1}',
  },
  'guessBookNext': {
    'en': 'Next Verse',
    'np': 'अर्को वचन',
  },
  'hintLongerBook': {
    'en': 'One of the longer books of the Bible',
    'np': 'बाइबलका लामा पुस्तकहरूमध्ये एक',
  },
  'hintMidBook': {
    'en': 'A mid-sized book',
    'np': 'मध्यम आकारको पुस्तक',
  },
  'hintShorterBook': {
    'en': 'A shorter book',
    'np': 'छोटो पुस्तक',
  },

  // ---- Book Order Race ----------------------------------------------------
  'bookOrderLoading': {
    'en': 'Shuffling the books...',
    'np': 'पुस्तकहरू मिसाइँदै...',
  },
  'bookOrderQuestion': {
    'en': 'Tap the books in Bible order',
    'np': 'पुस्तकहरू बाइबलको क्रममा थिच्नुहोस्',
  },
  'bookOrderStartWith': {
    'en': 'Round {0} - start with the earliest book.',
    'np': 'पटक {0} - सबैभन्दा अघिल्लो पुस्तकबाट सुरु गर्नुहोस्।',
  },
  'bookOrderFooter': {
    'en': 'Pick the next book in canonical order. A wrong tap breaks your '
        'streak but keeps you on this round.',
    'np': 'क्रमैसँग अर्को पुस्तक छान्नुहोस्। गलत थिचाइले लगातार टुट्छ तर यही पटकमै '
        'रहनुहुन्छ।',
  },

  // ---- Find the Chapter ---------------------------------------------------
  'findChapterLoading': {
    'en': 'Laying out the grid...',
    'np': 'ग्रिड तयार हुँदै...',
  },
  'findChapterTap': {
    'en': 'Tap "{0}"',
    'np': '"{0}" थिच्नुहोस्',
  },
  'findChapterFooter': {
    'en': 'Find "{0}" fast - each hit scores 10 and a new grid appears. Wrong '
        'taps cost your streak.',
    'np': '"{0}" छिट्टो खोज्नुहोस् - हरेक सही थिचाइले 10 अंक र नयाँ ग्रिड। गलत '
        'थिचाइले लगातार टुट्छ।',
  },
  'findChapterTimeUp': {
    'en': 'Time is up - you found {0} chapters!',
    'np': 'समय सकियो - तपाईंले {0} अध्याय फेल्नुभयो!',
  },

  // ---- Fun Facts (engine) -------------------------------------------------
  'factLongestVerse': {
    'en': 'Longest verse in the Bible',
    'np': 'बाइबलको सबैभन्दा लामो वचन',
  },
  'factLongestVerseExplain': {
    'en': '{0} has {1} characters.',
    'np': '{0} मा {1} अक्षर छन्।',
  },
  'factShortestVerse': {
    'en': 'Shortest verse in the Bible',
    'np': 'बाइबलको सबैभन्दा छोटो वचन',
  },
  'factShortestVerseExplain': {
    'en': '"{0}" - {1} has {2} characters.',
    'np': '"{0}" - {1} मा {2} अक्षर छन्।',
  },
  'factMostChapters': {
    'en': 'Book with the MOST chapters',
    'np': 'सबैभन्दा धेरै अध्याय भएको पुस्तक',
  },
  'factFewestChapters': {
    'en': 'Book with the FEWEST chapters',
    'np': 'सबैभन्दा कम अध्याय भएको पुस्तक',
  },
  'factChaptersOf': {
    'en': '{0} has {1} chapters.',
    'np': '{0} मा {1} अध्याय छन्।',
  },
  'factChaptersOfOne': {
    'en': '{0} has {1} chapter.',
    'np': '{0} मा {1} अध्याय छ।',
  },
  'factMostVerses': {
    'en': 'Book with the MOST verses',
    'np': 'सबैभन्दा धेरै वचन भएको पुस्तक',
  },
  'factFewestVerses': {
    'en': 'Book with the FEWEST verses',
    'np': 'सबैभन्दा कम वचन भएको पुस्तक',
  },
  'factVersesOf': {
    'en': '{0} has {1} verses.',
    'np': '{0} मा {1} वचन छन्।',
  },
  'factVersesOfOne': {
    'en': '{0} has {1} verse.',
    'np': '{0} मा {1} वचन छ।',
  },
  'factNtMostChapters': {
    'en': 'Most-chaptered book of the New Testament',
    'np': 'नयाठमा सबैभन्दा धेरै अध्याय भएको पुस्तक',
  },
  'factNtMostVerses': {
    'en': 'Most-versed book of the New Testament',
    'np': 'नयाठमा सबैभन्दा धेरै वचन भएको पुस्तक',
  },
  'factBookCount': {
    'en': 'Books in the Bible',
    'np': 'बाइबलमा रहेका पुस्तकहरू',
  },
  'factBookCountExplain': {
    'en': 'The Protestant canon has 66 books ({0} loaded locally).',
    'np': 'प्रोटेस्ट्यान्ट विश्वासको ग्रन्थमा 66 पुस्तक छन् (यहाँ {0} लोड भएका छन्)।',
  },
  'factOtCount': {
    'en': 'Books in the Old Testament',
    'np': 'पुरानो नियममा रहेका पुस्तकहरू',
  },
  'factOtCountExplain': {
    'en': 'The Old Testament has {0} books.',
    'np': 'पुरानो नियममा {0} पुस्तक छन्।',
  },
  'factNtCount': {
    'en': 'Books in the New Testament',
    'np': 'नयाँ नियममा रहेका पुस्तकहरू',
  },
  'factNtCountExplain': {
    'en': 'The New Testament has {0} books.',
    'np': 'नयाँ नियममा {0} पुस्तक छन्।',
  },
  'factTotalChapters': {
    'en': 'Chapters in the whole Bible',
    'np': 'सम्पूर्ण बाइबलका अध्याय',
  },
  'factTotalChaptersExplain': {
    'en': 'The {0} books contain {1} chapters.',
    'np': '{0} पुस्तकमा {1} अध्याय छन्।',
  },
  'factTotalVerses': {
    'en': 'Verses in the whole Bible',
    'np': 'सम्पूर्ण बाइबलका वचन',
  },
  'factTotalVersesExplain': {
    'en': 'The {0} books add up to {1} verses.',
    'np': '{0} पुस्तकमा जम्मा {1} वचन छन्।',
  },
  'factSingleChapter': {
    'en': 'Single-chapter books',
    'np': 'एउटै अध्याय भएका पुस्तकहरू',
  },
  'factSingleChapterExplain': {
    'en': '{0} each have one chapter.',
    'np': '{0} - यी प्रत्येकको एउटै मात्र अध्याय छ।',
  },
  'factsTitle': {
    'en': 'Bible Fun Facts',
    'np': 'बाइबलका रमाइला तथ्य',
  },
  'factsNext': {
    'en': 'Next fact  >',
    'np': 'अर्को तथ्य  >',
  },
};

/// Typed, language-resolved access to [bibleGameUiCopy].
///
/// `const` instances (one per language) so a page can simply do
/// `ref.watch(bibleGameStringsProvider).higherLowerQuestion`.
class BibleGameStrings {
  /// The locale code used to look strings up (see [BibleGameLanguage.code]).
  final String code;

  const BibleGameStrings._(this.code);

  static const BibleGameStrings english = BibleGameStrings._('en');
  static const BibleGameStrings nepali = BibleGameStrings._('ne');

  /// The copy bundle for [language].
  static BibleGameStrings of(BibleGameLanguage language) {
    return language == BibleGameLanguage.nepali ? nepali : english;
  }

  /// The language this bundle belongs to.
  BibleGameLanguage get language =>
      code == BibleGameLanguage.nepali.code
          ? BibleGameLanguage.nepali
          : BibleGameLanguage.english;

  /// The key this bundle reads inside [bibleGameUiCopy].
  ///
  /// The copy is JSON-shaped and therefore keyed the way the rest of the app's
  /// bilingual payloads are (`en` / `np`), while the ISO code for Nepali is
  /// `ne`. Without this mapping every Nepali lookup would miss and silently
  /// fall back to English.
  String get _copyKey => language == BibleGameLanguage.nepali ? 'np' : 'en';

  /// The raw string for [key] in this language, with `{0}`, `{1}` replaced by
  /// [args].
  ///
  /// Falls back to the English string, then to [fallback], so a missing or
  /// mis-shaped copy entry can never render an empty widget or a literal
  /// `{0}`.
  String text(
    String key, {
    List<String> args = const [],
    String fallback = '',
  }) {
    final entry = bibleGameUiCopy[key];
    var value = entry?[_copyKey];
    if (value == null || value.isEmpty) value = entry?['en'];
    if (value == null || value.isEmpty) value = fallback;
    for (var i = 0; i < args.length; i++) {
      value = value!.replaceAll('{$i}', args[i]);
    }
    return value ?? '';
  }

  /// Same as [text] but each argument is rendered with the numeral style of
  /// this language (Devanagari digits for Nepali).
  String numberText(
    String key, {
    required List<int> numbers,
    String fallback = '',
  }) {
    return text(
      key,
      args: [for (final value in numbers) formatCount(value, language)],
      fallback: fallback,
    );
  }

  // ---- Hub ----------------------------------------------------------------
  String get hubTitle => text('hubTitle', fallback: 'Bible Games');
  String get guessBookTitle =>
      text('guessBookTitle', fallback: 'Guess the Book');
  String get guessBookSubtitle => text('guessBookSubtitle');
  String get higherLowerTitle =>
      text('higherLowerTitle', fallback: 'Higher / Lower');
  String get higherLowerSubtitle => text('higherLowerSubtitle');
  String get bookOrderTitle =>
      text('bookOrderTitle', fallback: 'Book Order Race');
  String get bookOrderSubtitle => text('bookOrderSubtitle');
  String get findChapterTitle =>
      text('findChapterTitle', fallback: 'Find the Chapter');
  String get findChapterSubtitle => text('findChapterSubtitle');

  // ---- Shared -------------------------------------------------------------
  String get dataUnavailableTitle => text('dataUnavailableTitle');
  String get dataUnavailableBody => text('dataUnavailableBody');
  String get loadFailed => text('loadFailed');
  String get neverEnding => text('neverEnding', fallback: 'Never-ending');
  String get nextRound => text('nextRound', fallback: 'Next Round');
  String get playAgain => text('playAgain', fallback: 'Play Again');
  String get goHome => text('goHome', fallback: 'Home');
  String get noNepaliVerse => text('noNepaliVerse');
  String get gameLanguage => text('gameLanguage', fallback: 'Game language');
  String get gameLanguageSystem =>
      text('gameLanguageSystem', fallback: 'Following your phone language');
  String get gameLanguageManual =>
      text('gameLanguageManual', fallback: 'Chosen by you');
  String get gameLanguageUseDevice =>
      text('gameLanguageUseDevice', fallback: 'Follow phone language');

  /// `1/12` style position indicator, numerals in this language's style.
  String counter(int index, int total) => text(
        'counter',
        args: [formatCount(index, language), formatCount(total, language)],
        fallback: '$index/$total',
      );

  String roundLabel(int number) =>
      numberText('roundLabel', numbers: [number], fallback: 'Round $number');

  String secondsLeft(int seconds) =>
      numberText('secondsLeft', numbers: [seconds], fallback: '${seconds}s left');

  String chaptersSuffix(int chapters) => numberText(
        'chaptersSuffix',
        numbers: [chapters],
        fallback: '$chapters ch',
      );

  String correctOutOf(int total) => numberText(
        'correctOutOf',
        numbers: [total],
        fallback: 'Correct answers out of $total',
      );

  String bestStreak(int streak) => numberText(
        'bestStreak',
        numbers: [streak],
        fallback: 'Best streak: $streak',
      );

  // ---- Higher / Lower -----------------------------------------------------
  String get higherLowerLoading => text('higherLowerLoading');
  String get higherLowerQuestion => text('higherLowerQuestion');
  String get higherLowerFooter => text('higherLowerFooter');

  /// Correct-answer copy. The chapter count uses the numeral style of this
  /// language; the book name is already localised by the caller, so it is
  /// substituted verbatim.
  String higherLowerCorrect(String book, int chapters) => text(
        'higherLowerCorrect',
        args: [book, formatCount(chapters, language)],
        fallback: 'More chapters: $book ($chapters).',
      );

  String higherLowerWrong(String book, int chapters) => text(
        'higherLowerWrong',
        args: [book, formatCount(chapters, language)],
        fallback: 'Streak broken! $book wins with $chapters chapters.',
      );

  // ---- Guess the Book -----------------------------------------------------
  String get guessBookLoading => text('guessBookLoading');
  String get guessBookQuestion => text('guessBookQuestion');
  String get guessBookChoose =>
      text('guessBookChoose', fallback: 'Choose the book');
  String get guessBookNext => text('guessBookNext', fallback: 'Next Verse');
  String get hintLongerBook => text('hintLongerBook');
  String get hintMidBook => text('hintMidBook');
  String get hintShorterBook => text('hintShorterBook');

  String guessBookHint(String hint) =>
      text('guessBookHint', args: [hint], fallback: 'Hint: $hint');

  String guessBookAnswer(String book, String reference) => text(
        'guessBookAnswer',
        args: [book, reference],
        fallback: 'Answer: $book - $reference',
      );

  // ---- Book Order Race ----------------------------------------------------
  String get bookOrderLoading => text('bookOrderLoading');
  String get bookOrderQuestion => text('bookOrderQuestion');
  String get bookOrderFooter => text('bookOrderFooter');

  String bookOrderStartWith(int round) => numberText(
        'bookOrderStartWith',
        numbers: [round],
        fallback: 'Round $round - start with the earliest book.',
      );

  // ---- Find the Chapter ---------------------------------------------------
  String get findChapterLoading => text('findChapterLoading');

  String findChapterTap(String label) =>
      text('findChapterTap', args: [label], fallback: 'Tap "$label"');

  String findChapterTimeUp(int found) => numberText(
        'findChapterTimeUp',
        numbers: [found],
        fallback: 'Time is up - you found $found chapters!',
      );

  String findChapterFooter(String label) => text(
        'findChapterFooter',
        args: [label],
        fallback: 'Find "$label" fast - each hit scores 10 and a new grid '
            'appears. Wrong taps cost your streak.',
      );

  // ---- Fun Facts ----------------------------------------------------------
  String get factsTitle => text('factsTitle', fallback: 'Bible Fun Facts');
  String get factsNext => text('factsNext', fallback: 'Next fact  >');
  String get factLongestVerse => text('factLongestVerse');
  String get factShortestVerse => text('factShortestVerse');
  String get factMostChapters => text('factMostChapters');
  String get factFewestChapters => text('factFewestChapters');
  String get factMostVerses => text('factMostVerses');
  String get factFewestVerses => text('factFewestVerses');
  String get factNtMostChapters => text('factNtMostChapters');
  String get factNtMostVerses => text('factNtMostVerses');
  String get factBookCount => text('factBookCount');
  String get factOtCount => text('factOtCount');
  String get factNtCount => text('factNtCount');
  String get factTotalChapters => text('factTotalChapters');
  String get factTotalVerses => text('factTotalVerses');
  String get factSingleChapter => text('factSingleChapter');

  String factLongestVerseExplain(String reference, int length) => text(
        'factLongestVerseExplain',
        args: [reference, formatCount(length, language)],
        fallback: '$reference has $length characters.',
      );

  String factShortestVerseExplain(
    String verseText,
    String reference,
    int length,
  ) =>
      text(
        'factShortestVerseExplain',
        args: [verseText, reference, formatCount(length, language)],
        fallback: '"$verseText" - $reference has $length characters.',
      );

  String factChaptersOf(String book, int chapters) => text(
        'factChaptersOf',
        args: [book, formatCount(chapters, language)],
        fallback: '$book has $chapters chapters.',
      );

  String factChaptersOfOne(String book, int chapters) => text(
        'factChaptersOfOne',
        args: [book, formatCount(chapters, language)],
        fallback: '$book has $chapters chapter.',
      );

  String factVersesOf(String book, int verses) => text(
        'factVersesOf',
        args: [book, formatCount(verses, language)],
        fallback: '$book has $verses verses.',
      );

  String factVersesOfOne(String book, int verses) => text(
        'factVersesOfOne',
        args: [book, formatCount(verses, language)],
        fallback: '$book has $verses verse.',
      );

  String factBookCountExplain(int loaded) => numberText(
        'factBookCountExplain',
        numbers: [loaded],
        fallback: 'The Protestant canon has 66 books ($loaded loaded locally).',
      );

  String factOtCountExplain(int count) => numberText(
        'factOtCountExplain',
        numbers: [count],
        fallback: 'The Old Testament has $count books.',
      );

  String factNtCountExplain(int count) => numberText(
        'factNtCountExplain',
        numbers: [count],
        fallback: 'The New Testament has $count books.',
      );

  String factTotalChaptersExplain(int books, int chapters) => text(
        'factTotalChaptersExplain',
        args: [formatCount(books, language), formatCount(chapters, language)],
        fallback: 'The $books books contain $chapters chapters.',
      );

  String factTotalVersesExplain(int books, int verses) => text(
        'factTotalVersesExplain',
        args: [formatCount(books, language), formatCount(verses, language)],
        fallback: 'The $books books add up to $verses verses.',
      );

  String factSingleChapterExplain(String books) => text(
        'factSingleChapterExplain',
        args: [books],
        fallback: '$books each have one chapter.',
      );
}
