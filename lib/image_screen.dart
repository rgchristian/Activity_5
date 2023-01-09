import 'package:act_5/image_model.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({Key? key}) : super(key: key);

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen>  with WidgetsBindingObserver {
  late final ImageModel _model;
  bool _detectPermission = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    _model = ImageModel();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
  }

  void didChangeAppLifeCycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
    _detectPermission && (_model.imageSection == ImageSection.noStoragePermissionPermanent)) {
      _detectPermission = false;
      _model.requestPermission();
    } else if (state == AppLifecycleState.paused &&
    _model.imageSection == ImageSection.noStoragePermissionPermanent) {
      _detectPermission = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Consumer<ImageModel>(
      builder: (context, model, child) {
        Widget widget;

        switch (model.imageSection) {
          case ImageSection.noStoragePermission:
            widget =_ImagePermissions(
              isPermanent: false,
              onPressed: _checkPermissionAndPick,
            );
            break;
           case ImageSection.noStoragePermissionPermanent:
            widget = _ImagePermissions(
              isPermanent: true,
              onPressed: _checkPermissionAndPick,
            );
            break;
          case ImageSection.browseFiles:
            widget = _PickFile(onPressed: _checkPermissionAndPick);
            break;
          case ImageSection.imageLoaded:
            widget = _ImageLoaded(file: _model.file!);
            break;
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Image Viewer'),
            ),
            body: widget,
          );
        },
      ),
    );
  }

  Future<void> _checkPermissionAndPick() async {
    final hasFilePermission = await _model.requestPermission();
    if (hasFilePermission) {
      try {
        await _model.pickFile();
      } on Exception catch (e) {
        debugPrint('Error when choosing a file: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occured when choosing a file'),
          ),
        );
      }
    }
  }
}

class _ImagePermissions extends StatelessWidget {
  final bool isPermanent;
  final VoidCallback onPressed;

  const _ImagePermissions({
    Key? key,
    required this.isPermanent,
    required this.onPressed,
}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:  const EdgeInsets.only(
              left: 16.0,
              top: 24.0,
              right: 16.0
            ),
            child: Text(
              'Read files permission',
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 16.0,
              top: 24.0,
              right: 16.0
            ),
            child: const Text(
                'We need to request your permission to access local files.',
              textAlign: TextAlign.center,
            ),
          ),
          if (isPermanent)
            Container(
              padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 24.0,
                  right: 16.0
              ),
              child: const Text(
                'You need to grant this access to proceed.',
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            padding: const EdgeInsets.only(
                left: 16.0,
                top: 24.0,
                right: 16.0,
                bottom: 24.0,
            ),
            child: ElevatedButton(
              child: Text(isPermanent ? 'Open Settings' : 'Allow Access'),
              onPressed: () => isPermanent ? openAppSettings() : onPressed(),
            ),
          )
        ],
      ),
    );
  }
}

class _PickFile extends StatelessWidget {
  final VoidCallback onPressed;

  const _PickFile({
    Key? key, required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
    child: ElevatedButton(
      child: const Text('Choose a file'),
      onPressed: onPressed,
    ),
  );
}

class _ImageLoaded extends StatelessWidget {
  final File file;

  const _ImageLoaded({Key? key,
  required this.file
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 196.0,
        height: 196.0,
        child: ClipOval(
          child: Image.file(
            file, fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}