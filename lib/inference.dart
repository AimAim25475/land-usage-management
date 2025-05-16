import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

class Logger {
  static void log(String message) {
    print(message);
  }
}


class Inference {

  static Future<void> runInferenceIsolate(Map<String, String> args) async {
    final imagePath = args['imagePath']!;
    final outputDirPath = args['outputDirPath']!;
    final modelFilePath = args['modelFilePath']!;

    // load tfLite model from file
    late Interpreter interpreter;
    try {
      interpreter = await Interpreter.fromFile(File(modelFilePath));
    } catch (e) {
      throw Exception('Failed to load model from file: $e');
    }

    // Load the image
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      throw Exception('Image file does not exist: $imagePath');
    }

    final image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) {
      throw Exception('Failed to decode image: $imagePath');
    }

    // pad the image divisible patch size using padding
    const patchSize = 512;
    int paddedWidth = ((image.width + patchSize - 1) ~/ patchSize) * patchSize;
    int paddedHeight = ((image.height + patchSize - 1) ~/ patchSize) * patchSize;
    int padRight = paddedWidth - image.width;
    int padBottom = paddedHeight - image.height;
    img.Image paddedImage = _reflectPad(image, padRight, padBottom);

    
    final patches = _extractPatchesStatic(paddedImage, patchSize, stride: patchSize ~/ 2);

    
    final outputPatches = <img.Image>[];
    for (var i = 0; i < patches.length; i++) {
      final input = _preprocessImageStatic(patches[i]);
      final inputShape = interpreter.getInputTensor(0).shape;
      final inputType = interpreter.getInputTensor(0).type;
      final outputShape = interpreter.getOutputTensor(0).shape;
      final outputType = interpreter.getOutputTensor(0).type;
      Logger.log('Input shape: $inputShape, type: $inputType');
      Logger.log('Output shape: $outputShape, type: $outputType');

      //[1, 4, 512, 512]
      final outputBuffer = List.generate(1, (_) =>
        List.generate(4, (_) =>
          List.generate(512, (_) =>
            List.filled(512, 0.0))));
      interpreter.run(input, outputBuffer);

      // 
      final predPatch = _outputToImageStatic(outputBuffer[0]);
      outputPatches.add(predPatch);
    }

    
    final resultImage = _combinePatchesStatic(outputPatches, paddedWidth, paddedHeight);

    
    final outputDir = Directory('$outputDirPath/prediction_plots');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final resultPath = path.join(outputDir.path, 'captured_$timestamp.png');
    File(resultPath).writeAsBytesSync(img.encodePng(resultImage));

    Logger.log('Inference completed. Result saved to $resultPath');
  }

  // isolate use 
  // preprocess image [1, 3, 512, 512] float32 
  // returns nests list [1, 3, 512, 512] 
  static List<List<List<List<double>>>> _preprocessImageStatic(img.Image image) {
    // 512x512
    int h = image.height;
    int w = image.width;
    //
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];
    List<List<List<double>>> channels = List.generate(3, (c) =>
      List.generate(512, (y) =>
        List.generate(512, (x) {
          double v = 0.0;
          if (x < w && y < h) {
            final pixel = image.getPixel(x, y);
            if (c == 0) {
              v = pixel.r / 255.0;
            } else if (c == 1) {
              v = pixel.g / 255.0;
            } else {
              v = pixel.b / 255.0;
            }
          }
          return (v - mean[c]) / std[c];
        })
      )
    );
    return [channels];
  }

  static List<img.Image> _extractPatchesStatic(img.Image image, int patchSize, {int? stride}) {
    final patches = <img.Image>[];
    final s = stride ?? patchSize;
    for (var y = 0; y <= image.height - patchSize; y += s) {
      for (var x = 0; x <= image.width - patchSize; x += s) {
        final patch = img.copyCrop(image, x: x, y: y, width: patchSize, height: patchSize);
        patches.add(patch);
      }
    }
    return patches;
  }

  static img.Image _combinePatchesStatic(List<img.Image> patches, int width, int height) {
    final result = img.Image(width: width, height: height);
    final count = img.Image(width: width, height: height);
    const patchSize = 512;
    final stride = patchSize ~/ 2;
    int patchIndex = 0;
    for (var y = 0; y <= height - patchSize; y += stride) {
      for (var x = 0; x <= width - patchSize; x += stride) {
        if (patchIndex < patches.length) {
          final patch = patches[patchIndex];
          for (var py = 0; py < patch.height; py++) {
            for (var px = 0; px < patch.width; px++) {
              int rx = x + px;
              int ry = y + py;
              if (rx < width && ry < height) {
                final pixel = patch.getPixel(px, py);
                //RGB values
                final oldPixel = result.getPixel(rx, ry);
                result.setPixelRgb(
                  rx,
                  ry,
                  oldPixel.r + pixel.r,
                  oldPixel.g + pixel.g,
                  oldPixel.b + pixel.b,
                );
                //overlap
                final countPixel = count.getPixel(rx, ry);
                count.setPixelRgb(
                  rx,
                  ry,
                  countPixel.r + 1,
                  countPixel.g + 1,
                  countPixel.b + 1,
                );
              }
            }
          }
          patchIndex++;
        }
      }
    }
    //overlapping regions
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final countPixel = count.getPixel(x, y);
        final c = countPixel.r;
        if (c > 0) {
          final pixel = result.getPixel(x, y);
          result.setPixelRgb(
            x,
            y,
            (pixel.r / c).round(),
            (pixel.g / c).round(),
            (pixel.b / c).round(),
          );
        }
      }
    }
    return result;
  }

  // Visualization [num_classes, 512, 512] 
  static img.Image _outputToImageStatic(List<List<List<double>>> output) {
    // output: [num_classes, 512, 512]
    final h = output[0].length;
    final w = output[0][0].length;
    final imgOut = img.Image(width: w, height: h);
    // tab10
    const tab10 = [
      [31, 119, 180],   // 0
      [255, 127, 14],   // 1
      [44, 160, 44],    // 2
      [214, 39, 40],    // 3
      [148, 103, 189],  // 4
      [140, 86, 75],    // 5
      [227, 119, 194],  // 6
      [127, 127, 127],  // 7
      [188, 189, 34],   // 8
      [23, 190, 207],   // 9
    ];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        int maxIdx = 0;
        double maxVal = output[0][y][x];
        for (int c = 1; c < output.length; c++) {
          if (output[c][y][x] > maxVal) {
            maxVal = output[c][y][x];
            maxIdx = c;
          }
        }
        final color = tab10[maxIdx % tab10.length];
        imgOut.setPixelRgb(x, y, color[0], color[1], color[2]);
      }
    }
    return imgOut;
  }

  //padding helper
  static img.Image _reflectPad(img.Image image, int padRight, int padBottom) {
    int newWidth = image.width + padRight;
    int newHeight = image.height + padBottom;
    img.Image padded = img.Image(width: newWidth, height: newHeight);
    //original
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        padded.setPixel(x, y, image.getPixel(x, y));
      }
    }
    // pad right
    for (int y = 0; y < image.height; y++) {
      for (int x = image.width; x < newWidth; x++) {
        int reflectX = image.width - 1 - (x - image.width);
        reflectX = reflectX.clamp(0, image.width - 1);
        padded.setPixel(x, y, image.getPixel(reflectX, y));
      }
    }
    // pad bottom
    for (int y = image.height; y < newHeight; y++) {
      int reflectY = image.height - 1 - (y - image.height);
      reflectY = reflectY.clamp(0, image.height - 1);
      for (int x = 0; x < newWidth; x++) {
        padded.setPixel(x, y, padded.getPixel(x, reflectY));
      }
    }
    return padded;
  }

  // ใช้ remove method ในการ isolate
}