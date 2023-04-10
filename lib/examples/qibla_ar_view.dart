import 'dart:math';

import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class QiblaARView extends StatefulWidget {
  @override
  _QiblaARViewState createState() => _QiblaARViewState();
}

class _QiblaARViewState extends State<QiblaARView> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;
  double _compassHeading = 0.0;
  double _qiblaDirection = 0.0;
  double _qiblaDistance = 0.0;

  double qiblaLatitude = 21.423333;
  double qiblaLongitude = 39.823333;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getQiblaDirection();
  }

  void _getQiblaDirection() async {
    await Geolocator.checkPermission();
    // Get the device's current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Calculate the direction to the Qibla
    double latitude = position.latitude;
    double longitude = position.longitude;

    double qiblaAngle = _calculateQiblaAngle(latitude, longitude);
    double qiblaDistance = _calculateQiblaDistance(latitude, longitude);
    setState(() {
      _qiblaDirection = qiblaAngle;
      _qiblaDistance = qiblaDistance;
    });
  }

  double _calculateQiblaAngle(double latitude, double longitude) {
    double phi = math.radians(21.423333); // latitude of the Kaaba in degrees
    double lambda = math
        .radians(39.823333 - longitude); // longitude of the Kaaba in degrees
    double psi = atan2(
        sin(lambda),
        cos(math.radians(latitude)) * tan(phi) -
            sin(math.radians(latitude)) * cos(lambda));
    double qiblaAngle = math.degrees(psi);
    return qiblaAngle;
  }

  Future<void> _onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) async {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;

    // Load the pin asset
    ARNode node = ARNode(
        type: NodeType.webGLB,
        //C:\Users\samer\Downloads\ar_flutter_plugin-main\ar_flutter_plugin-main\example\Models\kaaba3\mecca1blender.gltf
        uri:
            "https://github.com/samer2373/example/blob/master/Models/kaaba3/KaabaBlender.glb?raw=true",
        scale: math.Vector3(0.1, 0.1, 0.1),
        position: math.Vector3(0, -0.2, -1),
        eulerAngles: math.Vector3.zero());

    arObjectManager.addNode(node);

    // ARKitReferenceNode pinNode = await arController.addReferenceNode(
    //   filePath: 'pin.glb',
    //   scale: Vector3(0.1, 0.1, 0.1),
    // );
    arObjectManager
        .removeNode(node); // Remove the node so that it can be added later

    // Add the pin at the Qibla direction
    double distanceFromCamera = 5.0; // Distance from the camera to the pin
    double elevationAngle =
        0.0; // Elevation angle of the pin (0 degrees = horizontal)

    /// get the current camera position and direction
    Matrix4? cameraPose = await arSessionManager.getCameraPose();
    math.Vector3 cameraPosition = cameraPose!.getTranslation();
    math.Vector3 cameraDirection = cameraPose.getRotation().forward;
    math.Vector3 qiblaDirection = math.Vector3(
      sin(math.radians(_qiblaDirection)),
      0.0,
      cos(math.radians(_qiblaDirection)),
    );
    math.Vector3 pinPosition = cameraPosition +
        cameraDirection.normalized() * distanceFromCamera +
        qiblaDirection.normalized() * elevationAngle;

    var pinNode = ARNode(
        type: node.type,
        uri: node.uri,
        scale: node.scale,
        position: pinPosition,
        eulerAngles: node.eulerAngles);
    // Add the pin to the AR View

    arObjectManager.addNode(
      pinNode,
    );

    FlutterCompass.events?.listen((event) async {
      setState(() {
        _compassHeading = event.heading ?? 0.0;
        _getQiblaDirection();
      });
      // //   // Set the rotation of the node based on the difference between the compass heading and the Qibla direction
      // double angleDiff = _qiblaDirection - _compassHeading;
      // pinNode.eulerAngles = math.Vector3(0, math.radians(angleDiff), 0);
      //update the node
      // arObjectManager.removeNode(pinNode);
      // arObjectManager.addNode(pinNode);
    });

    // // Add The Qibla Direction Indicator to the AR View
    // ARNode node = ARNode(
    //     type: NodeType.webGLB,
    //     uri:
    //         "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
    //     scale: math.Vector3(0.1, 0.1, 0.1),
    //     position: math.Vector3(0, -0.2, -1),
    //     eulerAngles: math.Vector3.zero());

    // arObjectManager.addNode(node);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Qibla AR View'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Compass heading: $_compassHeading',
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 20.0),
                Text(
                  'Qibla direction: $_qiblaDirection',
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 20.0),
                Text(
                  'Qibla distance: $_qiblaDistance',
                  style: TextStyle(fontSize: 18.0),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ARKitNode node = ARKitNode(
          //   geometry: ARKitSphere(radius: 0.1),
          //   position:
          //       Vector3(0, -0.2, -1), // Set the initial position of the node
          //   eulerAngles: Vector3.zero(),
          // );
          // await arkitController.add(node);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  double _calculateQiblaDistance(double latitude, double longitude) {
    // Calculate the distance to the Qibla in meters
    double phi = math.radians(21.423333); // latitude of the Kaaba in degrees
    double lambda =
        math.radians(39.823333); // longitude of the Kaaba in degrees
    double phi1 = math.radians(latitude); // latitude of the device in degrees
    double lambda1 =
        math.radians(longitude); // longitude of the device in degrees
    double R = 6371000; // radius of the earth in meters
    double d = acos(sin(phi) * sin(phi1) +
            cos(phi) * cos(phi1) * cos(lambda1 - lambda)) *
        R;
    return d;
  }
}
