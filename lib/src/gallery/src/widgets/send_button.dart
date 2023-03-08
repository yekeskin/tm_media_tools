import 'package:drishya_picker/drishya_picker.dart';
import 'package:drishya_picker/src/animations/animations.dart';
import 'package:drishya_picker/src/gallery/src/widgets/gallery_builder.dart';
import 'package:flutter/material.dart';

///
class SendButton extends StatelessWidget {
  ///
  const SendButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  ///
  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GalleryBuilder(
        controller: controller,
        builder: (value, child) {
          final crossFadeState = value.selectedEntities.isEmpty
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond;
          return AppAnimatedCrossFade(
            crossFadeState: crossFadeState,
            firstChild: const SizedBox(),
            secondChild: Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  onPressed: () {
                    Navigator.of(context).pop(value.selectedEntities);
                  },
                  shape: const CircleBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  child: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Positioned(
                  top: -6,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    radius: 12,
                    child: Text(
                      '${value.selectedEntities.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
