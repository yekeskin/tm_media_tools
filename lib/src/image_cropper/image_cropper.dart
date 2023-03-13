import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tm_native_media/tm_native_media.dart';

///
class ImageCropper extends StatefulWidget {
  ///
  ImageCropper({
    required this.input,
    required this.callback,
    Key? key,
    this.output,
  }) : super(key: key);

  /// Input file
  final File input;

  /// Output file
  File? output;

  /// Will be called once the image is processed
  final void Function(File) callback;

  ///
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();

  @override
  ImageCropperState createState() => ImageCropperState();
}

///
class ImageCropperState extends State<ImageCropper> {
  bool _verticalFlip = false;
  int _rotate = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Expanded(
                child: ExtendedImage.file(
                  widget.input,
                  extendedImageEditorKey: widget.editorKey,
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.editor,
                  initEditorConfigHandler: (state) {
                    return EditorConfig(
                      maxScale: 8,
                      editorMaskColorHandler: (ctx, pointerDown) {
                        return Colors.black
                            .withOpacity(pointerDown ? 0.4 : 0.8);
                      },
                      lineColor: Colors.white.withOpacity(0.7),
                      cornerColor: Colors.white,
                    );
                  },
                ),
              ),
              ColoredBox(
                color: Colors.black,
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Flip',
                        icon: const Icon(Icons.flip),
                        onPressed: () {
                          widget.editorKey.currentState!.flip();
                          _verticalFlip = !_verticalFlip;
                        },
                      ),
                      IconButton(
                        tooltip: 'Rotate',
                        icon: const Icon(Icons.rotate_right),
                        onPressed: () {
                          widget.editorKey.currentState!.rotate();
                          _rotate = (_rotate + 90) % 360;
                        },
                      ),
                      IconButton(
                        tooltip: 'Done',
                        icon: const Icon(Icons.done),
                        onPressed: () async {
                          final rect =
                              widget.editorKey.currentState!.getCropRect();

                          File outputFile;
                          if (widget.output != null) {
                            outputFile = widget.output!;
                          } else {
                            final tempDir = await getTemporaryDirectory();
                            tempDir.createSync(recursive: true);
                            outputFile = File(
                              path.join(
                                tempDir.path,
                                'crop_${path.basename(widget.input.path)}',
                              ),
                            );
                          }

                          final output = await TMNativeMedia.processImage(
                            widget.input.path,
                            outputFile.path,
                            cropX: rect!.left.toInt(),
                            cropY: rect.top.toInt(),
                            cropWidth: rect.width.toInt(),
                            cropHeight: rect.height.toInt(),
                            verticalFlip: _verticalFlip,
                            rotate: _rotate,
                          );
                          widget.callback(output);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 8,
            top: 16,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                height: 36,
                width: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black26,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
