import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

List getLocations(prefs) {
  var storedValue = prefs.getString('locations');
  if (storedValue == null) {
    storedValue = jsonEncode([]);
  }
  var locations = jsonDecode(storedValue);
  return locations;
}

void main() {
  bool callbackLocation = false;
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel _channel = const MethodChannel('geolocation_plugin');
  _channel.setMethodCallHandler((MethodCall call) async {
    print(call.method);
    if (call.method == "callbackLocation") {
      callbackLocation = true;

      var lat = call.arguments.split(',')[0];
      var lon = call.arguments.split(',')[1];
      var vel = call.arguments.split(',')[2];
      var isRunningInBackground = call.arguments.split(',')[3];

      if (isRunningInBackground == "true") {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List locations = getLocations(prefs);
        locations.add({'lat': lat, 'lon': lon});
        prefs.setString('locations', jsonEncode(locations));
      }
    }
  });

  runApp(MyApp(
    callbackLocation: callbackLocation,
  ));
}

class MyApp extends StatelessWidget {
  bool callbackLocation = false;

  MyApp({this.callbackLocation});

  @override
  Widget build(BuildContext context) {
    if (callbackLocation) {
      return SizedBox();
    }

    return MaterialApp(
      title: 'Background Geolocation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<LatLng> points = <LatLng>[];

  @override
  void initState() {
    super.initState();
    PermissionHandler().requestPermissions(
        [PermissionGroup.locationAlways, PermissionGroup.locationAlways]);
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var i = 0;
      print(prefs.getString('locations'));
      List locations = getLocations(prefs);
      if (locations.length > 0) {
        points.clear();
      } else {
        points = <LatLng>[
          new LatLng(-22.849477, -47.160276),
          new LatLng(-22.849744, -47.159847),
          new LatLng(-22.852884, -47.155100),
          new LatLng(-22.854505, -47.152386),
          new LatLng(-22.857330, -47.145885),
        ];
      }
      while (i < locations.length) {
        points.add(new LatLng(double.parse(locations[i]['lat']),
            double.parse(locations[i]['lon'])));
        i++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Geolocation'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.remove('locations');
            },
            icon: Icon(Icons.delete),
          )
        ],
      ),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(-22.848923, -47.161038),
            zoom: 13.0,
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            PolylineLayerOptions(polylines: [
              new Polyline(points: points, strokeWidth: 5.0, color: Colors.blue)
            ]),
          ],
        ),
      ),
    );
  }
}
