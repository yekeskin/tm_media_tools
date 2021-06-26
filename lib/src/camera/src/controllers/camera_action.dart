import 'dart:io';

import 'package:camera/camera.dart';
import 'package:drishya_picker/src/camera/src/entities/gradient_color.dart';
import 'package:drishya_picker/src/draggable_resizable/src/controller/stickerbooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';
import 'package:photo_manager/photo_manager.dart';

import '../entities/camera_type.dart';
import '../utils/ui_handler.dart';
import 'controller_notifier.dart';
import 'exposure.dart';
import 'zoom.dart';

///
class CameraAction extends ValueNotifier<ActionValue> {
  ///
  CameraAction({
    required ControllerNotifier controllerNotifier,
    required BuildContext context,
  })  : _controllerNotifier = controllerNotifier,
        _uiHandler = UIHandler(context),
        zoom = Zoom(controllerNotifier),
        exposure = Exposure(controllerNotifier, UIHandler(context)),
        stickerController = StickerboothController(),
        super(ActionValue());

  final ControllerNotifier _controllerNotifier;
  final UIHandler _uiHandler;

  ///
  final Zoom zoom;

  ///
  final Exposure exposure;

  ///
  final StickerboothController stickerController;

  ///
  bool get initialized => _controllerNotifier.initialized;

  /// Call this only when [initialized] is true
  CameraController get controller => _controllerNotifier.value.controller!;

  ///
  CameraLensDirection get lensDirection =>
      value.cameraDescription?.lensDirection ?? CameraLensDirection.back;

  ///
  CameraLensDirection get oppositeLensDirection =>
      lensDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

  /// Hide close button on textfield has focus or while editing stickers
  bool get hideCloseButton =>
      value.hasFocus || value.editingMode || value.isRecordingVideo;

  /// Hive gradient background changer button
  bool get hideBackgroundChangerButton =>
      value.editingMode || value.cameraType != CameraType.text;

  /// Hide flash button
  bool get hideFlashButton =>
      value.cameraType == CameraType.text ||
      (value.cameraType == CameraType.selfi &&
          lensDirection != CameraLensDirection.back) ||
      lensDirection != CameraLensDirection.back ||
      value.isRecordingVideo;

  /// Hide sticker's editing button's
  bool get hideStickerEditingButton =>
      value.editingMode || value.cameraType != CameraType.text;

  /// Hide tab to type text button
  bool get hideEditingTextButton =>
      value.cameraType != CameraType.text ||
      value.hasFocus ||
      value.hasStickers;

  /// Hive shutter view on Textview
  bool get hideShutterView => value.cameraType == CameraType.text;

  /// Hide camera type slider view
  bool get hideCameraTypeScroller =>
      value.hasFocus ||
      value.editingMode ||
      value.isRecordingVideo ||
      value.hasStickers;

  /// Hide gallery preview button
  bool get hideGalleryPreviewButton =>
      value.cameraType == CameraType.text || value.isRecordingVideo;

  /// Hide gallery preview button
  bool get hideCameraRotationButton =>
      value.cameraType == CameraType.text || value.isRecordingVideo;

  /// Show sticker delete popup
  bool get showStickerDeletePopup => value.editingMode;

  /// Show screenshot capture view on Textview
  bool get showScreenshotCaptureView => value.hasStickers;

  @override
  void dispose() {
    zoom.dispose();
    exposure.dispose();
    stickerController.dispose();
    super.dispose();
  }

  /// Update controller value
  void updateValue({
    bool? hasStickers,
    bool? isEditing,
    bool? hasFocus,
  }) {
    value = value.copyWith(
      hasStickers: hasStickers,
      editingMode: isEditing,
      hasFocus: hasFocus,
    );
  }

  /// Change Textview background
  void changeBackground() {
    final current = value.background;
    final index = gradients.indexOf(current);
    final hasMatch = index != -1;
    final nextIndex = hasMatch && index + 1 < gradients.length ? index + 1 : 0;
    value = value.copyWith(background: gradients[nextIndex]);
  }

  ///
  void changeCameraType(CameraType type) {
    final canSwitch =
        type == CameraType.selfi && lensDirection != CameraLensDirection.front;
    if (canSwitch) {
      switchCameraDirection(CameraLensDirection.front);
    }
    value = value.copyWith(cameraType: type);
  }

  /// Create new camera
  Future<CameraController?> createCamera({
    CameraDescription? cameraDescription,
  }) async {
    // if (cameraDescription == null) {
    //   _controllerNotifier.value = const ControllerValue();
    // }

    var description = cameraDescription ?? value.cameraDescription;
    var cameras = value.cameras;

    // Fetch camera descriptions is description is not available
    if (description == null) {
      cameras = await availableCameras();
      description = cameras[0];
    }

    // create camera controller
    final controller = CameraController(
      description,
      value.resolutionPreset,
      enableAudio: value.enableAudio,
      imageFormatGroup: value.imageFormatGroup,
    );

    // listen controller
    controller.addListener(() {
      if (controller.value.hasError) {
        final error = 'Camera error ${controller.value.errorDescription}';
        _uiHandler.showSnackBar(error);
        _controllerNotifier.value =
            _controllerNotifier.value.copyWith(error: error);
      }
    });

    try {
      await controller.initialize();
      _controllerNotifier.value = ControllerValue(
        controller: controller,
        isReady: true,
      );
      value = value.copyWith(
        cameraDescription: description,
        cameras: cameras,
      );

      if (controller.description.lensDirection == CameraLensDirection.back) {
        unawaited(controller.setFlashMode(value.flashMode));
      }
      unawaited(Future.wait([
        controller.getMinExposureOffset().then(exposure.setMinExposure),
        controller.getMaxExposureOffset().then(exposure.setMaxExposure),
        controller.getMaxZoomLevel().then(zoom.setMaxZoom),
        controller.getMinZoomLevel().then(zoom.setMinZoom),
      ]));
    } on CameraException catch (e) {
      _uiHandler.showExceptionSnackbar(e);
    } catch (e) {
      _uiHandler.showSnackBar(e.toString());
    }

    return controller;

    //
  }

  /// Take picture
  Future<void> takePicture() async {
    if (!initialized) {
      _uiHandler.showSnackBar('Couldn\'t find the camera!');
      return;
    }

    if (value.isTakingPicture) {
      _uiHandler.showSnackBar('Capturing is currently running..');
      return;
    }

    try {
      // Update state
      value = value.copyWith(isTakingPicture: true);

      final xFile = await controller.takePicture();
      final file = File(xFile.path);
      final data = await file.readAsBytes();
      final entity = await PhotoManager.editor.saveImage(
        data,
        title: path.basename(file.path),
      );

      if (file.existsSync()) {
        unawaited(file.delete());
      }

      // Update state
      value = value.copyWith(isTakingPicture: false);

      if (entity != null) {
        _uiHandler.pop<AssetEntity>(entity);
      } else {
        _uiHandler.showSnackBar('Something went wrong! Please try again');
        value = value.copyWith(isTakingPicture: false);
        return;
      }
    } on CameraException catch (e) {
      _uiHandler.showSnackBar('Exception occured while capturing picture : $e');
      value = value.copyWith(isTakingPicture: false);
      return;
    }
  }

  /// Switch camera direction
  void switchCameraDirection(CameraLensDirection direction) {
    try {
      final description = value.cameras.firstWhere(
        (element) => element.lensDirection == direction,
      );
      createCamera(cameraDescription: description);
    } on CameraException catch (e) {
      _uiHandler.showExceptionSnackbar(e);
    }
  }

  /// Set flash mode
  void changeFlashMode() async {
    if (!initialized) {
      _uiHandler.showSnackBar('Couldn\'t find the camera!');
      return;
    }

    try {
      final mode = controller.value.flashMode == FlashMode.off
          ? FlashMode.always
          : FlashMode.off;
      value = value.copyWith(flashMode: mode);
      await controller.setFlashMode(mode);
    } on CameraException catch (e) {
      _uiHandler.showExceptionSnackbar(e);
      rethrow;
    }
  }

  /// Start video recording
  Future<void> startVideoRecording() async {
    if (!initialized) {
      _uiHandler.showSnackBar('Couldn\'t find the camera!');
      return;
    }

    if (value.isRecordingVideo) {
      _uiHandler.showSnackBar('Recording is already started!');
      return;
    }

    try {
      await controller.startVideoRecording();
      value = value.copyWith(
        isRecordingVideo: true,
        isRecordingPaused: false,
      );
    } on CameraException catch (e) {
      _uiHandler.showExceptionSnackbar(e);
      value = value.copyWith(isRecordingVideo: false);
      return;
    }
  }

  /// Stop/Complete video recording
  void stopVideoRecording() async {
    if (!initialized) {
      _uiHandler.showSnackBar('Couldn\'t find the camera!');
      return;
    }

    if (value.isRecordingVideo) {
      try {
        final xfile = await controller.stopVideoRecording();
        final file = File(xfile.path);
        final entity = await PhotoManager.editor.saveVideo(
          file,
          title: path.basename(xfile.path),
        );
        if (file.existsSync()) {
          unawaited(file.delete());
        }
        // Update state
        value = value.copyWith(isRecordingVideo: false);

        if (entity != null) {
          _uiHandler.pop(entity);
          return;
        } else {
          _uiHandler.showSnackBar('Something went wrong! Please try again');
          return;
        }
      } on CameraException catch (e) {
        _uiHandler.showExceptionSnackbar(e);
        // Update state
        value = value.copyWith(isRecordingVideo: false);
        rethrow;
      }
    } else {
      _uiHandler.showSnackBar('Recording not found!');
      return;
    }
  }

  /// Pause video recording
  void pauseVideoRecording() async {
    if (!initialized) {
      _uiHandler.showSnackBar('Couldn\'t find the camera!');
      return;
    }

    if (value.isRecordingVideo) {
      try {
        await controller.pauseVideoRecording();
        // Update state
        value = value.copyWith(isRecordingPaused: true);
      } on CameraException catch (e) {
        // Update state
        _uiHandler.showExceptionSnackbar(e);
        rethrow;
      }
    } else {
      _uiHandler.showSnackBar('Recording not found!');
      return;
    }
  }

  /// Resume video recording
  void resumeVideoRecording() async {
    if (!initialized) {
      _uiHandler.showSnackBar('Couldn\'t find the camera!');
      return;
    }

    if (value.isRecordingPaused) {
      try {
        await controller.resumeVideoRecording();
        // Update state
        value = value.copyWith(isRecordingPaused: false);
      } on CameraException catch (e) {
        _uiHandler.showExceptionSnackbar(e);
        rethrow;
      }
    } else {
      _uiHandler.showSnackBar('Couldn\'t resume the video!');
      return;
    }
  }

  /// Lock unlock capture orientation i,e. Portrait and Landscape
  void lockUnlockCaptureOrientation() async {
    if (!initialized) {
      _uiHandler.showSnackBar('Couldn\'t find the camera!');
      return;
    }

    if (controller.value.isCaptureOrientationLocked) {
      await controller.unlockCaptureOrientation();
      _uiHandler.showSnackBar('Capture orientation unlocked');
    } else {
      await controller.lockCaptureOrientation();
      _uiHandler.showSnackBar(
        '''Capture orientation locked to ${controller.value.lockedCaptureOrientation.toString().split('.').last}''',
      );
    }
  }

  //
}

///
class ActionValue {
  ///
  ActionValue({
    this.cameraDescription,
    this.cameras = const [],
    this.enableAudio = true,
    this.cameraType = CameraType.text,
    this.flashMode = FlashMode.off,
    this.resolutionPreset = ResolutionPreset.medium,
    this.imageFormatGroup = ImageFormatGroup.jpeg,
    this.isTakingPicture = false,
    this.isRecordingVideo = false,
    this.isRecordingPaused = false,
    this.hasFocus = false,
    this.editingMode = false,
    this.hasStickers = false,
    GradientColor? background,
  }) : background = background ?? gradients[0];

  ///
  final CameraDescription? cameraDescription;

  ///
  final List<CameraDescription> cameras;

  ///
  final CameraType cameraType;

  ///
  final bool enableAudio;

  ///
  final FlashMode flashMode;

  ///
  final ResolutionPreset resolutionPreset;

  ///
  final ImageFormatGroup imageFormatGroup;

  ///
  final bool isTakingPicture;

  ///
  final bool isRecordingVideo;

  ///
  final bool isRecordingPaused;

  ///
  final bool hasFocus;

  ///
  final bool editingMode;

  ///
  final bool hasStickers;

  ///
  final GradientColor background;

  ///
  ActionValue copyWith({
    CameraDescription? cameraDescription,
    List<CameraDescription>? cameras,
    CameraType? cameraType,
    bool? enableAudio,
    FlashMode? flashMode,
    bool? isTakingPicture,
    bool? isRecordingVideo,
    bool? isRecordingPaused,
    bool? hasFocus,
    bool? editingMode,
    bool? hasStickers,
    GradientColor? background,
  }) {
    return ActionValue(
      cameraDescription: cameraDescription ?? this.cameraDescription,
      cameras: cameras ?? this.cameras,
      cameraType: cameraType ?? this.cameraType,
      enableAudio: enableAudio ?? this.enableAudio,
      flashMode: flashMode ?? this.flashMode,
      isTakingPicture: isTakingPicture ?? this.isTakingPicture,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isRecordingPaused: isRecordingPaused ?? this.isRecordingPaused,
      hasFocus: hasFocus ?? this.hasFocus,
      editingMode: editingMode ?? this.editingMode,
      hasStickers: hasStickers ?? this.hasStickers,
      background: background ?? this.background,
    );
  }
}