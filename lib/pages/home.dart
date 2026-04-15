import 'package:flutter/material.dart';
import 'package:flutter_joystick_customisable/flutter_joystick_customisable.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

import 'package:pibot/pages/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  InternetAddress address = InternetAddress('10.0.0.133');
  final int port = 5005;
  RawDatagramSocket? _socket;

  DragInfo? _leftInfo;
  DragInfo? _rightInfo;

  var jsonPacket = {
    'LDir': 'F',
    'LAng': 0,
    'LLen': 0,
    'RDir': 'F',
    'RAng': 0,
    'RLen': 0,
    'But': '-',
  };

  @override
  void initState() {
    super.initState();
    _loadAddress();
    _initSocket();
  }

  void _loadAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString('ip');
    if (ip != null && ip.isNotEmpty) {
      try {
        setState(() {
          address = InternetAddress(ip);
        });
      } catch (e) {
        print("Invalid IP address: $ip");
      }
    }
  }

  void _initSocket() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  void goToSettings() async {
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const Settings(),
          fullscreenDialog: true,
        ));

    if (result != null && result is String) {
      try {
        setState(() {
          address = InternetAddress(result);
        });
      } catch (e) {
        print("Invalid IP address returned from settings: $result");
      }
    }
  }

  void sendPacket() {
    // print(jsonPacket);
    if (_socket != null) {
      String pack = json.encode(jsonPacket);
      _socket!.send(pack.codeUnits, address, port);
    }
  }

  void joystickl(double degrees, double distance) {
    String degS;
    String disS;

    //convert to tank drive
    if (degrees <= 90 || degrees >= 270) {
      //forward
      jsonPacket['LDir'] = 'F';
    } else {
      //backward
      jsonPacket['LDir'] = 'B';
    }

    degS = degrees.toStringAsFixed(0);
    disS = (distance * 100).toStringAsFixed(0);

    jsonPacket['LAng'] = degS;
    jsonPacket['LLen'] = disS;

    sendPacket();
  }

  void joystickr(double degrees, double distance) {
    String degS;
    String disS;

    //convert to tank drive
    if (degrees <= 90 || degrees >= 270) {
      //forward
      jsonPacket['RDir'] = 'F';
    } else {
      //backward
      jsonPacket['RDir'] = 'B';
    }

    degS = degrees.toStringAsFixed(0);
    disS = (distance * 100).toStringAsFixed(0);

    jsonPacket['RAng'] = degS;
    jsonPacket['RLen'] = disS;

    sendPacket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        leading: IconButton(
          padding: const EdgeInsets.symmetric(),
          icon: const Icon(
            Icons.arrow_back,
            size: 48.0,
          ),
          onPressed: () => SystemNavigator.pop(),
        ),
        title: const Text('piBot'),
        actions: [
          PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              size: 48.0,
            ),
            itemBuilder: (content) => [
              const PopupMenuItem(
                value: 1,
                child: Text("Settings"),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text("About"),
              ),
            ],
            onSelected: (int menu) {
              if (menu == 1) {
                goToSettings();
              } else if (menu == 2) {
                Navigator.pushNamed(context, '/about');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Video Stream Background
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Mjpeg(
                isLive: true,
                fit: BoxFit.cover,
                stream: 'http://${address.address}:5000/video_feed',
                error: (context, error, stack) {
                  return const Center(
                    child: Text(
                      'Waiting for video stream...',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          // Joysticks Overlay
          Positioned.fill(
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox(
                    width: 8.0,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "x: ${_leftInfo?.x.toStringAsFixed(2) ?? 0.0}, y: ${_leftInfo?.y.toStringAsFixed(2) ?? 0.0}",
                        style: const TextStyle(
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                      ),
                      Opacity(
                        opacity: 0.8,
                        child: Joystick(
                            stickSize: 80,
                            enableButtonControls: true,
                            directionButtonColor: Colors.transparent,
                            stickGradientColors: const [Colors.blue, Colors.blueAccent],
                            dragPadColor: Colors.blueGrey.withOpacity(0.4),
                            onDragStart: () {
                              // You can use this callback for your business case when the stick/ball start dragging
                            },
                            onDragEnd: () {
                              // You can use this callback for your business case when the stick/ball stop dragging
                            },
                            dragCallback: (DragInfo? dragInfo) {
                              setState(() {
                                _leftInfo = dragInfo;
                              });
                              if (dragInfo != null) {
                                double degrees = (atan2(dragInfo.y, dragInfo.x) * 180 / pi) + 90;
                                if (degrees < 0) degrees += 360;
                                double distance = sqrt(dragInfo.x * dragInfo.x + dragInfo.y * dragInfo.y);
                                if (distance > 1.0) distance = 1.0;
                                joystickl(degrees, distance);
                              }
                            }),
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.blueGrey.withOpacity(0.6),
                        elevation: 20.0,
                        heroTag: 'X',
                        child: const Text(
                          'X',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        onPressed: () {
                          jsonPacket['But'] = 'X';
                          sendPacket();
                          jsonPacket['But'] = '-';
                          sendPacket();
                        },
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      FloatingActionButton(
                        backgroundColor: Colors.blueGrey.withOpacity(0.6),
                        elevation: 20.0,
                        heroTag: 'Y',
                        child: const Text(
                          'Y',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        onPressed: () {
                          jsonPacket['But'] = 'Y';
                          sendPacket();
                          jsonPacket['But'] = '-';
                          sendPacket();
                        },
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "x: ${_rightInfo?.x.toStringAsFixed(2) ?? 0.0}, y: ${_rightInfo?.y.toStringAsFixed(2) ?? 0.0}",
                        style: const TextStyle(
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                      ),
                      Opacity(
                        opacity: 0.8,
                        child: Joystick(
                            stickSize: 80,
                            enableButtonControls: true,
                            directionButtonColor: Colors.transparent,
                            stickGradientColors: const [Colors.blue, Colors.blueAccent],
                            dragPadColor: Colors.blueGrey.withOpacity(0.4),
                            onDragStart: () {
                              // You can use this callback for your business case when the stick/ball start dragging
                            },
                            onDragEnd: () {
                              // You can use this callback for your business case when the stick/ball stop dragging
                            },
                            dragCallback: (DragInfo? dragInfo) {
                              setState(() {
                                _rightInfo = dragInfo;
                              });
                              if (dragInfo != null) {
                                double degrees = (atan2(dragInfo.y, dragInfo.x) * 180 / pi) + 90;
                                if (degrees < 0) degrees += 360;
                                double distance = sqrt(dragInfo.x * dragInfo.x + dragInfo.y * dragInfo.y);
                                if (distance > 1.0) distance = 1.0;
                                joystickr(degrees, distance);
                              }
                            }),
                      )
                    ],
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
