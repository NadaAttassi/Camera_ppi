import 'package:flutter/material.dart';
import 'test.dart'; // Importez votre page de test
import 'package:camera/camera.dart';

List<CameraDescription>? cameras; // Declare cameras here

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); // Initialize the cameras
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language App',
      initialRoute: '/test', // Start page (SplashScreen)
      routes: {
        '/test': (context) => TestPage(cameras: cameras!), // Pass cameras here
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
