import 'package:html/dom.dart';
import 'package:synchronized/synchronized.dart';

typedef BiliChapterLogLoader = Future<String> Function(String url);

class BiliChapterLogResolver {
  final String domain;
  final BiliChapterLogLoader loadScript;

  final Lock _lock = Lock();
  final Map<String, BiliChapterLogTemplate> _templateCache = {};

  BiliChapterLogResolver({
    required this.domain,
    required this.loadScript,
  });

  Future<Map<String, int>?> getShuffleParams(Document doc) async {
    var script = doc
        .querySelectorAll("script")
        .where((s) => s.attributes["src"]?.contains("chapterlog.js?v") ?? false)
        .firstOrNull;
    if (script == null) {
      return null;
    }

    int? chapterId = int.tryParse(
      RegExp("chapterid:'(\\d+)'").firstMatch(doc.outerHtml)?.group(1) ?? '',
    );
    if (chapterId == null) {
      return null;
    }

    String jsSrc = script.attributes["src"]!;
    String scriptUrl = Uri.parse(domain).resolve(jsSrc).toString();
    BiliChapterLogTemplate template = await _getTemplate(scriptUrl);
    return template.toShuffleParams(chapterId);
  }

  Future<BiliChapterLogTemplate> _getTemplate(String scriptUrl) {
    return _lock.synchronized(() async {
      if (_templateCache.containsKey(scriptUrl)) {
        return _templateCache[scriptUrl]!;
      }

      String js;
      try {
        js = await loadScript(scriptUrl);
      } catch (e) {
        throw Exception("failed to load chapterlog.js: $scriptUrl, $e");
      }

      BiliChapterLogTemplate? template = BiliChapterLogTemplate.tryParse(js);
      if (template == null) {
        throw Exception("failed to parse chapterlog.js: $scriptUrl");
      }

      _templateCache[scriptUrl] = template;
      return template;
    });
  }
}

class BiliChapterLogTemplate {
  static const int _defaultFixedLength = 20;
  static final RegExp _fixedLengthStartPattern = RegExp(
    r'if\s*\(\s*[_$a-zA-Z0-9]+\s*>\s*',
  );
  static final RegExp _seedExpressionPattern = RegExp(
    r'=\s*(.+?Number\s*\(\s*chapterId\s*\).+?)\s*;',
  );
  static final RegExp _lcgExpressionPattern = RegExp(
    r'=\s*(\(\s*[_$a-zA-Z0-9]+\s*\*.+?\)\s*%\s*.+?)\s*;',
  );
  static final RegExp _obfuscatedSeedPattern = RegExp(
    r'var\s+[_$a-zA-Z0-9]+\s*=\s*[^;]*?Number\s*\(\s*[_$a-zA-Z0-9]+\s*\)\s*,\s*([^,)]+?)\s*\)\s*,\s*([^,)]+?)\s*\)\s*,',
  );
  static final RegExp _obfuscatedLcgPattern = RegExp(
    r'([_$a-zA-Z0-9]+)\s*=\s*[^;]*?\(\s*\1\s*,\s*([^,)]+?)\s*\)\s*,\s*([^,)]+?)\s*\)\s*,\s*([^;)]+?)\s*\)\s*;',
  );

  final int fixedLength;
  final int seedMultiplier;
  final int seedOffset;
  final int a;
  final int c;
  final int mod;

  const BiliChapterLogTemplate({
    required this.fixedLength,
    required this.seedMultiplier,
    required this.seedOffset,
    required this.a,
    required this.c,
    required this.mod,
  });

  @override
  String toString() {
    return 'BiliChapterLogTemplate('
        'fixedLength: $fixedLength, '
        'seedMultiplier: $seedMultiplier, '
        'seedOffset: $seedOffset, '
        'a: $a, '
        'c: $c, '
        'mod: $mod'
        ')';
  }

  Map<String, int> toShuffleParams(int chapterId) {
    return {
      "fixedLength": fixedLength,
      "seed": chapterId * seedMultiplier + seedOffset,
      "a": a,
      "c": c,
      "mod": mod,
    };
  }

  static BiliChapterLogTemplate? tryParse(String js) {
    BiliChapterLogTemplate? plainTemplate = _tryParsePlain(js);
    if (plainTemplate != null) {
      return plainTemplate;
    }

    return _tryParseObfuscated(js);
  }

  static BiliChapterLogTemplate? _tryParsePlain(String js) {
    String? fixedLengthExpression = _extractTrailingExpression(
      js,
      _fixedLengthStartPattern,
      ')',
    );
    RegExpMatch? seedMatch = _seedExpressionPattern.firstMatch(js);
    RegExpMatch? lcgMatch = _lcgExpressionPattern.firstMatch(js);
    if (fixedLengthExpression == null ||
        seedMatch == null ||
        lcgMatch == null) {
      return null;
    }

    int? fixedLength = _evalIntExpression(
      _stripOuterParentheses(fixedLengthExpression),
    );
    ({int multiplier, int offset})? seedParams = _parseSeedExpression(
      seedMatch.group(1),
    );
    ({int a, int c, int mod})? lcgParams = _parseLcgExpression(
      lcgMatch.group(1),
    );
    if (fixedLength == null || seedParams == null || lcgParams == null) {
      return null;
    }

    return BiliChapterLogTemplate(
      fixedLength: fixedLength,
      seedMultiplier: seedParams.multiplier,
      seedOffset: seedParams.offset,
      a: lcgParams.a,
      c: lcgParams.c,
      mod: lcgParams.mod,
    );
  }

  static BiliChapterLogTemplate? _tryParseObfuscated(String js) {
    ({int multiplier, int offset})? seedParams = _parseObfuscatedSeedExpression(
      js,
    );
    ({int a, int c, int mod})? lcgParams = _parseObfuscatedLcgExpression(js);
    if (seedParams == null || lcgParams == null) {
      return null;
    }

    return BiliChapterLogTemplate(
      fixedLength: _defaultFixedLength,
      seedMultiplier: seedParams.multiplier,
      seedOffset: seedParams.offset,
      a: lcgParams.a,
      c: lcgParams.c,
      mod: lcgParams.mod,
    );
  }

  static int? _evalIntExpression(String? expression) {
    if (expression == null) {
      return null;
    }

    try {
      return _ChapterLogExpressionParser(expression).parse();
    } catch (_) {
      return null;
    }
  }

  static ({int multiplier, int offset})? _parseSeedExpression(String? expr) {
    if (expr == null) {
      return null;
    }

    int? offset = _evalExpressionWithVariables(expr, {
      'chapterId': 0,
    });
    int? oneValue = _evalExpressionWithVariables(expr, {
      'chapterId': 1,
    });
    if (offset == null || oneValue == null) {
      return null;
    }

    return (multiplier: oneValue - offset, offset: offset);
  }

  static ({int multiplier, int offset})? _parseObfuscatedSeedExpression(
    String js,
  ) {
    for (final match in _obfuscatedSeedPattern.allMatches(js)) {
      int? multiplier = _evalIntExpression(match.group(1));
      int? offset = _evalIntExpression(match.group(2));
      if (multiplier == null || offset == null) {
        continue;
      }
      if (multiplier <= 0 || offset < 0) {
        continue;
      }
      return (multiplier: multiplier, offset: offset);
    }
    return null;
  }

  static ({int a, int c, int mod})? _parseLcgExpression(String? expr) {
    if (expr == null) {
      return null;
    }

    List<String> modParts = _splitTopLevel(expr, '%');
    if (modParts.length != 2) {
      return null;
    }

    int? mod = _evalIntExpression(modParts[1]);
    if (mod == null) {
      return null;
    }

    String left = _stripOuterParentheses(modParts[0]);
    String? variableName = _firstIdentifier(left);
    if (variableName == null) {
      return null;
    }

    int? c = _evalExpressionWithVariables(left, {
      variableName: 0,
    });
    int? oneValue = _evalExpressionWithVariables(left, {
      variableName: 1,
    });
    if (c == null || oneValue == null) {
      return null;
    }

    return (a: oneValue - c, c: c, mod: mod);
  }

  static ({int a, int c, int mod})? _parseObfuscatedLcgExpression(String js) {
    for (final match in _obfuscatedLcgPattern.allMatches(js)) {
      int? a = _evalIntExpression(match.group(2));
      int? c = _evalIntExpression(match.group(3));
      int? mod = _evalIntExpression(match.group(4));
      if (a == null || c == null || mod == null) {
        continue;
      }
      if (a <= 0 || c < 0 || mod <= a || mod <= c) {
        continue;
      }
      return (a: a, c: c, mod: mod);
    }
    return null;
  }

  static int? _evalExpressionWithVariables(
    String expression,
    Map<String, int> variables,
  ) {
    String normalized = expression;
    for (var entry in variables.entries) {
      normalized = normalized.replaceAll(
        RegExp('Number\\s*\\(\\s*${entry.key}\\s*\\)'),
        entry.value.toString(),
      );
      normalized = normalized.replaceAll(
        RegExp('\\b${entry.key}\\b'),
        entry.value.toString(),
      );
    }
    return _evalIntExpression(normalized);
  }

  static List<String> _splitTopLevel(String expression, String operator) {
    List<String> parts = [];
    int start = 0;
    int depth = 0;
    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (char == '(') {
        depth++;
        continue;
      }
      if (char == ')') {
        depth--;
        continue;
      }
      if (depth == 0 && expression.startsWith(operator, i)) {
        parts.add(expression.substring(start, i).trim());
        start = i + operator.length;
        i += operator.length - 1;
      }
    }
    parts.add(expression.substring(start).trim());
    return parts;
  }

  static String _stripOuterParentheses(String expression) {
    String value = expression.trim();
    while (value.startsWith('(') && value.endsWith(')')) {
      int depth = 0;
      bool wrapsWholeExpression = true;
      for (int i = 0; i < value.length; i++) {
        String char = value[i];
        if (char == '(') {
          depth++;
        } else if (char == ')') {
          depth--;
          if (depth == 0 && i != value.length - 1) {
            wrapsWholeExpression = false;
            break;
          }
        }
      }
      if (!wrapsWholeExpression) {
        return value;
      }
      value = value.substring(1, value.length - 1).trim();
    }
    return value;
  }

  static String? _firstIdentifier(String expression) {
    RegExpMatch? match = RegExp(r'[_$a-zA-Z][_$a-zA-Z0-9]*').firstMatch(
      expression,
    );
    return match?.group(0);
  }

  static String? _extractTrailingExpression(
    String source,
    RegExp startPattern,
    String terminator,
  ) {
    RegExpMatch? match = startPattern.firstMatch(source);
    if (match == null) {
      return null;
    }

    int start = match.end;
    int depth = 0;
    for (int i = start; i < source.length; i++) {
      String char = source[i];
      if (char == '(') {
        depth++;
        continue;
      }
      if (char == ')') {
        if (depth == 0 && terminator == ')') {
          return source.substring(start, i).trim();
        }
        depth--;
        continue;
      }
      if (depth == 0 && char == terminator) {
        return source.substring(start, i).trim();
      }
    }
    return null;
  }
}

class _ChapterLogExpressionParser {
  final String source;
  int _index = 0;

  _ChapterLogExpressionParser(this.source);

  int parse() {
    int value = _parseBitwiseXor();
    _skipWhitespace();
    if (_index != source.length) {
      throw FormatException('Unexpected token', source, _index);
    }
    return value;
  }

  int _parseBitwiseXor() {
    int value = _parseShift();
    while (true) {
      _skipWhitespace();
      if (!_match('^')) {
        return value;
      }
      value ^= _parseShift();
    }
  }

  int _parseShift() {
    int value = _parseAddSub();
    while (true) {
      _skipWhitespace();
      if (_match('<<')) {
        value <<= _parseAddSub();
        continue;
      }
      if (_match('>>>') || _match('>>')) {
        value >>= _parseAddSub();
        continue;
      }
      return value;
    }
  }

  int _parseAddSub() {
    int value = _parseMulDivMod();
    while (true) {
      _skipWhitespace();
      if (_match('+')) {
        value += _parseMulDivMod();
        continue;
      }
      if (_match('-')) {
        value -= _parseMulDivMod();
        continue;
      }
      return value;
    }
  }

  int _parseMulDivMod() {
    int value = _parseUnary();
    while (true) {
      _skipWhitespace();
      if (_match('*')) {
        value *= _parseUnary();
        continue;
      }
      if (_match('/')) {
        value ~/= _parseUnary();
        continue;
      }
      if (_match('%')) {
        value %= _parseUnary();
        continue;
      }
      return value;
    }
  }

  int _parseUnary() {
    _skipWhitespace();
    if (_match('+')) {
      return _parseUnary();
    }
    if (_match('-')) {
      return -_parseUnary();
    }
    if (_match('~')) {
      return ~_parseUnary();
    }
    return _parsePrimary();
  }

  int _parsePrimary() {
    _skipWhitespace();
    if (_match('(')) {
      int value = _parseBitwiseXor();
      _skipWhitespace();
      if (!_match(')')) {
        throw FormatException('Missing closing parenthesis', source, _index);
      }
      return value;
    }

    int start = _index;
    while (_index < source.length && _isNumberChar(source.codeUnitAt(_index))) {
      _index++;
    }
    if (start == _index) {
      throw FormatException('Expected number', source, _index);
    }

    String token = source.substring(start, _index);
    if (token.startsWith('0x') || token.startsWith('0X')) {
      return int.parse(token.substring(2), radix: 16);
    }
    return int.parse(token);
  }

  bool _isNumberChar(int codeUnit) {
    return (codeUnit >= 48 && codeUnit <= 57) ||
        (codeUnit >= 65 && codeUnit <= 70) ||
        (codeUnit >= 97 && codeUnit <= 102) ||
        codeUnit == 120 ||
        codeUnit == 88;
  }

  bool _match(String value) {
    if (source.startsWith(value, _index)) {
      _index += value.length;
      return true;
    }
    return false;
  }

  void _skipWhitespace() {
    while (_index < source.length) {
      int codeUnit = source.codeUnitAt(_index);
      if (codeUnit == 32 || codeUnit == 9 || codeUnit == 10 || codeUnit == 13) {
        _index++;
        continue;
      }
      return;
    }
  }
}
