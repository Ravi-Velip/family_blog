import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Common {

  getFinalResult(bool key, value) {
    var _identifier = new Map();
    _identifier['key'] = key;
    _identifier['value'] = value;
    return _identifier;
  }

  validateEmail(String email) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if(!regex.hasMatch(email)) return true; else return false;
  }

  getLoggedInUser() async => await FirebaseAuth.instance.currentUser();

  updateSharedPreference() async {
    try{
      var loggedInUser = await FirebaseAuth.instance.currentUser();
      var user = await Firestore.instance.collection('users').where('uid', isEqualTo: loggedInUser.uid).getDocuments();
      SharedPreferences _prefs = await SharedPreferences.getInstance();
      await _prefs.setString('userId', user.documents[0].documentID);
      await _prefs.setString('avatar', user.documents[0].data['avatar']);
      await _prefs.setString('name', user.documents[0].data['name']);
      await _prefs.setString('uid', user.documents[0].data['uid']);
      await _prefs.setString('emailId', user.documents[0].data['emailId']);
      await _prefs.setString('bio', user.documents[0].data['bio']);
      await _prefs.setString('gender', user.documents[0].data['gender']);
    }
    catch(e){
      print(e.toString());
    }

  }

}

