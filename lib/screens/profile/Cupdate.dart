import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Define the Chef class if it's not yet defined
class Chef {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;

  Chef({required this.uid, required this.name, required this.email, required this.phoneNumber});
}

class CProfileManagement extends StatefulWidget {
  @override
  _CProfileManagementState createState() => _CProfileManagementState();
}

class _CProfileManagementState extends State<CProfileManagement> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();

  User? user; // Change from Chef to User
  final TextEditingController chefNameController = TextEditingController();
  final TextEditingController chefEmailController = TextEditingController();
  final TextEditingController chefPhoneController = TextEditingController();
  String selectedAddress = '';

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser; // Use currentUser instead
    if (user != null) {
      _fetchChefData();
    }
  }

  Future<void> _fetchChefData() async {
    final chefSnapshot = await _database.child('chefs').child(user!.uid).once();
    final chefData = chefSnapshot.snapshot.value as Map<dynamic, dynamic>;

    setState(() {
      chefNameController.text = chefData['name'] ?? '';
      chefEmailController.text = chefData['email'] ?? '';
      chefPhoneController.text = chefData['phoneNumber'] ?? '';
      selectedAddress = chefData['address'] ?? '';
    });
  }

  bool _validateInputs() {
    if (chefNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name cannot be empty.')));
      return false;
    }
    if (chefPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone number cannot be empty.')));
      return false;
    }
    if (!RegExp(r'^(9|7)\d{7}$').hasMatch(chefPhoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone number must start with 9 or 7 and be 8 digits long.')));
      return false;
    }
    if (selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an address.')));
      return false;
    }
    return true;
  }

  Future<void> _updateChefData() async {
    if (user != null && _validateInputs()) {
      await _database.child('chefs').child(user!.uid).update({
        'name': chefNameController.text,
        'email': chefEmailController.text,
        'phoneNumber': chefPhoneController.text,
        'address': selectedAddress,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _showForgotPasswordDialog() {
    TextEditingController resetEmailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Reset Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: resetEmailController,
                  decoration: InputDecoration(hintText: "Enter your email", enabled: !isLoading),
                ),
                if (isLoading)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  String email = resetEmailController.text.trim();
                  if (email.isNotEmpty) {
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      await _auth.sendPasswordResetEmail(email: email);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset email sent!')));
                    } on FirebaseAuthException catch (e) {
                      String errorMessage = 'Failed to send reset email';
                      if (e.code == 'user-not-found') {
                        errorMessage = 'No account found with this email.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter your email')));
                  }
                },
                child: Text("Send"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile Management'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chef Name', style: TextStyle(fontSize: 16)),
                TextField(
                  controller: chefNameController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                Text('Email', style: TextStyle(fontSize: 16)),
                TextField(
                  controller: chefEmailController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  readOnly: true,
                ),
                SizedBox(height: 16),
                Text('Phone Number', style: TextStyle(fontSize: 16)),
                TextField(
                  controller: chefPhoneController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                Text('Address', style: TextStyle(fontSize: 16)),
                DropdownButtonFormField<String>(
                  value: selectedAddress.isNotEmpty ? selectedAddress : null,
                  hint: Text('Select Address'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAddress = newValue!;
                    });
                  },
                  items: <String>[
                    'Muscat',
                    'Rustaq',
                    'Sohar',
                    'Sur',
                    'Nizwa',
                    'Salalah',
                    'Bahla',
                    'Ibri',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _updateChefData,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.purple),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      shadowColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.3)),
                      elevation: MaterialStateProperty.all(5),
                    ),
                    child: Container(
                      width: 200,
                      child: Text(
                        "Update Profile",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _showForgotPasswordDialog,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.grey),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      shadowColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.3)),
                      elevation: MaterialStateProperty.all(5),
                    ),
                    child: Container(
                      width: 200,
                      child: Text(
                        "Reset Password",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

