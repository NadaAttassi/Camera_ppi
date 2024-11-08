import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TestPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  TestPage({required this.cameras});

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool isWorking = false;
  String result = "";
  CameraController? cameraController;
  CameraImage? imgCamera;

  // Load the model
  loadModel() async {
    await Tflite.loadModel(
      model: "assets/action.tflite", // Ensure the model is stored in the assets folder
      labels: "assets/labels.txt", // Ensure the labels file is also in assets
    );
  }

  // Initialize the camera
  void initCamera() {
    cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );

    cameraController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});

      cameraController!.startImageStream((image) {
        if (!isWorking) {
          isWorking = true;
          imgCamera = image;
          processCameraImage();
        }
      });
    });
  }

  // Process camera image and perform inference
  void processCameraImage() async {
    if (imgCamera != null) {
      // Convert the camera image to a format that TFLite can process
      img.Image image = convertCameraImageToImage(imgCamera!);
      print("Image converted to format: ${image.width}x${image.height}");

      // Save the image temporarily
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/camera_image.png';
      File tempFile = File(tempPath)..writeAsBytesSync(img.encodePng(image));
      print("Image saved to: $tempPath");

      // Run the model inference
      var output = await Tflite.runModelOnImage(
        path: tempPath,
        numResults: 2,  // Adjust based on your model's output
        threshold: 0.1, // Adjust the threshold as needed
        asynch: true,
      );
      print("Model inference completed");

      // Process the results
      if (output != null && output.isNotEmpty) {
        setState(() {
          result = output[0]["label"]; // Adjust to extract the label from the output
          print("Prediction: $result");
          isWorking = false;
        });
      } else {
        print("No results from the model.");
        setState(() {
          result = "No prediction";
          isWorking = false;
        });
      }
    }
  }



  // Convert the camera image to a format TFLite can process
  img.Image convertCameraImageToImage(CameraImage cameraImage) {
    // For simplicity, assuming camera image is in YUV420 format
    // This function might need to be customized depending on your camera image format
    var plane = cameraImage.planes[0];
    var bytes = plane.bytes;
    img.Image image = img.Image.fromBytes(cameraImage.width, cameraImage.height, bytes);
    return image;
  }

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera(); // Initialize the camera when the page is created
  }

  @override
  void dispose() async {
    await Tflite.close();
    cameraController?.dispose(); // Dispose the camera when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Page'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page for Testing'),
            SizedBox(height: 20),
            Text(result),
            SizedBox(height: 20),
            // Show camera preview if the camera is initialized
            cameraController != null && cameraController!.value.isInitialized
                ? Expanded(
              child: CameraPreview(cameraController!),
            )
                : CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
