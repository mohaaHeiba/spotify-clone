import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/loginandregister/LoginScreen.dart';
import 'package:music_app/navigationbar/Tabbar.dart';
import 'package:music_app/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBxTkW5H_YcHmB4keyg3xPAnnrzotg2jY4",
      appId: "1:968611689726:android:0cacf8c2c1edf6af2461af",
      messagingSenderId: "968611689726",
      projectId: "musicapp-86300",
    ),
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_app.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      child: MaterialApp(
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          scaffoldBackgroundColor: Colors.black,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black38,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(fontSize: 16),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
            ),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white38,
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return Tabbar();
        }

        return LoginScreen();
      },
    );
  }
}
