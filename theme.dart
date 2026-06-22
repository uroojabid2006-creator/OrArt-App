import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const lavender = Color(0xFFC9B5FF);
  static const lavenderDeep = Color(0xFFA78BFF);
  // More saturated variants for punchier pastel UI
  static const lavenderSaturated = Color(0xFF8F57FF);
  static const peach = Color(0xFFFFD6BF);
  static const peachDeep = Color(0xFFFFB48A);
  static const peachSaturated = Color(0xFFFF8C56);
  static const mint = Color(0xFFBFF3E0);
  static const mintDeep = Color(0xFF9EF0CC);
  static const mintSaturated = Color(0xFF3FE6B8);
  static const pastelTeal = Color(0xFF9DDCDC);
  static const pastelTealSaturated = Color(0xFF35CFC0);
  static const cream = Color(0xFFFFF8F2);
  static const text = Color(0xFF1A1A1A);
  static const softShadow = Color(0x0F141414);
  static const pastelPink = Color(0xFFFFB6C1);
  static const pastelPinkSaturated = Color(0xFFFF7AA0);
  // Light background variants for screens
  static const lightPinkBackground = Color(0xFFFFF0F5);
  static const lightBlueBackground = Color(0xFFE8F7FF);
}

final Gradient homeGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.lavender, AppColors.peach],
);

ThemeData buildAppTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    primaryColor: AppColors.lavenderSaturated,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.lavenderSaturated,
      secondary: AppColors.mintSaturated,
      background: AppColors.cream,
      surface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      titleTextStyle: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    ),
    textTheme: GoogleFonts.quicksandTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: AppColors.lavenderSaturated,
      ),
    ),
  );
}

class PastelCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  const PastelCard({
    required this.child,
    this.onTap,
    this.radius = 20,
    this.borderColor,
    super.key,
  });
  @override
  State<PastelCard> createState() => _PastelCardState();
}

class _PastelCardState extends State<PastelCard> {
  bool _hover = false;
  bool _press = false;
  @override
  Widget build(BuildContext context) {
    final r = widget.radius;
    final dy = _hover ? -1.5 : 0.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _press = true),
        onTapUp: (_) => setState(() => _press = false),
        onTapCancel: () => setState(() => _press = false),
        onTap: widget.onTap,
        child: Transform.translate(
          offset: Offset(0, dy),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(r),
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!, width: 1.2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.softShadow,
                  blurRadius: _hover ? 16 : 12,
                  offset: Offset(0, _hover ? 8 : 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class PastelChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const PastelChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: selected ? (Matrix4.identity()..translate(0, -1.5)) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(selected ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.18),
                    blurRadius: 12,
                    spreadRadius: 0.2,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.text,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AnimatedFillIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color fillColor;
  final Color iconColor;
  final double size;
  const AnimatedFillIcon({
    required this.icon,
    required this.selected,
    required this.fillColor,
    this.iconColor = Colors.white,
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: size + 18,
      height: size + 18,
      decoration: BoxDecoration(
        color: selected ? fillColor : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size,
        color: selected ? iconColor : AppColors.text.withOpacity(0.7),
      ),
    );
  }
}

class PastelButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  const PastelButton({
    required this.child,
    this.onPressed,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final g =
        gradient ??
        LinearGradient(
          colors: [AppColors.lavenderSaturated, AppColors.peachSaturated],
        );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : g,
        color: onPressed == null ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: AppColors.softShadow,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
