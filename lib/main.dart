import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
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
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _showPermissionDialog();
  }

  Future<void> _showPermissionDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('This app needs access to your storage to function properly. Do you want to allow access?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _statusMessage = 'Permission denied';
                });
              },
            ),
            TextButton(
              child: const Text('Allow'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestPermission();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();

      if (statuses[Permission.storage]!.isGranted) {
        setState(() {
          _statusMessage = "Storage Permission Granted";
        });
        await _pickFilesAndUpload();
      } else {
        setState(() {
          _statusMessage = "Storage Permission Denied";
        });
      }
    } else if (status.isGranted) {
      setState(() {
        _statusMessage = "Storage Permission Already Granted";
      });
      await _pickFilesAndUpload();
    }
  }

  Future<void> _pickFilesAndUpload() async {
    try {
      // Pick files using file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Allow selecting multiple files
        type: FileType.any, // Allow any type of file
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();
        for (var file in files) {
          await _uploadFile(file);
        }
        setState(() {
          _statusMessage = 'All files uploaded successfully';
        });
      } else {
        setState(() {
          _statusMessage = 'No files selected';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting files: $e';
      });
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      final uri = Uri.parse('http://172.20.10.4:4545/upload'); // Replace with your server URL
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        print('File uploaded successfully: ${file.path}');
      } else {
        print('Failed to upload file: ${file.path}');
      }
    } catch (e) {
      print('Error uploading file: ${file.path}, $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Uploader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _showPermissionDialog,
              child: const Text('Request Storage Permission'),
            ),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}
