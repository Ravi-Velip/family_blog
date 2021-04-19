import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings Page'),
        leading: Container(),
        centerTitle: true,
      ),
      body: Center(
        child: RaisedButton(
          onPressed: (){
            Navigator.of(context).pushNamed('/profilepage');
          },
          child: Text('ProfilePage'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}









/*

return Container(
      child: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.of(context).pushNamed('/profilepage');
            },
          ),
          Divider(
            color: Colors.tealAccent,
            height: 0.0,
          ),
          ListTile(
            leading: Icon(Icons.power_settings_new),
            title: Text('Sign Out'),
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                Navigator.of(context).pushReplacementNamed('/landingpage');
              }).catchError((e) {
                print(e);
              });
            },
          ),
        ],
      ),
    );


 */