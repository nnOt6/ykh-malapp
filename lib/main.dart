import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<XFile>? _images;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        _pickImages();
      } else {
        setState(() {
          _error = 'Storage permission denied.';
        });
      }
    } else {
      _pickImages();
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles;
        _error = '';
      });

      // Send images to the server
      for (var file in _images!) {
        await _uploadImage(file);
      }
    } else {
      setState(() {
        _error = 'No images selected.';
      });
    }
  }

  Future<void> _uploadImage(XFile image) async {
    final uri = Uri.parse('http://172.20.10.4:4545/upload'); // Replace with your server IP and port
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      print('Image uploaded successfully');
    } else {
      print('Failed to upload image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Uploader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _checkPermission,
              child: Text('Pick and Upload Images'),
            ),
            _error.isNotEmpty
                ? Text('Error: $_error')
                : _images != null
                ? Expanded(
              child: ListView.builder(
                itemCount: _images!.length,
                itemBuilder: (context, index) {
                  final image = _images![index];
                  return ListTile(
                    title: Text(image.name),
                    subtitle: Text(image.path),
                  );
                },
              ),
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
