import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'services/common.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Map _sharedPrefs = new Map();
  QuerySnapshot _families;
  QuerySnapshot _familyMembers;
  Firestore _firestore = Firestore.instance;
  List<DocumentSnapshot> _posts = [];
  DocumentSnapshot _lastDocument;
  ScrollController _scrollController = ScrollController();
  int _postsPerPage = 10;
  bool _morePosts = false;
  bool _morePostsAvailable = true;
  bool loadingPosts = true;
  String _familyId;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getFirstQuery();

    _scrollController.addListener(() {
      double _maxScroll = _scrollController.position.maxScrollExtent;
      double _currentScroll = _scrollController.position.pixels;
      double _delta = MediaQuery.of(context).size.height * 0.25;

      if (_maxScroll - _currentScroll < _delta) {
        _getMorePosts();
      }
    });
  }

  _getFirstQuery() async {
    await _getSharedPreferences();
    await _getFamilies();
    if (_familyId != null) {
      await _getFamilyMembers(_familyId);
      _getPosts();
    }
  }

  _getChangedPost() async {
    await _getFamilyMembers(_familyId);
    _getPosts();
  }

  _getSharedPreferences() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.clear();
    if (!_prefs.containsKey('userId')) {
      await Common().updateSharedPreference();
    }
    for(var prefs in _prefs.getKeys()){
      _sharedPrefs[prefs] = await _prefs.get(prefs);
    }
  }

  _getFamilies() async {
    _families = await Firestore.instance.collection('families')
        .where('memberIds', arrayContains: _sharedPrefs['userId']).getDocuments();
    setState(() {
      if(_families.documents.length > 0) _familyId = _families.documents[0].documentID;
    });
  }

  _getFamilyMembers(String familyId) async {
    _familyMembers = await Firestore.instance.collection('families')
        .document(familyId).collection('members').getDocuments();
    setState(() {
      _familyMembers = _familyMembers;
    });
  }

  _getPosts() async {
    Query _query = _firestore.collection('posts').where('families', arrayContains: _familyId).orderBy('createdOn', descending: true).limit(_postsPerPage);
    setState(() {
      loadingPosts = true;
    });
    QuerySnapshot _querySnapshot = await _query.getDocuments();
    _posts = _querySnapshot.documents;
    if (_querySnapshot.documents.length != 0) {
      _lastDocument =
      _querySnapshot.documents[_querySnapshot.documents.length - 1];
    }
    setState(() {
      loadingPosts = false;
    });
  }

  _getMorePosts() async {
    print('Getting more posts....');

    if (_morePostsAvailable == false) {
      print('No more posts found.');
      return;
    }

    if (_morePosts == true) {
      return;
    }

    _morePosts = true;
    Query _query = _firestore.collection('posts').where('families', arrayContains: _familyId).orderBy('createdOn', descending: true)
        .startAfter([_lastDocument.data['createdOn']]).limit(_postsPerPage);
    QuerySnapshot _querySnapshot = await _query.getDocuments();
    if (_querySnapshot.documents.length < _postsPerPage) {
      _morePostsAvailable = false;
      return;
    }
    _lastDocument = _querySnapshot.documents[_querySnapshot.documents.length - 1];
    _posts.addAll(_querySnapshot.documents);
    _morePosts = false;
  }

  List<CachedNetworkImageProvider> _getImages(var imageMetaData) {
    List<CachedNetworkImageProvider> _cacheImageProvides =
    new List<CachedNetworkImageProvider>();
    for (var _image in imageMetaData) {
      _cacheImageProvides
          .add(CachedNetworkImageProvider(_image['downloadUrl']));
    }
    return _cacheImageProvides;
  }

  Widget _postHeaderListTile(String userId, Timestamp createdOn) {
//    var _user = _familyMembers.documents.firstWhere((e){
//      if(e.data['userId'] == userId){
//        return true;
//      }
//      else {
//        return false;
//      }
//    });

  var _user = _familyMembers.documents.firstWhere((e) => e.data['userId'] == userId, orElse:
  () => null);

  if (_user == null) return SizedBox();

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: _familyMembers != null && _user.data['avatar'] != null
            ? NetworkImage(_user.data['avatar'])
            : AssetImage('assets/personIcon.png'),
        radius: 20,
      ),
      title: _familyMembers != null
          ? Text(_user.data['name'])
          : Text('Name'),
      subtitle: Text(timeago.format(createdOn.toDate())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Family Blog', style: TextStyle(fontFamily: 'Pacifico', fontWeight: FontWeight.w100),),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.dehaze,
              color: Colors.white,
            ),
            onPressed: () {
              _scaffoldKey.currentState.openEndDrawer();
            },
          ),
        ],
      ),
//      floatingActionButton: CustomFloatingButton('homepage'),
//      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar('homepage'),
      endDrawer: CustomDrawer(_sharedPrefs),
      body: Column(
        children: <Widget>[
          _families != null
              ? _families.documents.length > 0
              ? Container(
            color: Colors.white,
            padding: EdgeInsets.all(5),
            height: MediaQuery.of(context).size.height * 0.06,
            width: MediaQuery.of(context).size.width,
            child: _families != null
                ? DropdownButtonHideUnderline(
                child: ButtonTheme(
                  colorScheme: ColorScheme.light(),
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    items: _families.documents.map((DocumentSnapshot document){
                      return new DropdownMenuItem<String>(
                        value: document.documentID,
                        child: Text(document.data['familyName']),
                      );
                    }).toList(),
                    onChanged: ((value) async {
                      setState(() {
                        _familyId = value;
                      });
                      _getChangedPost();
                    }),
                    value: _familyId,
                    style: new TextStyle(
                      color: Colors.black,
                    ),
                    iconEnabledColor: Colors.green,
                  ),
                )
            )
                : Center(child:Text('LOADING...')),
          )
              : SizedBox()
              : SizedBox(),
          _posts.length == 0
              ? Container(
            alignment: Alignment(0, 0),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Text('No posts to display.'),
            ),
          )
              : Expanded(
            child: ListView.builder(
                controller: _scrollController,
                itemCount: _posts.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: <Widget>[
                      _postHeaderListTile(_posts[index].data['userId'], _posts[index].data['createdOn']),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: Carousel(
                          images:
                          _getImages(_posts[index].data['imageMetaData']),
//                    images: [
//                      CachedNetworkImageProvider(_posts[index].data['imageMetaData'][0]['downloadUrl']),
//                      CachedNetworkImage(
//                        imageUrl: _posts[index].data['imageMetaData'][0]['downloadUrl'],
//                        placeholder: (context, url) => new CircularProgressIndicator(),
//                      ),
//                      NetworkImage(_posts[index].data['imageMetaData'][0]['downloadUrl'], scale: 10.0),
//                      new NetworkImage('https://cdn-images-1.medium.com/max/2000/1*wnIEgP1gNMrK5gZU7QS0-A.jpeg'),
//                      new ExactAssetImage("assets/images/LaunchImage.jpg")
//                    ],
                          boxFit: BoxFit.fitHeight,
                          autoplay: false,
                          dotSize: 4.0,
                          dotIncreaseSize: 2.0,
                          dotBgColor: Colors.black.withOpacity(0.5),
                          dotSpacing: 11,
                          indicatorBgPadding: 10.0,
                          dotColor: Colors.white,
                          noRadiusForIndicator: true,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10.0),
                        child: Text(_posts[index].data['postText']),
                      ),
                      Divider(
                        height: 1.0,
                        color: Colors.grey,
                      ),
                    ],
                  );
                }),
          ),
        ],
      ),
    );
  }
}
