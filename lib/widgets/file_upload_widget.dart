import 'package:flutter/material.dart';
import '../utils/storage_utils.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';

class FileUploadWidget extends StatelessWidget {
  final Function(String) onFileUploaded;

  FileUploadWidget({required this.onFileUploaded});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Upload File'),
      onPressed: () async {
        try {
          FilePickerResult? result = await FilePicker.platform.pickFiles();
          if (result != null) {
            final file = result.files.single;
            final downloadURL = await StorageUtils.uploadFile(file.bytes!, file.name);
            onFileUploaded(file.name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File uploaded successfully: ${file.name}')),
            );
          }
        } catch (e) {
          developer.log('Error in FileUploadWidget: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading file: $e')),
          );
        }
      },
    );
  }
}