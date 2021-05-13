import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'home.dart';
import 'testproduct.dart';
import 'drawer.dart';
import 'package:flutter_icons/flutter_icons.dart';

/*class Store extends StatelessWidget {
  final Map<String, dynamic> store;
  static String storeId;
  Store({Key key, this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String storeName = store['name'];
    storeId = store["id"];
    return MaterialApp(
      title: 'Basket',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyStorePage(title: "Welcome to ${storeName}", store: store["id"]),
    );
  }
}*/

class Store extends StatefulWidget {
  //MyStorePage({Key key, this.title, this.store}) : super(key: key);
  final Map<String, dynamic> store;
  static String storeId;
  static String storeName;
  String title = "Basket";
  Store({Key key, this.store}) : super(key: key);

  @override
  _MyStorePageState createState() => _MyStorePageState();
}

class _MyStorePageState extends State<Store> {
  var storage = firebase_storage.FirebaseStorage.instance;
  String storeImage;
  bool isLoading = false;
  String url =
      "https://storage.googleapis.com/store-images-storage-1/default_store_front.jpg";

  @override
  void initState() {
    super.initState();
    setStoreImage(widget.store["id"]);
  }

  void _setStoreImage(newUrl) {
    setState(() {
      url = newUrl;
    });
  }

  Future<void> setStoreImage(String storeId) async {
    print("STOREID for Image: ${storeId}");
    String imagePath = "${storeId}/store_images/store-front.jpg";
    print(imagePath);
    String url = await firebase_storage.FirebaseStorage.instance
        .ref()
        .child(imagePath)
        .getDownloadURL();
    print("IMAGE URL: ${url}\n");
    _setStoreImage(url);
  }

  Future<void> scanBarcode() async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", false, ScanMode.BARCODE);
    print("PRODUCT BARCODE: ${barcode}");
    //return barcodeScanRes;
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              Product(barcode: barcode, store: widget.store["id"])),
    );
  }

  @override
  Widget build(BuildContext context) {
    Store.storeId = widget.store["id"];
    Store.storeName = widget.store["name"];
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text('Welcome to ' + widget.store["name"]),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Image.network(url),
            Text("Scan a product barcode to start shopping."),
            FlatButton(
                color: Colors.lightBlueAccent,
                textColor: Colors.white,
                padding: EdgeInsets.all(20.0),
                onPressed: () {
                  scanBarcode();
                },
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(FontAwesome.barcode, size: 80)
                          /*Transform.rotate(
                            angle: 90 * pi / 180,
                            child: 
                            
                            
                            Icon(
                              Icons.format_align_justify,
                              color: Colors.white,
                              size: 80.0,
                            )
                            
                            ),
                     */
                          ),
                      Text("Scan Barcode", style: TextStyle(fontSize: 30.0))
                    ])),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
