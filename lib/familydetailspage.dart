import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/familymanagement.dart';
import 'dashboard.dart';
import 'services/common.dart';

class FamilyDetails extends StatefulWidget {

  final String familyId;
  final Map sharedPrefs;
  final String familyName;

  FamilyDetails({
    Key key,
    @required this.familyId,
    @required this.sharedPrefs,
    @required this.familyName
  }) : super(key: key);

  @override
  _FamilyDetails createState() => _FamilyDetails(familyId, sharedPrefs, familyName);

}

class _FamilyDetails extends State<FamilyDetails> {

  String _familyId;
  String _memberEmail;
  String _familyName;
  bool _modifyPrivilege = false;
  bool _isProcessing = false;
  Map _sharedPrefs;
  var _addNewFamilyMember = new Map();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _formKey = GlobalKey<FormState>();

  _FamilyDetails(this._familyId, this._sharedPrefs, this._familyName);

  @override
  void initState() {
    checkModifyPrivilege();
    super.initState();
  }

  checkModifyPrivilege() async {
    QuerySnapshot _getMember = await Firestore.instance.collection('families').document(_familyId).collection('members')
        .where('userId', isEqualTo: _sharedPrefs['userId']).getDocuments();
    setState(() {
      if (_getMember.documents[0].data['role'] == 'Owner' || _getMember.documents[0].data['role'] == 'Admin') {
        _modifyPrivilege = true;
      }
    });
  }

  _displaySnackBar(Map content) {
    final snackBar = SnackBar(
      duration: Duration(seconds: 3),
      content: Text(content['value'], style: TextStyle(color: Colors.white),),
      backgroundColor: content['key'] ? Colors.green : Colors.red,);
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future<void> _addNewMember() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add new family member'),
          content: Container(
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Form(
                    onChanged: () {
                      setState(() {
                        _addNewFamilyMember.clear();
                      });
                    },
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          decoration: InputDecoration(hintText: 'Email Id'),
                          validator: (String value) {
                            if (value.isEmpty) {
                              return 'Enter member\'s email Id.';
                            }
                            if (Common().validateEmail(value)) {
                              return 'Please enter valid email id.';
                            }
                            setState(() {
                              _memberEmail = value;
                            });
                          },
                        ),
                        SizedBox(height: 10.0),
                        _addNewFamilyMember['key'] == false
                            ? Text(
                          _addNewFamilyMember['value'],
                          style: TextStyle(color: Colors.red, fontSize: 12.0),
                          textDirection: TextDirection.ltr,
                        )
                            : SizedBox(),
                        SizedBox(height: 10.0),
                        _isProcessing
                            ? CircularProgressIndicator(
                          backgroundColor: Colors.blue,
                          semanticsLabel: 'Loading',
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
                                  shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
                                  textColor: Colors.white,
                                  child: Text('Save'),
                                  onPressed: () async {
                                    if (_formKey.currentState.validate()) {
                                      _isProcessing = true;
                                      print('Member email id: ' + _memberEmail);
                                      _addNewFamilyMember = await FamilyManagement().addNewMemberToFamily(_memberEmail, _familyId, _familyName, 'Member');
                                      if (_addNewFamilyMember['key']) {
                                        Navigator.pop(context);
                                        _displaySnackBar(_addNewFamilyMember);
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
                                      _addNewFamilyMember.clear();
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

  Future<void> _removeFamilyMember(DocumentSnapshot doc) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title:
            RichText(
              text: TextSpan(
              text: 'Do you want to remove ',
              style: TextStyle(color: Colors.black, fontSize: 15.0),
              children: <TextSpan>[
                TextSpan(text: doc['name'], style: TextStyle(color: Colors.teal)),
                TextSpan(text: ' from the family ?'),
              ],
            ),
          ),
          content: Container(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                  return _isProcessing
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator()
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            FlatButton(
                              color: Colors.blue,
                              shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
                              textColor: Colors.white,
                              child: Text('Yes'),
                              onPressed: () async {
                                setState(() {
                                  _isProcessing = true;
                                });
                                print(_isProcessing);
                                var _removeFamilyMember = await FamilyManagement().removeMemberFromFamily(_familyId, doc.documentID, doc.data['name'], doc.data['userId']);
                                Navigator.of(context).pop();
                                _displaySnackBar(_removeFamilyMember);
                                setState(() {
                                  _isProcessing = false;
                                });
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
                        );
              }),
          ),
        );
      },
    );
  }

  Widget _customDismissListTile(BuildContext context, DocumentSnapshot doc) {
    return Dismissible(
      key: Key(''),
      child: _customListTile(context, doc),
//      onDismissed: (direction) {
//        Scaffold.of(context).showSnackBar(SnackBar(content: Text("${doc.data['name']} removed")));
//      },
      confirmDismiss: (direction) {
        _removeFamilyMember(doc);
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

  Widget _customListTile(BuildContext context, DocumentSnapshot doc) {
    return ListTile(
      leading: doc['avatar'] == null
        ? CircleAvatar(
            backgroundImage: AssetImage('assets/personIcon.png'),
            radius: 25,
          )
        : CircleAvatar(
            backgroundImage: NetworkImage(doc['avatar']),
            radius: 25,
          ),
      title: Text(doc['name']),
      subtitle: Text(doc['role']),
      trailing: _modifyPrivilege
        ? doc['role'] != 'Owner'
          ? IconButton(
              icon: Icon(
                Icons.supervisor_account,
                color: doc['role'] == 'Member' ? Colors.grey : Colors.green,
                size: 30.0,
              ),
              onPressed: () async {
                if(doc['role'] != 'Owner') {
                  var _memberRoleUpdate = await FamilyManagement().updateMemberRoles(_familyId, doc.documentID);
                  _displaySnackBar(_memberRoleUpdate);
                }
              })
          : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: CustomDrawer(_sharedPrefs),
      appBar: AppBar(
        title: Text(_familyName),
        actions: <Widget>[
          _modifyPrivilege
          ? IconButton(
            icon: Icon(Icons.person_add, color: Colors.white,),
            onPressed: () {
              _isProcessing = false;
              _addNewMember();
            },
          )
          : SizedBox(),
          IconButton(
            icon: Icon(Icons.dehaze, color: Colors.white,),
            onPressed: () {
              _scaffoldKey.currentState.openEndDrawer();
            },
          ),
        ],
      ),
      body: StreamBuilder(
          stream: Firestore.instance.collection('families').document(_familyId).collection('members').snapshots(),
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
              padding: EdgeInsets.all(0),
              separatorBuilder: (context, index) => SizedBox(),
              itemCount: snapshot.data.documents.length,
              itemBuilder: ((context, index) {
                if(snapshot.data.documents[index]['role'] == 'Owner') {
                  return _customListTile(context, snapshot.data.documents[index]);
                }
                if(_modifyPrivilege) {
                  return _customDismissListTile(context, snapshot.data.documents[index]);
                }
                else {
                  return _customListTile(context, snapshot.data.documents[index]);
                }
              }),
            );
          }),
    );
  }
}
