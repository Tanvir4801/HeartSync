import 'package:flutter/material.dart';

class AppTheme {
  static const Color duskIndigo = Color(0xFF1C1B33);
  static const Color inkDark = Color(0xFF121022);
  static const Color mistWhite = Color(0xFFF3F1F6);
  static const Color dawnAmber = Color(0xFFF2A65A);
  static const Color horizonRose = Color(0xFFE8927C);
  static const Color lavenderDusk = Color(0xFF9B8AC4);
  static const Color surface = Color(0xFF252440);
  static const Color surface2 = Color(0xFF2E2C4A);
  static const Color border = Color(0xFF3A3859);
  static const Color textPrimary = Color(0xFFF3F1F6);
  static const Color textMuted = Color(0xFF8E8BAA);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFACC15);
  static const Color danger = Color(0xFFF87171);

  static Color primary = dawnAmber;
  static Color secondary = horizonRose;

  static ThemeData dark([Map<String, dynamic>? themeTokens]) {
    final bg = themeTokens?['bg'] != null ? _hex(themeTokens!['bg']) : duskIndigo;
    final pri = themeTokens?['primary'] != null ? _hex(themeTokens!['primary']) : dawnAmber;
    final sec = themeTokens?['secondary'] != null ? _hex(themeTokens!['secondary']) : horizonRose;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: pri,
        secondary: sec,
        surface: surface,
        error: danger,
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: pri.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, color: textMuted, fontFamily: 'Inter'),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: pri);
          return const IconThemeData(color: textMuted);
        }),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: pri)),
        hintStyle: const TextStyle(color: textMuted, fontFamily: 'Inter'),
        labelStyle: const TextStyle(color: textMuted, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pri,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }

  static Color _hex(String h) {
    final hex = h.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class HorizonLinePainter extends CustomPainter {
  final double progress;
  HorizonLinePainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width * progress, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(colors: [AppTheme.duskIndigo, AppTheme.horizonRose, AppTheme.dawnAmber]).createShader(rect)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width * progress, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(HorizonLinePainter old) => old.progress != progress;
}

class HorizonLine extends StatelessWidget {
  final double progress;
  final double height;
  const HorizonLine({super.key, this.progress = 1.0, this.height = 2});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: HorizonLinePainter(progress: progress)),
    );
  }
}
