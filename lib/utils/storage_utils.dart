import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;

class StorageUtils {
  static Future<String> uploadFile(Uint8List fileBytes, String fileName) async {
    try {
      print('Uploading file: $fileName');
      print('File size: ${fileBytes.length} bytes');
      
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putData(fileBytes);
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      print('File uploaded successfully. Download URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  static Future<List<String>> getAllFileNames() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('uploads');
      final result = await ref.listAll();
      return result.items.map((item) => item.name).toList();
    } catch (e) {
      developer.log('Error getting file names: $e');
      return [];
    }
  }

  static Future<List<String>> getRssFeedFiles() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('rss_feeds');
      final result = await ref.listAll();
      return result.items.map((item) => item.name).toList();
    } catch (e) {
      developer.log('Error getting RSS feed files: $e');
      return [];
    }
  }

  static Future<String?> getRssFeedUrl(String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('rss_feeds/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      developer.log('Error getting RSS feed URL: $e');
      return null;
    }
  }
}