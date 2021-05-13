import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'drawer.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class completedTransactions extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _completedTransactionState();
}

class _completedTransactionState extends State<completedTransactions> {
  final firestoreInstance = cf.FirebaseFirestore.instance;
  User firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text("Completed Transactions"),
      ),
      body: StreamBuilder(
          stream: firestoreInstance
              .collection('Users')
              .doc(firebaseUser.uid)
              .collection('user_transactions')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            int a = 0;
            return ListView(
              children: snapshot.data.docs.map((document) {
                a = a + 1;
                String products = "";
                var product_names = document.data()['product_names'];
                document.data()['products'].forEach((k, v) => {
                      products = products + product_names[k],
                      products = products + " " + v,
                      products = products + "\n"
                    });
                return Container(
                  child: Container(
                    child: Card(
                      color: (a % 2 == 0) ? Colors.grey : Colors.blue,
                      //alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () {
                          getStringValuesSF() async {
                            Map<String, dynamic> shoppingcart =
                                document.data()['products'];
                            List<String> cart = [];
                            //for (var i = 0; i < shoppingcart.keys.length; i++) {
                            //  cart.add(shoppingcart.keys.elementAt(i));
                            //}
                            //print(cart);
                            for (var key in shoppingcart.keys) {
                              try {
                                String imagePath =
                                    "${document.data()['store']}/product_images/${key}.jpg";
                                String url = await firebase_storage
                                    .FirebaseStorage.instance
                                    .ref()
                                    .child(imagePath)
                                    .getDownloadURL();
                                cart.add(url);
                              } catch (e) {
                                var imagePath = 'no-image.jpg';
                                String url = await firebase_storage
                                    .FirebaseStorage.instance
                                    .ref()
                                    .child(imagePath)
                                    .getDownloadURL();
                                cart.add(url);
                              }
                            }
                            return cart;
                          }

                          showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return Scaffold(
                                  /*drawer: MyDrawer(),
                                  appBar: AppBar(
                                    title: Text("Transaction Product"),
                                  ),*/
                                  body: Container(
                                      child: FutureBuilder(
                                          future: getStringValuesSF(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot snapshot) {
                                            print(snapshot.data);
                                            if (snapshot.data == null) {
                                              return Container(
                                                  child: Center(
                                                      child:
                                                          Text("Loading...")));
                                            } else {
                                              return ListView.builder(
                                                itemCount: snapshot.data.length,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  List keys = document
                                                      .data()['products']
                                                      .keys
                                                      .toList();
                                                  var item = keys[index];
                                                  return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 2.0,
                                                      ),
                                                      child: Card(
                                                          elevation: 4.0,
                                                          child: ListTile(
                                                            leading:
                                                                Image.network(
                                                                    snapshot.data[
                                                                        index],
                                                                    height:
                                                                        200.0),
                                                            title: Text(document
                                                                        .data()[
                                                                    'product_names']
                                                                [item]),
                                                            trailing: Text(document
                                                                            .data()[
                                                                        'products']
                                                                    [item] +
                                                                " for \$" +
                                                                document.data()[
                                                                        'product_prices']
                                                                    [item]),
                                                          )));
                                                },
                                              );
                                            }
                                          })),
                                );
                              });
                        },
                        child: Text(
                            "Price: \$" +
                                document.data()['total_price'].toString() +
                                "\n Store: " +
                                document.data()['store_name'].toString() +
                                "\n Time: " +
                                document.data()['timestamp'].toString() +
                                "\n Products: \n" +
                                products +
                                "\n",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
    );
  }
}
