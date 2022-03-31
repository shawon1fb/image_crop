import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_crop/app/utils/file_picker_utils.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:get/utils.dart';

class HomeView extends StatefulWidget {
  final String title;

  HomeView({required this.title});

  @override
  _HomeViewState createState() => _HomeViewState();
}

enum AppState {
  free,
  picked,
  cropped,
}

class _HomeViewState extends State<HomeView> {
  late AppState state;
  File? imageFile;

  double percent = 0.0;

  @override
  void initState() {
    super.initState();
    state = AppState.free;
  }

  Future<void> upload(File f) async {
    try {
      var formData = FormData.fromMap({
        'name': 'sunny  apu',
        'image': await MultipartFile.fromFile(f.path,
            filename: f.path.split('/').last),
      });

      Dio dio = Dio();

      await Future.delayed(const Duration(seconds: 2));
      var response = await dio.post(
        'https://bagcomfort.com/api/upload',
        data: formData,
        onSendProgress: (int sent, int total) {
          print('$sent => $total =>${sent / total}');
          percent = sent / total;
          if (mounted) {
            setState(() {});
          }
        },
      );
      print(response.statusCode);
      print(response.data);
    } catch (e, t) {
      print(e);
      print(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          LinearPercentIndicator(
            width: MediaQuery.of(context).size.width,
            lineHeight: 8.0,
            percent: percent,
            barRadius: const Radius.circular(10),
            progressColor: Colors.red,
            backgroundColor: Colors.grey,
          ),
          const SizedBox(
            height: 30,
          ),
          Expanded(
            child: Center(
              child: imageFile != null ? Image.file(imageFile!) : Container(),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          if (imageFile != null)
            Text(Utils.getRollupSize(imageFile!.lengthSync())),
          const SizedBox(
            height: 30,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () {
          if (state == AppState.free)
            _pickImage();
          else if (state == AppState.picked)
            _cropImage();
          else if (state == AppState.cropped) _clearImage();
        },
        child: _buildButtonIcon(),
      ),
    );
  }

  Widget _buildButtonIcon() {
    if (state == AppState.free) {
      return Icon(Icons.add);
    } else if (state == AppState.picked) {
      return Icon(Icons.crop);
    } else if (state == AppState.cropped) {
      return Icon(Icons.clear);
    } else {
      return Container();
    }
  }

  Future<Null> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    imageFile = pickedImage != null ? File(pickedImage.path) : null;
    if (imageFile != null) {
      await _cropImage();
      setState(() {
        state = AppState.picked;
      });
    }
  }

  Future<Null> _cropImage() async {
    File? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile!.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                // CropAspectRatioPreset.ratio3x2,
                // CropAspectRatioPreset.original,
                // CropAspectRatioPreset.ratio4x3,
                // CropAspectRatioPreset.ratio16x9
              ]
            : [
                //  CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                // CropAspectRatioPreset.ratio3x2,
                // CropAspectRatioPreset.ratio4x3,
                // CropAspectRatioPreset.ratio5x3,
                // CropAspectRatioPreset.ratio5x4,
                // CropAspectRatioPreset.ratio7x5,
                // CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: const AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        iosUiSettings: const IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      imageFile = croppedFile;
      imageFile = await FlutterImagePicker.compressImage(imageFile!);
      await upload(imageFile!);
      setState(() {
        state = AppState.cropped;
      });
    }
  }

  void _clearImage() {
    imageFile = null;
    setState(() {
      state = AppState.free;
    });
  }
}
