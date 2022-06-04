import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeService();

  runApp(MyApp());
}

SharedPreferences? prefs;

Future<void> initializeService() async {

  prefs = await SharedPreferences.getInstance();
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

// to ensure this executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
void onIosBackground() {
  WidgetsFlutterBinding.ensureInitialized();

}
double ?distanceInMeters;
Position ?userLocation;
void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  service.onDataReceived.listen((event) {
    if (event!["action"] == "setAsForeground") {
      service.setForegroundMode(true);
      return;
    }

    if (event["action"] == "setAsBackground") {
      service.setForegroundMode(false);
    }

    if (event["action"] == "stopService") {
      service.stopBackgroundService();
    }
  });



  service.setForegroundMode(true);
  Timer.periodic(Duration(seconds: 30), (timer) async {
    if (!(await service.isServiceRunning())) timer.cancel();
    Position userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    service.setNotificationInfo(
      title: "GPS :",
      content: "Updated at ${userLocation.latitude}${userLocation.longitude}",
    );

    service.sendData(
      {"current_date": '${userLocation.latitude},${userLocation.longitude}'},
    );


    //  print('longitude' + userLocation.longitude.toString());
    // print('latitude' + userLocation.latitude.toString());
    prefs = await SharedPreferences.getInstance();

     double? value1 = prefs?.getDouble('latitude');
  double? value2 = prefs?.getDouble('longitude');

    distanceInMeters = Geolocator.distanceBetween(value1!, value2!, userLocation.latitude, userLocation.longitude);

    int distance = distanceInMeters!.toInt();
     print('userLocation' + userLocation.longitude.toString());
     print('latitude' + userLocation.latitude.toString());
    print("Hello" '${value1}');
    print("Hello" '${value2}');
    print("distanace"+distance. toString());
    if (!(distance >= 5)){
      double currentvol = 0.5;
      currentvol = await PerfectVolumeControl.getVolume();
      PerfectVolumeControl.hideUI = true;
      PerfectVolumeControl.setVolume(0.0);

      print("currentvol"+currentvol.toString());
    }else{
      PerfectVolumeControl.hideUI = true;
      PerfectVolumeControl.setVolume(1.0);
    }

  });



}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Position ?currentLocation;
  String text = "Stop Service";

 double ?value1 ;
  double? value2;
  List addresses=[];
  @override
  void initState() {

    super.initState();
  }

  void getLocation() async {

    Position currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await prefs!.clear();
    // prefs!.setDouble('latitude',currentLocation.latitude);
    // prefs!.setDouble('longitude',currentLocation.longitude);
    // final value2 = prefs?.getDouble('longitude');
    prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs!.setDouble('latitude',currentLocation.latitude);
      prefs!.setDouble('longitude',currentLocation.longitude);
      value1 = prefs?.getDouble('latitude');
      value2 = prefs?.getDouble('longitude');

    });
    addresses = await placemarkFromCoordinates(currentLocation.latitude, currentLocation.longitude);







// distanceInMeters = Geolocator.distanceBetween(currentLocation.latitude, currentLocation.longitude, 52.3546274, 4.8285838);
//     print(distanceInMeters);
//     print("postion"+'${currentLocation}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
appBar: AppBar(),
        body: Column(
          children: [
            StreamBuilder<Map<String, dynamic>?>(
              stream: FlutterBackgroundService().onDataReceived,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!;
                // print('Anmol' + data["current_date"].toString());

                return Text(data['current_date'].toString());
              },
            ),
            ElevatedButton(
              child: Text("Foreground Mode"),
              onPressed: () {
                FlutterBackgroundService()
                    .sendData({"action": "setAsForeground"});
              },
            ),
            ElevatedButton(
              child: Text("Background Mode"),
              onPressed: () {
                FlutterBackgroundService()
                    .sendData({"action": "setAsBackground"});
              },
            ),
            ElevatedButton(
              child: Text(text),
              onPressed: () async {
                final service = FlutterBackgroundService();
                var isRunning = await service.isServiceRunning();
                if (isRunning) {
                  service.sendData(
                    {"action": "stopService"},
                  );
                } else {
                  service.start();
                }

                if (!isRunning) {
                  text = 'Stop Service';
                } else {
                  text = 'Start Service';
                }
                setState(() {});
              },
            ),
            ElevatedButton(
              child: Text("GetLoaction"),
              onPressed: () {


                getLocation();
                // double? value1 = prefs!.getDouble('latitude');
                // double? value2 = prefs!.getDouble('longitude');
                // print("Hello"+'${value1} ${value2}');



              },
            ),

            Container(

                child: Text(value1.toString()+""+value2.toString()))



          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            FlutterBackgroundService().sendData({
              "hello": "world",
            });
          },
          child: Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}
