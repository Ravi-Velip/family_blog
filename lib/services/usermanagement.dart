import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'common.dart';

class UserManagement {

  storeNewUser(String name, user) async {
    try {
      return await Firestore.instance.collection('/users').add({
        'uid': user.uid,
        'name': name,
        'emailId': user.email,
        'avatar': user.photoUrl,
        'bio': null,
        'gender': null,
        'numberOfPosts' : 0,
        'createdOn': Timestamp.now()
      }).then((value) async {
        SharedPreferences _prefs = await SharedPreferences.getInstance();
        await _prefs.setString('userId', value.documentID);
        await _prefs.setString('uid', user.uid);
        await _prefs.setString('emailId', user.email);
        await _prefs.setString('avatar', user.photoUrl);
        await _prefs.setString('name', name);
        return await Common().getFinalResult(true, 'You\'ve been logged in successfully.');
      }).catchError((e) {
        throw e;
      });
    } catch(e) {
      return await Common().getFinalResult(false, 'ERROR: ${e.toString()}');
    }

  }

  signInWithGoogle() async {
    try{
      GoogleSignIn _googleSignIn = new GoogleSignIn();
      FirebaseAuth _auth = FirebaseAuth.instance;
      GoogleSignInAccount _googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication _googleAuth = await _googleUser.authentication;
      AuthCredential _credential = GoogleAuthProvider.getCredential(
        idToken: _googleAuth.idToken,
        accessToken: _googleAuth.accessToken,
      );
      FirebaseUser _user = await _auth.signInWithCredential(_credential);
      var _currentUser = await Firestore.instance.collection('users').where('uid', isEqualTo: _user.uid).getDocuments();
      if(_currentUser.documents.length == 0){
        var _getUser = await storeNewUser(_user.displayName, _user);
        if(!_getUser['key']) {
          throw _getUser['value'];
        }
      }
      return await Common().getFinalResult(true, 'You\'ve been logged in successfully.');
    } catch(e) {
      return await Common().getFinalResult(false, 'ERROR: ${e.toString()}');
    }
  }

  signUpWithEmail(String email, String password, String name) async {
    try{
      final FirebaseUser _createUserWithEmail = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      return await storeNewUser(name, _createUserWithEmail);
    } catch(e){
      return await Common().getFinalResult(false, 'ERROR: ${e.toString()}');
    }
  }

}