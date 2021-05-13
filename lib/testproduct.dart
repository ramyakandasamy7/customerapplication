import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'cart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'drawer.dart';

class Product extends StatefulWidget {
  Product({Key key, this.barcode, this.store}) : super(key: key);
  final String store;
  final String barcode;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Product> {
  Set<String> _cartList = Set<String>();
  String prod_img_url =
      "https://storage.cloud.google.com/store-images-storage-1/no-image.jpg?authuser=2";

  Map<String, dynamic> _shoppingcart = Map<String, dynamic>();

  @override
  void initState() {
    super.initState();
    getStringValuesSF();
    setProductImage();
  }

  void _setProductImage(newUrl) {
    setState(() {
      prod_img_url = newUrl;
    });
  }

  Future<void> setProductImage() async {
    print("STOREID for Image: ${widget.store}");
    print("BARCODE for Image: ${widget.barcode}");
    String imagePath = "${widget.store}/product_images/${widget.barcode}.jpg";
    print(imagePath);
    try {
      String url = await firebase_storage.FirebaseStorage.instance
          .ref()
          .child(imagePath)
          .getDownloadURL();
      print("IMAGE URL: ${url}\n");
      _setProductImage(url);
    } catch (e) {
      imagePath = 'no-image.jpg';
      String url = await firebase_storage.FirebaseStorage.instance
          .ref()
          .child(imagePath)
          .getDownloadURL();
      print("IMAGE URL: ${url}\n");
      _setProductImage(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("STORE: ############################### " + widget.store);
    print("Default Product Image URL: ${prod_img_url}");
    return Scaffold(
      appBar: AppBar(
        title: Text("Product Page"),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: GestureDetector(
              child: Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Icon(
                    Icons.shopping_cart,
                    size: 36.0,
                  ),
                  if (_cartList.length > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 2.0),
                      child: CircleAvatar(
                        radius: 8.0,
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        child: Text(
                          _shoppingcart.length.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                //if (_cartList.isNotEmpty)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Cart({}),
                  ),
                );
              },
            ),
          )
        ],
      ),
      body: Center(
        child: Container(
            padding: const EdgeInsets.all(10.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: Firestore.instance
                  .collection(widget.store)
                  .doc(widget.barcode)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError)
                  return new Text('Error: ${snapshot.error}');
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return new Text('Loading...');
                  default:
                    return new Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                  child: Text(
                                snapshot.data['name'],
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25.0),
                              )),
                              Expanded(
                                  child: Text(
                                "\$" + snapshot.data['price'],
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 25.0),
                              ))
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                  padding: EdgeInsets.all(10),
                                  child: FittedBox(
                                      child: Image.network(prod_img_url,
                                          height: 200.0),
                                      fit: BoxFit.fill))
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "In cart: " +
                                    (_shoppingcart.containsKey(widget.barcode)
                                        ? _shoppingcart[widget.barcode][0]
                                            .toString()
                                        : '0'),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0),
                              ),
                              Text(
                                "Aisle: " + snapshot.data['aisle'],
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0),
                              ),
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                child: Icon(Icons.remove_circle,
                                    color: Colors.red, size: 100),
                                onTap: () {
                                  setState(() {
                                    String item = widget.barcode;
                                    if (_shoppingcart.containsKey(item) &&
                                        _shoppingcart[item][0] > 1) {
                                      _shoppingcart[item][0] =
                                          _shoppingcart[item][0] - 1;
                                    } else {
                                      _shoppingcart.remove(item);
                                    }
                                    var s = json.encode(_shoppingcart);
                                    print(s);
                                    addToCart(s);
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Icon(Icons.add_circle,
                                    color: Colors.green, size: 100),
                                onTap: () {
                                  setState(() {
                                    String item = widget.barcode;
                                    _cartList.add(item);
                                    if (_shoppingcart.containsKey(item)) {
                                      _shoppingcart[item][0] =
                                          _shoppingcart[item][0] + 1;
                                    } else {
                                      _shoppingcart[item] = [
                                        1,
                                        snapshot.data['price'],
                                        snapshot.data['name']
                                      ];
                                    }
                                    var s = json.encode(_shoppingcart);
                                    print(s);
                                    addToCart(s);
                                  });
                                },
                              ),
                            ]),
                      ],
                    );
                }
              },
            )),
      ),
    );
  }

  getStringValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    Set<String> cart = {};
    Map<String, dynamic> shoppingcart = new Map<String, dynamic>();
    if (prefs.containsKey('cart')) {
      String stringValue = prefs.getString('cart');
      shoppingcart = json.decode(stringValue);
      for (var i = 0; i < shoppingcart.keys.length; i++) {
        cart.add(shoppingcart.keys.elementAt(i));
      }
    }
    setState(() {
      _cartList = cart;
      _shoppingcart = shoppingcart;
    });
  }

  addToCart(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ " + value);
    prefs.setString('cart', value);
  }
}
