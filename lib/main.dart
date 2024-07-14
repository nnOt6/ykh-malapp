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
  List<File> _files = [];
  String _error = '';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage Permission Granted")),
        );
        await _pickFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage Permission Denied")),
        );
      }
    } else if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage Permission Already Granted")),
      );
      await _pickFiles();
    }
  }

  Future<void> _pickFiles() async {
    try {
      // Pick files from the device
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'docx', 'xlsx', 'txt', 'mp4', 'mp3'], // Add more extensions as needed
      );

      if (result != null) {
        List<File> pickedFiles = result.files
            .map((file) => File(file.path!))
            .toList();

        setState(() {
          _files = pickedFiles;
        });

        // Print file paths to console
        for (var file in _files) {
          print('Found file: ${file.path}');
        }

        // Upload files to the server
        for (var file in _files) {
          await _uploadFile(file);
        }
      } else {
        setState(() {
          _error = 'No files selected.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking files: $e';
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
        title: const Text('File Picker and Upload'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _showPermissionDialog,
              child: const Text('Request Storage Permission'),
            ),
            _error.isNotEmpty
                ? Text('Error: $_error')
                : Expanded(
              child: ListView.builder(
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return ListTile(
                    title: Text(file.path),
                    subtitle: Text('${file.lengthSync()} bytes'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
