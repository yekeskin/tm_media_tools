import 'package:flutter/material.dart';
import 'package:drishya_picker/drishya_picker.dart';

import 'grid_view_widget.dart';

///
class Picker1 extends StatefulWidget {
  @override
  _Picker1State createState() => _Picker1State();
}

class _Picker1State extends State<Picker1> {
  final notifier = ValueNotifier(<AssetEntity>[]);
  final controller = DrishyaController();

  Future<void> _pickData({DrishyaSetting? setting}) async {
    final data = await controller.pickDrishya(setting: setting);
    notifier.value = data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick using controller'),
      ),
      body: DrishyaPicker(
        controller: controller,
        // requestType: RequestType.image,
        child: Column(
          children: [
            // Grid view
            Expanded(
              child: Container(
                color: Colors.grey.shade200,
                child: GridViewWidget(notifier: notifier),
              ),
            ),

            // Textfield
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Test field',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  CircleAvatar(
                    backgroundColor: Colors.cyan,
                    minRadius: 10.0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _pickData(
                          setting: DrishyaSetting(
                            selectedItems: notifier.value,
                            maximum: 10,
                            albumSubtitle: 'image only',
                            source: DrishyaSource.camera,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            //
          ],
        ),
      ),
    );
  }
}
