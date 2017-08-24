// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._interceptors;

/**
 * The interceptor class for [String]. The compiler recognizes this
 * class as an interceptor, and changes references to [:this:] to
 * actually use the receiver of the method, which is generated as an extra
 * argument added to each member.
 */
@JsPeerInterface(name: 'String')
class JSString extends Interceptor implements String, JSIndexable<String> {
  const JSString();

  @notNull
  int codeUnitAt(@nullCheck int index) {
    // Suppress 2nd null check on index and null check on length
    // (JS String.length cannot be null).
    final len = this.length;
    if (index < 0 || index >= len) {
      throw new RangeError.index(index, this, 'index', null, len);
    }
    return JS('int', r'#.charCodeAt(#)', this, index);
  }

  @notNull
  Iterable<Match> allMatches(@nullCheck String string,
      [@nullCheck int start = 0]) {
    final len = string.length;
    if (0 > start || start > len) {
      throw new RangeError.range(start, 0, len);
    }
    return allMatchesInStringUnchecked(this, string, start);
  }

  Match matchAsPrefix(@nullCheck String string, [@nullCheck int start = 0]) {
    final stringLength = JS('int', '#.length', string);
    if (start < 0 || start > stringLength) {
      throw new RangeError.range(start, 0, stringLength);
    }
    final thisLength = JS('int', '#.length', this);
    if (start + thisLength > stringLength) return null;
    for (int i = 0; i < thisLength; i++) {
      if (string.codeUnitAt(start + i) != this.codeUnitAt(i)) {
        return null;
      }
    }
    return new StringMatch(start, string, this);
  }

  @notNull
  String operator +(@nullCheck String other) {
    return JS('String', r'# + #', this, other);
  }

  @notNull
  bool endsWith(@nullCheck String other) {
    var otherLength = other.length;
    var thisLength = this.length;
    if (otherLength > thisLength) return false;
    return other == substring(thisLength - otherLength);
  }

  @notNull
  String replaceAll(Pattern from, @nullCheck String to) {
    return stringReplaceAllUnchecked(this, from, to);
  }

  @notNull
  String replaceAllMapped(Pattern from, String convert(Match match)) {
    return this.splitMapJoin(from, onMatch: convert);
  }

  @notNull
  String splitMapJoin(Pattern from,
      {String onMatch(Match match), String onNonMatch(String nonMatch)}) {
    return stringReplaceAllFuncUnchecked(this, from, onMatch, onNonMatch);
  }

  @notNull
  String replaceFirst(Pattern from, @nullCheck String to,
      [@nullCheck int startIndex = 0]) {
    RangeError.checkValueInInterval(startIndex, 0, this.length, "startIndex");
    return stringReplaceFirstUnchecked(this, from, to, startIndex);
  }

  @notNull
  String replaceFirstMapped(
      Pattern from, @nullCheck String replace(Match match),
      [@nullCheck int startIndex = 0]) {
    RangeError.checkValueInInterval(startIndex, 0, this.length, "startIndex");
    return stringReplaceFirstMappedUnchecked(this, from, replace, startIndex);
  }

  @notNull
  List<String> split(@nullCheck Pattern pattern) {
    if (pattern is String) {
      return JS('JSExtendableArray', r'#.split(#)', this, pattern);
    } else if (pattern is JSSyntaxRegExp && regExpCaptureCount(pattern) == 0) {
      var re = regExpGetNative(pattern);
      return JS('JSExtendableArray', r'#.split(#)', this, re);
    } else {
      return _defaultSplit(pattern);
    }
  }

  @notNull
  String replaceRange(
      @nullCheck int start, int end, @nullCheck String replacement) {
    end = RangeError.checkValidRange(start, end, this.length);
    return stringReplaceRangeUnchecked(this, start, end, replacement);
  }

  @notNull
  List<String> _defaultSplit(Pattern pattern) {
    List<String> result = <String>[];
    // End of most recent match. That is, start of next part to add to result.
    int start = 0;
    // Length of most recent match.
    // Set >0, so no match on the empty string causes the result to be [""].
    int length = 1;
    for (var match in pattern.allMatches(this)) {
      @notNull
      int matchStart = match.start;
      @notNull
      int matchEnd = match.end;
      length = matchEnd - matchStart;
      if (length == 0 && start == matchStart) {
        // An empty match right after another match is ignored.
        // This includes an empty match at the start of the string.
        continue;
      }
      int end = matchStart;
      result.add(this.substring(start, end));
      start = matchEnd;
    }
    if (start < this.length || length > 0) {
      // An empty match at the end of the string does not cause a "" at the end.
      // A non-empty match ending at the end of the string does add a "".
      result.add(this.substring(start));
    }
    return result;
  }

  @notNull
  bool startsWith(Pattern pattern, [@nullCheck int index = 0]) {
    // Suppress null check on length and all but the first
    // reference to index.
    int length = JS('int', '#.length', this);
    if (index < 0 || JS('int', '#', index) > length) {
      throw new RangeError.range(index, 0, this.length);
    }
    if (pattern is String) {
      String other = pattern;
      int otherLength = JS('int', '#.length', other);
      int endIndex = index + otherLength;
      if (endIndex > length) return false;
      return other == JS('String', r'#.substring(#, #)', this, index, endIndex);
    }
    return pattern.matchAsPrefix(this, index) != null;
  }

  @notNull
  String substring(@nullCheck int startIndex, [int _endIndex]) {
    var length = this.length;
    final endIndex = _endIndex ?? length;
    if (startIndex < 0) throw new RangeError.value(startIndex);
    if (startIndex > endIndex) throw new RangeError.value(startIndex);
    if (endIndex > length) throw new RangeError.value(endIndex);
    return JS('String', r'#.substring(#, #)', this, startIndex, endIndex);
  }

  @notNull
  String toLowerCase() {
    return JS('String', r'#.toLowerCase()', this);
  }

  @notNull
  String toUpperCase() {
    return JS('String', r'#.toUpperCase()', this);
  }

  // Characters with Whitespace property (Unicode 6.2).
  // 0009..000D    ; White_Space # Cc       <control-0009>..<control-000D>
  // 0020          ; White_Space # Zs       SPACE
  // 0085          ; White_Space # Cc       <control-0085>
  // 00A0          ; White_Space # Zs       NO-BREAK SPACE
  // 1680          ; White_Space # Zs       OGHAM SPACE MARK
  // 180E          ; White_Space # Zs       MONGOLIAN VOWEL SEPARATOR
  // 2000..200A    ; White_Space # Zs       EN QUAD..HAIR SPACE
  // 2028          ; White_Space # Zl       LINE SEPARATOR
  // 2029          ; White_Space # Zp       PARAGRAPH SEPARATOR
  // 202F          ; White_Space # Zs       NARROW NO-BREAK SPACE
  // 205F          ; White_Space # Zs       MEDIUM MATHEMATICAL SPACE
  // 3000          ; White_Space # Zs       IDEOGRAPHIC SPACE
  //
  // BOM: 0xFEFF
  @notNull
  static bool _isWhitespace(@notNull int codeUnit) {
    // Most codeUnits should be less than 256. Special case with a smaller
    // switch.
    if (codeUnit < 256) {
      switch (codeUnit) {
        case 0x09:
        case 0x0A:
        case 0x0B:
        case 0x0C:
        case 0x0D:
        case 0x20:
        case 0x85:
        case 0xA0:
          return true;
        default:
          return false;
      }
    }
    switch (codeUnit) {
      case 0x1680:
      case 0x180E:
      case 0x2000:
      case 0x2001:
      case 0x2002:
      case 0x2003:
      case 0x2004:
      case 0x2005:
      case 0x2006:
      case 0x2007:
      case 0x2008:
      case 0x2009:
      case 0x200A:
      case 0x2028:
      case 0x2029:
      case 0x202F:
      case 0x205F:
      case 0x3000:
      case 0xFEFF:
        return true;
      default:
        return false;
    }
  }

  /// Finds the index of the first non-whitespace character, or the
  /// end of the string. Start looking at position [index].
  @notNull
  static int _skipLeadingWhitespace(String string, @nullCheck int index) {
    const int SPACE = 0x20;
    const int CARRIAGE_RETURN = 0x0D;
    var stringLength = string.length;
    while (index < stringLength) {
      int codeUnit = string.codeUnitAt(index);
      if (codeUnit != SPACE &&
          codeUnit != CARRIAGE_RETURN &&
          !_isWhitespace(codeUnit)) {
        break;
      }
      index++;
    }
    return index;
  }

  /// Finds the index after the last non-whitespace character, or 0.
  /// Start looking at position [index - 1].
  @notNull
  static int _skipTrailingWhitespace(String string, @nullCheck int index) {
    const int SPACE = 0x20;
    const int CARRIAGE_RETURN = 0x0D;
    while (index > 0) {
      int codeUnit = string.codeUnitAt(index - 1);
      if (codeUnit != SPACE &&
          codeUnit != CARRIAGE_RETURN &&
          !_isWhitespace(codeUnit)) {
        break;
      }
      index--;
    }
    return index;
  }

  // Dart2js can't use JavaScript trim directly,
  // because JavaScript does not trim
  // the NEXT LINE (NEL) character (0x85).
  @notNull
  String trim() {
    const int NEL = 0x85;

    // Start by doing JS trim. Then check if it leaves a NEL at
    // either end of the string.
    final result = JS('String', '#.trim()', this);
    final length = result.length;
    if (length == 0) return result;
    int firstCode = result.codeUnitAt(0);
    int startIndex = 0;
    if (firstCode == NEL) {
      startIndex = _skipLeadingWhitespace(result, 1);
      if (startIndex == length) return "";
    }

    int endIndex = length;
    // We know that there is at least one character that is non-whitespace.
    // Therefore we don't need to verify that endIndex > startIndex.
    int lastCode = result.codeUnitAt(endIndex - 1);
    if (lastCode == NEL) {
      endIndex = _skipTrailingWhitespace(result, endIndex - 1);
    }
    if (startIndex == 0 && endIndex == length) return result;
    return JS('String', r'#.substring(#, #)', result, startIndex, endIndex);
  }

  // Dart2js can't use JavaScript trimLeft directly,
  // because it is not in ES5, so not every browser implements it,
  // and because those that do will not trim the NEXT LINE character (0x85).
  @notNull
  String trimLeft() {
    const int NEL = 0x85;

    // Start by doing JS trim. Then check if it leaves a NEL at
    // the beginning of the string.
    String result;
    int startIndex = 0;
    if (JS('bool', 'typeof #.trimLeft != "undefined"', this)) {
      result = JS('String', '#.trimLeft()', this);
      if (result.length == 0) return result;
      int firstCode = result.codeUnitAt(0);
      if (firstCode == NEL) {
        startIndex = _skipLeadingWhitespace(result, 1);
      }
    } else {
      result = this;
      startIndex = _skipLeadingWhitespace(this, 0);
    }
    if (startIndex == 0) return result;
    if (startIndex == result.length) return "";
    return JS('String', r'#.substring(#)', result, startIndex);
  }

  // Dart2js can't use JavaScript trimRight directly,
  // because it is not in ES5 and because JavaScript does not trim
  // the NEXT LINE character (0x85).
  @notNull
  String trimRight() {
    const int NEL = 0x85;

    // Start by doing JS trim. Then check if it leaves a NEL or BOM at
    // the end of the string.
    String result;
    @notNull
    int endIndex = 0;
    // trimRight is implemented by Firefox and Chrome/Blink,
    // so use it if it is there.
    if (JS('bool', 'typeof #.trimRight != "undefined"', this)) {
      result = JS('String', '#.trimRight()', this);
      endIndex = result.length;
      if (endIndex == 0) return result;
      int lastCode = result.codeUnitAt(endIndex - 1);
      if (lastCode == NEL) {
        endIndex = _skipTrailingWhitespace(result, endIndex - 1);
      }
    } else {
      result = this;
      endIndex = _skipTrailingWhitespace(this, this.length);
    }

    if (endIndex == result.length) return result;
    if (endIndex == 0) return "";
    return JS('String', r'#.substring(#, #)', result, 0, endIndex);
  }

  @notNull
  String operator *(@nullCheck int times) {
    if (0 >= times) return '';
    if (times == 1 || this.length == 0) return this;
    if (times != JS('int', '# >>> 0', times)) {
      // times >= 2^32. We can't create a string that big.
      throw const OutOfMemoryError();
    }
    var result = '';
    String s = this;
    while (true) {
      if (times & 1 == 1) result = s + result;
      times = JS('int', '# >>> 1', times);
      if (times == 0) break;
      s += s;
    }
    return result;
  }

  @notNull
  String padLeft(@nullCheck int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    return padding * delta + this;
  }

  @notNull
  String padRight(@nullCheck int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    return this + padding * delta;
  }

  @notNull
  List<int> get codeUnits => new CodeUnits(this);

  @notNull
  Runes get runes => new Runes(this);

  @notNull
  int indexOf(@nullCheck Pattern pattern, [@nullCheck int start = 0]) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (pattern is String) {
      return stringIndexOfStringUnchecked(this, pattern, start);
    }
    if (pattern is JSSyntaxRegExp) {
      JSSyntaxRegExp re = pattern;
      Match match = firstMatchAfter(re, this, start);
      return (match == null) ? -1 : match.start;
    }
    var length = this.length;
    for (int i = start; i <= length; i++) {
      if (pattern.matchAsPrefix(this, i) != null) return i;
    }
    return -1;
  }

  @notNull
  int lastIndexOf(@nullCheck Pattern pattern, [int _start]) {
    var length = this.length;
    var start = _start ?? length;
    if (start < 0 || start > length) {
      throw new RangeError.range(start, 0, length);
    }
    if (pattern is String) {
      String other = pattern;
      if (start + other.length > length) {
        start = length - other.length;
      }
      return stringLastIndexOfUnchecked(this, other, start);
    }
    for (int i = start; i >= 0; i--) {
      if (pattern.matchAsPrefix(this, i) != null) return i;
    }
    return -1;
  }

  @notNull
  bool contains(@nullCheck Pattern other, [@nullCheck int startIndex = 0]) {
    if (startIndex < 0 || startIndex > this.length) {
      throw new RangeError.range(startIndex, 0, this.length);
    }
    return stringContainsUnchecked(this, other, startIndex);
  }

  @notNull
  bool get isEmpty => JS('int', '#.length', this) == 0;

  @notNull
  bool get isNotEmpty => !isEmpty;

  @notNull
  int compareTo(@nullCheck String other) {
    return this == other ? 0 : JS('bool', r'# < #', this, other) ? -1 : 1;
  }

  // Note: if you change this, also change the function [S].
  @notNull
  String toString() => this;

  /**
   * This is the [Jenkins hash function][1] but using masking to keep
   * values in SMI range.
   *
   * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
   */
  @notNull
  int get hashCode {
    // TODO(ahe): This method shouldn't have to use JS. Update when our
    // optimizations are smarter.
    int hash = 0;
    int length = JS('int', '#.length', this);
    for (int i = 0; i < length; i++) {
      hash = 0x1fffffff & (hash + JS('int', r'#.charCodeAt(#)', this, i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = JS('int', '# ^ (# >> 6)', hash, hash);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = JS('int', '# ^ (# >> 11)', hash, hash);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  @notNull
  Type get runtimeType => String;

  @notNull
  int get length => JS('int', r'#.length', this);

  @notNull
  String operator [](@nullCheck int index) {
    if (index >= JS('int', '#.length', this) || index < 0) {
      throw diagnoseIndexError(this, index);
    }
    return JS('String', '#[#]', this, index);
  }
}
