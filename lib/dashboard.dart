import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:flutter_application_1/inference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? latestImagePath;
  String? predictionFilePath;
  String? predictionPlotPath;
  late ClassificationModel _model;
  bool _isPredicting = false;

  @override
  void initState() {
    super.initState();
    _loadLatestImage();
  }

  void _loadLatestImage() async {
    final dir = Directory('D:/testing deploy on hugging face/LandManagement_backup/flutter_application_1/data/test/images');
    if (dir.existsSync()) {
      final images = dir
          .listSync()
          .where((f) => f.path.endsWith('.png'))
          .toList();
      if (images.isNotEmpty) {
        images.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        setState(() {
          latestImagePath = images.first.path;
        });
      }
    }
  }

  Future<String> _copyModelToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/model.tflite';
    final modelFile = File(modelPath);
    if (!modelFile.existsSync()) {
      final data = await rootBundle.load('models/model.tflite');
      await modelFile.writeAsBytes(data.buffer.asUint8List());
    }
    return modelPath;
  }

  void _startPrediction() async {
    if (_isPredicting) return;
    setState(() {
      _isPredicting = true;
    });
    if (latestImagePath == null || !latestImagePath!.endsWith('.png')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No valid .png file selected for prediction.')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelFilePath = await _copyModelToFile();
      await compute(
        Inference.runInferenceIsolate,
        {
          'imagePath': latestImagePath!,
          'outputDirPath': directory.path,
          'modelFilePath': modelFilePath,
        },
      );

      // Find the latest prediction output in prediction_plots directory
      final predictionDir = Directory('${directory.path}/prediction_plots');
      String? latestPredictionPath;
      if (predictionDir.existsSync()) {
        final preds = predictionDir
            .listSync()
            .where((f) => f.path.endsWith('.png'))
            .toList();
        if (preds.isNotEmpty) {
          preds.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
          latestPredictionPath = preds.first.path;
        }
      }

      setState(() {
        predictionPlotPath = latestPredictionPath;
        _isPredicting = false;
      });

      // Print the output path to the debug console using debugPrint
      if (latestPredictionPath != null) {
        debugPrint('Prediction output saved at: ' + latestPredictionPath);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction completed successfully!')),
      );
    } catch (e) {
      setState(() {
        _isPredicting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _openGallery() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');

      if (!imagesDir.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No images directory found.')),
        );
        return;
      }

      final images = imagesDir
          .listSync()
          .where((file) => file.path.endsWith('.png'))
          .toList();

      if (images.isNotEmpty) {
        final selectedImage = await Navigator.push<File?>(
          context,
          MaterialPageRoute(
            builder: (context) => GalleryPage(images: images),
          ),
        );

        if (selectedImage != null) {
          final tifPath = selectedImage.path.replaceAll('.png', '.tif');
          final tifFile = File(tifPath);

          if (tifFile.existsSync()) {
            final targetDir = Directory('${directory.path}/test/images');
            if (!targetDir.existsSync()) {
              targetDir.createSync(recursive: true);
            }

            final targetImagePath =
                '${targetDir.path}/${selectedImage.path.split('/').last}';
            final targetTifPath =
                '${targetDir.path}/${tifFile.path.split('/').last}';

            File(selectedImage.path).copySync(targetImagePath);
            tifFile.copySync(targetTifPath);

            setState(() {
              latestImagePath = targetImagePath;
              predictionFilePath = targetTifPath;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image selected and moved successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No matching .tif file found for the selected .png image.')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No .png images found in the directory.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadModel() async {
    _model = await PytorchLite.loadClassificationModel(
      "models/model.tflite",
      224, 224,
      5,
    );
  }

  Future<String> _predict(File imageFile) async {
    return await _model.getImagePrediction(await imageFile.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // เปิด gallerty
              Align(
                alignment: Alignment.topCenter,
                child: ElevatedButton(
                  onPressed: _openGallery,
                  child: Text('Open Gallery'),
                ),
              ),
              const SizedBox(height: 16),

              // ดึงเภาพเเคปหน้าจอ 
              if (latestImagePath != null) ...[
                Text('Captured Image:'),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 256,
                    maxWidth: 256,
                  ),
                  child: Image.file(File(latestImagePath!), fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isPredicting ? null : _startPrediction,
                  child: _isPredicting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Predicting...'),
                          ],
                        )
                      : Text('Start Prediction'),
                ),
              ],
              if (predictionPlotPath != null) ...[
                const SizedBox(height: 24),
                Text('Prediction Output:'),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 256,
                    maxWidth: 256,
                  ),
                  child: Image.file(File(predictionPlotPath!), fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                // Show the output file path in the UI
                Text(
                  'Output file path:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  predictionPlotPath!,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  final List<FileSystemEntity> images;

  const GalleryPage({required this.images, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gallery')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context, File(images[index].path));
            },
            child: Image.file(
              File(images[index].path),
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}