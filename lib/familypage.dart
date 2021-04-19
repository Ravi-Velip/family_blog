import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/familymanagement.dart';
import 'dashboard.dart';
import 'familydetailspage.dart';


class Family extends StatefulWidget {
  @override
  _FamilyState createState() => _FamilyState();

}

class _FamilyState extends State<Family> {

  Map _sharedPrefs = new Map();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _createFamily = new Map();
  String _userId;
  String _familyName;
  bool _isProcessing = false;

  initState() {
    super.initState();
    _getSharedPreferences();
  }

  _getSharedPreferences() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    for(var prefs in _prefs.getKeys()){
      _sharedPrefs[prefs] = await _prefs.get(prefs);
    }
    setState(() {
      _userId = _sharedPrefs['userId'].toString();
    });
  }

  _displaySnackBar(Map content) {
    final snackBar = SnackBar(
      duration: Duration(seconds: 3),
      content: Text(content['value'], style: TextStyle(color: Colors.white),),
      backgroundColor: content['key'] ? Colors.green : Colors.red,);
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future<void> _createNewFamily() async {
    var _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create a family'),
          content: Container(
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          decoration: InputDecoration(hintText: 'Family name'),
                          focusNode: FocusNode(),
                          validator: (String value) {
                            if (value.isEmpty) {
                              return 'Please enter your family name.';
                            }
                            setState(() {
                              _familyName = value;
                            });
                          },
                        ),
                        SizedBox(height: 10.0),
                        _createFamily['key'] == false
                          ? Text(_createFamily['value'],
                            style: TextStyle(color: Colors.red, fontSize: 12.0),
                            textDirection: TextDirection.ltr,
                          )
                          : SizedBox(),
                        SizedBox(height: 10.0),
                        _isProcessing
                          ? CircularProgressIndicator(
                            backgroundColor: Colors.blue,
                            semanticsLabel: 'LOADING...',
                          )
                          : SizedBox(),
                        SizedBox(height: 10.0),
                        _isProcessing
                          ? SizedBox()
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              FlatButton(
                                color: Colors.blue,
                                shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.circular(2.0)),
                                textColor: Colors.white,
                                child: Text('Save'),
                                onPressed: () async {
                                  if (_formKey.currentState.validate()) {
                                    _isProcessing = true;
                                    _createFamily = await FamilyManagement().createNewFamily(_familyName);
                                    if (_createFamily['key']) {
                                      Navigator.pop(context);
                                      _displaySnackBar(_createFamily);
                                    }
                                    setState(() {
                                      _isProcessing = false;
                                    });
                                  }
                                },
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              FlatButton(
                                color: Colors.red,
                                shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.circular(2.0)),
                                textColor: Colors.white,
                                child: Text('Cancel'),
                                onPressed: () {
                                  setState(() {
                                    Navigator.of(context).pop();
                                  });
                                },
                              )
                            ],
                          ),
                      ],
                    ),
                  );
                }),
          ),
        );
      },
    );
  }

  Future<void> _deleteFamily(DocumentSnapshot doc) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return SimpleDialog(
          title:
          RichText(
            text: TextSpan(
              text: 'Do you want to delete ',
              style: TextStyle(color: Colors.black, fontSize: 15.0),
              children: <TextSpan>[
                TextSpan(text: doc['familyName'], style: TextStyle(color: Colors.teal)),
                TextSpan(text: ' family ?'),
              ],
            ),
          ),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  color: Colors.blue,
                  shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
                  textColor: Colors.white,
                  child: Text('Yes'),
                  onPressed: () async {
                    var _deleteFamily = await FamilyManagement().deleteFamily(doc.documentID, doc.data['familyName']);
                    Navigator.of(context).pop();
                    _displaySnackBar(_deleteFamily);
                  },
                ),
                SizedBox(width: 10,),
                FlatButton(
                  color: Colors.red,
                  shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
                  textColor: Colors.white,
                  child: Text('No'),
                  onPressed: () {
                    setState(() {
                      Navigator.of(context).pop();
                    });
                  },
                )
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _customDismissListTile(DocumentSnapshot doc) {
    return Dismissible(
      key: Key(''),
      child: _customListTile(doc),
//      onDismissed: (direction) {
//        Scaffold.of(context).showSnackBar(SnackBar(content: Text("${doc.data['name']} removed")));
//      },
      confirmDismiss: (direction) {
        _deleteFamily(doc);
      },
      background: Container(
        padding: EdgeInsets.all(20.0),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
        alignment: AlignmentDirectional.centerEnd,
        color: Colors.red,
      ),
      direction: DismissDirection.endToStart,
    );
  }

  Widget _customListTile(DocumentSnapshot doc) {
    return ListTile(
      title: Text(doc['familyName']),
      subtitle: Text('Members: ${doc['memberIds'] != null ? doc['memberIds'].length : ''}'),
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
              FamilyDetails(familyId: doc.documentID.toString(), sharedPrefs: _sharedPrefs, familyName: doc['familyName']),),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: CustomDrawer(_sharedPrefs),
      appBar: AppBar(
        title: Text('Families'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white,),
            onPressed: () {
              _isProcessing = false;
              _createNewFamily();
            },
          ),
          IconButton(
            icon: Icon(Icons.dehaze, color: Colors.white,),
            onPressed: () {
              _scaffoldKey.currentState.openEndDrawer();
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar('familypage'),
      body: StreamBuilder(
          stream: Firestore.instance.collection('families').where('memberIds', arrayContains: _userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return
                Container(
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
            return ListView.separated(
              padding: EdgeInsets.all(1.0),
              separatorBuilder: (context, index) => SizedBox(),
              itemCount: snapshot.data.documents.length,
              itemBuilder: ((context, index) {
                if(snapshot.data.documents.length > 0) {
                  if(snapshot.data.documents[index]['owner'] == _userId) {
                    return _customDismissListTile(snapshot.data.documents[index]);
                  }
                  else{
                    return _customListTile(snapshot.data.documents[index]);
                  }
                }
              }),
            );
          }),
    );
  }
}
