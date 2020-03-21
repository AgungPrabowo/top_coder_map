import 'dart:convert';
import 'package:flag/flag.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:top_coder_map/modelCorona.dart';
import 'main.dart';
import 'package:http/http.dart' as http;

class Corona extends StatefulWidget {
  @override
  _CoronaState createState() => _CoronaState();
}

class _CoronaState extends State<Corona> {
  Future<List<ModelCorona>> listCorona;
  final MapController _mapController = MapController();

  Future<List<ModelCorona>> coronaData() async {
    final client = http.Client();
    try {
      final response = await client
          .get('https://coronavirus-tracker-api.herokuapp.com/v2/locations');
      final result = json.decode(response.body);
      List<ModelCorona> dataCorona = (result["locations"] as List)
          .map((data) => ModelCorona.fromJson(data))
          .toList();
      return dataCorona;
    } finally {
      client.close();
    }
  }

  @override
  void initState() {
    listCorona = coronaData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Corona Virus Tracker"),
      ),
      body: FutureBuilder<List<ModelCorona>>(
        future: listCorona,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Text("null");
              break;
            case ConnectionState.waiting:
              return Container(
                height: 200.0,
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                alignment: Alignment.bottomCenter,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
              break;
            case ConnectionState.done:
              return Stack(
                children: <Widget>[
                  CoronaMap(
                      documents: snapshot.data,
                      initialPosition: LatLng(-6.992149, 110.404104),
                      mapController: _mapController),
                  CoronaListTile(
                      documents: snapshot.data, mapController: _mapController),
                ],
              );
              break;
            case ConnectionState.active:
              return Text("");
              break;
          }
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: FlutterLogo(
                colors: Colors.red,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text(
                'Ice Cream Stores',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MyApp()),
                    (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              title: Text(
                'Corona Virus Tracker',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Corona()),
                    (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CoronaMap extends StatelessWidget {
  CoronaMap({
    Key key,
    @required this.documents,
    @required this.initialPosition,
    @required this.mapController,
  }) : super(key: key);

  final List<ModelCorona> documents;
  final LatLng initialPosition;
  final MapController mapController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double computedRadius(int confirmed) {
    double total = confirmed / 10;
    return total > 100 ? 90 : total < 10 ? 10 : total;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: initialPosition,
        zoom: 5,
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
                  builder: (ctx) => Container(
                    child: GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text('Tapped on green FlutterLogo Marker'),
                        ));
                      },
                      child: Icon(
                        Icons.location_on,
                        size: 20.0,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                  point: LatLng(double.parse(document.coordinate.latitude),
                      double.parse(document.coordinate.longitude)),
                ),
              )
              .toList(),
        ),
        CircleLayerOptions(
          circles: documents
              .map(
                (document) => CircleMarker(
                  point: LatLng(double.parse(document.coordinate.latitude),
                      double.parse(document.coordinate.longitude)),
                  color: Colors.red.withOpacity(0.3),
                  borderStrokeWidth: 3.0,
                  borderColor: Colors.transparent,
                  radius: computedRadius(document.latest.confirmed),
                ),
              )
              .toList(),
        )
      ],
    );
  }
}

class CoronaListTile extends StatefulWidget {
  const CoronaListTile({
    Key key,
    @required this.documents,
    @required this.mapController,
  }) : super(key: key);

  final List<ModelCorona> documents;
  final MapController mapController;

  @override
  _CoronaListTileState createState() => _CoronaListTileState();
}

class _CoronaListTileState extends State<CoronaListTile>
    with TickerProviderStateMixin {
  void _animatedMapMove(LatLng destLocation, double destZoom) {
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

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 100,
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
                      title: Text(widget.documents[index].country),
                      subtitle: Text(
                        "Confirmed : ${widget.documents[index].latest.confirmed} \nDeaths : ${widget.documents[index].latest.deaths} \nRecovered : ${widget.documents[index].latest.recovered} \nProvince : ${widget.documents[index].province}",
                      ),
                      isThreeLine: true,
                      leading: Container(
                        child: Flags.getMiniFlag(
                            widget.documents[index].countryCode, 60, 60),
                      ),
                      onTap: () {
                        _animatedMapMove(
                            LatLng(
                                double.parse(widget
                                    .documents[index].coordinate.latitude),
                                double.parse(widget
                                    .documents[index].coordinate.longitude)),
                            8);
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
