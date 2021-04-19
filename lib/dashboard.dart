import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'familypage.dart';
import 'createpost.dart';
import 'homepage.dart';
import 'profile.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer(Map sharePrefs) {
    this._sharedPrefs = sharePrefs;
  }
  Map _sharedPrefs;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          image: new DecorationImage(
            image: new AssetImage("assets/bgTheme1.jpg"),
            fit: BoxFit.cover,
            colorFilter: new ColorFilter.mode(
                Colors.white.withOpacity(0.1), BlendMode.dstATop),
          ),
        ),
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                _sharedPrefs['name'] != null ? _sharedPrefs['name'] : '',
                style: TextStyle(color: Colors.white,),
              ),
              accountEmail: Text(
                _sharedPrefs['emailId'] != null ? _sharedPrefs['emailId'] : '',
                style: TextStyle(color: Colors.white70),
              ),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.9),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: _sharedPrefs['avatar'] != null
                          ? NetworkImage(_sharedPrefs['avatar'])
                          : AssetImage('assets/personIcon.png'),
                    )),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.person,
                color: Colors.teal,
              ),
              title: Text(
                'Profile',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(doc: _sharedPrefs)
                  ),
                );
              },
            ),
            Divider(
              color: Colors.grey,
              height: 1,
            ),
            ListTile(
              leading: Icon(
                Icons.power_settings_new,
                color: Colors.teal,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (Route<dynamic> route) => false);
              },
            ),
            Divider(
              color: Colors.grey,
              height: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  CustomBottomNavBar(String pageRoute) {
    this._pageRoute = pageRoute;
  }
  String _pageRoute;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      child: Container(
        height: 50.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.home,
                size: 30.0,
                color: _pageRoute == 'homepage' ? Colors.teal : Colors.black87,
              ),
              onPressed: () {
//                Navigator.of(context).pushNamed('/homepage');
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new HomePage()));
              },
            ),
            IconButton(
              icon: Icon(
                Icons.add_box,
                size: 30.0,
                color:
                    _pageRoute == 'createpost' ? Colors.teal : Colors.black87,
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new CreatePost()));
//                Navigator.of(context).pushNamed('/createpost');
              },
            ),
            IconButton(
              icon: Icon(
                Icons.people,
                size: 30.0,
                color:
                    _pageRoute == 'familypage' ? Colors.teal : Colors.black87,
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new Family()));
//                Navigator.pushNamed(context, "/familypage");
//                Navigator.of(context).pushNamed('/familypage');
              },
            )
          ],
        ),
      ),
    );
  }
}
