import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neeraj_flutter_app/base/baseClass.dart';
import 'package:neeraj_flutter_app/connectivity/bluetooth_serial_connectivty.dart';
import 'package:neeraj_flutter_app/connectivity/bluettoth_coneectivty.dart';
import 'package:neeraj_flutter_app/constants/assets.dart';
import 'package:neeraj_flutter_app/constants/dimensions.dart';
import 'package:neeraj_flutter_app/constants/styling/button_style.dart';
import 'package:neeraj_flutter_app/data/shared_preference/my_shared_preference.dart';
import 'package:neeraj_flutter_app/models/category_data.dart';
import 'package:neeraj_flutter_app/models/main_category_model.dart';
import 'package:neeraj_flutter_app/utils/device_utils.dart';
import 'package:neeraj_flutter_app/widgets/custom_text.dart';
import 'package:neeraj_flutter_app/widgets/horizontal_gap.dart';
import 'package:neeraj_flutter_app/widgets/vertical_gap.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

///Created by Naman Gupta on 9/11/22.

class FreeRunScreen extends StatefulWidget {
  SubCategoryDetail subCategoryDetail;

  FreeRunScreen(this.subCategoryDetail);

  @override
  State<StatefulWidget> createState() {
    return FreeRunScreenState(subCategoryDetail);
  }
}

class FreeRunScreenState extends BaseClass with SingleTickerProviderStateMixin {
  SubCategoryDetail subCategoryDetail;
  bool isAnyBluetoothConnected = false;
  bool ifBleConnected = false;
  bool ifSerialConnected = false;
  ArduinoSerialConnectivity? connectivity = null;
  BleConnectivity? bleConnect = null;

  FreeRunScreenState(this.subCategoryDetail);

  ScanResult? scanResult;
  double redSliderValue = 0;
  double greenSliderValue = 0;
  double blueSliderValue = 0;
  double ultrasonicValue = 0;
  double dumpValue = 0;
  bool isHorn = false;

  double exacavtorSwingValue = 0;
  double exacavtorBucketValue = 0;
  double exacavtorBoomValue = 0;
  double exacavtorArmValue = 0;

  late AnimationController _animationController;
  bool ultrasonicSwitchValue = false;
  bool forkLiftSwap = false;
  bool craneLiftSwap = false;
  bool craneSwingSwap = false;
  bool catapultSwap = false;
  bool ballShooterSwap = false;

  bool armyTankShootSwap = false;
  bool armyTankSwingSwap = false;
  int outputObstaceleavoider = 0;
  int proximityOne = 0;
  int proximityTwo = 0;
  int obstacleAvoiderThreShold = -1;
  String outputAvoidoValue = "";

  late final TextEditingController prox_1_black_controller;
  late final TextEditingController prox_1_white_controller;

  late final TextEditingController prox_2_black_controller;
  late final TextEditingController prox_2_white_controller;
  double prox_2_black = 0;
  double prox_2_average = 0;
  double prox_2_white = 0;
  double prox_1_black = 0;
  double prox_1_average = 0;
  double prox_1_white = 0;
  bool isLineFollowerPlay = false;
  double radarAngle = 0;
  bool shouldIncrease = true;

  @override
  void initState() {
    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 150));
    _animationController.repeat(reverse: true);

    prox_1_black_controller = TextEditingController();
    prox_1_white_controller = TextEditingController();
    prox_2_black_controller = TextEditingController();
    prox_2_white_controller = TextEditingController();

    autoConnectInit();
    pointers.add(RangePointer(
      value: radarAngle,
      cornerStyle: CornerStyle.bothCurve,
      width: 10,
      sizeUnit: GaugeSizeUnit.logicalPixel,
      gradient: SweepGradient(
        colors: <Color>[Color(0xFFCC2B5E), Color(0xFF753A88)],
      ),
    ));
    getPrefsValues();
    super.initState();
  }

  void getPrefsValues() async {
    prox_1_black =
        await MySharedPreference.getDouble(MySharedPreference.PROXY_1_BLACK);
    prox_1_white =
        await MySharedPreference.getDouble(MySharedPreference.PROXY_1_WHITE);
    prox_1_average =
        await MySharedPreference.getDouble(MySharedPreference.PROXY_1_AVERAGE);
    prox_2_black =
        await MySharedPreference.getDouble(MySharedPreference.PROXY_2_BLACK);
    prox_2_white =
        await MySharedPreference.getDouble(MySharedPreference.PROXY_2_WHITE);
    prox_2_average =
        await MySharedPreference.getDouble(MySharedPreference.PROXY_2_AVERAGE);
    prox_1_black_controller.text = prox_1_black.toString();
    prox_1_white_controller.text = prox_1_white.toString();
    prox_2_black_controller.text = prox_2_black.toString();
    prox_2_white_controller.text = prox_2_white.toString();
    redSliderValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_REDSLIDER);
    greenSliderValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_GREENSLIDER);
    blueSliderValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_BLUESLIDER);
    dumpValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_DUMPSLIDER);
    exacavtorSwingValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_SWINGSLIDER);
    exacavtorArmValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_ARMSLIDER);
    exacavtorBoomValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_BOONSLIDER);

    exacavtorBucketValue = await MySharedPreference.getDouble(
        MySharedPreference.FREERUN_BUCKETSLIDER);
    setState(() {});
  }

  void autoConnectInit() async {
    if (!isAnyBluetoothConnected) {
      String rsid =
          await MySharedPreference.getString(MySharedPreference.SERIALRSSID);
      if (rsid != null && rsid.isNotEmpty) {
        connectivity =
            ArduinoSerialConnectivity(onNondBleConnectvity, onrecvNonBleData);
        connectivity!.autoConnectBluetooth(rsid);
      }
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  @override
  Widget? setBody() {
    if (subCategoryDetail.title == SubCategoryData.LINE_FOLLOWER) {
      return SingleChildScrollView(
        child: Container(
          height: DeviceUtils.getScreenHeight(context),
          width: DeviceUtils.getScreenWidtht(context),
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: DeviceUtils.getScreenWidtht(context),
                      margin: EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          HorizontalGap(30),
                          InkWell(
                            onTap: () {
                              onOkayPressed();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              child: Image.asset(
                                Assets.BACK_BUTTON,
                                height: 40,
                                width: 40,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Center(
                            child: CustomText(
                                isAnyBluetoothConnected
                                    ? "Connected"
                                    : "Not Connected",
                                TextStyle(
                                    color: isAnyBluetoothConnected
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          )),
                          InkWell(
                            onTap: onTapBluetoothIcon,
                            child: Image.asset(
                              Assets.BLUETOOTH_SIGN,
                              height: 40,
                              width: 40,
                            ),
                          ),
                          HorizontalGap(30),
                        ],
                      ),
                    ),
                    VerticalGap(12),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(child: proximity_1()),
                          HorizontalGap(24),
                          Expanded(child: proximity_2())
                        ],
                      ),
                    ),
                    VerticalGap(1),
                    ElevatedButton(
                        child: Text(isLineFollowerPlay ? "STOP" : "Play"),
                        onPressed: () {
                          if (!isLineFollowerPlay) {
                            //start play send command d5
                            writeToBLuetooth([0XD5]);
                            setState(() {
                              isLineFollowerPlay = true;
                              shouldStopLine = true;
                            });
                          } else {
                            writeToBLuetooth([0XD6]);

                            setState(() {
                              isLineFollowerPlay = false;
                              shouldStopLine = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isLineFollowerPlay ? Colors.red : Colors.blue)),
                  ]),
              Positioned(
                child: FadeTransition(
                  opacity: _animationController,
                  child: Image.asset(
                    isAnyBluetoothConnected ? Assets.GREEN_DOT : Assets.RED_DOT,
                    height: 25,
                    width: 25,
                  ),
                ),
                top: 10,
                right: 150,
              ),
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: ElevatedButton(
              //       child: Text(isLineFollowerPlay ? "STOP" : "Play"),
              //       onPressed: () {
              //         if (!isLineFollowerPlay) {
              //           //start play send command d5
              //           writeToBLuetooth([0XD5]);
              //           setState(() {
              //             isLineFollowerPlay = true;
              //             shouldStopLine = true;
              //           });
              //         } else {
              //           setState(() {
              //             isLineFollowerPlay = false;
              //             shouldStopLine = false;
              //           });
              //           startSendingLineFollowerCommand();
              //         }
              //       },
              //       style: ElevatedButton.styleFrom(
              //           backgroundColor:
              //               isLineFollowerPlay ? Colors.red : Colors.blue)),
              // )
            ],
          ),
        ),
      );
      ;
    } else
      return Container(
        height: DeviceUtils.getScreenHeight(context),
        width: DeviceUtils.getScreenWidtht(context),
        decoration: BoxDecoration(color: Colors.lightBlueAccent),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Positioned(
                  left: 70,
                  child: Container(
                    height: DeviceUtils.getScreenHeight(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClipRRect(
                          clipBehavior: Clip.none,
                          borderRadius: BorderRadius.circular(10),
                          child: Material(
                            elevation: 0,
                            color: Colors.transparent,
                            child: Ink.image(
                              image: AssetImage(Assets.UP_ARROW),
                              fit: BoxFit.cover,
                              width: 100.0,
                              height: 100.0,
                              child: InkWell(
                                onTapUp: (event) {
                                  writeToBLuetooth([0XB4]);
                                },
                                onTapDown: (event) {
                                  writeToBLuetooth([0XB0]);
                                },
                                onTapCancel: () {
                                  writeToBLuetooth([0XB4]);
                                },
                              ),
                            ),
                          ),
                        ),
                        VerticalGap(32),
                        ClipRRect(
                            clipBehavior: Clip.none,
                            borderRadius: BorderRadius.circular(10),
                            child: Material(
                                elevation: 0,
                                color: Colors.transparent,
                                child: InkWell(
                                  onTapUp: (event) {
                                    writeToBLuetooth([0XB4]);
                                  },
                                  onTapDown: (event) {
                                    writeToBLuetooth([0XB1]);
                                  },
                                  onTapCancel: () {
                                    writeToBLuetooth([0XB4]);
                                  },
                                  onTap: () {
                                    // writeToBLuetooth([0XB1]);
                                    // Future.delayed(Duration(milliseconds: 100),
                                    //     () {
                                    //   writeToBLuetooth([0XB4]);
                                    // });
                                  },
                                  child: Image.asset(
                                    Assets.DOWN_ARROW,
                                    width: 100,
                                    height: 100,
                                  ),
                                ))),
                      ],
                    ),
                  )),
              Positioned(
                  right: 50,
                  child: Container(
                    height: DeviceUtils.getScreenHeight(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClipRRect(
                            clipBehavior: Clip.none,
                            borderRadius: BorderRadius.circular(10),
                            child: Material(
                                elevation: 0,
                                color: Colors.transparent,
                                child: InkWell(
                                  onTapUp: (event) {
                                    writeToBLuetooth([0XB4]);
                                  },
                                  onTapDown: (event) {
                                    writeToBLuetooth([0XB2]);
                                  },
                                  onTapCancel: () {
                                    writeToBLuetooth([0XB4]);
                                  },
                                  onTap: () {
                                    // writeToBLuetooth([0XB2]);
                                    // Future.delayed(Duration(milliseconds: 100),
                                    //     () {
                                    //   writeToBLuetooth([0XB4]);
                                    // });
                                  },
                                  child: Image.asset(
                                    Assets.LEFTOW,
                                    width: 100,
                                    height: 100,
                                  ),
                                ))),
                        HorizontalGap(8),
                        ClipRRect(
                            clipBehavior: Clip.none,
                            borderRadius: BorderRadius.circular(10),
                            child: Material(
                                elevation: 0,
                                color: Colors.transparent,
                                child: InkWell(
                                  onTapUp: (event) {
                                    writeToBLuetooth([0XB4]);
                                  },
                                  onTapDown: (event) {
                                    writeToBLuetooth([0XB3]);
                                  },
                                  onTapCancel: () {
                                    writeToBLuetooth([0XB4]);
                                  },
                                  onTap: () {
                                    // writeToBLuetooth([0XB3]);
                                    // Future.delayed(Duration(milliseconds: 100),
                                    //     () {
                                    //   writeToBLuetooth([0XB4]);
                                    // });
                                  },
                                  child: Image.asset(
                                    Assets.RIGHT_ARROW,
                                    width: 100,
                                    height: 100,
                                  ),
                                ))),
                      ],
                    ),
                  )),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: DeviceUtils.getScreenHeight(context),
                  margin: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: DeviceUtils.getScreenWidtht(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            HorizontalGap(30),
                            InkWell(
                              onTap: () {
                                onOkayPressed();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                child: Image.asset(
                                  Assets.BACK_BUTTON,
                                  height: 40,
                                  width: 40,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Center(
                              child: CustomText(
                                  isAnyBluetoothConnected
                                      ? "Connected"
                                      : "Not Connected",
                                  TextStyle(
                                      color: isAnyBluetoothConnected
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            )),
                            InkWell(
                              onTap: onTapBluetoothIcon,
                              child: Image.asset(
                                Assets.BLUETOOTH_SIGN,
                                height: 40,
                                width: 40,
                              ),
                            ),
                            HorizontalGap(30),
                          ],
                        ),
                      ),
                      VerticalGap(12),
                      getCenterLayout(subCategoryDetail.title),
                    ],
                  ),
                ),
              ),
              Positioned(
                child: FadeTransition(
                  opacity: _animationController,
                  child: Image.asset(
                    isAnyBluetoothConnected ? Assets.GREEN_DOT : Assets.RED_DOT,
                    height: 25,
                    width: 25,
                  ),
                ),
                top: 10,
                right: 150,
              ),
              (subCategoryDetail.title == SubCategoryData.OBSTACLE_AVOIDER ||
                      subCategoryDetail.title == SubCategoryData.EDGE_DETECTOR)
                  ? Positioned(
                      left: 80,
                      top: 10,
                      child: getSwitchForObstacleAvoider(),
                    )
                  : Container()
            ],
          ),
        ),
      );
  }

  void onRedSliderChange(double val) {
    setState(() {
      redSliderValue = val;
    });
    writeToBLuetooth([0XC2, val.toInt()]);
    MySharedPreference.setDouble(
        MySharedPreference.FREERUN_REDSLIDER, redSliderValue);
  }

  void onGreenSliderChange(double val) {
    setState(() {
      greenSliderValue = val;
    });
    writeToBLuetooth([0XC3, val.toInt()]);
    MySharedPreference.setDouble(
        MySharedPreference.FREERUN_GREENSLIDER, greenSliderValue);
  }

  void onBlueSliderChange(double val) {
    setState(() {
      blueSliderValue = val;
    });
    writeToBLuetooth([0XC4, val.toInt()]);
    MySharedPreference.setDouble(
        MySharedPreference.FREERUN_BLUESLIDER, blueSliderValue);
  }

  Timer? longPressTimer;

  Widget getCenterLayout(String gameName) {
    print("game name is >>> ${gameName}");
    if (gameName == SubCategoryData.FREE_RUN &&
        subCategoryDetail.mainCategoryTitle == CategoryData.ACCELEREO)
      return Expanded(
        child: Container(
          width: DeviceUtils.getScreenWidtht(context) * 0.30,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      if (redSliderValue > 0) {
                        redSliderValue = redSliderValue - 10;
                        onRedSliderChange(redSliderValue);
                      } else if (redSliderValue <= 0) {
                        redSliderValue = 0;
                        onRedSliderChange(redSliderValue);
                      }
                    },
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (redSliderValue > 0) {
                          redSliderValue = redSliderValue - 10;
                          onRedSliderChange(redSliderValue);
                        } else if (redSliderValue <= 0) {
                          redSliderValue = 0;
                          onRedSliderChange(redSliderValue);
                        }
                      });
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.MINUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                  CustomText("RED:- ${redSliderValue.round()}",
                      TextStyle(color: Colors.black, fontSize: 12)),
                  InkWell(
                    onTap: () {
                      if (redSliderValue < 255) {
                        redSliderValue = redSliderValue + 10;
                        onRedSliderChange(redSliderValue);
                      } else if (redSliderValue >= 255) {
                        redSliderValue = 255;
                        onRedSliderChange(redSliderValue);
                      }
                    },
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (redSliderValue < 255) {
                          redSliderValue = redSliderValue + 10;
                          onRedSliderChange(redSliderValue);
                        } else if (redSliderValue >= 255) {
                          redSliderValue = 255;
                          onRedSliderChange(redSliderValue);
                        }
                      });
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.PLUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ],
              ),
              // Container(
              //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
              //   child: Slider(
              //     value: redSliderValue,
              //     onChanged: onRedSliderChange,
              //     max: 255,
              //     label: redSliderValue.round().toString(),
              //     divisions: 255,
              //     thumbColor: Colors.grey,
              //     activeColor: Colors.red,
              //     inactiveColor: Colors.grey,
              //   ),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (greenSliderValue > 0) {
                          greenSliderValue = greenSliderValue - 10;
                          onGreenSliderChange(greenSliderValue);
                        } else if (greenSliderValue <= 0) {
                          greenSliderValue = 0;
                          onGreenSliderChange(greenSliderValue);
                        }
                      });
                    },
                    onTap: () {
                      if (greenSliderValue > 0) {
                        greenSliderValue = greenSliderValue - 10;
                        onGreenSliderChange(greenSliderValue);
                      } else if (greenSliderValue <= 0) {
                        greenSliderValue = 0;
                        onGreenSliderChange(greenSliderValue);
                      }
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.MINUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                  CustomText("Green:- ${greenSliderValue.round()}",
                      TextStyle(color: Colors.black, fontSize: 12)),
                  InkWell(
                    onTap: () {
                      if (greenSliderValue < 255) {
                        greenSliderValue = greenSliderValue + 10;
                        onGreenSliderChange(greenSliderValue);
                      } else if (greenSliderValue >= 255) {
                        greenSliderValue = 255;
                        onGreenSliderChange(greenSliderValue);
                      }
                    },
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (greenSliderValue < 255) {
                          greenSliderValue = greenSliderValue + 10;
                          onGreenSliderChange(greenSliderValue);
                        } else if (greenSliderValue >= 255) {
                          greenSliderValue = 255;
                          onGreenSliderChange(greenSliderValue);
                        }
                      });
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.PLUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ],
              ),
              // Container(
              //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
              //   child: Slider(
              //     value: greenSliderValue,
              //     onChanged: onGreenSliderChange,
              //     max: 255,
              //     label: greenSliderValue.round().toString(),
              //     divisions: 255,
              //     thumbColor: Colors.grey,
              //     activeColor: Colors.green,
              //     inactiveColor: Colors.grey,
              //   ),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      if (blueSliderValue > 0) {
                        blueSliderValue = blueSliderValue - 10;
                        onBlueSliderChange(blueSliderValue);
                      } else if (blueSliderValue <= 0) {
                        blueSliderValue = 0;
                        onBlueSliderChange(blueSliderValue);
                      }
                    },
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (blueSliderValue > 0) {
                          blueSliderValue = blueSliderValue - 10;
                          onBlueSliderChange(blueSliderValue);
                        } else if (blueSliderValue <= 0) {
                          blueSliderValue = 0;
                          onBlueSliderChange(blueSliderValue);
                        }
                      });
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.MINUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                  CustomText("Blue:- ${blueSliderValue.round()}",
                      TextStyle(color: Colors.black, fontSize: 12)),
                  InkWell(
                    onTap: () {
                      if (blueSliderValue < 255) {
                        blueSliderValue = blueSliderValue + 10;
                        onBlueSliderChange(blueSliderValue);
                      } else if (blueSliderValue >= 255) {
                        blueSliderValue = 255;
                        onBlueSliderChange(blueSliderValue);
                      }
                    },
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (blueSliderValue < 255) {
                          blueSliderValue = blueSliderValue + 10;
                          onBlueSliderChange(blueSliderValue);
                        } else if (blueSliderValue >= 255) {
                          blueSliderValue = 255;
                          onBlueSliderChange(blueSliderValue);
                        }
                      });
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.PLUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ],
              ),
              // Container(
              //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
              //   child: Slider(
              //     value: blueSliderValue,
              //     onChanged: onBlueSliderChange,
              //     max: 255,
              //     label: blueSliderValue.round().toString(),
              //     divisions: 255,
              //     thumbColor: Colors.grey,
              //     activeColor: Colors.blue,
              //     inactiveColor: Colors.grey,
              //   ),
              // ),
              InkWell(
                onTap: () {
                  setState(() {
                    isHorn = !isHorn;
                  });
                  if (isHorn) {
                    writeToBLuetooth([0XC0]);
                  } else {
                    writeToBLuetooth([0XC1]);
                  }
                },
                child: Image.asset(
                  isHorn ? Assets.CAR_HORN_ON : Assets.CAR_HORN_OFF,
                  height: 60,
                  width: 110,
                ),
              ),
              VerticalGap(10),
            ],
          ),
        ),
      );
    else if (gameName == SubCategoryData.SOCCER) {
      return Expanded(
        child: Center(
          child: ClipRRect(
              clipBehavior: Clip.none,
              borderRadius: BorderRadius.circular(10),
              child: Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      writeToBLuetooth([0XBC, 80]);
                      Future.delayed(Duration(milliseconds: 3000), () {
                        writeToBLuetooth([0XBC, 0]);
                        Future.delayed(Duration(milliseconds: 3000), () {
                          writeToBLuetooth([0XBC, 80]);
                        });
                      });
                    },
                    child: Image.asset(
                      Assets.SOCCER,
                      height: 100,
                      width: 100,
                      fit: BoxFit.fill,
                    ),
                  ))),
        ),
      );
    } else if (gameName == SubCategoryData.THOR_HAMMER) {
      return Expanded(
          child: Center(
        child: ClipRRect(
            clipBehavior: Clip.none,
            borderRadius: BorderRadius.circular(10),
            child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    writeToBLuetooth([0XBB, 0]);
                    Future.delayed(Duration(milliseconds: 3000), () {
                      writeToBLuetooth([0XBB, 90]);
                      Future.delayed(Duration(milliseconds: 3000), () {
                        writeToBLuetooth([0XBB, 0]);
                      });
                    });
                  },
                  child: Image.asset(Assets.THOR_HAMMER,
                      height: 100, width: 100, fit: BoxFit.fill),
                ))),
      ));
    } else if (gameName == SubCategoryData.OBSTACLE_AVOIDER ||
        gameName == SubCategoryData.EDGE_DETECTOR ||
        gameName == SubCategoryData.OBSTACLE_AVOIDER) {
      return !ultrasonicSwitchValue
          ? Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                      "OUTPUT:-$outputAvoidoValue",
                      const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  VerticalGap(8),
                  CustomText(
                      "Distance:- $outputObstaceleavoider",
                      const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  VerticalGap(8),
                  CustomText(
                      "Set Ultrasonic value:-$ultrasonicValue",
                      const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  VerticalGap(16),
                  Container(
                    width: DeviceUtils.getScreenWidtht(context) * 0.30,
                    child: Slider(
                      value: ultrasonicValue,
                      onChanged: onUltrasonicValueChange,
                      max: 255,
                      label: ultrasonicValue.round().toString(),
                      divisions: 255,
                      thumbColor: Colors.grey,
                      activeColor: Colors.yellow,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                  VerticalGap(8),
                  Container(
                      width: 100,
                      child: ElevatedButton(
                          onPressed: () {
                            obstacleAvoiderThreShold = ultrasonicValue.toInt();
                          },
                          child: Center(child: Text("Set"))))
                ],
              ),
            )
          : Container();
    } else if (gameName == SubCategoryData.DUMPER) {
      return Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomText(
                "Dump",
                TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic)),
            VerticalGap(8),
            Container(
              width: DeviceUtils.getScreenWidtht(context) * 0.30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      if (dumpValue > 0) {
                        dumpValue = dumpValue - 10;
                        onDumpValueChange(dumpValue);
                      } else if (dumpValue <= 0) {
                        dumpValue = 0;
                        onDumpValueChange(dumpValue);
                      }
                    },
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (dumpValue > 0) {
                          dumpValue = dumpValue - 10;
                          onDumpValueChange(dumpValue);
                        } else if (dumpValue <= 0) {
                          dumpValue = 0;
                          onDumpValueChange(dumpValue);
                        }
                      });
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.MINUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                  CustomText("Dump:- ${dumpValue.round()}",
                      TextStyle(color: Colors.black, fontSize: 12)),
                  InkWell(
                    onTap: () {
                      if (dumpValue < 60) {
                        dumpValue = dumpValue + 10;
                        onDumpValueChange(dumpValue);
                      } else if (dumpValue >= 60) {
                        dumpValue = 60;
                        onDumpValueChange(dumpValue);
                      }
                    },
                    onTapDown: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                      longPressTimer =
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                        if (dumpValue < 60) {
                          dumpValue = dumpValue + 10;
                          onDumpValueChange(dumpValue);
                        } else if (dumpValue >= 60) {
                          dumpValue = 60;
                          onDumpValueChange(dumpValue);
                        }
                      });
                    },
                    onTapUp: (event) {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    onTapCancel: () {
                      if (longPressTimer != null) {
                        longPressTimer!.cancel();
                      }
                    },
                    child: Image.asset(
                      Assets.PLUS,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ],
              ),
            ),

            // Container(
            //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
            //   child: Slider(
            //     value: dumpValue,
            //     onChanged: onDumpValueChange,
            //     max: 50,
            //     divisions: 50,
            //     thumbColor: Colors.grey,
            //     activeColor: Colors.yellow,
            //     inactiveColor: Colors.grey,
            //   ),
            // )
          ],
        ),
      );
    } else if (gameName == SubCategoryData.FORKLIFT) {
      return Container(
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Swap",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
                Switch(
                    value: forkLiftSwap,
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        forkLiftSwap = val;
                      });
                    })
              ],
            ),
            VerticalGap(16),
            InkWell(
              onTapDown: (event) {
                if (forkLiftSwap) {
                  writeToBLuetooth([0XB6]);
                } else {
                  writeToBLuetooth([0XB5]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XB7]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XB7]);
              },
              child: Image.asset(
                Assets.LIFT,
                height: 80,
                width: 80,
              ),
            ),
            VerticalGap(16),
            InkWell(
              onTapDown: (event) {
                if (forkLiftSwap) {
                  writeToBLuetooth([0XB5]);
                } else {
                  writeToBLuetooth([0XB6]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XB7]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XB7]);
              },
              child: Image.asset(
                Assets.DROP,
                height: 80,
                width: 80,
              ),
            ),
          ],
        )),
      );
    } else if (gameName == SubCategoryData.CRANE) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Swap(Swing)",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
                Switch(
                    value: craneLiftSwap,
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        craneLiftSwap = val;
                      });
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Swap(Lift)",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
                Switch(
                    value: craneSwingSwap,
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        craneSwingSwap = val;
                      });
                    })
              ],
            ),
            VerticalGap(16),
            InkWell(
              onTapDown: (event) {
                if (craneSwingSwap) {
                  writeToBLuetooth([0XB9]);
                } else {
                  writeToBLuetooth([0XB8]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XBA]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XBA]);
              },
              child: Image.asset(
                Assets.LIFT,
                height: 50,
                width: 50,
              ),
            ),
            VerticalGap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTapDown: (event) {
                    if (craneLiftSwap) {
                      writeToBLuetooth([0XB5]);
                    } else {
                      writeToBLuetooth([0XB6]);
                    }
                  },
                  onTapCancel: () {
                    writeToBLuetooth([0XB7]);
                  },
                  onTapUp: (event) {
                    writeToBLuetooth([0XB7]);
                  },
                  child: Image.asset(
                    Assets.SWING_LEFT,
                    height: 50,
                    width: 50,
                  ),
                ),
                HorizontalGap(16),
                InkWell(
                  onTapDown: (event) {
                    if (craneLiftSwap) {
                      writeToBLuetooth([0XB6]);
                    } else {
                      writeToBLuetooth([0XB5]);
                    }
                  },
                  onTapCancel: () {
                    writeToBLuetooth([0XB7]);
                  },
                  onTapUp: (event) {
                    writeToBLuetooth([0XB7]);
                  },
                  child: Image.asset(
                    Assets.SWING_RIGHT,
                    height: 50,
                    width: 50,
                  ),
                ),
              ],
            ),
            VerticalGap(8),
            InkWell(
              onTapDown: (event) {
                if (craneSwingSwap) {
                  writeToBLuetooth([0XB8]);
                } else {
                  writeToBLuetooth([0XB9]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XBA]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XBA]);
              },
              child: Image.asset(
                Assets.DROP,
                height: 50,
                width: 50,
              ),
            ),
          ],
        ),
      );
    } else if (gameName == SubCategoryData.CATAPULT) {
      return Container(
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Swap",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
                Switch(
                    value: catapultSwap,
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        catapultSwap = val;
                      });
                    })
              ],
            ),
            VerticalGap(16),
            InkWell(
              onTapDown: (event) {
                if (catapultSwap) {
                  writeToBLuetooth([0XB6]);
                } else {
                  writeToBLuetooth([0XB5]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XB7]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XB7]);
              },
              child: Image.asset(
                Assets.THROW,
                height: 80,
                width: 80,
                fit: BoxFit.fill,
              ),
            ),
            VerticalGap(16),
            InkWell(
              onTapDown: (event) {
                if (catapultSwap) {
                  writeToBLuetooth([0XB5]);
                } else {
                  writeToBLuetooth([0XB6]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XB7]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XB7]);
              },
              child: Image.asset(
                Assets.RELOAD,
                height: 80,
                width: 80,
              ),
            ),
          ],
        )),
      );
    } else if (gameName == SubCategoryData.BALL_SHOOTER) {
      return Container(
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Swap",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
                Switch(
                    value: ballShooterSwap,
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        ballShooterSwap = val;
                      });
                    })
              ],
            ),
            VerticalGap(16),
            InkWell(
              onTapDown: (event) {
                if (ballShooterSwap) {
                  writeToBLuetooth([0XB6]);
                } else {
                  writeToBLuetooth([0XB5]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XB7]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XB7]);
              },
              child: Image.asset(
                Assets.SHOOOT,
                height: 80,
                width: 80,
              ),
            ),
            VerticalGap(16),
            InkWell(
              onTapDown: (event) {
                if (ballShooterSwap) {
                  writeToBLuetooth([0XB5]);
                } else {
                  writeToBLuetooth([0XB6]);
                }
              },
              onTapCancel: () {
                writeToBLuetooth([0XB7]);
              },
              onTapUp: (event) {
                writeToBLuetooth([0XB7]);
              },
              child: Image.asset(
                Assets.RELOAD,
                height: 80,
                width: 80,
              ),
            ),
          ],
        )),
      );
    } else if (gameName == SubCategoryData.EXCAVATOR) {
      return Expanded(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: DeviceUtils.getScreenWidtht(context) * 0.30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        if (exacavtorSwingValue > 0) {
                          setState(() {
                            exacavtorSwingValue = exacavtorSwingValue - 10;
                          });
                          writeToBLuetooth([0XBB, exacavtorSwingValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_SWINGSLIDER,
                              exacavtorSwingValue);
                        } else if (exacavtorSwingValue <= 0) {
                          setState(() {
                            exacavtorSwingValue = 0;
                          });
                          writeToBLuetooth([0XBB, exacavtorSwingValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_SWINGSLIDER,
                              exacavtorSwingValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorSwingValue > 0) {
                            setState(() {
                              exacavtorSwingValue = exacavtorSwingValue - 10;
                            });
                            writeToBLuetooth(
                                [0XBB, exacavtorSwingValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_SWINGSLIDER,
                                exacavtorSwingValue);
                          } else if (exacavtorSwingValue <= 0) {
                            setState(() {
                              exacavtorSwingValue = 0;
                            });
                            writeToBLuetooth(
                                [0XBB, exacavtorSwingValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_SWINGSLIDER,
                                exacavtorSwingValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.MINUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                    CustomText("Swing:- ${exacavtorSwingValue.round()}",
                        TextStyle(color: Colors.black, fontSize: 12)),
                    InkWell(
                      onTap: () {
                        if (exacavtorSwingValue < 180) {
                          setState(() {
                            exacavtorSwingValue = exacavtorSwingValue + 10;
                          });
                          writeToBLuetooth([0XBB, exacavtorSwingValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_SWINGSLIDER,
                              exacavtorSwingValue);
                        } else if (exacavtorSwingValue >= 180) {
                          setState(() {
                            exacavtorSwingValue = 180;
                          });
                          writeToBLuetooth([0XBB, exacavtorSwingValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_SWINGSLIDER,
                              exacavtorSwingValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorSwingValue < 180) {
                            setState(() {
                              exacavtorSwingValue = exacavtorSwingValue + 10;
                            });
                            writeToBLuetooth(
                                [0XBB, exacavtorSwingValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_SWINGSLIDER,
                                exacavtorSwingValue);
                          } else if (exacavtorSwingValue >= 180) {
                            setState(() {
                              exacavtorSwingValue = 180;
                            });
                            writeToBLuetooth(
                                [0XBB, exacavtorSwingValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_SWINGSLIDER,
                                exacavtorSwingValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.PLUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ],
                ),
              ),

              // Container(
              //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
              //   child: Slider(
              //     value: exacavtorSwingValue,
              //     onChanged: (val) {
              //       setState(() {
              //         exacavtorSwingValue = val;
              //       });
              //       writeToBLuetooth([0XBB, exacavtorSwingValue.toInt()]);
              //     },
              //     max: 180,
              //     divisions: 180,
              //     thumbColor: Colors.grey,
              //     activeColor: Colors.yellow,
              //     inactiveColor: Colors.grey,
              //   ),
              // ),
              Container(
                width: DeviceUtils.getScreenWidtht(context) * 0.30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        if (exacavtorBucketValue > 0) {
                          setState(() {
                            exacavtorBucketValue = exacavtorBucketValue - 10;
                          });
                          writeToBLuetooth(
                              [0XBC, exacavtorBucketValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BUCKETSLIDER,
                              exacavtorBucketValue);
                        } else if (exacavtorBucketValue <= 0) {
                          setState(() {
                            exacavtorBucketValue = 0;
                          });
                          writeToBLuetooth(
                              [0XBC, exacavtorBucketValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BUCKETSLIDER,
                              exacavtorBucketValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorBucketValue > 0) {
                            setState(() {
                              exacavtorBucketValue = exacavtorBucketValue - 10;
                            });
                            writeToBLuetooth(
                                [0XBC, exacavtorBucketValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BUCKETSLIDER,
                                exacavtorBucketValue);
                          } else if (exacavtorBucketValue <= 0) {
                            setState(() {
                              exacavtorBucketValue = 0;
                            });
                            writeToBLuetooth(
                                [0XBC, exacavtorBucketValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BUCKETSLIDER,
                                exacavtorBucketValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.MINUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                    CustomText("Bucket:- ${exacavtorBucketValue.round()}",
                        TextStyle(color: Colors.black, fontSize: 12)),
                    InkWell(
                      onTap: () {
                        if (exacavtorBucketValue < 180) {
                          setState(() {
                            exacavtorBucketValue = exacavtorBucketValue + 10;
                          });
                          writeToBLuetooth(
                              [0XBC, exacavtorBucketValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BUCKETSLIDER,
                              exacavtorBucketValue);
                        } else if (exacavtorBucketValue >= 180) {
                          setState(() {
                            exacavtorBucketValue = 180;
                          });
                          writeToBLuetooth(
                              [0XBC, exacavtorBucketValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BUCKETSLIDER,
                              exacavtorBucketValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorBucketValue < 180) {
                            setState(() {
                              exacavtorBucketValue = exacavtorBucketValue + 10;
                            });
                            writeToBLuetooth(
                                [0XBC, exacavtorBucketValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BUCKETSLIDER,
                                exacavtorBucketValue);
                          } else if (exacavtorBucketValue >= 180) {
                            setState(() {
                              exacavtorBucketValue = 180;
                            });
                            writeToBLuetooth(
                                [0XBC, exacavtorBucketValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BUCKETSLIDER,
                                exacavtorBucketValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.PLUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ],
                ),
              ),
              // Text("Bucket",
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              // Container(
              //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
              //   child: Slider(
              //     value: exacavtorBucketValue,
              //     onChanged: (val) {
              //       setState(() {
              //         exacavtorBucketValue = val;
              //       });
              //       writeToBLuetooth([0XBC, val.toInt()]);
              //     },
              //     max: 180,
              //     divisions: 180,
              //     thumbColor: Colors.grey,
              //     activeColor: Colors.yellow,
              //     inactiveColor: Colors.grey,
              //   ),
              // ),
              Container(
                width: DeviceUtils.getScreenWidtht(context) * 0.30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        if (exacavtorBoomValue > 0) {
                          setState(() {
                            exacavtorBoomValue = exacavtorBoomValue - 10;
                          });
                          writeToBLuetooth(
                              [0XBD, 180 - exacavtorBoomValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BOONSLIDER,
                              exacavtorBoomValue);
                        } else if (exacavtorBoomValue <= 0) {
                          setState(() {
                            exacavtorBoomValue = 0;
                          });
                          writeToBLuetooth(
                              [0XBD, 180 - exacavtorBoomValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BOONSLIDER,
                              exacavtorBoomValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorBoomValue > 0) {
                            setState(() {
                              exacavtorBoomValue = exacavtorBoomValue - 10;
                            });
                            writeToBLuetooth(
                                [0XBD, 180 - exacavtorBoomValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BOONSLIDER,
                                exacavtorBoomValue);
                          } else if (exacavtorBoomValue <= 0) {
                            setState(() {
                              exacavtorBoomValue = 0;
                            });
                            writeToBLuetooth(
                                [0XBD, 180 - exacavtorBoomValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BOONSLIDER,
                                exacavtorBoomValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.MINUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                    CustomText("Boon:- ${exacavtorBoomValue.round()}",
                        TextStyle(color: Colors.black, fontSize: 12)),
                    InkWell(
                      onTap: () {
                        if (exacavtorBoomValue < 180) {
                          setState(() {
                            exacavtorBoomValue = exacavtorBoomValue + 10;
                          });
                          writeToBLuetooth(
                              [0XBD, 180 - exacavtorBoomValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BOONSLIDER,
                              exacavtorBoomValue);
                        } else if (exacavtorBoomValue >= 180) {
                          setState(() {
                            exacavtorBoomValue = 180;
                          });
                          writeToBLuetooth(
                              [0XBD, 180 - exacavtorBoomValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_BOONSLIDER,
                              exacavtorBoomValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorBoomValue < 180) {
                            setState(() {
                              exacavtorBoomValue = exacavtorBoomValue + 10;
                            });
                            writeToBLuetooth(
                                [0XBD, 180 - exacavtorBoomValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BOONSLIDER,
                                exacavtorBoomValue);
                          } else if (exacavtorBoomValue >= 180) {
                            setState(() {
                              exacavtorBoomValue = 180;
                            });
                            writeToBLuetooth(
                                [0XBD, 180 - exacavtorBoomValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_BOONSLIDER,
                                exacavtorBoomValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.PLUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ],
                ),
              ),
              // Text("Boon",
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              // Container(
              //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
              //   child: Slider(
              //     value: exacavtorBoomValue,
              //     onChanged: (val) {
              //       setState(() {
              //         exacavtorBoomValue = val;
              //       });
              //       writeToBLuetooth([0XBD, val.toInt()]);
              //     },
              //     max: 180,
              //     divisions: 180,
              //     thumbColor: Colors.grey,
              //     activeColor: Colors.yellow,
              //     inactiveColor: Colors.grey,
              //   ),
              // ),
              Container(
                width: DeviceUtils.getScreenWidtht(context) * 0.30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        if (exacavtorArmValue > 0) {
                          setState(() {
                            exacavtorArmValue = exacavtorArmValue - 10;
                          });
                          writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_ARMSLIDER,
                              exacavtorArmValue);
                        } else if (exacavtorArmValue <= 0) {
                          setState(() {
                            exacavtorArmValue = 0;
                          });
                          writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_ARMSLIDER,
                              exacavtorArmValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorArmValue > 0) {
                            setState(() {
                              exacavtorArmValue = exacavtorArmValue - 10;
                            });
                            writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_ARMSLIDER,
                                exacavtorArmValue);
                          } else if (exacavtorArmValue <= 0) {
                            setState(() {
                              exacavtorArmValue = 0;
                            });
                            writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_ARMSLIDER,
                                exacavtorArmValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.MINUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                    CustomText("Arm:- ${exacavtorArmValue.round()}",
                        TextStyle(color: Colors.black, fontSize: 12)),
                    InkWell(
                      onTap: () {
                        if (exacavtorArmValue < 180) {
                          setState(() {
                            exacavtorArmValue = exacavtorArmValue + 10;
                          });
                          writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_ARMSLIDER,
                              exacavtorArmValue);
                        } else if (exacavtorArmValue >= 180) {
                          setState(() {
                            exacavtorArmValue = 180;
                          });
                          writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                          MySharedPreference.setDouble(
                              MySharedPreference.FREERUN_ARMSLIDER,
                              exacavtorArmValue);
                        }
                      },
                      onTapDown: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                        longPressTimer = Timer.periodic(
                            Duration(milliseconds: 100), (timer) {
                          if (exacavtorArmValue < 180) {
                            setState(() {
                              exacavtorArmValue = exacavtorArmValue + 10;
                            });
                            writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_ARMSLIDER,
                                exacavtorArmValue);
                          } else if (exacavtorArmValue >= 180) {
                            setState(() {
                              exacavtorArmValue = 180;
                            });
                            writeToBLuetooth([0XBE, exacavtorArmValue.toInt()]);
                            MySharedPreference.setDouble(
                                MySharedPreference.FREERUN_ARMSLIDER,
                                exacavtorArmValue);
                          }
                        });
                      },
                      onTapUp: (event) {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      onTapCancel: () {
                        if (longPressTimer != null) {
                          longPressTimer!.cancel();
                        }
                      },
                      child: Image.asset(
                        Assets.PLUS,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ],
                ),
              ),
              VerticalGap(20),

              // Text("Arm",
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              // Container(
              //   width: DeviceUtils.getScreenWidtht(context) * 0.30,
              //   child: Slider(
              //     value: exacavtorArmValue,
              //     onChanged: (val) {
              //       setState(() {
              //         exacavtorArmValue = val;
              //       });
              //       writeToBLuetooth([0XBE, val.toInt()]);
              //     },
              //     max: 180,
              //     divisions: 180,
              //     thumbColor: Colors.grey,
              //     activeColor: Colors.yellow,
              //     inactiveColor: Colors.grey,
              //   ),
              // )
            ],
          ),
        ),
      );
    } else if (gameName == CategoryData.ARNY_TANK) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Swap(Shoot)",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic)),
                    Switch(
                        value: armyTankShootSwap,
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            armyTankShootSwap = val;
                          });
                        })
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Swap(Swing)",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic)),
                    Switch(
                        value: armyTankSwingSwap,
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            armyTankSwingSwap = val;
                          });
                        })
                  ],
                )
              ],
            ),
            InkWell(
              onTapDown: (event) {
                if (armyTankShootSwap) {
                  writeToBLuetooth([0XB9]);
                } else {
                  writeToBLuetooth([0XB8]);
                }
              },
              onTapUp: (event) {
                writeToBLuetooth([0XBA]);
              },
              child: Image.asset(
                Assets.SHOOOTER_MDPI,
                height: 60,
                width: 60,
              ),
            ),
            VerticalGap(2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTapDown: (event) {
                    if (armyTankSwingSwap) {
                      writeToBLuetooth([0XB6]);
                    } else {
                      writeToBLuetooth([0XB5]);
                    }
                  },
                  onTapUp: (event) {
                    writeToBLuetooth([0XB7]);
                  },
                  child: Image.asset(
                    Assets.SWING_MDPI,
                    height: 60,
                    width: 60,
                  ),
                ),
                HorizontalGap(16),
                InkWell(
                  onTapDown: (event) {
                    if (armyTankSwingSwap) {
                      writeToBLuetooth([0XB5]);
                    } else {
                      writeToBLuetooth([0XB6]);
                    }
                  },
                  onTapUp: (event) {
                    writeToBLuetooth([0XB7]);
                  },
                  child: Image.asset(
                    Assets.SWING_MDPI_2,
                    height: 60,
                    width: 60,
                  ),
                ),
              ],
            ),
            VerticalGap(2),
            InkWell(
              onTapDown: (event) {
                if (armyTankShootSwap) {
                  writeToBLuetooth([0XB8]);
                } else {
                  writeToBLuetooth([0XB9]);
                }
              },
              onTapUp: (event) {
                writeToBLuetooth([0XBA]);
              },
              child: Image.asset(
                Assets.RELOAD,
                height: 60,
                width: 60,
              ),
            ),
          ],
        ),
      );
    } else if (gameName == SubCategoryData.RADAR) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Angle:- ",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black)),
                Container(
                  width: 70,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Text(radarAngle.toString()),
                ),
                HorizontalGap(16),
                Text("Distance:- ",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black)),
                Container(
                  width: 70,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Text(outputObstaceleavoider.toString()),
                ),
              ],
            ),
            VerticalGap(32),
            Container(
              height: 250,
              width: 200,
              color: Colors.transparent,
              child: SfRadialGauge(
                enableLoadingAnimation: false,
                backgroundColor: Colors.white,
                axes: <RadialAxis>[
                  RadialAxis(
                    maximum: 180,
                    minimum: 0,
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 180,
                        color: Colors.black12,
                      )
                    ],
                    interval: 20.0,
                    axisLineStyle: AxisLineStyle(
                        cornerStyle: CornerStyle.bothCurve,
                        color: Colors.black12,
                        thickness: 10),
                    pointers: pointers,
                  )
                ],
              ),
            )
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  List<GaugePointer> pointers = [];

  void addNeedleWidget(double value) {
    final List<Color> gradient = [
      Colors.red,
      Colors.red,
      Colors.green,
      Colors.green,
    ];
    final double fillPercent = (outputObstaceleavoider / 255) *
        100.toDouble(); // fills 56.23% for container from bottom
    final double fillStop = (100 - fillPercent) / 100;
    final List<double> stops = [0.0, fillStop, fillStop, 1.0];
    setState(() {
      pointers.add(NeedlePointer(
        enableDragging: false,
        value: value,
        needleStartWidth: 1,
        needleEndWidth: 1,
        needleLength: 100,
        gradient: LinearGradient(
            stops: stops,
            colors: gradient,
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter),
      ));
    });
    print("pointers data length=" + pointers.length.toString());
  }

  void onUltrasonicValueChange(double val) {
    setState(() {
      ultrasonicValue = val;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    onOkayPressed();

    super.dispose();
  }

  void onDumpValueChange(double val) {
    setState(() {
      dumpValue = val;
    });
    writeToBLuetooth([0XBB, val.toInt()]);
    MySharedPreference.setDouble(
        MySharedPreference.FREERUN_DUMPSLIDER, dumpValue);
  }

  Widget getSwitchForObstacleAvoider() {
    return Container(
      child: Row(
        children: [
          CustomText("Automatic", TextStyle(color: Colors.black, fontSize: 12)),
          HorizontalGap(2),
          Switch(
              value: ultrasonicSwitchValue,
              onChanged: switchForObstacleAvoiderChange,
              activeColor: Colors.white70,
              activeTrackColor: Colors.green),
          HorizontalGap(2),
          CustomText("Manual", TextStyle(color: Colors.black, fontSize: 12))
        ],
      ),
    );
  }

  void switchForObstacleAvoiderChange(bool val) {
    setState(() {
      ultrasonicSwitchValue = val;
    });
  }

  void onTapBluetoothIcon() {
    //call alert dialog if android device to choose the device bluetooth.
    if (io.Platform.isAndroid) {
      //show chooser option
      showAlertMessage(
          "select the bluetooth connected with your device?", context);
    } else {
      // for ios directly call the ble
      onSelectBle();
    }
  }

  void showAlertMessage(String message, BuildContext context) {
    if (isAnyBluetoothConnected) {
      showAlertOkayMessage(
          "You want to connect new device previous connection will lost? ",
          onOkayPressed);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Alert",
          style: TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () {
                onSelectBle();
                Navigator.pop(context, true);
              },
              child: Container(
                color: Colors.deepPurple,
                padding: const EdgeInsets.all(14),
                child: const Text(
                  "BLE",
                  style: TextStyle(color: Colors.white),
                ),
              )),
          TextButton(
              onPressed: () {
                onSelectNonBle();
                Navigator.pop(context, true);
              },
              child: Container(
                color: Colors.deepPurple,
                padding: const EdgeInsets.all(14),
                child: const Text(
                  "NON-BLE",
                  style: TextStyle(color: Colors.white),
                ),
              ))
        ],
      ),
    );
  }

  void onSelectBle() {
    bleConnect = BleConnectivity();
    bleConnect!.askRuntimePermissions(
        context, showBottomDialog, connectBleDevice, onrecvBleData);
  }

  void onrecvBleData(List<int> data) {
    setState(() {
      outputObstaceleavoider = data.first;
    });
    if (subCategoryDetail.title == SubCategoryData.OBSTACLE_AVOIDER) {
      startObstacle();
    } else if (subCategoryDetail.title == SubCategoryData.EDGE_DETECTOR) {
      startEdge();
    } else if (subCategoryDetail.title == SubCategoryData.LINE_FOLLOWER) {
      if (d1) {
        setState(() {
          proximityOne = data.first;
        });
      } else {
        setState(() {
          proximityTwo = data.first;
        });
      }
    } else if (subCategoryDetail.title == SubCategoryData.RADAR) {
      setState(() {
        if (radarAngle == 180 || radarAngle == 0) {
          pointers.removeRange(1, pointers.length);
        }
        if (radarAngle <= 175 && shouldIncrease) {
          radarAngle = radarAngle + 5;
          addNeedleWidget(radarAngle);
          shouldIncrease = true;
        } else {
          radarAngle = radarAngle - 5;
          addNeedleWidget(radarAngle);

          if (radarAngle <= 0) {
            shouldIncrease = true;
          } else {
            shouldIncrease = false;
          }
        }
      });
      writeToBLuetooth([0XBB, radarAngle.toInt()]);
    }
  }

  void onrecvNonBleData(Uint8List data) {
    setState(() {
      outputObstaceleavoider = data.first;
    });
    if (subCategoryDetail.title == SubCategoryData.OBSTACLE_AVOIDER) {
      startObstacle();
    } else if (subCategoryDetail.title == SubCategoryData.EDGE_DETECTOR) {
      startEdge();
    } else if (subCategoryDetail.title == SubCategoryData.LINE_FOLLOWER) {
      if (d1) {
        setState(() {
          proximityOne = data.first;
        });
      } else {
        setState(() {
          proximityTwo = data.first;
        });
      }
    } else if (subCategoryDetail.title == SubCategoryData.RADAR) {
      setState(() {
        if (radarAngle == 180 || radarAngle == 0) {
          pointers.removeRange(1, pointers.length);
        }
        if (radarAngle <= 175 && shouldIncrease) {
          radarAngle = radarAngle + 5;
          addNeedleWidget(radarAngle);

          shouldIncrease = true;
        } else {
          radarAngle = radarAngle - 5;
          addNeedleWidget(radarAngle);

          if (radarAngle <= 0) {
            shouldIncrease = true;
          } else {
            shouldIncrease = false;
          }
        }
      });
      writeToBLuetooth([0XBB, radarAngle.toInt()]);
    }
  }

  void onSelectNonBle() {
    if (connectivity == null) {
      connectivity =
          ArduinoSerialConnectivity(onNondBleConnectvity, onrecvNonBleData);
    }
    connectivity!.start(context);
  }

  void onNondBleConnectvity(bool value) {
    setState(() {
      isAnyBluetoothConnected = value;
      ifSerialConnected = value;
    });
    if (ifSerialConnected) {
      if (subCategoryDetail.title == SubCategoryData.OBSTACLE_AVOIDER ||
          subCategoryDetail.title == SubCategoryData.EDGE_DETECTOR) {
        startSendingObstacleAvoiderCommandToRecvValues();
      } else if (subCategoryDetail.title == SubCategoryData.LINE_FOLLOWER) {
        startSendingLineFollowerCommand();
      } else if (subCategoryDetail.title == SubCategoryData.RADAR) {
        startSendingRadarCommand([0XD0]);
      }
    } else {
      if (subCategoryDetail.title == SubCategoryData.OBSTACLE_AVOIDER ||
          subCategoryDetail.title == SubCategoryData.EDGE_DETECTOR) {
        stopSendingObstacleAvoiderCommandToRecvValues();
      } else if (subCategoryDetail.title == SubCategoryData.LINE_FOLLOWER) {
      } else if (subCategoryDetail.title == SubCategoryData.RADAR) {
        stopSendingRadarCommand();
      }
    }
  }

  void onOkayPressed() {
    if (isAnyBluetoothConnected) {
      if (obstacleAvoiderThreShold != -1) {
        writeToBLuetooth([0XB4]);
      }
      if (ifSerialConnected) {
        connectivity!.disconnecToBluetooth();
      } else {
        bleConnect!.disconnectToBluetooth(scanResult!);
      }
    }
    if (commandTimer != null) {
      commandTimer?.cancel();
    }
  }

  bool d1 = false;
  bool shouldStopLine = false;

  void startSendingLineFollowerCommand() {
    if (commandTimer != null) {
      commandTimer!.cancel();
    }
    commandTimer = Timer.periodic(Duration(milliseconds: 600), (timer) {
      if (!shouldStopLine) {
        if (!d1) {
          d1 = true;
          writeToBLuetooth([0XD1]);
        } else {
          d1 = false;
          writeToBLuetooth([0XD2]);
        }
      }
    });
  }

  void startSendingObstacleAvoiderCommandToRecvValues() {
    commandTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      writeToBLuetooth([0XD0]);
    });
  }

  void stopSendingObstacleAvoiderCommandToRecvValues() {
    commandTimer?.cancel();
    if (obstacleAvoiderThreShold != -1) {
      writeToBLuetooth([0XB4]);
    }
  }

  void showBottomDialog(Stream data) {
    showModalBottomSheet(
        constraints: BoxConstraints(maxWidth: 300, minHeight: 100),
        context: context,
        builder: (context) {
          return StreamBuilder(
            builder: (c, snapshot) {
              if (snapshot.data != null) {
                return Container(
                  child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: (snapshot.data as List<dynamic>)!.length,
                      itemBuilder: (context, index) {
                        return (snapshot.data as List<ScanResult>)[index]
                                .device
                                .name!
                                .isNotEmpty
                            ? InkWell(
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
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
                                          (snapshot.data
                                                  as List<ScanResult>)[index]
                                              .device
                                              .name,
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.lightGreen),
                                        ),
                                      ),
                                      HorizontalGap(10),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.all(
                                                Dimensions.size_8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    Dimensions.size_10),
                                              ),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (getButtonText((snapshot.data
                                                        as List<ScanResult>)[
                                                    index]) ==
                                                "Disconnect") {
                                              bleConnect!.disconnectToBluetooth(
                                                  (snapshot.data as List<
                                                      ScanResult>)[index]);
                                            } else {
                                              bleConnect!.connectToBluetooth(
                                                  (snapshot.data as List<
                                                      ScanResult>)[index]);
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                              width: 100,
                                              child: CustomText(
                                                getButtonText((snapshot.data
                                                        as List<ScanResult>)[
                                                    index]),
                                                ButtonStyles
                                                    .getButtonTextStyle(),
                                                textAlign: TextAlign.center,
                                              ))),
                                      HorizontalGap(10),
                                    ],
                                  ),
                                ),
                              )
                            : Container();
                      }),
                );
              } else {
                return Container();
              }
            },
            initialData: [],
            stream: data,
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

  String getButtonText(ScanResult r) {
    String st = "Connect";
    if (scanResult != null) {
      if (scanResult!.device.id.id == r.device.id.id) {
        if (ifBleConnected) {
          return "Disconnect";
        }
      }
    }
    return st;
  }

  void writeToBLuetooth(List<int> data) {
    if (isAnyBluetoothConnected) {
      if (ifSerialConnected) {
        Uint8List list = Uint8List(data.length);
        for (int i = 0; i < data.length; i++) {
          list[i] = data[i];
        }
        connectivity!.writeToConnection(list);
      } else {
        bleConnect!.writeToBle(data);
      }
    } else {
      showToast("Bluetooth not connected");
    }
  }

  void connectBleDevice(BluetoothDeviceState state, ScanResult result) {
    this.scanResult = result;
    if (state == BluetoothDeviceState.connected) {
      setState(() {
        isAnyBluetoothConnected = true;
        ifBleConnected = true;
      });
      if (subCategoryDetail.title == SubCategoryData.OBSTACLE_AVOIDER ||
          subCategoryDetail.title == SubCategoryData.EDGE_DETECTOR) {
        startSendingObstacleAvoiderCommandToRecvValues();
      } else if (subCategoryDetail.title == SubCategoryData.LINE_FOLLOWER) {
        startSendingLineFollowerCommand();
      } else if (subCategoryDetail.title == SubCategoryData.RADAR) {
        startSendingRadarCommand([0XD0]);
      }
    } else if (state == BluetoothDeviceState.disconnected) {
      setState(() {
        isAnyBluetoothConnected = false;
        ifBleConnected = false;
      });
      if (subCategoryDetail.title == SubCategoryData.OBSTACLE_AVOIDER ||
          subCategoryDetail.title == SubCategoryData.EDGE_DETECTOR) {
        stopSendingObstacleAvoiderCommandToRecvValues();
      } else if (subCategoryDetail.title == SubCategoryData.RADAR) {
        stopSendingRadarCommand();
      }
    }
  }

  void startObstacle() {
    if (obstacleAvoiderThreShold != -1) {
      if (outputObstaceleavoider > obstacleAvoiderThreShold) {
        //go forward
        setState(() {
          outputAvoidoValue = "Forward";
        });
        writeToBLuetooth([0XB0]);
      } else {
        //left turn
        setState(() {
          outputAvoidoValue = "Backward";
        });
        writeToBLuetooth([0XB1]);
        Future.delayed(Duration(milliseconds: 150), () {
          setState(() {
            outputAvoidoValue = "Left";
          });
          writeToBLuetooth([0XB2]);
        });
      }
    }
  }

  bool isBackward = false;

  void startEdge() {
    if (obstacleAvoiderThreShold != -1) {
      if (outputObstaceleavoider < obstacleAvoiderThreShold) {
        //go forward
        setState(() {
          outputAvoidoValue = "Forward";
        });
        writeToBLuetooth([0XB0]);
      } else {
        //left turn

        setState(() {
          outputAvoidoValue = "Backward";
        });
        writeToBLuetooth([0XB1]);
        Future.delayed(Duration(milliseconds: 150), () {
          setState(() {
            outputAvoidoValue = "Left";
          });
          writeToBLuetooth([0XB2]);
        });
      }
    }
  }

  Timer? commandTimer;

  void runCommandTimer(List<int> command) {
    if (commandTimer != null) {
      commandTimer?.cancel();
    }
    commandTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      writeToBLuetooth(command);
    });
  }

  void startSendingRadarCommand(List<int> command) {
    commandTimer?.cancel();
    if (io.Platform.isAndroid) {
      commandTimer = Timer.periodic(Duration(milliseconds: 600), (timer) {
        writeToBLuetooth(command);
      });
    } else {
      commandTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        writeToBLuetooth(command);
      });
    }
  }

  void stopSendingRadarCommand() {
    if (commandTimer != null) {
      commandTimer?.cancel();
    }
  }

  Widget proximity_1() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            color: Colors.greenAccent,
            padding: EdgeInsets.all(8),
            child: CustomText("Proximity 1 :-   $proximityOne",
                TextStyle(fontSize: 14, color: Colors.black)),
          ),
          VerticalGap(4),
          Container(
              color: Colors.grey,
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText("Black Value:-",
                      TextStyle(color: Colors.black, fontSize: 14)),
                  HorizontalGap(16),
                  Container(
                    width: 100,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.white,
                    child: TextField(
                        controller: prox_1_black_controller,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                        ],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            constraints: BoxConstraints(),
                            isDense: true,
                            contentPadding: EdgeInsets.zero),
                        style: TextStyle(color: Colors.black)),
                  )
                ],
              )),
          VerticalGap(4),
          Container(
              color: Colors.pinkAccent,
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText("White Value:-",
                      TextStyle(color: Colors.black, fontSize: 14)),
                  HorizontalGap(16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    width: 100,
                    color: Colors.white,
                    child: TextField(
                        controller: prox_1_white_controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero),
                        style: TextStyle(color: Colors.black)),
                  ),
                ],
              )),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  prox_1_white = double.parse(prox_1_white_controller.text);
                  prox_1_black = double.parse(prox_1_black_controller.text);
                  prox_1_average = (prox_1_white + prox_1_black) / 2;
                });
                writeToBLuetooth([0XD3, prox_1_average.toInt()]);
                MySharedPreference.setDouble(
                    MySharedPreference.PROXY_1_BLACK, prox_1_black);
                MySharedPreference.setDouble(
                    MySharedPreference.PROXY_1_WHITE, prox_1_white);
                MySharedPreference.setDouble(
                    MySharedPreference.PROXY_1_AVERAGE, prox_1_average);
              },
              child: CustomText("Set", TextStyle())),
          VerticalGap(4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 8),
            color: Colors.yellow,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText("Black Value:-   " + prox_1_black.toString(),
                    TextStyle(fontSize: 14, color: Colors.black)),
                CustomText("White Value:-   " + prox_1_white.toString(),
                    TextStyle(fontSize: 14, color: Colors.black)),
                CustomText("Threshold Value:-   " + prox_1_average.toString(),
                    TextStyle(fontSize: 14, color: Colors.black)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget proximity_2() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            color: Colors.greenAccent,
            padding: EdgeInsets.all(8),
            child: CustomText("Proximity 2 :-    $proximityTwo",
                TextStyle(fontSize: 14, color: Colors.black)),
          ),
          VerticalGap(4),
          Container(
              color: Colors.grey,
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText("Black Value:-",
                      TextStyle(color: Colors.black, fontSize: 14)),
                  HorizontalGap(16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    width: 100,
                    color: Colors.white,
                    child: TextField(
                        controller: prox_2_black_controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                        ],
                        maxLines: 1,
                        minLines: 1,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(0),
                            isDense: true),
                        style: TextStyle(
                          color: Colors.black,
                        )),
                  )
                ],
              )),
          VerticalGap(4),
          Container(
              color: Colors.pinkAccent,
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText("White Value:-",
                      TextStyle(color: Colors.black, fontSize: 14)),
                  HorizontalGap(16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    width: 100,
                    color: Colors.white,
                    child: TextField(
                        controller: prox_2_white_controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.all(0),
                        ),
                        style: TextStyle(color: Colors.black)),
                  )
                ],
              )),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  prox_2_white = double.parse(prox_2_white_controller.text);
                  prox_2_black = double.parse(prox_2_black_controller.text);
                  prox_2_average = (prox_2_white + prox_2_black) / 2;
                });
                writeToBLuetooth([0XD4, prox_2_average.toInt()]);
                MySharedPreference.setDouble(
                    MySharedPreference.PROXY_2_BLACK, prox_2_black);
                MySharedPreference.setDouble(
                    MySharedPreference.PROXY_2_WHITE, prox_2_white);
                MySharedPreference.setDouble(
                    MySharedPreference.PROXY_2_AVERAGE, prox_2_average);
              },
              child: CustomText("Set", TextStyle())),
          VerticalGap(4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 8),
            color: Colors.yellow,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText("Black Value:-   " + prox_2_black.toString(),
                    TextStyle(fontSize: 14, color: Colors.black)),
                CustomText("White Value:-   " + prox_2_white.toString(),
                    TextStyle(fontSize: 14, color: Colors.black)),
                CustomText("Threshold Value:-   " + prox_2_average.toString(),
                    TextStyle(fontSize: 14, color: Colors.black)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
