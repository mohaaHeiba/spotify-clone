import 'package:flutter/material.dart';
import 'package:music_app/navigationbar/Tabbar.dart';
import 'package:music_app/navigationbar/profile.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onUpdate;

  const SettingsPage({super.key, required this.onUpdate});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        title:
            const Text("Settings", style: TextStyle(color: Color(0xFFEEEEEE))),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => Tabbar()));
          },
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEEEEEE)),
        ),
      ),
      backgroundColor: const Color(0xFF121212),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SectionTitle(title: "Account"),
          SettingsTile(
            icon: Icons.person,
            title: "Profile",
            subtitle: "View and edit your profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Profile(
                    onUpdate: widget.onUpdate,
                  ),
                ),
              );
            },
          ),
          const Divider(color: Color(0xFFEEEEEE)),
          const SectionTitle(title: "About"),
          const SettingsTile(
            icon: Icons.info,
            title: "App Version",
            subtitle: "1.0.0",
            onTap: null,
          ),
          SettingsTile(
            icon: Icons.privacy_tip,
            title: "Privacy Policy",
            subtitle: "Read our privacy policy",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFEEEEEE),
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFEEEEEE)),
      title: Text(
        title,
        style: const TextStyle(
            color: Color(0xFFEEEEEE), fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF76ABAE)),
      ),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_forward_ios,
          color: Color(0xFFEEEEEE), size: 16),
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }
}
