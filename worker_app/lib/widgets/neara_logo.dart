import 'package:flutter/material.dart';

class NearaLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool showText;
  final double? fontSize;
  
  const NearaLogo({
    super.key,
    this.width = 120,
    this.height = 120,
    this.color,
    this.showText = false,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/neara_logo.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
          color: color, // Tint the logo if color is provided
          colorBlendMode: color != null ? BlendMode.srcIn : null,
          errorBuilder: (context, error, stackTrace) {
            // Fallback UI if logo image fails to load
            return Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)], // Worker app orange theme
                ),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'NEARA',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
              letterSpacing: 2.0,
            ),
          ),
          Text(
            'WORKER',
            style: TextStyle(
              fontSize: (fontSize ?? 24) * 0.6,
              fontWeight: FontWeight.w600,
              color: (color ?? Theme.of(context).primaryColor).withOpacity(0.8),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact logo for app bars and small spaces
class NearaLogoCompact extends StatelessWidget {
  final double size;
  final Color? color;
  
  const NearaLogoCompact({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NearaLogo(
      width: size,
      height: size,
      color: color,
      showText: false,
    );
  }
}

/// Large logo for splash screens and onboarding
class NearaLogoBrand extends StatelessWidget {
  final Color? color;
  
  const NearaLogoBrand({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NearaLogo(
      width: 200,
      height: 200,
      color: color,
      showText: true,
      fontSize: 32,
    );
  }
}
