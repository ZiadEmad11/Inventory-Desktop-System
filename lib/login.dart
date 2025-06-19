import 'package:flutter/material.dart';
import 'home.dart';
import 'package:sqflite/sqflite.dart';


class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _login() {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Le nom d\'utilisateur ou le mot de passe ne peut pas être vide';
      });
    } else if (username == 'PharoanAlur' && password == '0001110') {
      // Redirect to home.dart if credentials are correct
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()), // Navigate to Home screen
      );
    } else {
      // Show error message if credentials are incorrect
      setState(() {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black54, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF1B0745), width: 1.5),
          ),
          errorStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          fillColor: Colors.transparent,
          labelStyle: TextStyle(fontSize: 16, color: Color(0xFF1B0745)),
          prefixIconColor: Color(0xFF1B0745),
          floatingLabelStyle: TextStyle(color: Color(0xFF1B0745)),
        ),
      ),
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/bg_login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                    ),
                    child: Card(
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        side: BorderSide(color: Colors.white, width: 3),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Image.asset(
                              'images/LOGIN_LOGO.png',
                              width: MediaQuery.of(context).size.width * 0.2,
                            ),
                            SizedBox(height: 20),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            TextField(
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              controller: usernameController,
                              cursorColor: Color(0xFF1B0745), // Set cursor color
                              decoration: InputDecoration(
                                labelText: 'Nom d\'utilisateur',
                                prefixIcon: const Icon(Icons.person),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              keyboardType: TextInputType.text,
                              obscureText: _obscureText,
                              textInputAction: TextInputAction.done,
                              controller: passwordController,
                              cursorColor: Color(0xFF1B0745), // Set cursor color
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility : Icons.visibility_off,
                                    color: Color(0xFF1B0745),
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16.0)),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.hovered)) {
                                        return Color(0xFF1B0745).withOpacity(0.8);
                                      }
                                      if (states.contains(MaterialState.pressed)) {
                                        return Color(0xFF1B0745).withOpacity(0.6);
                                      }
                                      return Color(0xFF1B0745); // Default color
                                    },
                                  ),
                                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                                ),
                                child: Text(
                                  'Connexion',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,color: Colors.white
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
