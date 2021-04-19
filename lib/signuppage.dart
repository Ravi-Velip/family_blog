import 'package:flutter/material.dart';
import 'services/common.dart';
import 'services/usermanagement.dart';
import 'package:flutter/gestures.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String _email, _password, _name;
  var _formKey = GlobalKey<FormState>();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  _showLoadingDialog() {
    setState(() {
      _formKey.currentState.reset();
    });
    return showDialog(context: context, builder: (_){
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white.withOpacity(0.8),
        alignment: Alignment(0, 0),
        child: CircularProgressIndicator(),
      );
    });
  }

  _errorSnackBar(String displayMessage) {
    final snackBar = SnackBar(
      content: Text(displayMessage, style: TextStyle(color: Colors.white),),
      backgroundColor: Colors.redAccent,
      duration: Duration(seconds: 3),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () {
        _formKey.currentState.reset();
        return new Future(() => true);
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              image: new DecorationImage(
                image: new AssetImage("assets/bgTheme1.jpg"),
                fit: BoxFit.cover,
                colorFilter: new ColorFilter.mode(
                    Colors.black.withOpacity(0.1), BlendMode.dstATop),
              ),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                            style: TextStyle(color: Colors.teal),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Welcome to ',
                                style: TextStyle(
                                    fontFamily: 'PTSans', fontSize: 20),
                              ),
                              TextSpan(
                                text: 'Family Blog',
                                style: TextStyle(
                                    fontFamily: 'Pacifico',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25),
                              ),
                            ]),
                      ),
                      SizedBox(
                        height: 70.0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(
                              color: Colors.blueGrey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(
                              color: Colors.blueGrey,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color: Colors.blueGrey,
                          ),
                        ),
                        validator: (String value) {
                          if (value.isEmpty)
                            return 'Please enter your full name.';
                          setState(() {
                            _name = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter your e-mail',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(
                              color: Colors.blueGrey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(
                              color: Colors.blueGrey,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.blueGrey,
                          ),
                        ),
                        validator: (String value) {
                          if (value.isEmpty) return 'Please enter e-mail id.';

                          if (Common().validateEmail(value)) {
                            return 'Please enter valid e-mail id.';
                          }

                          setState(() {
                            _email = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(
                              color: Colors.blueGrey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(
                              color: Colors.blueGrey,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Colors.blueGrey,
                          ),
                        ),
                        obscureText: true,
                        validator: (String value) {
                          if (value.isEmpty) {
                            return 'Please enter password.';
                          }
                          setState(() {
                            _password = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: RaisedButton(
                          child: Text('SIGN UP'),
                          color: Colors.blue,
                          textColor: Colors.white,
                          shape: StadiumBorder(),
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              _showLoadingDialog();
                              var _signUp = await UserManagement().signUpWithEmail(_email, _password, _name);
                              if(_signUp['key']) {
//                              Navigator.of(context).pop();
//                              Navigator.of(context).pushReplacementNamed('/homepage');
                                Navigator.of(context).pushNamedAndRemoveUntil('/homepage', (Route<dynamic> route) => false);
                              }
                              else{
                                Navigator.pop(context);
                                _errorSnackBar(_signUp['value']);
                              }
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Already having an account ? ',
                          style: TextStyle(color: Colors.black54),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context)
                                      .pushNamed('/login')
                                      .then((_) {
                                    _formKey.currentState.reset();
                                  });
                                },
                            ),
                            TextSpan(
                              text: ' here',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
