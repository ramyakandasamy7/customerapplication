import 'package:flutter/material.dart';
import 'dish_object.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'testproduct.dart';
import 'store_page.dart';

import 'payment.dart';
import 'drawer.dart';

class Cart extends StatefulWidget {
  final Set<String> _cart;

  Cart(this._cart);

  @override
  _CartState createState() => _CartState(this._cart);
}

class _CartState extends State<Cart> {
  _CartState(this._cart);

  Set<String> _cart;
  static String the_price;

  getStringValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String stringValue = prefs.getString('cart');
    if (stringValue == null) {
      return [];
    }
    Map<String, dynamic> shoppingcart = json.decode(stringValue);
    List<String> cart = [];
    //for (var i = 0; i < shoppingcart.keys.length; i++) {
    //  cart.add(shoppingcart.keys.elementAt(i));
    //}
    //print(cart);
    for (var key in shoppingcart.keys) {
      String store = Store.storeId;
      String barcode = key;
      String imagePath = "${store}/product_images/${key}.jpg";
      String url = "";
      try {
        url = await firebase_storage.FirebaseStorage.instance
            .ref()
            .child(imagePath)
            .getDownloadURL();
        print("IMAGE URL: ${url}\n");
        shoppingcart[key].add(url);
      } catch (e) {
        imagePath = 'no-image.jpg';
        url = await firebase_storage.FirebaseStorage.instance
            .ref()
            .child(imagePath)
            .getDownloadURL();
        shoppingcart[key].add(url);
      }
    }
    return shoppingcart;
  }

  getPrice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String stringValue = prefs.getString('cart');
    if (stringValue == null) {
      return 0;
    }
    Map<String, dynamic> shoppingcart = json.decode(stringValue);
    List keys = shoppingcart.keys.toList();
    double price = 0.00;
    for (String x in keys) {
      price = price + double.parse(shoppingcart[x][1]) * shoppingcart[x][0];
    }
    return price;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: MyDrawer(),
      appBar: new AppBar(
        title: new Text("Shopping Cart"),
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Payment(the_price: the_price)));
                },
                child: Icon(
                  Icons.credit_card,
                  size: 26.0,
                ),
              )),
        ],
      ),
      body: Container(
        child: FutureBuilder(
          future: getStringValuesSF(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            print(snapshot.data);
            if (snapshot.data == null) {
              return Container(child: Center(child: Text("Loading...")));
            } else {
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  List keys = snapshot.data.keys.toList();
                  var item = keys[index];
                  print(item);
                  return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      child: Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => Product(
                                      barcode: item, store: Store.storeId)),
                            );
                          },
                          child: Card(
                            elevation: 4.0,
                            child: ListTile(
                                leading: Image.network(snapshot.data[item][3],
                                    height: 200.0),
                                title: Text(snapshot.data[item][2].toString()),
                                trailing: Text(
                                    snapshot.data[item][0].toString() +
                                        " for: \$" +
                                        snapshot.data[item][1].toString())),
                          ),
                        ),
                      ));
                },
              );
            }
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 75,
          child: FutureBuilder(
            future: getPrice(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              print(snapshot.data);
              the_price = (snapshot.data * 1.08).toStringAsFixed(2);
              if (snapshot.data != null) {
                return Column(
                  children: <Widget>[
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text("Total Price:", textAlign: TextAlign.start),
                          Text("\$" + snapshot.data.toStringAsFixed(2),
                              textAlign: TextAlign.end),
                        ]),
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text("Tax Amount:", textAlign: TextAlign.start),
                          Text("\$" + (snapshot.data * .08).toStringAsFixed(2),
                              textAlign: TextAlign.end),
                        ]),
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text("Total Price:", textAlign: TextAlign.start),
                          Text("\$" + (snapshot.data * 1.08).toStringAsFixed(2),
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
