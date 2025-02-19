import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:neeraj_flutter_app/constants/dimensions.dart';
import 'package:neeraj_flutter_app/constants/styling/button_style.dart';
import 'package:neeraj_flutter_app/data/shared_preference/my_shared_preference.dart';
import 'package:neeraj_flutter_app/widgets/custom_text.dart';
import 'package:neeraj_flutter_app/widgets/horizontal_gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

///Created by Neeraj Vijayvargiya on 08/11/22.
class ArduinoSerialConnectivity {
  FlutterBluetoothSerial instance = FlutterBluetoothSerial.instance;
  BluetoothState _state = BluetoothState.UNKNOWN;
  List<BluetoothDevice> list = [];
  late BluetoothConnection? blConnection;
  late final Function nonBleIsConnected;
  late final Function dataRecieved;

  ArduinoSerialConnectivity(this.nonBleIsConnected, this.dataRecieved);

  void start(BuildContext context) async {
    print("inside start");
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
    if (statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
      print(statuses[Permission.bluetoothConnect]);
      if (instance.isEnabled == true) {
        showBondedDevices(context);
      } else {
        enableBluetoth(context);
      }
      instance.onStateChanged().listen((event) {
        _state = event;
        print("adapter state=" + event.stringValue);
        if (_state == BluetoothState.STATE_OFF) {
          nonBleIsConnected(false);
          enableBluetoth(context);
        } else if (_state == BluetoothState.STATE_ON) {
          showBondedDevices(context);
        }
      });
      //showBottomDialog(context);
    }

    // await instance.state.then((value) => () {
    //       print("then state=" + value.stringValue);
    //
    //       _state = value;
    //       if (_state == BluetoothState.STATE_OFF) {
    //
    //       } else if (_state == BluetoothState.STATE_ON) {
    //         showBondedDevices();
    //       }
    //     });
  }

  void enableBluetoth(BuildContext context) {
    instance.requestEnable().then((value) => {
          if (value == true) {showBondedDevices(context)}
        });
  }

  void showBondedDevices(BuildContext context) async {
    print("inside bonded devices");
    list.clear();
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
    if (statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
      print(statuses[Permission.bluetoothConnect]);

      // await instance.requestDiscoverable(5);
      // ProgressDialog pd = ProgressDialog(context: context);
      // pd.show(max: 5, msg: "Loading devices");
      instance.getBondedDevices().then((value) {
        for (BluetoothDevice d in value) {
          print("found bonded device:" + d.address);
          list.add(d);
        }
        showBottomDialog(context);
      });

      // instance.startDiscovery().listen((event) {
      //   print("device found in discovery=" + event.device.address);
      //   if (event.device.bondState.isBonded) {
      //     print(
      //         "device found in discovery with bonded=" + event.device.address);
      //
      //
      //   }
      // }, onDone: () {
      //   pd.close();
      //   showBottomDialog(context);
      // }, onError: (handleError) {
      //   pd.close();
      // });
      // instance
      //     .getBondedDevices()
      //     .then((value) => () {
      //           for (BluetoothDevice d in value) {
      //             list.add(d);
      //             print("devices found=" + d.address);
      //           }
      //           showBottomDialog(context);
      //         })
      //     .onError((error, stackTrace) => () {
      //           print("inside the error");
      //         });
    }
  }

  void showBottomDialog(BuildContext context) {
    showModalBottomSheet(
        constraints: BoxConstraints(maxWidth: 300, minHeight: 100),
        context: context,
        builder: (context) {
          return Container(
            child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    child: Container(
                      height: 50,
                      width: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          HorizontalGap(10),
                          Icon(
                            Icons.bluetooth,
                            color: Colors.blue,
                            size: 20,
                          ),
                          HorizontalGap(10),
                          Expanded(
                            child: Text(
                              list[index].name!,
                              style: TextStyle(
                                  fontSize: 15, color: Colors.lightGreen),
                            ),
                          ),
                          HorizontalGap(10),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.all(Dimensions.size_8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(Dimensions.size_10),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                connectToBluetooth(list[index]);
                                Navigator.pop(context);
                              },
                              child: Container(
                                  width: 100,
                                  child: CustomText(
                                    list[index].isConnected
                                        ? "Disconnect"
                                        : "Connect",
                                    ButtonStyles.getButtonTextStyle(),
                                    textAlign: TextAlign.center,
                                  ))),
                          HorizontalGap(10),
                        ],
                      ),
                    ),
                  );
                }),
          );
        },
        isDismissible: true,
        useRootNavigator: false,
        isScrollControlled: false,
        backgroundColor: Colors.white,
        elevation: 10.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0))));
  }

  void disconnecToBluetooth() {
    nonBleIsConnected(false);
    if (blConnection != null && blConnection!.isConnected) {
      blConnection!.close();
    }
  }

  void autoConnectBluetooth(String rssid) async {
    print("inside auto connect $rssid");
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
    if (statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
      print("permission granted");
      if (instance.isEnabled == true) {
        autoConnection(rssid);
      } else {
        instance.requestEnable().then((value) => {
              if (value == true) {autoConnection(rssid)}
            });
      }
      instance.onStateChanged().listen((event) async {
        _state = event;
        print("adapter state=" + event.stringValue);
        if (_state == BluetoothState.STATE_OFF) {
          nonBleIsConnected(false);
        } else if (_state == BluetoothState.STATE_ON) {
          // bluetooth is enabled
          autoConnection(rssid);
        }
      });
    }
  }

  void autoConnection(String rssid) async {
    print("inside connecting to $rssid");
    try {
      blConnection = await BluetoothConnection.toAddress(rssid);
      if (blConnection!.isConnected) {
        MySharedPreference.setString(MySharedPreference.SERIALRSSID, rssid);
        nonBleIsConnected(true);
        blConnection!.input!.listen((event) {
          dataRecieved(event);

          print("recv value=" + event.first.toString());
        });
      }
    } on PlatformException catch (err) {}
  }

  void connectToBluetooth(BluetoothDevice d) async {
    if (d.isConnected) {
      disconnecToBluetooth();
      return;
    }
    try {
      blConnection = await BluetoothConnection.toAddress(d.address);
      if (blConnection!.isConnected) {
        MySharedPreference.setString(MySharedPreference.SERIALRSSID, d.address);
        nonBleIsConnected(true);
        blConnection!.input!.listen((event) {
          dataRecieved(event);

          print("recv value=" + event.first.toString());
        });
        // Uint8List data = Uint8List(2);
        // data[0] = (0xC2);
        // data[1] = (0x64);
        // writeToConnection(data);
      }
    } on PlatformException catch (err) {}
  }

  void writeToConnection(Uint8List data) async {
    if (blConnection!.isConnected) {
      blConnection!.output.add(data);
      await blConnection!.output.allSent;
    } else {
      nonBleIsConnected(false);
    }
  }
}
