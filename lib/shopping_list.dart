import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'home.dart';
import 'drawer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ShoppingList extends StatefulWidget {
  @override
  _MyShoppingListPageState createState() => _MyShoppingListPageState();
}

class _MyShoppingListPageState extends State<ShoppingList> {
  //bool _hasSpeech = false;
  stt.SpeechToText _speech;
  bool _isListening = false;
  double _confidence = 1.0;
  String _text = "Type manually or use voice.";
  var txt = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    readShoppingList();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError: $val'));
      if (available) {
        print("Setting _isListening to true");
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;

            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
              print(_text);
              String newText = txt.text + "\n" + _text;
              writeShoppingList(newText);
              txt.text = newText.replaceAll(
                  new RegExp(r'(?:[\t ]*(?:\r?\n|\r))+'), '\n');
              setState(() => _isListening = false);
              _speech.stop();
            }
          }),
        );
      }
    } else {
      print("Setting _isListening to false");
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: MyDrawer(),
        appBar: AppBar(
          title: Text('Shopping List'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
          animate: _isListening,
          glowColor: Theme.of(context).primaryColor,
          endRadius: 75.0,
          duration: const Duration(milliseconds: 2000),
          repeatPauseDuration: const Duration(milliseconds: 100),
          repeat: true,
          child: FloatingActionButton(
              onPressed: _listen,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Type manually or press the button below to use voice.",
                style: TextStyle(fontSize: 20),
              ),
              Divider(
                height: 20,
                thickness: 2,
                indent: 0,
                endIndent: 0,
              ),
              FlatButton(
                  color: Colors.lightBlueAccent,
                  textColor: Colors.white,
                  padding: EdgeInsets.all(5.0),
                  onPressed: clearShoppingList,
                  child: Text("Clear")),
              TextField(
                keyboardType: TextInputType.multiline,
                maxLines: 20,
                decoration: InputDecoration(
                    hintText: "Type manually or use the voice feature below.",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10.0)),
                controller: txt,
                onChanged: (text) {
                  writeShoppingList(text);
                },
              ),
            ],
          )), // This trailing comma makes auto-formatting nicer for build methods.
        ));
  }

  Future<void> clearShoppingList() async {
    txt.text = "";
    writeShoppingList(txt.text);
  }

  Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    print(directory.path);
    return directory.path;
  }

  Future<File> getLocalFile() async {
    final path = await getLocalPath();
    return File('$path/shopping_list.txt');
  }

  Future<File> writeShoppingList(String text) async {
    final file = await getLocalFile();
    return file.writeAsString('$text');
  }

  Future<void> readShoppingList() async {
    final file = await getLocalFile();
    String contents = await file.readAsString();
    txt.text = contents;
  }
}
