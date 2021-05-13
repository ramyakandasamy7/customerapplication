import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/cart.dart';
import 'package:my_app/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/search_product.dart';
import './store_page.dart';
import './signin_page.dart';
import './main.dart';
import './completedtransactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'product_main.dart';
import 'search_product.dart';
import 'testproduct.dart';
import 'shopping_list.dart';
import 'user_profile.dart';
import 'home.dart';

class MyDrawer extends StatefulWidget {
  final String title = "Basket";
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  SignInPage signin = new SignInPage();
  final firestoreInstance = cf.FirebaseFirestore.instance;
  User firebaseUser = FirebaseAuth.instance.currentUser;
  Future<Map<String, dynamic>> getStore(storeId) async {
    final response = await http.get(
        'https://us-west2-mastersproject-293220.cloudfunctions.net/get_store?sid=${storeId}');

    int statusCode = response.statusCode;
    print("Status CODE: ${statusCode}");
    var json = jsonDecode(response.body);
    json['id'] = storeId;
    return json;
  }

  Future<void> scanQR() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", false, ScanMode.QR);
    print(barcodeScanRes);
    FirebaseFirestore storeDataIns = FirebaseFirestore.instance;
    DocumentSnapshot storeDataSH =
        await storeDataIns.collection('Stores').doc(barcodeScanRes).get();
    Map<String, dynamic> storeData = storeDataSH.data();
    /*
    For GeoPoint instance, use GeoPoint.latitude and GeoPoint.longitude 
    */
    storeData['id'] = barcodeScanRes;
    //final storeData = await getStore(barcodeScanRes);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => Store(store: storeData)),
    );
  }

  Future<void> goStore(barcodeScanRes) async {
    FirebaseFirestore storeDataIns = FirebaseFirestore.instance;
    DocumentSnapshot storeDataSH =
        await storeDataIns.collection('Stores').doc(barcodeScanRes).get();
    Map<String, dynamic> storeData = storeDataSH.data();
    /*
  For GeoPoint instance, use GeoPoint.latitude and GeoPoint.longitude 
  */
    storeData['id'] = barcodeScanRes;
    //final storeData = await getStore(barcodeScanRes);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => Store(store: storeData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(Store.storeId != null ? Store.storeId : "No Store Selected");
    return Drawer(
      child: Container(
        color: Colors.blue,
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(
                  (Store.storeName != null
                      ? "Welcome to " + Store.storeName
                      : "No Store Selected"),
                  style: TextStyle(fontSize: 20)),
            ),
            ListTile(
              title:
                  Text('Locate Store', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Home(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Create a Shopping List',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ShoppingList()),
                );
              },
            ),
            ListTile(
              title:
                  Text('User Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => userProfile(),
                  ),
                );
              },
            ),
            ListTile(
              title:
                  Text('Shopping Cart', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Cart({}),
                  ),
                );
              },
            ),
            ListTile(
                title: Text('Previous Transactions',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => completedTransactions()),
                  );
                }),
            ListTile(
              title: Text('Add Products'),
              enabled: Store.storeId != null,
              onTap: () {
                if (Store.storeId != null) goStore(Store.storeId);
              },
            ),
            ListTile(
              title: Text('Search Product'),
              enabled: Store.storeId != null,
              onTap: () {
                if (Store.storeId != null)
                  showSearch(
                      context: context, delegate: _SearchAppBarDelegate());
              },
            ),
            ListTile(
              title: Text('List Product'),
              enabled: Store.storeId != null,
              onTap: () {
                if (Store.storeId != null)
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(title: "List Products"),
                    ),
                  );
              },
            ),
          ],
        ),
      ), // Populate the Drawer in the next step.
    ); // This trailing comma makes auto-formatting nicer for build methods
  }
}

class StoreData {
  final String id;
  final String name;
  final String address;
  final Float longtitude;
  final Float latitude;

  StoreData({this.id, this.name, this.address, this.longtitude, this.latitude});

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
        id: json["id"],
        name: json["_fieldProto"]["name"]["stringValue"],
        address: json["_fieldProto"]["address"]["stringValue"],
        longtitude: json["_fieldProto"]["coordinates"]["geoPointValue"]
            ["longtitude"],
        latitude: json["_fieldProto"]["coordinates"]["geoPointValue"]
            ["latitude"]);
  }
}

class _SearchAppBarDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          close(context, null);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(Store.storeId).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return new Text('Loading...');

        final results = snapshot.data.docs.where((a) =>
            a['name'].toString().toLowerCase().startsWith(query.toLowerCase()));

        //final test = results.map<Widget>((a) => (a['name']).toList());

        return new ListView.builder(
          itemCount: results.length,
          itemBuilder: (BuildContext context, int index) {
            return new Column(
              children: <Widget>[
                new ListTile(
                  title: new Text(results.elementAt(index)['name'].toString()),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => Product(
                              barcode: results.elementAt(index).id.toString(),
                              store: Store.storeId)),
                    );
                  },
                ),
                new Divider(
                  height: 2.0,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(Store.storeId).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return new Text('Loading...');

        final results = snapshot.data.docs.where((a) =>
            a['name'].toString().toLowerCase().contains(query.toLowerCase()));

        //final test = results.map<Widget>((a) => (a['name']).toList());

        return new ListView.builder(
          itemCount: results.length,
          itemBuilder: (BuildContext context, int index) {
            return new Column(
              children: <Widget>[
                new ListTile(
                  title: new Text(results.elementAt(index)['name'].toString()),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Searching for ' +
                              results.elementAt(index)['name'].toString()),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text('Aisle Number: ' +
                                    results
                                        .elementAt(index)['aisle']
                                        .toString()),
                                Text('Quantity Left: ' +
                                    results
                                        .elementAt(index)['quantity']
                                        .toString()),
                                Text('Price: \$' +
                                    results
                                        .elementAt(index)['price']
                                        .toString()),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Ok'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                new Divider(
                  height: 2.0,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class Item {
  final String title;

  Item({@required this.title});
}
