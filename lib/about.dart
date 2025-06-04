import 'package:flutter/material.dart';
import 'package:retrowave/neos/neo_box.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white54 : Colors.black26;
    final fadedText = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: NeuBox(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.arrow_back, color: iconColor),
                      ),
                    ),
                  ),
                  Text(
                    'A B O U T',
                    style: TextStyle(
                      fontSize: 18,
                      letterSpacing: 2,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 50, width: 50),
                ],
              ),
              const SizedBox(height: 30),

              // Emotional Description
              Text(
                '''MELO isn't just a music app.  
It’s a quiet space in a noisy world.

A place where melodies meet memories,  
and every beat feels personal.

Crafted for those who find comfort in sound,  
for the ones who hum in silence,  
and for hearts that dance to their own rhythm.

Offline. Effortless. Intimate.  
From favorites that feel like home,  
to gentle sleep timers that say goodnight —  
MELO stays with you.

Built with love,  
shaped by rhythm,  
and made for souls like yours.  

— aj_labs 💫''',
                style: TextStyle(fontSize: 16, height: 1.65, color: fadedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
