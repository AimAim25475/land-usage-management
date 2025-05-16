import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  MapType _currentMapType = MapType.normal;
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final Set<Marker> _markers = {};
  final GlobalKey _mapKey = GlobalKey();

  final LatLng _center = const LatLng(45.521563, -122.677433);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal
              ? MapType.satellite
              : MapType.normal;
    });
  }

  void _goToCoordinates() {
    final double? lat = double.tryParse(_latController.text);
    final double? lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null) {
      final LatLng target = LatLng(lat, lng);
      mapController.animateCamera(CameraUpdate.newLatLng(target));
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(target.toString()),
            position: target,
            infoWindow: InfoWindow(
              title: 'Selected Location',
              snippet: 'Lat: $lat, Lng: $lng',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });
    }
  }

  Future<Uint8List?> captureMapImage() async {
    RenderRepaintBoundary boundary =
        _mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    var image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } //แปลงเป็น png

  Uint8List cropCenter(Uint8List originalBytes) {
    img.Image original = img.decodeImage(originalBytes)!;
    int size = 512;
    int x = (original.width - size) ~/ 2;
    int y = (original.height - size) ~/ 2;

    img.Image cropped = img.copyCrop(
      original,
      x: x,
      y: y,
      width: size,
      height: size,
    );
    return Uint8List.fromList(img.encodePng((cropped)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            key: _mapKey,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              mapType: _currentMapType,
              markers: _markers,
            ),
          ),
          Center(
            child: Container(
              width: 170, // ปรับขนาดให้ตรงกับ crop (เช่น 512 / 3)
              height: 170,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withOpacity(0.8),
                  width: 2,
                ),
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 10,
            child: SizedBox(
              width: 56,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6.0,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Container(
                        height: 200,
                        padding: EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _latController,
                                decoration: InputDecoration(
                                  labelText: 'Latitude',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: _lngController,
                                decoration: InputDecoration(
                                  labelText: 'Longitude',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _goToCoordinates();
                                },
                                child: Text('Go to Coordinates'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Icon(Icons.directions, size: 24),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 10,
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                heroTag: "MapType",
                backgroundColor: Colors.purple.shade50,
                elevation: 6.0,
                onPressed: _onMapTypeButtonPressed,
                child: Icon(Icons.map, size: 24),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 10,
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                heroTag: "CaptureButton",
                backgroundColor: Colors.purple.shade50,
                elevation: 6.0,
                onPressed: () async {
                  Uint8List? image = await captureMapImage();
                  if (image != null) {
                    Uint8List cropped = cropCenter(image);

                    // Save PNG
                    final appDir = await getApplicationDocumentsDirectory();
                    final imagesDir = Directory('${appDir.path}/images');
                    if (!imagesDir.existsSync()) {
                      imagesDir.createSync(recursive: true);
                    }
                    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                    String pngPath = '${imagesDir.path}/captured_$timestamp.png';
                    File pngFile = File(pngPath);
                    await pngFile.writeAsBytes(cropped);

                    // Convert PNG to TIFF
                    img.Image? decodedImage = img.decodeImage(cropped);
                    if (decodedImage != null) {
                      String tifPath = pngPath.replaceAll('.png', '.tif');
                      File(tifPath).writeAsBytesSync(img.encodeTiff(decodedImage));
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Image saved and converted to TIFF!')),
                    );
                  }
                },
                child: Icon(Icons.camera, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
