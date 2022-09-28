import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pdfs;
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'mobile.dart' if (dart.library.html) 'web.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart' as ml;
import 'details.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<File> _files = [];
  String _text = '';
  XFile _image;

  Future<void> _convertImageToPDF() async {
    PdfDocument document = PdfDocument();

    for (int i = 0; i < _files.length; i++) {
      PdfPage page = document.pages.add();
      String file = _files[i].path;
      final PdfImage image = PdfBitmap(await _readImageData('$file'));
      page.graphics.drawImage(
          image, Rect.fromLTWH(0, 0, page.size.width, page.size.height));
    }
    List<int> bytes = document.save();
    //Dispose the document.
    document.dispose();
    //Get external storage directory
    Directory directory = (await getApplicationDocumentsDirectory());
    //Get directory path
    String path = directory.path;
    //Create an empty file to write PDF data
    File file = File('$path/Output.pdf');
    //Write PDF data
    await file.writeAsBytes(bytes, flush: true);
    //Open the PDF document in mobile
    OpenFile.open('$path/Output.pdf');
  }

  Future<List<int>> _readImageData(String name) async {
    File _file = File('$name');
    Uint8List _bytes = _file.readAsBytesSync();
    final ByteData data = ByteData.view(_bytes.buffer);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        centerTitle: true,
        actions: [
          FlatButton(
            onPressed: scanText,
            child: Text(
              'Scan',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: new GridView.builder(
              itemCount: _files.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) {
                return displaySelectedFile(_files[index]);
              },
            ),
          ),
          Positioned(
            left: 30.0,
            bottom: 18.0,
            child: RaisedButton(
              onPressed: _convertImageToPDF,
              color: Colors.blue,
              child: Text(
                'Get PDF',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          XFile cameraFile;
          print('Pressed');
          cameraFile =
              await ImagePicker().pickImage(source: ImageSource.camera);
          _image = cameraFile;
          print(cameraFile.path);
          List<File> temp = _files;
          final File selectedImage = File(cameraFile.path);
          temp.add(selectedImage);
          setState(() {
            _files = temp;
          });
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  Future scanText() async {
    showDialog(
        context: context,
        builder: (_) => new Center(
              child: CircularProgressIndicator(),
            ));
    final ml.FirebaseVisionImage visionImage =
        ml.FirebaseVisionImage.fromFile(File(_image.path));
    final ml.TextRecognizer textRecognizer =
        ml.FirebaseVision.instance.textRecognizer();
    final ml.VisionText visionText =
        await textRecognizer.processImage(visionImage);

    for (ml.TextBlock block in visionText.blocks) {
      for (ml.TextLine line in block.lines) {
        _text += line.text + '\n';
      }
    }

    Navigator.of(context).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Details(_text)));
  }

  Widget displaySelectedFile(File file) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        height: 200.0,
        width: 200.0,
        child: Image.file(file),
      ),
    );
  }
}
