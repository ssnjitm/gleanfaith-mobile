import '../../domain/entities/quiz_entities.dart';

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  if (value is Map) return value.values.toList();
  return const [];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

/// Lenient int reader — the API mixes `10`, `10.0` (aggregation results) and
/// `"10"`, and a raw `as int?` cast throws on the latter two which used to
/// break the whole daily quiz payload.
int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

/// Reads a scalar. Maps and lists are deliberately NOT stringified: doing so
/// would render a bilingual node as the literal `{en: ..., np: ...}` and leak
/// container text (a `type` of `mcq`) into a question body. Nested structures
/// are resolved by `_bilingual` / `_asMap` instead.
String? _asString(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is num || value is bool) return value.toString();
  return null;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

/// Devanagari block (U+0900–U+097F) — the script Nepali is written in.
final RegExp _devanagari = RegExp(r'[\u0900-\u097F]');

/// True when [value] contains Devanagari characters, i.e. it is Nepali text.
///
/// The backend ships both languages per question but does not guarantee *which*
/// key holds the Nepali variant (`textNp`, `nepaliQuestion`, a nested `np`
/// object, a per-option `{en, np}` pair…). Detecting the script is name
/// agnostic, so a key rename cannot silently leave the EN | NP toggle dead.
bool _looksNepali(String? value) {
  if (value == null) return false;
  return _devanagari.hasMatch(value);
}

class QuizScheduleModel {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final int totalQuestions;
  final bool allowRetry;
  final int maxRetries;
  final String status;
  final Map<String, dynamic>? metadata;
  final String? quizSetId;

  const QuizScheduleModel({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.allowRetry,
    required this.maxRetries,
    required this.status,
    this.metadata,
    this.quizSetId,
  });

  factory QuizScheduleModel.fromJson(Map<String, dynamic> json) {
    // `GET /daily-quiz/today` does not return a bare schedule: it nests the
    // schedule (and sometimes a daily-quiz wrapper) under its own key, and the
    // identifier is then `quizScheduleId`/`scheduleId` rather than `_id`/`id`.
    // A missed id produced an EMPTY id, which made the Start button silently
    // disabled — the single worst failure mode of the daily quiz.
    final schedule =
        _asMap(json['quizSchedule']) ?? _asMap(json['schedule']) ?? const {};
    final daily =
        _asMap(json['dailyQuiz']) ?? _asMap(json['today']) ?? const {};
    // Nested values are defaults only: whatever the top level carries wins.
    final merged = <String, dynamic>{...schedule, ...daily, ...json};

    final quizSet =
        _asMap(merged['quizSet']) ??
        _asMap(merged['quiz_set']) ??
        // The schedule detail populates `quizSetId` into the whole set object.
        _asMap(merged['quizSetId']);
    final nestedQuestions = _asList(quizSet?['questions']);
    final rawTotal =
        _asInt(merged['totalQuestions']) ?? _asInt(merged['totalQuestion']);

    return QuizScheduleModel(
      id: _resolveId(json, schedule, daily),
      title: _asString(merged['title']) ?? '',
      startDateTime:
          _asDate(merged['startDateTime'] ?? merged['startsAt']) ??
          DateTime.now(),
      endDateTime:
          _asDate(merged['endDateTime'] ?? merged['endsAt']) ?? DateTime.now(),
      durationMinutes:
          _asInt(merged['durationMinutes']) ?? _asInt(merged['duration']) ?? 0,
      totalQuestions:
          rawTotal ?? (nestedQuestions.isNotEmpty ? nestedQuestions.length : 0),
      allowRetry: _asBool(merged['allowRetry']) ?? false,
      maxRetries: _asInt(merged['maxRetries']) ?? 1,
      status: _asString(merged['status']) ?? '',
      metadata: _asMetadata(merged['metadata']),
      quizSetId:
          _asString(merged['quizSetId']) ??
          _asString(merged['quizSet_id']) ??
          _asString(merged['setId']) ??
          _asString(quizSet?['_id']) ??
          _asString(quizSet?['id']),
    );
  }

  /// First identifier we can find, preferring the schedule's own id over the
  /// daily-quiz wrapper id — only a schedule id can be started.
  static String _resolveId(
    Map<String, dynamic> json,
    Map<String, dynamic> schedule,
    Map<String, dynamic> daily,
  ) {
    const keys = ['_id', 'id', 'quizScheduleId', 'scheduleId'];
    for (final source in [json, schedule, daily]) {
      for (final key in keys) {
        final value = _asString(source[key]);
        if (value != null) return value;
      }
    }
    return '';
  }

  static Map<String, dynamic>? _asMetadata(dynamic value) => _asMap(value);

  QuizScheduleModel copyWith({
    String? id,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? durationMinutes,
    int? totalQuestions,
    bool? allowRetry,
    int? maxRetries,
    String? status,
    Map<String, dynamic>? metadata,
    String? quizSetId,
  }) {
    return QuizScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      allowRetry: allowRetry ?? this.allowRetry,
      maxRetries: maxRetries ?? this.maxRetries,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      quizSetId: quizSetId ?? this.quizSetId,
    );
  }

  /// Marks a schedule served by the daily-quiz endpoints as a daily quiz.
  ///
  /// Those endpoints only return a daily schedule, but the payload often omits
  /// `metadata.isDaily`. Without the flag the app treated the session as a
  /// regular quiz: no EN | NP toggle, and the single-attempt rule did not apply.
  QuizScheduleModel asDaily() {
    if (metadata?['isDaily'] == true) return this;
    return copyWith(metadata: {...?metadata, 'isDaily': true});
  }

  QuizSchedule toEntity() {
    return QuizSchedule(
      id: id,
      title: title,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      durationMinutes: durationMinutes,
      totalQuestions: totalQuestions,
      allowRetry: allowRetry,
      maxRetries: maxRetries,
      status: status,
      metadata: metadata,
      quizSetId: quizSetId,
    );
  }
}

/// Which slot of an option list is being read.
enum _OptionMode {
  /// The English slot. A plain string only qualifies when it is not written in
  /// Devanagari.
  english,

  /// The Nepali slot. A plain string only qualifies when it is written in
  /// Devanagari.
  nepali,

  /// The options exactly as delivered, in the session's language. No script
  /// check — this is what the server's answer key lines up with.
  delivered,
}

class QuizQuestionModel {
  /// The English question text. Empty when the payload carried no English.
  final String text;

  /// The English options. Empty slots mean "no English option here".
  final List<String> options;
  final int questionIndex;
  final String? textNp;
  final List<String> optionsNp;

  /// The text exactly as delivered, in the language the session was requested
  /// in. The fallback when the requested language is not part of the payload.
  final String primaryText;

  /// The options exactly as delivered. The fallback for a missing language and
  /// the guarantee that the option count matches the server's answer key.
  final List<String> primaryOptions;

  final String? scriptureReference;

  const QuizQuestionModel({
    required this.text,
    required this.options,
    required this.questionIndex,
    this.textNp,
    this.optionsNp = const [],
    this.primaryText = '',
    this.primaryOptions = const [],
    this.scriptureReference,
  });

  factory QuizQuestionModel.fromJson(
    Map<String, dynamic> json, {
    int fallbackIndex = 0,
    QuizLanguage language = QuizLanguage.english,
  }) {
    // Shapes seen from the backend, all accepted:
    //  a) `question: {en, np}` + `options: [{id, text: {en, np}, is_correct}]`
    //  b) `text: "..."`      + `textNp: "..."`, `options: [...]`, `optionsNp: [...]`
    //  c) `en: {text, options}` + `np: {text, options}`
    //  d) `question: {np: {text, options}}` alongside an English `question`
    //
    // A fifth shape exists and it is the one that broke the EN | NP toggle:
    //  e) a **flat, single-language** payload — `text: "<nepali>"` and a list
    //     of Nepali option strings — which is what the backend returns for a
    //     session started with `?language=np`.
    //
    // The parser therefore never assumes the primary string is English: the
    // script decides which slot it belongs to. Assuming English made a Nepali
    // session render Nepali under the EN toggle, and the toggle looked inert.
    final delivered = _deliveredText(json, language: language);
    // (f) `GET /quiz-sets/{id}` and the set embedded in `GET /quiz-schedule/{id}`
    // keep the translations under `meta.textI18n` / `meta.optionsI18n`, with the
    // English wording also duplicated at the top level.
    final meta = _asMap(json['meta']) ?? _asMap(json['metadata']);
    final textI18n =
        _asMap(meta?['textI18n']) ?? _asMap(meta?['text_i18n']);
    var text = _englishText(json);
    if (text.isEmpty) {
      final localized = _asString(textI18n?['en']);
      if (localized != null && !_looksNepali(localized)) text = localized;
    }
    var textNp = _nepaliText(json, english: text);
    if (textNp == null || textNp.isEmpty) {
      final localized = _asString(textI18n?['np']) ??
          _asString(textI18n?['ne']);
      if (localized != null && localized.isNotEmpty) textNp = localized;
    }

    final optionsI18n =
        meta?['optionsI18n'] ?? meta?['options_i18n'];
    var options = _optionLabels(json['options'], mode: _OptionMode.english);
    var optionsNp = _optionLabels(json['options'], mode: _OptionMode.nepali);
    // The top-level `options` of a set are English; the Nepali list lives in
    // `meta.optionsI18n` as `[{id, text: {en, np}}]`.
    if (!_usable(optionsNp)) {
      final localized = _optionLabels(optionsI18n, mode: _OptionMode.nepali);
      if (_usable(localized)) optionsNp = localized;
    }
    var primaryOptions = _optionLabels(
      json['options'],
      mode: _OptionMode.delivered,
      language: language,
    );

    // (c) the language nodes carry their own text and options.
    if (options.isEmpty) {
      options = _optionLabels(
        _node(json, 'en')?['options'],
        mode: _OptionMode.english,
      );
    }
    if (options.isEmpty) {
      final localized = _optionLabels(optionsI18n, mode: _OptionMode.english);
      if (localized.isNotEmpty) options = localized;
    }
    if (!_usable(optionsNp)) {
      optionsNp = _optionLabels(
        _node(json, 'np')?['options'],
        mode: _OptionMode.nepali,
      );
    }
    // (b) a sibling list of Nepali options.
    if (!_usable(optionsNp)) {
      for (final key in const [
        'optionsNp',
        'options_np',
        'npOptions',
        'optionsNepali',
        'optionTranslations',
      ]) {
        final labels = _optionLabels(json[key], mode: _OptionMode.nepali);
        if (labels.isNotEmpty) {
          optionsNp = labels;
          break;
        }
      }
    }
    if (!_usable(primaryOptions)) {
      primaryOptions = _optionLabels(
        json['options'],
        mode: _OptionMode.delivered,
        language: language,
      );
    }
    if (primaryOptions.isEmpty && options.isNotEmpty) {
      primaryOptions = options;
    }

    return QuizQuestionModel(
      text: text,
      options: options,
      questionIndex:
          _asInt(json['questionIndex']) ??
          _asInt(json['index']) ??
          _asInt(json['order']) ??
          fallbackIndex,
      textNp: textNp,
      // A partial or mismatched Nepali list is discarded so answer indices stay
      // aligned with the answer key; `optionsFor` then falls back to the
      // delivered options.
      optionsNp:
          optionsNp.length == options.length && _usable(optionsNp)
          ? optionsNp
          : const [],
      primaryText: delivered.isNotEmpty ? delivered : text,
      primaryOptions: primaryOptions,
      scriptureReference:
          _asString(json['scripture_reference']) ??
          _asString(json['scriptureReference']) ??
          _asString(json['reference']) ??
          _asString(json['scripture']) ??
          _asString(json['verse_reference']) ??
          _asString(meta?['scriptureReference']) ??
          _asString(meta?['scripture_reference']),
    );
  }

  /// The `en` / `np` / `ne` / `nepali` sub-object, when the payload has one.
  static Map<String, dynamic>? _node(Map<String, dynamic> json, String key) {
    for (final alias in [key, if (key == 'np') ...['ne', 'nepali']]) {
      final map = _asMap(json[alias]);
      if (map != null) return map;
    }
    return null;
  }

  /// English question text.
  ///
  /// A plain string written in Devanagari is **not** English. The backend
  /// answers a `?language=np` session with a flat Nepali payload, and calling
  /// that text English is what made the EN | NP toggle look inert: the
  /// "English" slot held Nepali, so switching to English changed nothing.
  static String _englishText(Map<String, dynamic> json) {
    // (a) `question: {en, np}` — or the same bilingual node on `text`, which is
    // what the start endpoint uses today for its plain `text` string.
    for (final key in const ['question', 'text']) {
      final node = _asMap(json[key]);
      if (node == null) continue;
      final en = _bilingual(node).en;
      if (en != null) return en;
    }
    // (b) a plain `question` / `text` string.
    final plain = _asString(json['question']) ?? _asString(json['text']);
    if (plain != null) return _looksNepali(plain) ? '' : plain;
    // (c) top-level `en` as a node (`{text, options}`) or a plain string.
    final enNode = json['en'];
    final nested = _asString(_asMap(enNode)?['text']) ??
        _asString(_asMap(enNode)?['question']) ??
        _asString(enNode);
    if (nested != null) return _looksNepali(nested) ? '' : nested;
    // Nothing identifiable: an empty body is far better than a container
    // `toString()` or the question `type` leaking in as the question.
    return '';
  }

  /// The question text exactly as the backend delivered it.
  ///
  /// For a bilingual payload that is the slot of the language the session was
  /// requested in; for a flat payload it is the string itself. It is the
  /// fallback for a language the payload does not carry, so the question never
  /// renders blank.
  static String _deliveredText(
    Map<String, dynamic> json, {
    required QuizLanguage language,
  }) {
    // (a) a bilingual node on `question` / `text`.
    for (final key in const ['question', 'text']) {
      final node = _asMap(json[key]);
      if (node == null) continue;
      final pair = _bilingual(node);
      final delivered = _pickLanguage(pair.en, pair.np, language);
      if (delivered != null) return delivered;
    }
    // (b) a flat `question` / `text` string.
    final plain = _asString(json['question']) ?? _asString(json['text']);
    if (plain != null) return plain;
    // (c) the language nodes.
    final enNode = _asMap(json['en']);
    final npNode = _asMap(json['np']);
    if (enNode != null || npNode != null) {
      final delivered = _pickLanguage(
        _asString(enNode?['text']) ?? _asString(enNode?['question']),
        _asString(npNode?['text']) ?? _asString(npNode?['question']),
        language,
      );
      if (delivered != null) return delivered;
    }
    // (d) the language keys as plain strings.
    final delivered = _pickLanguage(
      _asString(json['en']),
      _asString(json['np']),
      language,
    );
    if (delivered != null) return delivered;
    return '';
  }

  /// The slot matching [language], falling back to the other one.
  static String? _pickLanguage(String? en, String? np, QuizLanguage language) {
    final preferred = language == QuizLanguage.nepali ? np : en;
    if (preferred != null && preferred.trim().isNotEmpty) return preferred;
    final other = language == QuizLanguage.nepali ? en : np;
    if (other != null && other.trim().isNotEmpty) return other;
    return null;
  }

  /// Nepali question text: known keys first, then a script scan so a renamed
  /// field cannot leave the EN | NP toggle inert.
  static String? _nepaliText(Map<String, dynamic> json, {required String english}) {
    // (a) `question: {en, np}` or `text: {en, np}`.
    for (final key in const ['question', 'text']) {
      final node = _asMap(json[key]);
      if (node == null) continue;
      final np = _bilingual(node).np;
      if (np != null) return np;
    }
    // (b) sibling keys.
    for (final key in const [
      'textNp',
      'text_np',
      'npText',
      'nepaliText',
      'questionNp',
      'translation',
    ]) {
      final candidate = _asString(json[key]);
      if (_looksNepali(candidate)) return candidate;
    }
    // (c) / (d) `np: {text, options}`.
    final npNode = json['np'];
    final nested = _asString(_asMap(npNode)?['text']) ??
        _asString(_asMap(npNode)?['question']) ??
        _asString(npNode);
    if (_looksNepali(nested)) return nested;

    // Last resort: any Devanagari string on the question that is not the
    // English text.
    return _scanNepali(json, exclude: english);
  }

  /// Reads one label per option for the requested slot.
  ///
  /// An entry may be a plain string, a boolean (TRUE_FALSE), `{text: "..."}` or
  /// `{text: {en, np}}`. When the inner value holds only one language, the whole
  /// entry is re-scanned by script, so `{text, translation}` also resolves.
  ///
  /// A plain string is only accepted for a language when it is actually
  /// written in that language's script. A Nepali-only payload therefore cannot
  /// masquerade as an English translation — that mislabelling is exactly what
  /// made the EN | NP toggle look inert.
  static List<String> _optionLabels(
    dynamic value, {
    required _OptionMode mode,
    QuizLanguage language = QuizLanguage.english,
  }) {
    final labels = <String>[];
    for (final option in _asList(value)) {
      if (option is bool) {
        final label = option ? 'True' : 'False';
        labels.add(label);
        continue;
      }
      final map = _asMap(option);
      if (map == null) {
        final label = _asString(option);
        if (label == null) continue;
        labels.add(_labelForScript(label, mode));
        continue;
      }
      final inner = map['text'] ?? map['label'] ?? map['option'];
      var pair = _bilingual(inner);
      if ((mode == _OptionMode.nepali ? pair.np : pair.en) == null) {
        pair = _bilingual(map);
      }
      final label = switch (mode) {
        _OptionMode.english => pair.en,
        _OptionMode.nepali => pair.np,
        _OptionMode.delivered => _pickLanguage(pair.en, pair.np, language),
      };
      labels.add((label == null || label.isEmpty) ? '' : label);
    }
    return labels;
  }

  /// A plain string belongs to the English slot when it is not written in
  /// Devanagari, and to the Nepali slot when it is.
  static String _labelForScript(String label, _OptionMode mode) {
    switch (mode) {
      case _OptionMode.english:
        return _looksNepali(label) ? '' : label;
      case _OptionMode.nepali:
        return _looksNepali(label) ? label : '';
      case _OptionMode.delivered:
        return label;
    }
  }

  /// Resolves a value that is either a plain string or a `{en, np}` object.
  ///
  /// Known keys are tried first (`en`/`np` plus their aliases), then the object
  /// is split by script: the first Devanagari string is the Nepali side, the
  /// first non-Devanagari one is the English side. The script split is what
  /// keeps the toggle working if the backend renames `np` to something else.
  static ({String? en, String? np}) _bilingual(dynamic value) {
    final map = _asMap(value);
    if (map == null) {
      final text = _asString(value);
      if (text == null) return (en: null, np: null);
      // A Devanagari string is Nepali, never English. Treating it as English
      // is how a Nepali session ended up with Nepali text in the English slot.
      return _looksNepali(text) ? (en: null, np: text) : (en: text, np: null);
    }

    var en =
        _asString(map['en']) ??
        _asString(map['english']) ??
        _asString(map['text']) ??
        _asString(map['question']);
    var np =
        _asString(map['np']) ??
        _asString(map['ne']) ??
        _asString(map['nepali']) ??
        _asString(map['nepaliText']) ??
        _asString(map['npText']) ??
        _asString(map['textNp']) ??
        _asString(map['text_np']);

    // Only real strings are considered, so `is_correct: true` or an option `id`
    // can never be mistaken for copy.
    final strings = map.entries
        .where((entry) => !_isMetadataKey(entry.key))
        .map((entry) => entry.value)
        .whereType<String>()
        .toList();
    en ??= strings.firstWhere(
      (candidate) => !_looksNepali(candidate),
      orElse: () => '',
    );
    np ??= strings.firstWhere(_looksNepali, orElse: () => '');

    return (en: en.isEmpty ? null : en, np: np.isEmpty ? null : np);
  }

  /// Keys that hold identifiers or flags rather than copy.
  static bool _isMetadataKey(String key) {
    final lower = key.toLowerCase();
    return lower == 'id' ||
        lower == '_id' ||
        lower == 'key' ||
        lower == 'value' ||
        lower == 'correct' ||
        lower.contains('correct') ||
        lower.contains('weight') ||
        lower.contains('point');
  }

  /// Any Devanagari string in [json] (one level of nesting), other than
  /// [exclude].
  static String? _scanNepali(Map<String, dynamic> json, {required String exclude}) {
    for (final entry in json.entries) {
      if (_isOptionKey(entry.key) || _isMetadataKey(entry.key)) continue;
      final candidate = _asString(entry.value);
      if (candidate != exclude && _looksNepali(candidate)) return candidate;
    }
    for (final entry in json.entries) {
      if (_isOptionKey(entry.key) || _isMetadataKey(entry.key)) continue;
      final map = _asMap(entry.value);
      if (map == null) continue;
      for (final inner in map.values) {
        final candidate = _asString(inner);
        if (candidate != exclude && _looksNepali(candidate)) return candidate;
      }
    }
    return null;
  }

  static bool _isOptionKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('option') || lower.contains('choice');
  }

  /// True when every slot holds real copy. Reading a plain English string list
  /// as Nepali yields empty placeholders, and those must not be mistaken for a
  /// translation.
  static bool _usable(List<String> labels) {
    return labels.isNotEmpty && labels.every((label) => label.isNotEmpty);
  }

  QuizQuestion toEntity() => QuizQuestion(
    text: text,
    options: options,
    questionIndex: questionIndex,
    textNp: textNp,
    optionsNp: optionsNp,
    primaryText: primaryText,
    primaryOptions: primaryOptions,
    scriptureReference: scriptureReference,
  );
}

class ActiveQuizModel {
  final String sessionId;
  final int durationSeconds;
  final List<QuizQuestion> questions;
  final String? scheduleId;
  final String? quizSetId;
  final String? title;
  final bool isDaily;
  final bool isSeries;
  final QuizLanguage language;

  const ActiveQuizModel({
    required this.sessionId,
    required this.durationSeconds,
    required this.questions,
    this.scheduleId,
    this.quizSetId,
    this.title,
    this.isDaily = false,
    this.isSeries = false,
    this.language = QuizLanguage.english,
  });

  factory ActiveQuizModel.fromJson(
    Map<String, dynamic> json, {
    QuizLanguage language = QuizLanguage.english,
  }) {
    final session = _asMap(json['session']) ?? const <String, dynamic>{};
    final quiz = _asMap(json['quiz']) ?? const <String, dynamic>{};
    final schedule = _asMap(json['schedule']) ?? const <String, dynamic>{};
    final quizSet =
        _asMap(json['quizSet']) ??
        _asMap(json['quiz_set']) ??
        // A populated reference (`quizSetId: {_id, questions...}`).
        _asMap(json['quizSetId']) ??
        const <String, dynamic>{};

    final rawQuestions = _asList(
      json['questions'] ??
          session['questions'] ??
          quiz['questions'] ??
          json['questionsList'] ??
          quizSet['questions'],
    );

    final questions = <QuizQuestion>[];
    for (var index = 0; index < rawQuestions.length; index++) {
      final raw = _asMap(rawQuestions[index]);
      if (raw == null) continue;
      questions.add(
        QuizQuestionModel.fromJson(
          raw,
          fallbackIndex: index,
          language: language,
        ).toEntity(),
      );
    }

    final metadata = _asMap(schedule['metadata']) ?? _asMap(json['metadata']);

    return ActiveQuizModel(
      sessionId:
          _asString(json['sessionId']) ??
          _asString(json['_id']) ??
          _asString(json['id']) ??
          _asString(session['sessionId']) ??
          _asString(session['_id']) ??
          '',
      durationSeconds:
          _asInt(json['durationSeconds']) ??
          _asInt(json['duration']) ??
          _asInt(json['remainingSeconds']) ??
          _asInt(json['timeLimitSeconds']) ??
          _asInt(session['durationSeconds']) ??
          0,
      questions: questions,
      scheduleId:
          _asString(json['quizScheduleId']) ??
          _asString(json['scheduleId']) ??
          _asString(schedule['_id']) ??
          _asString(schedule['id']),
      quizSetId:
          _asString(json['quizSetId']) ??
          _asString(json['quizSet_id']) ??
          _asString(json['setId']) ??
          _asString(quizSet['_id']) ??
          _asString(quizSet['id']) ??
          _asString(schedule['quizSetId']) ??
          _asString(schedule['quizSet_id']) ??
          _asString(_asMap(schedule['quizSetId'])?['_id']) ??
          _asString(_asMap(schedule['quizSetId'])?['id']),
      title:
          _asString(json['title']) ??
          _asString(quiz['title']) ??
          _asString(schedule['title']),
      isDaily: _asBool(metadata?['isDaily']) ?? false,
      isSeries:
          _asBool(metadata?['isSeries']) ??
          _asString(metadata?['seriesId']) != null,
      language: language,
    );
  }

  ActiveQuiz toEntity() => ActiveQuiz(
    sessionId: sessionId,
    durationSeconds: durationSeconds,
    questions: questions,
    scheduleId: scheduleId,
    quizSetId: quizSetId,
    title: title,
    isDaily: isDaily,
    isSeries: isSeries,
    language: language,
  );
}

class AnswerResultModel {
  final bool isCorrect;
  final int correctAnswerIndex;
  final String explanation;
  final int pointsEarned;
  final String? explanationNp;

  /// The explanation exactly as the backend sent it. The fallback when the
  /// requested language is not part of the payload.
  final String primaryExplanation;

  const AnswerResultModel({
    required this.isCorrect,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.pointsEarned,
    this.explanationNp,
    this.primaryExplanation = '',
  });

  factory AnswerResultModel.fromJson(Map<String, dynamic> json) {
    final delivered = _asString(json['explanation']) ?? '';
    // A Devanagari explanation is Nepali, never English. The backend answers
    // in the session's language, so a Nepali session returns a Nepali
    // explanation — calling that English made the EN | NP toggle look dead
    // on the feedback line too.
    final isNepali = _looksNepali(delivered);
    return AnswerResultModel(
      isCorrect: _asBool(json['isCorrect']) ?? false,
      correctAnswerIndex: _asInt(json['correctAnswerIndex']) ?? -1,
      explanation: isNepali ? '' : delivered,
      pointsEarned: _asInt(json['pointsEarned']) ?? 0,
      explanationNp: isNepali
          ? delivered
          : _findNepaliExplanation(json, explanation: delivered),
      primaryExplanation: delivered,
    );
  }

  /// Known aliases first, then a script scan of every other string in the
  /// payload, so a renamed field still translates.
  static String? _findNepaliExplanation(
    Map<String, dynamic> json, {
    required String explanation,
  }) {
    const aliases = [
      'explanationNp',
      'explanation_np',
      'npExplanation',
      'explanationNepali',
      'nepaliExplanation',
      'npText',
      'nepaliText',
    ];
    for (final alias in aliases) {
      final candidate = _asString(json[alias]);
      if (_looksNepali(candidate)) return candidate;
    }

    final nested = _asMap(json['np']) ?? _asMap(json['ne']) ??
        _asMap(json['nepali']);
    if (nested != null) {
      final candidate = _asString(
        nested['explanation'] ?? nested['text'] ?? nested['reason'],
      );
      if (_looksNepali(candidate)) return candidate;
    }

    for (final entry in json.entries) {
      final candidate = _asString(entry.value);
      if (candidate != explanation && _looksNepali(candidate)) return candidate;
    }

    return null;
  }

  AnswerResult toEntity() => AnswerResult(
    isCorrect: isCorrect,
    correctAnswerIndex: correctAnswerIndex,
    explanation: explanation,
    pointsEarned: pointsEarned,
    explanationNp: explanationNp,
    primaryExplanation: primaryExplanation,
  );
}

class QuizResultModel {
  final int score;
  final int maxPossibleScore;
  final int percentageScore;
  final bool passed;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int? totalPoints;
  final int? rank;

  const QuizResultModel({
    required this.score,
    required this.maxPossibleScore,
    required this.percentageScore,
    required this.passed,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    this.totalPoints,
    this.rank,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    final leaderboard =
        _asMap(json['leaderboard']) ??
        _asMap(json['ranking']) ??
        _asMap(json['userLevel']) ??
        const <String, dynamic>{};

    return QuizResultModel(
      score: _asInt(json['score']) ?? 0,
      maxPossibleScore:
          _asInt(json['maxPossibleScore']) ?? _asInt(json['maxScore']) ?? 0,
      percentageScore:
          _asInt(json['percentageScore']) ?? _asInt(json['percentage']) ?? 0,
      passed: _asBool(json['passed']) ?? false,
      totalQuestions:
          _asInt(json['totalQuestions']) ?? _asInt(json['totalAnswered']) ?? 0,
      correctAnswers: _asInt(json['correctAnswers']) ?? 0,
      wrongAnswers: _asInt(json['wrongAnswers']) ?? 0,
      totalPoints:
          _asInt(json['totalPoints']) ??
          _asInt(leaderboard['totalPoints']) ??
          _asInt(json['points']),
      rank:
          _asInt(json['rank']) ??
          _asInt(json['userRank']) ??
          _asInt(leaderboard['rank']) ??
          _asInt(leaderboard['allTimeRank']),
    );
  }

  QuizResult toEntity() => QuizResult(
    score: score,
    maxPossibleScore: maxPossibleScore,
    percentageScore: percentageScore,
    passed: passed,
    totalQuestions: totalQuestions,
    correctAnswers: correctAnswers,
    wrongAnswers: wrongAnswers,
    totalPoints: totalPoints,
    rank: rank,
  );
}

/// One row of `GET /quiz-schedule/history`.
class QuizAttemptModel {
  final String scheduleId;
  final String? sessionId;
  final bool isCompleted;
  final int? score;
  final DateTime? completedAt;

  const QuizAttemptModel({
    required this.scheduleId,
    this.sessionId,
    this.isCompleted = false,
    this.score,
    this.completedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    final schedule = _asMap(json['quizSchedule']) ?? const <String, dynamic>{};
    final status = (_asString(json['status']) ?? '').toLowerCase();
    final completedAt = _asDate(json['completedAt'] ?? json['finishedAt']);

    return QuizAttemptModel(
      scheduleId:
          _asString(json['quizScheduleId']) ??
          _asString(json['scheduleId']) ??
          _asString(schedule['_id']) ??
          _asString(schedule['id']) ??
          '',
      sessionId:
          _asString(json['sessionId']) ??
          _asString(json['session_id']) ??
          _asString(json['attemptId']),
      isCompleted:
          _asBool(json['isCompleted']) ??
          _asBool(json['completed']) ??
          status == 'completed' ||
              status == 'submitted' ||
              status == 'finished' ||
              completedAt != null,
      score: _asInt(json['score']) ?? _asInt(json['percentageScore']),
      completedAt: completedAt,
    );
  }

  QuizAttempt toEntity() => QuizAttempt(
    scheduleId: scheduleId,
    sessionId: sessionId,
    isCompleted: isCompleted,
    score: score,
    completedAt: completedAt,
  );
}

/// A row of `GET /quiz-schedule/series` plus its deployments.
class QuizSeriesModel {
  final String id;
  final String title;
  final String? description;
  final int durationValue;
  final String durationUnit;
  final String status;
  final List<QuizSchedule> deployments;

  const QuizSeriesModel({
    required this.id,
    required this.title,
    this.description,
    this.durationValue = 0,
    this.durationUnit = 'days',
    this.status = '',
    this.deployments = const [],
  });

  factory QuizSeriesModel.fromJson(Map<String, dynamic> json) {
    final rules = _asMap(json['defaultRules']) ?? const <String, dynamic>{};
    final title = _asString(json['title']) ?? '';

    final deployments =
        _asList(
          json['deployments'] ?? json['instances'] ?? json['schedules'],
        ).whereType<Map<dynamic, dynamic>>().map((raw) {
          final map = _asMap(raw) ?? const <String, dynamic>{};
          return QuizScheduleModel.fromJson(
            map['title'] == null ? {...map, 'title': title} : map,
          ).toEntity();
        }).toList();

    return QuizSeriesModel(
      id: _asString(json['_id']) ?? _asString(json['id']) ?? '',
      title: title,
      description: _asString(json['description']),
      durationValue:
          _asInt(json['durationValue']) ?? _asInt(rules['durationValue']) ?? 0,
      durationUnit: _asString(json['durationUnit']) ?? 'days',
      status: _asString(json['status']) ?? '',
      deployments: deployments,
    );
  }

  QuizSeries toEntity() => QuizSeries(
    id: id,
    title: title,
    description: description,
    durationValue: durationValue,
    durationUnit: durationUnit,
    status: status,
    deployments: deployments,
  );
}

/// A quiz set: the question documents the backend stores, with every
/// language variant it holds.
///
/// A running session is materialised in the language it was started with, so
/// the set is the only place the other wording can come from.
class QuizSetModel {
  final String id;
  final String title;
  final List<QuizQuestion> questions;

  const QuizSetModel({
    required this.id,
    required this.title,
    required this.questions,
  });

  factory QuizSetModel.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final root = data ?? json;
    // Accept a bare set, `{data: {...}}` and `{data: {quizSet: {...}}}`.
    final set =
        _asMap(json['quizSet']) ??
        _asMap(json['quiz_set']) ??
        _asMap(json['set']) ??
        _asMap(root['quizSet']) ??
        _asMap(root['quiz_set']) ??
        _asMap(root['set']) ??
        root;
    final rawQuestions = _asList(
      set['questions'] ?? root['questions'] ?? json['questions'],
    );

    final questions = <QuizQuestion>[];
    for (var index = 0; index < rawQuestions.length; index++) {
      final raw = _asMap(rawQuestions[index]);
      if (raw == null) continue;
      questions.add(
        QuizQuestionModel.fromJson(
          raw,
          fallbackIndex: index,
          // The set is bilingual; the English slot is the primary one and the
          // Nepali slot is read from the same document.
          language: QuizLanguage.english,
        ).toEntity(),
      );
    }

    return QuizSetModel(
      id:
          _asString(set['_id']) ??
          _asString(set['id']) ??
          _asString(root['_id']) ??
          _asString(root['id']) ??
          _asString(json['_id']) ??
          _asString(json['id']) ??
          '',
      title: _asString(set['title']) ?? _asString(root['title']) ?? '',
      questions: questions,
    );
  }

  QuizQuestionSet toEntity() => QuizQuestionSet(
    id: id,
    title: title,
    questions: questions,
  );
}
