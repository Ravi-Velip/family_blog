import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/postsmanagement.dart';
import 'homepage.dart';

var familyIds = new Map();
//Map selectedFamilies = {};
List selectedFamilies = new List();

class CustomCheckBoxTile extends StatefulWidget {
  final DocumentSnapshot doc;

  CustomCheckBoxTile({
    Key key,
    @required this.doc,
  }) : super(key: key);

  @override
  _CustomCheckBoxTileState createState() => _CustomCheckBoxTileState(doc);
}

class _CustomCheckBoxTileState extends State<CustomCheckBoxTile> {
  DocumentSnapshot _doc;

  _CustomCheckBoxTileState(this._doc);

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: familyIds[_doc.documentID.toString()],
      title: Text(_doc['familyName']),
      activeColor: Colors.green,
      onChanged: (bool value) {
        setState(() {
          familyIds[_doc.documentID.toString()] = value;
          if (familyIds[_doc.documentID.toString()]) {
            selectedFamilyList(_doc.documentID, true);
          } else {
            selectedFamilyList(_doc.documentID, false);
          }
        });
      },
    );
  }

  selectedFamilyList(String familyId, bool addFamily) {
    if (addFamily) {
      selectedFamilies.add(familyId);
    } else {
      selectedFamilies.remove(familyId);
    }
  }
}

class CreatePost extends StatefulWidget {
  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  List<Asset> images = List<Asset>();
  int _crossAxisCount = 3;
  String _error = '';
  String _postText;
  String _userId;
  bool _absorbValue = false;
  bool _isTagError = false;
  bool _noFamily = false;
  QuerySnapshot _families;
  var _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = new TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _getSharePrefs();
    familyIds.clear();
    selectedFamilies.clear();
    super.initState();
  }

  _getSharePrefs() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = _prefs.get('userId');
    });
    _getFamilies();
  }

  _getFamilies() async {
    _families = await Firestore.instance
        .collection('families')
        .where('memberIds', arrayContains: _userId)
        .getDocuments();
    setState(() {
      if (_families.documents.length == 0) {
        _noFamily = true;
      }
    });
  }

  _displaySnackBar(Map content) {
    final snackBar = SnackBar(
      content: Text(content['value']),
      backgroundColor: content['key'] ? Colors.green : Colors.red,
      duration: Duration(seconds: 2),
    );
    setState(() {
      images = List<Asset>();
      _postText = '';
      _controller.clear();
      _absorbValue = false;
    });
    _scaffoldKey.currentState.showSnackBar(snackBar).closed.then((val) {
      Navigator.push(_scaffoldKey.currentContext,
          new MaterialPageRoute(builder: (context) => new HomePage()));
    });
  }

  Future<void> _familyList() async {
    return showDialog<void>(
        context: _scaffoldKey.currentContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Select the families which you want to share your post.',
              style: TextStyle(fontSize: 15),
            ),
            content: StreamBuilder(
                stream: Firestore.instance
                    .collection('families')
                    .where('memberIds', arrayContains: _userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Container(
                      alignment: Alignment(0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          RefreshProgressIndicator(),
                          SizedBox(
                            height: 10,
                          ),
                          Text('LOADING...'),
                        ],
                      ),
                    );
                  if (snapshot.hasError)
                    return const Text('Error in receving data.');

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(1.0),
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: ((context, index) {
                      if (snapshot.data.documents.length > 0) {
                        print('LENGTH: ' +
                            snapshot.data.documents.length.toString());
                        if (!familyIds.containsKey(
                            snapshot.data.documents[index].documentID)) {
                          familyIds[snapshot.data.documents[index].documentID] =
                              false;
                        }
                        return CustomCheckBoxTile(
                            doc: snapshot.data.documents[index]);
                      }
                    }),
                  );
                }),
            actions: <Widget>[
              FlatButton(
                color: Colors.blue,
                shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(2.0)),
                textColor: Colors.white,
                child: Text('Done'),
                onPressed: () {
                  setState(() {
                    Navigator.of(context).pop();
                  });
                },
              ),
            ],
          );
        }).then((_) {
      setState(() {
        _isTagError = false;
        selectedFamilies = selectedFamilies;
      });
    });
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: _crossAxisCount,
      primary: true,
      crossAxisSpacing: 1,
      mainAxisSpacing: 0,
      shrinkWrap: true,
      physics: ScrollPhysics(),
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return AssetThumb(
          asset: asset,
          width: 400,
          height: 400,
        );
      }),
    );
  }

  Future<void> deleteAssets() async {
//    await MultiImagePicker.deleteImages(assets: images);
    setState(() {
      images = List<Asset>();
    });
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();
    String error = '';

    try {
      resultList = await MultiImagePicker.pickImages(
          maxImages: 12,
          enableCamera: true,
          selectedAssets: images,
          cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
          materialOptions: MaterialOptions(
            actionBarColor: '#008080',
            actionBarTitle: "Select photos",
            allViewTitle: "All Photos",
            selectCircleStrokeColor: "#adfd20",
            selectionLimitReachedText: "You can't select any more images.",
          ));
    } on PlatformException catch (e) {
      error = e.message;
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      _error = error;
      if (images.length == 1) _crossAxisCount = 1;
      if (images.length == 2 || images.length == 3 || images.length == 4)
        _crossAxisCount = 2;
      if (images.length > 4) _crossAxisCount = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'PTSans',
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text('Create Post'),
          actions: <Widget>[
            _noFamily
                ? SizedBox()
                : AbsorbPointer(
                    absorbing: _absorbValue,
                    child: IconButton(
                      splashColor: Colors.tealAccent,
                      icon: Icon(
                        Icons.add_photo_alternate,
                        color: _absorbValue
                            ? Colors.white70
                            : Colors.lightGreenAccent,
                      ),
                      onPressed: () {
                        loadAssets();
                      },
                    ),
                  ),
            images.length > 0
                ? AbsorbPointer(
                    absorbing: _absorbValue,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        alignment: Alignment(0, 0),
                        child: InkWell(
                          child: Text('SAVE'),
                          onTap: () async {
                            if (_formKey.currentState.validate() &&
                                selectedFamilies.length > 0) {
                              setState(() {
                                _absorbValue = true;
                              });
                              FocusScope.of(context).unfocus();
                              var _createPosts = await PostsManagement()
                                  .saveImage(images, _postText, _userId,
                                      selectedFamilies);
                              _displaySnackBar(_createPosts);
                            } else {
                              setState(() {
                                _isTagError = true;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  )
//                 AbsorbPointer(
//                    absorbing: _absorbValue,
//                    child: IconButton(
//                      splashColor: Colors.tealAccent,
//                      icon: Icon(
//                        Icons.delete,
//                        color: _absorbValue ? Colors.white70 : Colors.redAccent,
//                      ),
//                      onPressed: () {
//                        deleteAssets();
//                      },
//                    ),
//                  )
                : Container(),
          ],
        ),
        body: !_absorbValue
            ? GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: images.length == 0 || _noFamily
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(20.0),
                          child: _noFamily
                              ? Text(
                                  'You cannot create any posts because you\'re not part of any family',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54))
                              : Text(
                                  'No images selected. Please select the images you want to upload by '
                                  'clicking on the image add icon from the top-right corner of the screen.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: _error != ''
                            ? Center(
                                child: Text(
                                  'ERROR: $_error',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                              )
                            : ListView(
                                children: <Widget>[
                                  buildGridView(),
                                  Divider(
                                    color: Colors.grey,
                                  ),
                                  AbsorbPointer(
                                    absorbing: _absorbValue,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.only(right: 10, left: 10),
                                      child: TextFormField(
                                          controller: _controller,
                                          maxLength: 500,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Write something about this post',
                                            counterText: '',
                                            border: InputBorder.none,
                                          ),
                                          validator: (value) {
                                            if (value == '')
                                              return 'Error: Please write something about your post';
                                            setState(() {
                                              _postText = value;
                                            });
                                          }),
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.grey,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        InkWell(
                                          child: Text(
                                            'Tag family',
                                            style:
                                                TextStyle(color: Colors.blue),
                                          ),
                                          onTap: () {
                                            _familyList();
                                          },
                                        ),
                                        Text(
                                            '${selectedFamilies.length} family selected'),
                                      ],
                                    ),
                                  ),
                                  _isTagError
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 10),
                                          child: Text(
                                            'Error: Please select atleast one family',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red),
                                          ),
                                        )
                                      : SizedBox(),
                                  Divider(
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                      ),
              )
            : Center(
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                        width: 50.0,
                        height: 50.0,
                      ),
                      SizedBox(height: 20),
                      Text('Please wait while we create your post.'),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
