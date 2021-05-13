import 'package:flutter/material.dart';
import 'cart.dart';
import 'dish_object.dart';
import 'store_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(title: 'Place order'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> _dishes = List<String>();
  List<String> _prices = List<String>();
  List<String> _ids = List<String>();

  Set<String> _cartList = Set<String>();

  Map<String, dynamic> _shoppingcart = Map<String, dynamic>();

  @override
  void initState() {
    super.initState();
    getStringValuesSF();
    _populateDishes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                if (_cartList.isNotEmpty)
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
      body: _buildGridView(),
    );
  }

  ListView _buildListView() {
    return ListView.builder(
      itemCount: _dishes.length,
      itemBuilder: (context, index) {
        var item = _dishes[index];
        var price = _prices[index];
        var id = _ids[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 2.0,
          ),
          child: Card(
            elevation: 4.0,
            child: ListTile(
              title: Text(item),
              trailing: GestureDetector(
                child: (!_cartList.contains(item))
                    ? Icon(
                        Icons.add_circle,
                        color: Colors.green,
                      )
                    : Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                      ),
                onTap: () {
                  setState(() {
                    if (!_cartList.contains(item))
                      _cartList.add(item);
                    else
                      _cartList.remove(item);
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  GridView _buildGridView() {
    return GridView.builder(
        padding: const EdgeInsets.all(4.0),
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: _dishes.length,
        itemBuilder: (context, index) {
          var item = _dishes[index];
          var price = _prices[index];
          var id = _ids[index];
          return Card(
              elevation: 4.0,
              child: Stack(
                fit: StackFit.loose,
                alignment: Alignment.center,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        item,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.subhead,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        price,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.subhead,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 8.0,
                      bottom: 8.0,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: GestureDetector(
                        child: Icon(
                          Icons.add_circle,
                          color: Colors.green,
                        ),
                        onTap: () {
                          setState(() {
                            _cartList.add(id);
                            if (_shoppingcart.containsKey(id)) {
                              _shoppingcart[id][0] = _shoppingcart[id][0] + 1;
                            } else {
                              _shoppingcart[id] = [1, price, item];
                            }
                            var s = json.encode(_shoppingcart);
                            print(s);
                            addToCart(s);
                          });
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 8.0,
                      bottom: 8.0,
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        child: Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onTap: () {
                          setState(() {
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
                    ),
                  ),
                ],
              ));
        });
  }

  addToCart(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cart', value);
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

  void _populateDishes() {
    var list = <String>[];
    var prices = <String>[];
    var ids = <String>[];
    FirebaseFirestore.instance
        .collection(Store.storeId)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) {
                list.add(doc["name"]);
                prices.add(doc["price"]);
                ids.add(doc.id);
                setState(() {
                  _dishes = list;
                  _prices = prices;
                  _ids = ids;
                });
              })
            });
  }
}
