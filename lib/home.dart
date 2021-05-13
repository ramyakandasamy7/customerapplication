import 'dart:convert';
import 'dart:ffi';
//import 'dart:html';
import 'dart:math' show cos, sqrt, asin;
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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'product_main.dart';
import 'search_product.dart';
import 'testproduct.dart';
import 'shopping_list.dart';
import 'user_profile.dart';
import 'drawer.dart';
import 'package:flutter_icons/flutter_icons.dart';

class Home extends StatefulWidget {
  final String title = "Basket";
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Home> {
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

  void showProgresWheel() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [new CircularProgressIndicator()])),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [new Text("Finding your location...")])),
            ],
          ),
        );
      },
    );
  }

  void closeProgressDialog() {
    Navigator.pop(context);
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

  Future<Map<String, double>> getLocation() async {
    showProgresWheel();
    final geo = Geoflutterfire();
    final _firestore = FirebaseFirestore.instance;
    var collectionReference = _firestore.collection('Stores');
    var allDocs = await collectionReference.get();

    double radius = 1000;
    String field = 'geohash';

    Position res = await Geolocator().getCurrentPosition();
    print("TESTING: ${res}");
    final coord = new Coordinates(res.latitude, res.longitude);
    GeoFirePoint center =
        geo.point(latitude: res.latitude, longitude: res.longitude);
    print("COORDINATES: ${coord}");
    GeoFirePoint myLocation =
        geo.point(latitude: res.latitude, longitude: res.longitude);
    print("POSITION: ${myLocation.data}");

    Stream<List<DocumentSnapshot>> stream = geo
        .collection(collectionRef: collectionReference)
        .within(center: center, radius: radius, field: field);
    debugPrint("STREAM: ${allDocs}");

    double lat1 = res.latitude;
    double lon1 = res.longitude;

    allDocs.docs.forEach((el) {
      print(el.data());
      var data = el.data();
      Map<String, dynamic> storeData = data;
      GeoPoint coords = data['coordinates'];
      String id = data['id'].trim();
      storeData['id'] = id;
      String name = data['name'];
      double lat2 = coords.latitude;
      double lon2 = coords.longitude;
      double distance = calculateDistance(lat1, lon1, lat2, lon2);
      print("DISTANCE: ${distance}");
      if (distance < 10) {
        print("USING: ${id}");
        print("USING: ${name}");
        closeProgressDialog();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => Store(store: storeData)),
        );
      }
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    print(Store.storeId != null ? Store.storeId : "No Store Selected");
    return Scaffold(
        drawer: MyDrawer(),
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            Builder(builder: (BuildContext context) {
              return FlatButton(
                child: const Text('Sign out'),
                textColor: Theme.of(context).buttonColor,
                onPressed: () async {
                  String user = await signin.returnAuth();
                  if (user == null) {
                    Scaffold.of(context).showSnackBar(const SnackBar(
                      content: Text('No one has signed in.'),
                    ));
                    return;
                  }
                  signin.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => AuthTypeSelector()),
                  );
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(user + ' has successfully signed out.'),
                  ));
                },
              );
            })
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Text("Step 1: Select Your Store",
                        style: TextStyle(fontSize: 20)),
                  ),
                ),
                SizedBox(height: 100),
                GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    children: <Widget>[
                      Card(
                        color: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        elevation: 20,
                        child: GestureDetector(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(FontAwesome.map_marker,
                                      color: Colors.white, size: 40),
                                  Text("Locate Me",
                                      style: TextStyle(color: Colors.white))
                                ]
                                // button text
                                ),
                            onTap: () {
                              getLocation();
                            }),
                      ),
                      Card(
                        color: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        elevation: 20,
                        child: GestureDetector(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.qr_code_outlined,
                                    color: Colors.white,
                                    size: 40.0,
                                  ),
                                  Text("Scan Store QR",
                                      style: TextStyle(color: Colors.white))
                                ]
                                // button text
                                ),
                            onTap: () {
                              scanQR();
                            }),
                      ),
                    ]),
              ],
            ),
          ),
        )); // This trailing comma makes auto-formatting nicer for build methods
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

Widget _buildCard() => SizedBox(
      height: 210,
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text('Locate Me',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('My City, CA 99984'),
              leading: Icon(
                Icons.restaurant_menu,
                color: Colors.blue[500],
              ),
            ),
            Divider(),
            ListTile(
              title: Text('(408) 555-1212',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              leading: Icon(
                Icons.contact_phone,
                color: Colors.blue[500],
              ),
            ),
            ListTile(
              title: Text('costa@example.com'),
              leading: Icon(
                Icons.contact_mail,
                color: Colors.blue[500],
              ),
            ),
          ],
        ),
      ),
    );

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
}

class Item {
  final String title;

  Item({@required this.title});
}
