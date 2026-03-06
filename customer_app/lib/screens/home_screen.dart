import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/voice_hero_card.dart';
import '../widgets/sos_card.dart';
import '../widgets/quick_services_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16),
                HomeHeader(),
                SizedBox(height: 32),
                VoiceHeroCard(),
                SizedBox(height: 32),
                SosCard(),
                SizedBox(height: 32),
                QuickServicesList(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
