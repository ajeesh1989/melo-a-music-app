import 'package:flutter/material.dart';

class NeuBox extends StatelessWidget {
  final Widget child;

  const NeuBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isDark
                  ? [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.7),
                      offset: const Offset(5, 5),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(-5, -5),
                      blurRadius: 10,
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.grey.shade500,
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 15,
                      offset: Offset(-5, -5),
                    ),
                  ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
