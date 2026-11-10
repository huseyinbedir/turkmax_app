/// Cockpit metin biçimlendirme yardımcıları (saf fonksiyonlar).
abstract final class CockpitFormatters {
  /// 24 saat biçiminde `HH:mm`.
  static String clock(DateTime time) =>
      '${_two(time.hour)}:${_two(time.minute)}';

  /// 1 km altı 10 m'ye yuvarlanmış metre; üstü tek ondalıklı km (TR ayraç).
  static String distance(int meters) {
    if (meters < 1000) {
      final rounded = meters < 10 ? meters : (meters / 10).round() * 10;
      if (rounded < 1000) return '$rounded m';
    }
    final km = meters / 1000;
    final text = km >= 100 ? km.round().toString() : km.toStringAsFixed(1);
    return '${text.replaceAll('.', ',')} km';
  }

  /// `45 dk` veya `1 sa 05 dk`.
  static String duration(Duration duration) {
    final minutes = (duration.inSeconds / 60).ceil();
    if (minutes < 60) return '$minutes dk';
    return '${minutes ~/ 60} sa ${_two(minutes % 60)} dk';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
