import 'dart:io';
import 'dart:typed_data';

import 'package:drishya_picker/drishya_picker.dart';
import 'package:path/path.dart' as path;
import 'package:tm_native_media/tm_native_media.dart';

///
class LocalEntity extends DrishyaEntity {
  ///
  const LocalEntity({
    required String id,
    required File file,
    required int height,
    required int width,
    required int typeInt,
    Uint8List? pickedThumbData,
    File? pickedFile,
    int duration = 0,
    int orientation = 0,
    bool isFavorite = false,
    String? title,
    int? createDateSecond,
    int? modifiedDateSecond,
    String? relativePath,
    double? latitude,
    double? longitude,
    String? mimeType,
    int subtype = 0,
  })  : _file = file,
        super(
          id: id,
          height: height,
          width: width,
          typeInt: typeInt,
          duration: duration,
          orientation: orientation,
          isFavorite: isFavorite,
          title: title,
          createDateSecond: createDateSecond,
          modifiedDateSecond: modifiedDateSecond,
          relativePath: relativePath,
          latitude: latitude,
          longitude: longitude,
          mimeType: mimeType,
          subtype: subtype,
          pickedThumbData: pickedThumbData,
          pickedFile: pickedFile,
        );

  final File _file;

  ///
  static Future<LocalEntity> fromImageFile(
    File file, {
    Uint8List? pickedThumbData,
  }) async {
    final info = await TMNativeMedia.imageInformation(file.path);

    return LocalEntity(
      id: path.basename(file.path),
      file: file,
      height: info.height,
      width: info.width,
      orientation: info.orientation,
      duration: info.durationMs,
      mimeType: info.mimeType,
      typeInt: AssetType.image.index,
      pickedThumbData: pickedThumbData,
      pickedFile: file,
    );
  }

  ///
  static Future<LocalEntity> fromVideoFile(
    File file, {
    Uint8List? pickedThumbData,
  }) async {
    final info = await TMNativeMedia.videoInformation(file.path);

    return LocalEntity(
      id: path.basename(file.path),
      file: file,
      height: info.height,
      width: info.width,
      orientation: info.orientation,
      duration: info.durationMs,
      mimeType: info.mimeType,
      typeInt: AssetType.video.index,
      pickedThumbData: pickedThumbData,
      pickedFile: file,
    );
  }

  @override
  Future<bool> isLocallyAvailable({bool isOrigin = false}) async {
    return true;
  }

  @override
  Future<LatLng> latlngAsync() async => const LatLng();

  @override
  Future<File?> get file async {
    return _file;
  }

  @override
  Future<File?> get fileWithSubtype async {
    return _file;
  }

  @override
  Future<File?> get originFile async {
    return _file;
  }

  @override
  Future<File?> get originFileWithSubtype async {
    return _file;
  }

  @override
  Future<File?> loadFile({
    bool isOrigin = true,
    bool withSubtype = false,
    PMProgressHandler? progressHandler,
  }) async {
    return file;
  }

  @override
  Future<Uint8List?> get originBytes async {
    return _file.readAsBytes();
  }

  @override
  Future<Uint8List?> get thumbnailData async => pickedThumbData;

  @override
  Future<Uint8List?> thumbnailDataWithSize(
    ThumbnailSize size, {
    ThumbnailFormat format = ThumbnailFormat.jpeg,
    int quality = 100,
    PMProgressHandler? progressHandler,
    int frame = 0,
  }) async {
    return pickedThumbData;
  }

  @override
  Future<Uint8List?> thumbnailDataWithOption(
    ThumbnailOption option, {
    PMProgressHandler? progressHandler,
  }) async {
    return pickedThumbData;
  }

  @override
  Future<bool> get exists {
    return _file.exists();
  }

  @override
  Future<String?> getMediaUrl() async {
    return null;
  }

  @override
  Future<String?> get mimeTypeAsync async {
    return mimeType;
  }

  ///
  @override
  LocalEntity copyWith({
    File? file,
    Uint8List? pickedThumbData,
    File? pickedFile,
    String? id,
    int? typeInt,
    int? width,
    int? height,
    int? duration,
    int? orientation,
    bool? isFavorite,
    String? title,
    int? createDateSecond,
    int? modifiedDateSecond,
    String? relativePath,
    double? latitude,
    double? longitude,
    String? mimeType,
    int? subtype,
  }) =>
      LocalEntity(
        id: id ?? this.id,
        file: file ?? _file,
        pickedThumbData: pickedThumbData ?? this.pickedThumbData,
        pickedFile: pickedFile ?? this.pickedFile,
        typeInt: typeInt ?? this.typeInt,
        width: width ?? this.width,
        height: height ?? this.height,
        duration: duration ?? this.duration,
        orientation: orientation ?? this.orientation,
        isFavorite: isFavorite ?? this.isFavorite,
        title: title ?? this.title,
        createDateSecond: createDateSecond ?? this.createDateSecond,
        modifiedDateSecond: modifiedDateSecond ?? this.modifiedDateSecond,
        relativePath: relativePath ?? this.relativePath,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        mimeType: mimeType ?? this.mimeType,
        subtype: subtype ?? this.subtype,
      );
}
