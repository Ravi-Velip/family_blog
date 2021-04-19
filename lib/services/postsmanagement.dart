import 'package:firebase_storage/firebase_storage.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostsManagement {

  getFinalResult(bool key, value) {
    var _identifier = new Map();
    _identifier['key'] = key;
    _identifier['value'] = value;
    return _identifier;
  }

  Future saveImage(List<Asset> asset, String postsText, String userId, List families) async {

    List<Map> _imageMetaData = [];

    try{
      var _uid = new Uuid();
      String _imageType;
      String _imageFileName;
      for(Asset _image in asset) {
        _imageType = _image.name.substring(_image.name.lastIndexOf('.'), _image.name.length);
        _imageFileName = userId + '/postImages/' + _uid.v1() + _imageType;
        ByteData _byteData = await _image.requestOriginal(quality: 80);
        List<int> _imageData = _byteData.buffer.asUint8List();
        StorageReference _ref = FirebaseStorage.instance.ref().child(_imageFileName);
        StorageUploadTask _uploadTask = _ref.putData(_imageData);

        await _uploadTask.onComplete.then((val) async {
          String _name = await val.ref.getName();
          String _path = await val.ref.getPath();
          String _downloadUrl = await val.ref.getDownloadURL();

          _imageMetaData.add({
            'name': _name,
            'path': _path,
            'downloadUrl': _downloadUrl
          });

        }).catchError((e) {
          throw e.toString();
        });
      }
      return await createPosts(_imageMetaData, postsText, userId, families);
    }catch(e){
      return await getFinalResult(false, e.toString());
    }
  }

  Future createPosts(List<Map> imageMetaData, String postText, String userId, List families) async {
    try {
      return await Firestore.instance.collection('/posts').add({
        'userId': userId,
        'postText': postText,
        'families': families,
        'imageMetaData': imageMetaData,
        'createdOn': Timestamp.now()
      }).then((val) async {
        return await getFinalResult(true, 'Your post has been created successfully.');
      }).catchError((e){
        print('NOTE: YOU\'VE DELETE ALL THE IMAGES INSERTED IN FIREBASE');
        throw e.toString();
      });
    } catch(e) {
      return await getFinalResult(false, e.toString());
    }
  }

  Future deleteImage() async {

    String _imageURL = 'https://firebasestorage.googleapis.com/v0/b/familyblog-5de3e.appspot.com/o/IMG_20190428_214536.jpg?alt=media&token=9af2c308-8ff2-4e3d-8051-69ea3b6328d2';
    StorageReference _ref = FirebaseStorage.instance.ref().child('/familyBlogImages.jpg');
    _ref.delete();

//    I/flutter (10191): /IMG_20190428_200402.jpg
//    I/flutter (10191): IMG_20190428_200402.jpg
//    I/flutter (10191): familyblog-5de3e.appspot.com

  }

}
