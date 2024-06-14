import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({super.key});

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  String googleAPIKey = 'AIzaSyC95rMgVdu8A66B1jZ-0Q7xx4lcewmLHc4';
  late GoogleMapController mapController;
  LatLng? startPoint;
  LatLng? endPoint;
  List<LatLng> polylineCoordinates = [];
  List<Map<String, dynamic>> availableRoutes = [];
  bool settingStartPoint = true;
  Timer? _timer;
  int _currentRouteIndex = 0;
  int _routePointIndex = 0;
  Duration _currentDuration = Duration(milliseconds: 500);
  bool reachEndPoint = false;
  bool isMoving = false;
  int recommendedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _getDirections() async {
    recommendedIndex =0;
    if (startPoint == null || endPoint == null) return;

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${startPoint!.latitude},${startPoint!.longitude}&destination=${endPoint!.latitude},${endPoint!.longitude}&alternatives=true&key=$googleAPIKey';
    var response = await http.get(Uri.parse(url));
    var jsonResponse = jsonDecode(response.body);

    if (jsonResponse['routes'] != null && jsonResponse['routes'].isNotEmpty) {
      setState(() {
        availableRoutes = (jsonResponse['routes'] as List<dynamic>).cast<Map<String, dynamic>>();
        // Do not set the route here, it will be set when the user selects a route
      });
      _recommendRoute();
    }
  }

  void _recommendRoute() {
    int shortestDuration = availableRoutes[0]['legs'][0]['duration']['value'];
    int shortestDistance = availableRoutes[0]['legs'][0]['distance']['value'];
    for (int i = 1; i < availableRoutes.length; i++) {
      int duration = availableRoutes[i]['legs'][0]['duration']['value'];
      int distance = availableRoutes[i]['legs'][0]['distance']['value'];
      if (duration < shortestDuration || (duration == shortestDuration && distance < shortestDistance)) {
        shortestDuration = duration;
        shortestDistance = distance;
        recommendedIndex = i;
      }
    }

    _selectRoute(recommendedIndex);
  }

  void _selectRoute(int index) {
    setState(() {
      _currentRouteIndex = index;
      polylineCoordinates = _decodePolyline(availableRoutes[index]['overview_polyline']['points']);
      _routePointIndex = 0;
      if (_timer != null) {
        _timer!.cancel();
      }
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return points;
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      if (settingStartPoint) {
        startPoint = position;
        startPoint = position;
      } else {
        endPoint = position;
      }
      settingStartPoint = !settingStartPoint;

      // reset the route
      reachEndPoint = false;

      // don't want to show previous polyline when it comes to choose new points
      polylineCoordinates=[];

      isMoving = false;
    });
  }

  void _startJourney() {
    reachEndPoint = false;
    isMoving =true;
    setState(() {});
    if (polylineCoordinates.isEmpty) return;
    _timer = Timer.periodic(_currentDuration, (timer) {
      setState(() {
        if (_routePointIndex < polylineCoordinates.length - 1) {
          _routePointIndex++;
          startPoint = polylineCoordinates[_routePointIndex];
        } else {
          timer.cancel();

          //in the case of while moving on route and make a new route points, polylineCoordinates goes to empty. Without adding this condition, it will assume that it already reached the end point
          if(polylineCoordinates.isNotEmpty){
            setEndPointLocation();
          }
        }
      });
    });
  }

  void _resumeJourney(){
    _timer!.cancel();
    isMoving = false;
    setState(() {});
  }

  void setEndPointLocation(){
    startPoint = endPoint;
    reachEndPoint = true;
    isMoving = false;
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Maps Route')),
      body: Column(
        children: [
          SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _getDirections,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                  ),
                  child: Text('Get Directions', style: TextStyle(color: Colors.white),),
                ),
                ElevatedButton(
                  onPressed: () {
                    if(isMoving){
                      _resumeJourney();
                    }else{
                      _startJourney();
                    }
                  },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.orange),
                    ),
                  child: Text(isMoving?'Resume Journey':'Start Journey', style: TextStyle(color: Colors.white))
                ),
              ],
            ),
          ),
          SizedBox(height: 10,),
          Text('${reachEndPoint?'You have reached the end point':isMoving?'You are going to reach the end point':'Start your journey'}'),
          SizedBox(height: 20,),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(16.871311, 96.199379),
                zoom: 15,
              ),
              onTap: _onMapTapped,
              markers: {
                if (endPoint != null)
                  Marker(
                    markerId: MarkerId('end'),
                    position: endPoint!,
                    onTap: (){
                      settingStartPoint = false;
                    },
                    infoWindow: InfoWindow(title: 'End Point'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(reachEndPoint?BitmapDescriptor.hueGreen:BitmapDescriptor.hueRed)
                  ),
                if (startPoint != null)
                  Marker(
                    markerId: MarkerId('start'),
                    position: startPoint!,
                    infoWindow: InfoWindow(title: 'Start Point'),
                      onTap: (){
                        settingStartPoint = true;
                      },
                    icon: BitmapDescriptor.defaultMarkerWithHue(startPoint==endPoint?BitmapDescriptor.hueGreen:BitmapDescriptor.hueOrange)
                  ),
                // if (movingMarker != null) movingMarker!,
              },
              polylines: {
                Polyline(
                  polylineId: PolylineId('route'),
                  points: polylineCoordinates,
                  color: Colors.blue,
                  width: 5,
                ),
              },
            ),
          ),
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: availableRoutes.length,
              itemBuilder: (context, index) {
                var route = availableRoutes[index];
                var duration = route['legs'][0]['duration']['text'];
                var distance = route['legs'][0]['distance']['text'];
                return ListTile(
                  leading: Icon(Icons.directions, color: _currentRouteIndex==index?Colors.green:Colors.black,),
                  title: Text('Route ${index + 1} ${index==recommendedIndex?'(Recommended)':''}'),
                  subtitle: Text('Duration: $duration, Distance: $distance'),
                  onTap: () => _selectRoute(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
