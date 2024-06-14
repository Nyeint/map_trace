import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  LatLng startPoint = LatLng(16.871311, 96.199379);
  LatLng endPoint = LatLng(16.871311, 96.199379);
  LatLng currentPoint = LatLng(16.871311, 96.199379);
  Timer? _timer;
  int currentSpeedSecond = 300;
  Duration _currentDuration = Duration(milliseconds: 300);
  List<LatLng> routePoints = [];
  bool isOnPath = true;
  int wayNumbers = 0;
  int currentSpeed = 1;
  bool reachEndPoint = false;

  @override
  void initState() {
    super.initState();
    _calculateEndPoint();
    _generateRoute();
    _startMovingMarker();
  }

  void _calculateEndPoint() {
    final Distance distance = Distance();
    final double desiredDistance = 2000; // 7 km
    final List<double> bearingList = [45,90,135,225,270,315]; // Ea
    final double bearing = bearingList[Random().nextInt(bearingList.length)];
    endPoint = distance.offset(startPoint, desiredDistance, bearing);
  }

  void _generateRoute() {
    final polylinePoints = PolylinePoints();
    final result = polylinePoints.decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    routePoints = result.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  void _startMovingMarker() {
    final distance = Distance();
    final totalDistance = distance.as(LengthUnit.Meter, currentPoint, endPoint);
    final steps = totalDistance / 20; // Move in 500 meter increments
    final stepLat = (endPoint.latitude - startPoint.latitude) / steps;
    final stepLng = (endPoint.longitude - startPoint.longitude) / steps;

    _timer = Timer.periodic(_currentDuration, (timer) {
      final double remainingDistance = distance.as(LengthUnit.Meter, currentPoint, endPoint);

      setState(() {
        if (distance.as(LengthUnit.Meter, currentPoint, endPoint) < 10) {
          timer.cancel();
          setEndPointLocation();
        } else {
          final nextPoint= LatLng(
            currentPoint.latitude + stepLat,
            currentPoint.longitude + stepLng,
          );
          final double nextDistance = distance.as(LengthUnit.Meter, nextPoint, endPoint);
          if (nextDistance < remainingDistance) {
            currentPoint = nextPoint;
          } else {
            timer.cancel();
            setEndPointLocation();
          }
        }
      });
    });
  }

  void _updateSpeed(int level) {
    _timer?.cancel();
    switch (level) {
      case 1:
        _currentDuration = Duration(milliseconds: 300); // Slow
        break;
      case 2:
        _currentDuration = Duration(milliseconds: 200); // Medium
        break;
      case 3:
        _currentDuration = Duration(milliseconds: 100); // Fast
        break;
    }
    setState(() {});
    _startMovingMarker();
  }

  void goToNextWay(){
    ++wayNumbers;
    reachEndPoint = false;
    startPoint = endPoint;
    _calculateEndPoint();
    _startMovingMarker();
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    _startMovingMarker();
  }

  void _updateLocation(double lat, double lng) {
    final newPoint = LatLng(lat, lng);
    isOnPath = false;
    for (int i = 0; i < routePoints.length - 1; i++) {
      if (_isPointOnPolyline(newPoint, [startPoint,endPoint])) {
        isOnPath = true;
        break;
      }
    }
    if (isOnPath) {
      currentPoint = newPoint;
      if (_timer != null && !_timer!.isActive) {
        _resumeTimer();
      }
    } else {
      currentPoint = newPoint;
      _stopTimer();
    }
    setState(() {});
  }

  void setEndPointLocation(){
    currentPoint = endPoint;
    reachEndPoint = true;
    setState(() {});
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text("You reach the target point. Do you want to move next point?"),
              titleTextStyle: TextStyle(fontSize: 18, color:Colors.black),
              actions: [
                ElevatedButton(
                    onPressed: (){
                      context.pop();
                    }, child: Text('No')),
                ElevatedButton(
                    onPressed: (){
                      context.pop();
                      goToNextWay();
                    }, child: Text('Yes')),
              ],
          );
        }
    );
  }

  bool _isPointOnPolyline(LatLng point, List<LatLng> polyline, {double tolerance = 50}) {
    final Distance distance = Distance();
    for (int i = 0; i < polyline.length - 1; i++) {
      final LatLng p1 = polyline[i];
      final LatLng p2 = polyline[i + 1];
      final double d1 = distance.as(LengthUnit.Meter, point, p1);
      final double d2 = distance.as(LengthUnit.Meter, point, p2);
      final double d3 = distance.as(LengthUnit.Meter, p1, p2);

      if (d1 + d2 <= d3 + tolerance) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget speedWidget(int speed){
    return GestureDetector(
      onTap: (){
        setState(() {
          currentSpeed = speed;
        });
        _updateSpeed(speed);
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: currentSpeed==speed?Colors.blue:Colors.blueGrey.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Speed $speed',style: TextStyle(color: currentSpeed==speed? Colors.white:Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child:
                  FlutterMap(
                      options: MapOptions(
                          initialCenter: startPoint,
                          initialZoom: 13.0,
                          onTap: (tapPosition, latLongs) {
                            _updateLocation(latLongs.latitude, latLongs.longitude);
                          }
                      ),
                      children: [
                        tileLayer,
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [startPoint,endPoint],
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        MarkerLayer(markers: [
                          Marker(
                              point: currentPoint,
                              child: Icon(Icons.location_on_sharp, color: isOnPath?Colors.green:Colors.red, size: 40,))
                        ])
                      ]
                  ),
                ),

                Padding(
                    padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                    child: Text(currentPoint.toString())),
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    speedWidget(1),
                    SizedBox(width: 10,),
                    speedWidget(2),
                    SizedBox(width: 10,),
                    speedWidget(3),
                  ],
                ),
                SizedBox(height: 20,),
                GestureDetector(
                  onTap: (){
                    if(reachEndPoint){
                      goToNextWay();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: reachEndPoint?Colors.green:Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Ready to the next delivery?',style: TextStyle(color: reachEndPoint? Colors.white:Colors.black)),
                  ),
                ),
                SizedBox(height: 25,),
                Text('Number of completed deliveries  :    $wayNumbers'),
              ],
            ),
          ),
        ));
  }
}

TileLayer get tileLayer => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: const ['a', 'b', 'c'],
    userAgentPackageName: 'com.example.app'
);