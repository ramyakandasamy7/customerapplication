import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'store_page.dart';
import 'home.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart' as cf;

class Payment extends StatefulWidget {
  final String the_price;

  Payment({Key key, this.the_price}) : super(key: key);

  @override
  _PaymentState createState() => new _PaymentState();
}

class _PaymentState extends State<Payment> {
  Token _paymentToken;
  PaymentMethod _paymentMethod;
  String _error;
  final String _currentSecret =
      "sk_test_51FfZTxEJH78PwMb04B5u6AhNrDfdvzPYXlswlENuzp2iDKnZn7Bsuvm0Fsmg6uM7l9PM1kzSA4MB0Tqoxzvy1cxe00aL6rcbhG"; //set this yourself, e.g using curl
  PaymentIntentResult _paymentIntent;
  Source _source;

  final firestoreInstance = cf.FirebaseFirestore.instance;

  ScrollController _controller = ScrollController();

  final CreditCard testCard = CreditCard(
    number: '4242424242424242',
    expMonth: 08,
    expYear: 22,
  );

  getStringValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String stringValue = prefs.getString('cart');
    Map<String, dynamic> shoppingcart = json.decode(stringValue);
    return shoppingcart;
  }

  goToStore() async {
    String storeId = Store.storeId;
    cf.DocumentSnapshot storeDataSH =
        await firestoreInstance.collection('Stores').doc(storeId).get();
    Map<String, dynamic> storeData = storeDataSH.data();
    /*
    For GeoPoint instance, use GeoPoint.latitude and GeoPoint.longitude 
    */
    storeData['id'] = storeId;
    //final storeData = await getStore(barcodeScanRes);
    return storeData;
  }

  clearCart() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString('cart', "{}");
  }

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  initState() {
    super.initState();

    StripePayment.setOptions(StripeOptions(
        publishableKey: "pk_test_xueP3RRIWPJGb3igzkJQcPX200yDf5fc4L",
        merchantId: "horaymond6@gmail.com",
        androidPayMode: 'test'));
  }

  void setError(dynamic error) {
    _scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text(error.toString())));
    setState(() {
      _error = error.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(
          'Payment',
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _source = null;
                _paymentIntent = null;
                _paymentMethod = null;
                _paymentToken = null;
              });
            },
          )
        ],
      ),
      body: ListView(
        controller: _controller,
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          /*RaisedButton(
            child: Text("Create Source"),
            onPressed: () {
              StripePayment.createSourceWithParams(SourceParams(
                type: 'ideal',
                amount: 1,
                currency: 'usd',
                returnURL: 'example://stripe-redirect',
              )).then((source) {
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(content: Text('Received ${source.sourceId}')));
                setState(() {
                  _source = source;
                });
              }).catchError(setError);
            },
          ),
          Divider(),*/
          RaisedButton(
            child: Text("Create Token with Card Form"),
            onPressed: () {
              StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest())
                  .then((paymentMethod) {
                /*StripePayment.confirmPaymentIntent(
                  PaymentIntent(
                    clientSecret: _currentSecret,
                    paymentMethodId: paymentMethod.id,
                  ),
                );*/
                Future<dynamic> the_cart = getStringValuesSF();
                User firebaseUser = FirebaseAuth.instance.currentUser;
                DateTime now = DateTime.now();

                String convertedDateTime =
                    "${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString()}:${now.minute.toString()}";
                the_cart.then((id) {
                  Map<String, String> addTransaction = {};
                  Map<String, String> deductProduct = {};
                  Map<String, String> prices = {};
                  Map<String, String> productNames = {};
                  for (var x in id.keys) {
                    addTransaction[x] = id[x][0].toString();
                    productNames[x] = id[x][2].toString();
                    prices[x] = id[x][1].toString();
                  }
                  for (var y in id.keys) {
                    deductProduct[y] = id[y][0].toString();
                  }
                  for (var z in deductProduct.keys) {
                    print("THE KEY IS:" + z);
                    firestoreInstance.collection(Store.storeId).doc(z).update({
                      "quantity": cf.FieldValue.increment(
                          int.parse(deductProduct[z]) * -1)
                    });
                  }
                  firestoreInstance.collection("store_" + Store.storeId).add({
                    "products": addTransaction,
                    "product_names": productNames,
                    "product_prices": prices,
                    "timestamp": convertedDateTime,
                    "id": Store.storeId,
                    "total_price": widget.the_price,
                    "name": Store.storeName
                  });
                  firestoreInstance
                      .collection('Users')
                      .doc(firebaseUser.uid)
                      .collection('user_transactions')
                      .add({
                    "products": addTransaction,
                    "product_names": productNames,
                    "product_prices": prices,
                    "total_price": widget.the_price,
                    "store": Store.storeId,
                    "timestamp": convertedDateTime,
                    "store_name": Store.storeName
                  }).then((_) {
                    clearCart();
                    /*Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Home()),
                    );*/
                    goToStore().then((data) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => Store(store: data)),
                      );

                      // set up the button
                      Widget okButton = FlatButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      );
                      AlertDialog alert = AlertDialog(
                        title: Text("Transaction Complete"),
                        content: Text("Total Price was \$" + widget.the_price),
                        actions: [
                          okButton,
                        ],
                      );
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return alert;
                        },
                      );
                    });
                  });
                });
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(content: Text('Received ${paymentMethod.id}')));
                setState(() {
                  _paymentMethod = paymentMethod;
                });
              }).catchError(setError);
            },
          ),
          /* RaisedButton(
            child: Text("Create Token with Card"),
            onPressed: () {
              StripePayment.createTokenWithCard(
                testCard,
              ).then((token) {
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(content: Text('Received ${token.tokenId}')));
                setState(() {
                  _paymentToken = token;
                });
              }).catchError(setError);
            },
          ),
          Divider(),
          RaisedButton(
            child: Text("Create Payment Method with Card"),
            onPressed: () {
              StripePayment.createPaymentMethod(
                PaymentMethodRequest(
                  card: testCard,
                ),
              ).then((paymentMethod) {
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(content: Text('Received ${paymentMethod.id}')));
                setState(() {
                  _paymentMethod = paymentMethod;
                });
              }).catchError(setError);
            },
          ),
          RaisedButton(
            child: Text("Create Payment Method with existing token"),
            onPressed: _paymentToken == null
                ? null
                : () {
                    StripePayment.createPaymentMethod(
                      PaymentMethodRequest(
                        card: CreditCard(
                          token: _paymentToken.tokenId,
                        ),
                      ),
                    ).then((paymentMethod) {
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text('Received ${paymentMethod.id}')));
                      setState(() {
                        _paymentMethod = paymentMethod;
                      });
                    }).catchError(setError);
                  },
          ),
          Divider(),
          RaisedButton(
            child: Text("Confirm Payment Intent"),
            onPressed: _paymentMethod == null || _currentSecret == null
                ? null
                : () {
                    print(testCard);
                    StripePayment.confirmPaymentIntent(
                      PaymentIntent(
                        clientSecret: _currentSecret,
                        paymentMethod: PaymentMethodRequest(
                          card: testCard,
                        ),
                        paymentMethodId: _paymentMethod.id,
                      ),
                    ).then((paymentIntent) {
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(
                              'Received ${paymentIntent.paymentIntentId}')));
                      setState(() {
                        _paymentIntent = paymentIntent;
                      });
                    }).catchError(setError);
                  },
          ),
          RaisedButton(
            child: Text("Authenticate Payment Intent"),
            onPressed: _currentSecret == null
                ? null
                : () {
                    StripePayment.authenticatePaymentIntent(
                            clientSecret: _currentSecret)
                        .then((paymentIntent) {
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(
                              'Received ${paymentIntent.paymentIntentId}')));
                      setState(() {
                        _paymentIntent = paymentIntent;
                      });
                    }).catchError(setError);
                  },
          ),*/
          Divider(),
          RaisedButton(
            child: Text("Native payment"),
            onPressed: () {
              if (Platform.isIOS) {
                _controller.jumpTo(450);
              }
              StripePayment.paymentRequestWithNativePay(
                androidPayOptions: AndroidPayPaymentRequest(
                  totalPrice: "0.20",
                  currencyCode: "USD",
                ),
                applePayOptions: ApplePayPaymentOptions(
                  countryCode: 'US',
                  currencyCode: 'USD',
                  items: [
                    ApplePayItem(
                      label: 'Test',
                      amount: '1.00',
                    )
                  ],
                ),
              ).then((token) {
                setState(() {
                  _scaffoldKey.currentState.showSnackBar(
                      SnackBar(content: Text('Received ${token.tokenId}')));
                  _paymentToken = token;
                });
              }).catchError(setError);
            },
          ),
          RaisedButton(
            child: Text("Complete Native Payment"),
            onPressed: () {
              StripePayment.completeNativePayRequest().then((_) {
                Future<dynamic> the_cart = getStringValuesSF();
                User firebaseUser = FirebaseAuth.instance.currentUser;
                DateTime now = DateTime.now();

                String convertedDateTime =
                    "${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString()}:${now.minute.toString()}";
                the_cart.then((id) {
                  Map<String, String> addTransaction = {};
                  Map<String, String> productNames = {};
                  Map<String, String> prices = {};
                  Map<String, String> deductProduct = {};
                  for (var x in id.keys) {
                    addTransaction[x] = id[x][0].toString();
                    productNames[x] = id[x][2].toString();
                    prices[x] = id[x][1].toString();
                  }
                  for (var y in id.keys) {
                    deductProduct[y] = id[y][0].toString();
                  }
                  for (var z in deductProduct.keys) {
                    print("THE KEY IS:" + z);
                    firestoreInstance.collection(Store.storeId).doc(z).update({
                      "quantity": cf.FieldValue.increment(
                          int.parse(deductProduct[z]) * -1)
                    });
                  }
                  firestoreInstance.collection("store_" + Store.storeId).add({
                    "products": addTransaction,
                    "product_names": productNames,
                    "product_prices": prices,
                    "timestamp": convertedDateTime,
                    "id": Store.storeId,
                    "total_price": widget.the_price
                  });
                  firestoreInstance
                      .collection('Users')
                      .doc(firebaseUser.uid)
                      .collection('user_transactions')
                      .add({
                    "products": addTransaction,
                    "product_names": productNames,
                    "product_prices": prices,
                    "total_price": widget.the_price,
                    "store": Store.storeId,
                    "store_name": Store.storeName,
                    "timestamp": convertedDateTime
                  }).then((_) {
                    clearCart();
                    /*Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Home()),
                    );*/
                    goToStore().then((data) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => Store(store: data)),
                      );

                      // set up the button
                      Widget okButton = FlatButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      );
                      AlertDialog alert = AlertDialog(
                        title: Text("Transaction Complete"),
                        content: Text("Total Price was \$" + widget.the_price),
                        actions: [
                          okButton,
                        ],
                      );
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return alert;
                        },
                      );
                    });
                  });
                });
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(content: Text('Completed successfully')));
              }).catchError(setError);
            },
          ),
          Divider(),
          /*Text('Current source:'),
          Text(
            JsonEncoder.withIndent('  ').convert(_source?.toJson() ?? {}),
            style: TextStyle(fontFamily: "Monospace"),
          ),
          Divider(),
          Text('Current token:'),
          Text(
            JsonEncoder.withIndent('  ').convert(_paymentToken?.toJson() ?? {}),
            style: TextStyle(fontFamily: "Monospace"),
          ),
          Divider(),
          Text('Current payment method:'),
          Text(
            JsonEncoder.withIndent('  ')
                .convert(_paymentMethod?.toJson() ?? {}),
            style: TextStyle(fontFamily: "Monospace"),
          ),
          Divider(),
          Text('Current payment intent:'),
          Text(
            JsonEncoder.withIndent('  ')
                .convert(_paymentIntent?.toJson() ?? {}),
            style: TextStyle(fontFamily: "Monospace"),
          ),
          Divider(),
          Text('Current error: $_error'),*/
        ],
      ),
    );
  }
}
