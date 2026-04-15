import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static String? ipaddress;

  void newAddress(String ndata) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ndata);

    setState(() {
      ipaddress = (prefs.getString('ip'));
    });
  }

  _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ipaddress = (prefs.getString('ip'));
    });
  }

  @override
  Widget build(BuildContext context) {
    _getAddress();
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text('Settings'),
        //overide default back arrow to return data
        leading: IconButton(
          padding: const EdgeInsets.symmetric(),
          icon: const Icon(
            Icons.arrow_back,
            size: 48.0,
          ),
          onPressed: () => Navigator.pop(context, ipaddress),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            TextField(
              decoration: InputDecoration(
                fillColor: Colors.grey[500],
                filled: true,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                border: const OutlineInputBorder(),
                hintText: 'Enter new Bot IP',
              ),
              textAlign: TextAlign.center,
              onChanged: (String data) {
                newAddress(data);
              },
            ),
            const SizedBox(
              height: 2.0,
            ),
            Text(
              'Current Bot IP: $ipaddress',
              style: const TextStyle(
                fontSize: 20.0,
                color: Colors.white,
              ),
            ),
            const Text(
              'PORT: 5005',
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.white,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
