import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'services/profilemanagement.dart';

class Profile extends StatefulWidget {
  final Map doc;
  Profile({Key key, @required this.doc}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState(doc);
}

class _ProfileState extends State<Profile> {

  String _gender;
  File _imageFile;
  bool _isLocalImage = false;
  bool _isUpdating = false;
  Map<String, String> _updatedDoc = new Map();
  Map _doc;
  var _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  _ProfileState(this._doc);

  @override
  void initState() {
//    _getUser();
  print(_doc['userId']);
    super.initState();
  }

  _displaySnackBar(Map content) {
    final snackBar = SnackBar(
      duration: Duration(seconds: 3),
      content: Text(content['value'], style: TextStyle(color: Colors.white),),
      backgroundColor: content['key'] ? Colors.green : Colors.red,);
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Widget showImage() {
    return Container(
      margin: EdgeInsets.only(left: 70, right: 70),
      child: CircleAvatar(
        maxRadius: 90,
        minRadius: 90,
        backgroundImage: FileImage(_imageFile)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Profile'),
        actions: <Widget>[
          _isUpdating
          ? CircularProgressIndicator()
          : IconButton(
              icon: Icon(
                Icons.save,
                color: Colors.white,
              ),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                if (_formKey.currentState.validate()) {
                  if (_updatedDoc.isEmpty && _imageFile == null) {
                    _displaySnackBar({'key': true, 'value': 'Your profile is up to date.'});
                  }
                  print(_updatedDoc.length.toString() + _imageFile.toString() + _updatedDoc.toString());
                  if(_updatedDoc.length != 0 || _imageFile != null) {
                    _isUpdating = true;
                    var _updateProfile = await ProfileManagement().updateProfile(_updatedDoc, _doc['userId'], avatar: _imageFile);
                    setState(() {
                      if(_updateProfile['key']) {
                        print('clearing fields');
                        _isLocalImage = false;
                        _updatedDoc.clear();
                        _imageFile = null;
                      }
                      _isUpdating = false;
                    });
                    _displaySnackBar(_updateProfile);
                  }
                }
              }
            ),
        ],
      ),
      body: StreamBuilder(
        stream: Firestore.instance.collection('users').document(_doc['userId']).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
          return Container(
            alignment: Alignment(0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RefreshProgressIndicator(),
                SizedBox(height: 10,),
                Text('LOADING...'),
              ],
            ),
          );
          if (snapshot.hasError) return const Text('Error in receving data.');
          if (snapshot.hasData){
            return Center(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(20.0),
                    children: <Widget>[
                      _isLocalImage
                          ? showImage()
                          : Container(
                        margin: EdgeInsets.only(left: 70, right: 70),
                        child: CircleAvatar(
                          backgroundImage: snapshot.data['avatar'] != null
                              ? NetworkImage(snapshot.data['avatar'])
                              : AssetImage('assets/personIcon.png'),
                          minRadius: 90,
                          maxRadius: 90,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Center(
                        child: InkWell(
                          child: Text(
                            'Update profile image',
                            style: TextStyle(color: Colors.lightBlue),
                          ),
                          onTap: () async {
                            showDialog(
                                context: context,
                                builder: (_) {
                                  return Dialog(
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: <Widget>[
                                        ListTile(
                                          title: Text('Take a picture'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            _imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
                                            if(_imageFile != null) {
                                              Navigator.pop(context);
                                              setState(() {
                                                _isLocalImage = true;
                                              });
                                            }
                                          },
                                        ),
                                        Divider(
                                          color: Colors.grey,
                                        ),
                                        ListTile(
                                          title: Text('Select image from gallery'),
                                          onTap: () async {
                                            _imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
                                            if(_imageFile != null) {
                                              Navigator.pop(context);
                                              setState(() {
                                                  _isLocalImage = true;
                                              });
                                            }
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Name'),
                        initialValue: snapshot.data['name'],
                        validator: (value) {
                          if(value.isEmpty) return 'Please enter your name';
                          setState(() {
                            if(value != snapshot.data['name']) {
                              _updatedDoc['name'] = value;
                            }
                            else {
                              _updatedDoc.remove('name');
                            }
                          });
                        },
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'E-mail'),
                        initialValue: snapshot.data['emailId'],
                        enabled: false,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Bio'),
                        initialValue: snapshot.data['bio'],
                        validator: (value) {
//                          if(snapshot.data['bio'] == null) snapshot.data['bio'] = '';
                          setState(() {
                            if(value != snapshot.data['bio']) {
                              _updatedDoc['bio'] = value;
                            }
                            else {
                              _updatedDoc.remove('bio');
                            }
                          });
                        },
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      DropdownButton<String>(
                        items: <String>['Male', 'Female'].map((String value) {
                          return new DropdownMenuItem<String>(
                            value: value,
                            child: new Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                            print(_gender);
                            if(value != snapshot.data['gender']) {
                              _updatedDoc['gender'] = value;
                            }
                            else{
                              _updatedDoc.remove('gender');
                            }
                          });
                        },
                        hint: Text(snapshot.data['gender'] != null ? snapshot.data['gender'] : 'Gender'),
                        value: _gender,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          else return Container(child: Text('Loading'),);
        }
      ),
//      body: Center(
//        child: _user == null
//            ? CircularProgressIndicator(backgroundColor: Colors.white,)
//            : GestureDetector(
//                onTap: () {
//                  FocusScope.of(context).detach();
//                },
//                child: Form(
//                key: _formKey,
//                child: ListView(
//                  padding: EdgeInsets.all(20.0),
//                  children: <Widget>[
//                    _isLocalImage
//                        ? showImage()
//                        : Container(
//                          margin: EdgeInsets.only(left: 70, right: 70),
//                          child: CircleAvatar(
//                            backgroundImage: _user.data['avatar'] != null
//                            ? NetworkImage(_user.data['avatar'])
//                            : AssetImage('assets/personIcon.png'),
//                            minRadius: 90,
//                            maxRadius: 90,
//                          ),
//                    ),
//                    SizedBox(
//                      height: 10,
//                    ),
//                    Center(
//                      child: InkWell(
//                        child: Text(
//                          'Update profile image',
//                          style: TextStyle(color: Colors.lightBlue),
//                        ),
//                        onTap: () async {
//                          showDialog(
//                              context: context,
//                              builder: (_) {
//                                return Dialog(
//                                  child: ListView(
//                                    shrinkWrap: true,
//                                    children: <Widget>[
//                                      ListTile(
//                                        title: Text('Take a picture'),
//                                        onTap: () async {
//                                          Navigator.pop(context);
//                                          _imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
//                                          setState(() {
//                                            if(_imageFile != null) {
//                                              _isLocalImage = true;
//                                            }
//                                          });
//                                        },
//                                      ),
//                                      Divider(
//                                        color: Colors.grey,
//                                      ),
//                                      ListTile(
//                                        title: Text('Select image from gallery'),
//                                        onTap: () async {
//                                          Navigator.pop(context);
//                                          _imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
//                                          setState(() {
//                                            if(_imageFile != null) {
//                                              _isLocalImage = true;
//                                            }
//                                          });
//                                        },
//                                      )
//                                    ],
//                                  ),
//                                );
//                              });
//                        },
//                      ),
//                    ),
//                    SizedBox(
//                      height: 20,
//                    ),
//                    TextFormField(
//                      decoration: InputDecoration(labelText: 'Name'),
//                      initialValue: _user.data['name'],
//                      validator: (value) {
//                        if(value.isEmpty) return 'Please enter your name';
//                        setState(() {
//                          if(value != _user.data['name']) {
//                            _updatedDoc['name'] = value;
//                          }
//                          else {
//                            _updatedDoc.remove('name');
//                          }
//                        });
//                      },
//                    ),
//                    SizedBox(
//                      height: 20,
//                    ),
//                    TextFormField(
//                      decoration: InputDecoration(labelText: 'E-mail'),
//                      initialValue: _user.data['emailId'],
//                      enabled: false,
//                    ),
//                    SizedBox(
//                      height: 20,
//                    ),
//                    TextFormField(
//                      decoration: InputDecoration(labelText: 'Bio'),
//                      initialValue: _user.data['bio'],
//                      validator: (value) {
//                        if(_user.data['bio'] == null) _user.data['bio'] = '';
//                        setState(() {
//                          if(value != _user.data['bio']) {
//                            _updatedDoc['bio'] = value;
//                          }
//                          else {
//                            _updatedDoc.remove('bio');
//                          }
//                        });
//                      },
//                    ),
//                    SizedBox(
//                      height: 30,
//                    ),
//                    DropdownButton<String>(
//                      items: <String>['Male', 'Female'].map((String value) {
//                        return new DropdownMenuItem<String>(
//                          value: value,
//                          child: new Text(value),
//                        );
//                      }).toList(),
//                      onChanged: (value) {
//                        setState(() {
//                          _gender = value;
//                          if(value != _user.data['gender']) {
//                            _updatedDoc['gender'] = value;
//                          }
//                          else{
//                            _updatedDoc.remove('gender');
//                          }
//                        });
//                      },
//                      hint: Text('Gender'),
//                      value: _gender,
//                    ),
//                  ],
//                ),
//              ),
//        ),
//      ),
    );
  }
}
