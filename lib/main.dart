import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  Stream<QuerySnapshot> _iceCreamStores;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _iceCreamStores = Firestore.instance
        .collection('ice_cream_stores')
        .orderBy('name')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _iceCreamStores,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}}'));
          if (!snapshot.hasData) return Center(child: Text('Loading...'));

          return Stack(
            children: <Widget>[
              StoreMap(
                  documents: snapshot.data.documents,
                  initialPosition: LatLng(-6.992149, 110.404104),
                  mapController: _mapController),
              StoreListTile(
                  documents: snapshot.data.documents,
                  mapController: _mapController),
            ],
          );
        },
      ),
    );
  }
}

class StoreMap extends StatelessWidget {
  StoreMap({
    Key key,
    @required this.documents,
    @required this.initialPosition,
    @required this.mapController,
  }) : super(key: key);

  final List<DocumentSnapshot> documents;
  final LatLng initialPosition;
  final MapController mapController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: initialPosition,
        zoom: 12,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://api.tiles.mapbox.com/v4/"
              "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
          additionalOptions: {
            'accessToken':
                'pk.eyJ1IjoiaW5vb3JleGkiLCJhIjoiY2p6OWozaW1qMXdvNzNvbTJqdzRnZTBkNCJ9.tnXHDq0_ZB_O8qA2m9k5iQ',
            'id': 'mapbox.streets',
          },
        ),
        MarkerLayerOptions(
          markers: documents
              .map(
                (document) => Marker(
                  width: 30,
                  height: 40,
                  builder: (ctx) => Container(
                    child: GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text('Tapped on green FlutterLogo Marker'),
                        ));
                      },
                      child: Icon(
                        Icons.location_on,
                        size: 50.0,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                  point: LatLng(document['coordinates'].latitude,
                      document['coordinates'].longitude),
                ),
              )
              .toList(),
        ),
        PolylineLayerOptions(polylines: [])
      ],
    );
  }
}

class StoreListTile extends StatefulWidget {
  const StoreListTile({
    Key key,
    @required this.documents,
    @required this.mapController,
  }) : super(key: key);

  final List<DocumentSnapshot> documents;
  final MapController mapController;

  @override
  _StoreListTileState createState() => _StoreListTileState();
}

class _StoreListTileState extends State<StoreListTile>
    with TickerProviderStateMixin {
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    print("object");
    final _latTween = Tween<double>(
        begin: widget.mapController.center.latitude,
        end: destLocation.latitude);
    final _lngTween = Tween<double>(
        begin: widget.mapController.center.longitude,
        end: destLocation.longitude);
    final _zoomTween =
        Tween<double>(begin: widget.mapController.zoom, end: destZoom);

    var controllerAnimated = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    Animation<double> animation = CurvedAnimation(
        parent: controllerAnimated, curve: Curves.fastOutSlowIn);

    controllerAnimated.addListener(() {
      widget.mapController.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controllerAnimated.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controllerAnimated.dispose();
      }
    });

    controllerAnimated.forward();
  }

  // ListView.builder(
  //     itemCount: widget.documents.length,
  //     itemBuilder: (builder, index) {
  //       final document = widget.documents[index];
  //       return ListTile(
  //         title: Text(document['name']),
  //         subtitle: Text(document['description']),
  //         leading: Container(
  //           child: CircleAvatar(
  //             backgroundImage: NetworkImage(document['image']),
  //           ),
  //           width: 60,
  //           height: 60,
  //         ),
  //         onTap: () {
  //           _animatedMapMove(
  //               LatLng(document['coordinates'].latitude,
  //                   document['coordinates'].longitude),
  //               16);
  //         },
  //       );
  //     },
  //   );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.documents.length,
            itemBuilder: (builder, index) {
              return SizedBox(
                width: 340,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Card(
                    child: Center(
                        child: ListTile(
                      title: Text(widget.documents[index]['name']),
                      subtitle: Text(widget.documents[index]['description']),
                      leading: Container(
                        child: CircleAvatar(
                          backgroundImage:
                              NetworkImage(widget.documents[index]['image']),
                        ),
                        width: 60,
                        height: 60,
                      ),
                      onTap: () {
                        _animatedMapMove(
                            LatLng(
                                widget.documents[index]['coordinates'].latitude,
                                widget
                                    .documents[index]['coordinates'].longitude),
                            16);
                      },
                    )),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
