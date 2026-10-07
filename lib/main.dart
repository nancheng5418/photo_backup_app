import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'upload_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '相册备份',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _current = 0;
  int _total = 0;
  bool _uploading = false;
  String _status = '就绪';

  Future<void> _startBackup() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() => _status = '权限被拒绝，请允许相册访问');
      return;
    }

    setState(() { _uploading = true; _status = '正在读取相册...'; });

    final albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
    if (albums.isEmpty) return;
    final allAlbum = albums.first;
    final total = await allAlbum.assetCountAsync;

    final allPhotos = <AssetEntity>[];
    for (int page = 0; page < (total / 200).ceil(); page++) {
      final batch = await allAlbum.getAssetListPaged(page: page, size: 200);
      allPhotos.addAll(batch);
    }

    setState(() { _total = total; _status = '共 $_total 张照片，开始上传...'; });

    for (int i = 0; i < allPhotos.length; i += 3) {
      final batch = allPhotos.sublist(i, (i + 3).clamp(0, allPhotos.length));
      await Future.wait(batch.map((p) async {
        await uploadPhoto(p);
        if (mounted) setState(() { _current++; _status = '正在上传 $_current / $_total'; });
      }));
    }

    setState(() { _uploading = false; _status = '上传完成'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('相册备份')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_uploading) LinearProgressIndicator(value: _total == 0 ? null : _current / _total),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _startBackup,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('开始备份全部相册'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(240, 56)),
            ),
          ],
        ),
      ),
    );
  }
}
