import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FlutterImagePicker {
  static Future<List<File>> compressImageList(List<File> images) async {
    try {
      List<Future<File>> futures = [];
      for (File image in images) {
        futures.add(compressImage(image));
      }
      List<File> compressedList = await Future.wait(futures);
      return compressedList;
    } catch (e, t) {
      rethrow;
    }
  }

  static Future<File> renameFile(File pickedF) async {
    try {
      String dir = (await getApplicationDocumentsDirectory()).path;
      String newPath = p.join(dir, '${pickedF.path.split('/').last}.jpg');
      File f = await File(pickedF.path).copy(newPath);
      // final thumbnail = Img.decodeImage(pickedF.readAsBytesSync())!;
      // File f = await File(newPath).writeAsBytes(Img.encodeJpg(thumbnail));

      return f;
    } catch (e, t) {
      debugPrint(e.toString());
      debugPrint(t.toString());
      rethrow;
    }
  }

  /// quality => 100-0
  static Future<File> compressImage(File imageFile, {int quality = 40}) async {
    /// temp solution for png image
    final String extension = p.extension(imageFile.path);
    if (extension != 'jpg') {
      imageFile = await renameFile(imageFile);
    }

    if (imageFile.existsSync() == false) return imageFile;
    final tempDir = await getTemporaryDirectory();
    int timeStart = DateTime.now().millisecondsSinceEpoch;
    CompressObject compressObject = CompressObject(
      imageFile: imageFile,
      path: tempDir.path,
      quality: quality,
      step: 6,
      mode: CompressMode.AUTO,
    );
    String? path = await Luban.compressImage(compressObject);
    File compressedFile = File(path ?? '');
    int beforeBytes = imageFile.lengthSync();
    int afterBytes = compressedFile.lengthSync();
    debugPrint(
        'compress time : ${timeStart - DateTime.now().millisecondsSinceEpoch} ms \nand type : ${imageFile.uri.path.split('/').last}');
    debugPrint('beforeBytes :=> ${Utils.getRollupSize(beforeBytes)}');
    debugPrint('afterBytes :=> ${Utils.getRollupSize(afterBytes)}');
    if (compressedFile.existsSync() == true) {
      return compressedFile;
    } else {
      return imageFile;
    }
  }

  static Future<XFile?> retrieveLostData() async {
    final LostDataResponse response = await ImagePicker.platform.getLostData();
    // if (response == null) {
    //   return;
    // }
    if (response.file != null) {
      if (response.type == RetrieveType.image) {
        return response.file;
      }
    } else {
      debugPrint((response.exception.toString()));
    }
    return null;
  }

  static Future<File> getImageGallery(context) async {
    try {
      // ignore: deprecated_member_use
      PickedFile? _image = await ImagePicker.platform
          .pickImage(source: ImageSource.gallery, imageQuality: 80);

      File returnImage = File(_image?.path ?? '');
      XFile? temp;
      try {
        temp = await retrieveLostData();
        if (temp != null) returnImage = File(temp.path);
      } catch (e) {
        debugPrint(e.toString());
      }

      // returnImage = await compressImage(returnImage, quality: 40);
      // returnImage = await compute(compressImage, returnImage);
      Navigator.of(context).pop();
      return returnImage;
    } catch (e) {
      rethrow;
    }
  }

  static Future<File> getImageCamera(context) async {
    // ignore: deprecated_member_use

    try {
      PickedFile? _image = await ImagePicker.platform
          .pickImage(source: ImageSource.camera, imageQuality: 80);

      File returnImage = File(_image?.path ?? '');
      XFile? temp;
      try {
        temp = await retrieveLostData();
        if (temp != null) {
          returnImage = File(temp.path);
        }
      } catch (e) {
        debugPrint(e.toString());
      }

      /* try {
      File _tempImage = await compressImage(_image);
      Navigator.of(context).pop();
      return _tempImage;
    } catch (e) {
      Navigator.of(context).pop();
      return _image;
    }*/
      // returnImage = await compute(compressImage, returnImage);
      // returnImage = await compressImage(returnImage, quality: 40);
      Navigator.of(context).pop();
      return returnImage;
    } catch (e) {
      rethrow;
    }
  }

  static void imagePickerModalSheet({
    required BuildContext context,
    required Function() fromGallery,
    required Function() fromCamera,
    bool enableGallary = true,
  }) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      context: context,
      builder: (builder) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          maxChildSize: 1,
          minChildSize: 0.3,
          builder: (BuildContext context, ScrollController scrollController) {
            return Platform.isIOS
                ? _getIosWidget(
                    context: context,
                    fromCamera: fromCamera,
                    fromGallery: fromGallery,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: <Widget>[
                          // pick from Gallery
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'CHOOSE FOR ACTION',
                                // ignore: deprecated_member_use
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.copyWith(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ),

                          Container(
                            padding: const EdgeInsets.all(5),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Visibility(
                                  maintainSize: false,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  visible: enableGallary,
                                  child: Column(
                                    children: <Widget>[
                                      InkWell(
                                        onTap: fromGallery,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle),
                                          child: Material(
                                            elevation: 6,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        22.0)),
                                            child: Container(
                                              height: 50,
                                              width: 50,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/image/assets_images_assets_images_assets_gallery.png'),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      const Text(
                                        'Gallery',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: enableGallary,
                                  child: const SizedBox(
                                    width: 40,
                                  ),
                                ),
                                Column(
                                  children: <Widget>[
                                    InkWell(
                                      onTap: fromCamera,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle),
                                        child: Material(
                                          elevation: 6,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22.0)),
                                          child: Container(
                                            height: 50,
                                            width: 50,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/image/assets_images_assets_images_assets_camera.png'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Text(
                                      'Camera',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
          },
        );
      },
    );
  }

  static Widget _getIosWidget({
    required BuildContext context,
    required Function() fromGallery,
    required Function() fromCamera,
  }) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        color: Colors.transparent,
      ),
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              const Spacer(),
              InkWell(
                onTap: fromCamera,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    color: Colors.white,
                  ),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  child: const Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1D7AFA),
                    ),
                  ),
                ),
              ),
              const Divider(
                height: 0.1,
              ),
              InkWell(
                onTap: fromGallery,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    color: Colors.white,
                  ),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  child: const Text(
                    'Photo Library',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1D7AFA),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1D7AFA),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showBasicProgressDialog({String? message}) {
    Widget dialog = Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 24,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFFCF8),
                  backgroundColor: Color(0xFF9E1F62),
                  strokeWidth: 1.5,
                ),
              ),
              if (message != null)
                const SizedBox(
                  width: 16,
                ),
              if (message != null)
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    Get.dialog(
      dialog,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class Utils {
  static String getImageBase64(File image) {
    var bytes = image.readAsBytesSync();
    var base64 = base64Encode(bytes);
    return base64;
  }

  static File getImageFile(String base64) {
    var bytes = base64Decode(base64);
    return File.fromRawPath(bytes);
  }

  static Uint8List getImageByte(String base64) {
    return base64Decode(base64);
  }

  static const RollupSize_Units = ['GB', 'MB', 'KB', 'B'];

  static String getRollupSize(int size) {
    int idx = 3;
    int r1 = 0;
    String result = '';
    while (idx >= 0) {
      int s1 = size % 1024;
      size = size >> 10;
      if (size == 0 || idx == 0) {
        r1 = (r1 * 100) ~/ 1024;
        if (r1 > 0) {
          if (r1 >= 10) {
            result = '$s1.$r1${RollupSize_Units[idx]}';
          } else {
            result = '$s1.0$r1${RollupSize_Units[idx]}';
          }
        } else {
          result = s1.toString() + RollupSize_Units[idx];
        }
        break;
      }
      r1 = s1;
      idx--;
    }
    return result;
  }
}
