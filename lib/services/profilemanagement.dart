import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'common.dart';
import 'dart:io';
import 'package:image/image.dart' as Im;

class ProfileManagement {

  updateProfile(Map<String, String> userDoc, String userId, {File avatar}) async {
    try{
      if(avatar != null) {
        File _imageFile = avatar;
        var _uid = new Uuid();
        DocumentSnapshot _user = await Firestore.instance.collection('users').document(userId).get(); // Pass in to deleting the image.
        String _imageType = _imageFile.path.substring(_imageFile.path.lastIndexOf('.'), _imageFile.path.length);
        String _imageFileName = _uid.v1() + _imageType;
        FirebaseStorage _storage = FirebaseStorage.instance;
        StorageReference _reference = _storage.ref().child('$userId/profileAvatar/$_imageFileName');
        StorageUploadTask _uploadTask = _reference.putFile(_imageFile);

//        Im.Image _image =

        await _uploadTask.onComplete.then((val) async {
          userDoc['avatar'] = await val.ref.getDownloadURL();
          userDoc['avatarStoragePath'] = await val.ref.getPath();
          await Firestore.instance.collection('users').document(userId).updateData(userDoc);
        }).then((value) async {
          // Deleting old profile avatar and updating family members collection.
          if(_user['avatarStoragePath'] != null) {
            try{
              updateFamilyMember(userId, avatar: userDoc['avatar'], name: userDoc['name'] != null ? userDoc['name'] : null);
            }
            catch(e){
              print('Error in updating family members collection: ' + e.toString());
            }
            try{
              await _storage.ref().child(_user['avatarStoragePath']).delete();
            }
            catch(e){
              print('Error in deleting profile image: ' + e.toString());
            }
          }
        });
      }
      else {
        await Firestore.instance.collection('users').document(userId).updateData(userDoc).then((value) {
          if(userDoc['name'] != null) {
            try {
              updateFamilyMember(userId, name: userDoc['name']);
            }
            catch(e) {
              print('Error in updating family members collection: ' + e.toString());
            }
          }
        });
      }
      return await Common().getFinalResult(true, 'Profile has been updated successfully.');
    }
    catch(e) {
      print(e);
      return await Common().getFinalResult(false, e.toString());
    }
  }

  updateFamilyMember(String userId, {String name, String avatar}) async {
    QuerySnapshot _families = await Firestore.instance.collection('families')
        .where('memberIds', arrayContains: userId).getDocuments();

    for (int i=0; i<_families.documents.length; i++) {
      QuerySnapshot _members = await Firestore.instance.collection('families')
          .document(_families.documents[i].documentID).collection('members').where('userId', isEqualTo: userId).getDocuments();

      if(_members.documents.length > 0) {
        DocumentReference _memberDocReference =  _members.documents[0].reference;
        _memberDocReference.updateData({
          'name': name != null ? name : _members.documents[0].data['name'],
          'avatar': avatar != null ? avatar : _members.documents[0].data['avatar'],
        });
      }
    }
  }

}