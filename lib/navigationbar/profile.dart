import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profile extends StatefulWidget {
  final VoidCallback onUpdate;

  const Profile({super.key, required this.onUpdate});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  String _displayName = '';

  Future<void> _updateProfile() async {
    try {
      String newName = _nameController.text.trim();
      User? user = _auth.currentUser;

      if (user == null) {
        throw Exception("No user is signed in.");
      }

      // Validate fields
      if (newName.isEmpty) {
        throw Exception('Name cannot be empty');
      }

      // Update name if changed
      if (newName != user.displayName) {
        await user.updateDisplayName(newName);
        setState(() {
          _displayName = newName;
        });

        // Firestore update for name
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName});

        widget.onUpdate();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        title:
            const Text("Profile", style: TextStyle(color: Color(0xFFEEEEEE))),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
          color: Color(0xFFEEEEEE),
        ),
      ),
      backgroundColor: const Color(0xFF121212),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          User? user = snapshot.data;
          Future.microtask(() {
            _nameController.text = user?.displayName ?? '';
            if (_displayName.isEmpty) {
              setState(() {
                _displayName = user?.displayName ?? 'No name set';
              });
            }
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Profile Information",
                  style: TextStyle(
                    color: Color(0xFFEEEEEE),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Name Field Row
                _buildFieldRow(
                  label: "Name",
                  value: _displayName,
                  icon: Icons.person,
                  onPressed: () {
                    _showUpdateDialog(
                      context,
                      title: "Update Name",
                      controller: _nameController,
                      onSave: () async {
                        await _updateProfile();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Email Field Row
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 29, 29, 29),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Color(0xFFEEEEEE)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Email",
                            style: TextStyle(color: Color(0xFF76ABAE)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No email set',
                            style: const TextStyle(color: Color(0xFFEEEEEE)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 29, 29),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFEEEEEE)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF76ABAE))),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Color(0xFFEEEEEE))),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFEEEEEE)),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: const Color.fromARGB(255, 29, 29, 29),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFEEEEEE),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style:
                    const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                decoration: InputDecoration(
                  labelText: "Value",
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 41, 41, 41),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 54, 54),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                child: const Text("Save",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}
