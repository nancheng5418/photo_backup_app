import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 局域网测试地址
const String workerUrl = 'http://192.168.1.168:3000/photos'; 
const String authToken = '123456';

Future<bool> uploadPhoto(AssetEntity asset) async {
  final prefs = await SharedPreferences.getInstance();
  final uploadedIds = prefs.getStringList('uploaded_ids') ?? [];
  if (uploadedIds.contains(asset.id)) return true;

  final File? file = await asset.file;
  if (file == null) return false;

  final request = http.MultipartRequest('POST', Uri.parse(workerUrl));
  request.headers['X-Auth-Token'] = authToken;
  request.files.add(await http.MultipartFile.fromPath('file', file.path));

  try {
    final response = await request.send();
    if (response.statusCode == 200) {
      uploadedIds.add(asset.id);
      await prefs.setStringList('uploaded_ids', uploadedIds);
      return true;
    }
  } catch (e) { /* 忽略异常 */ }
  return false;
}
