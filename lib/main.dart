// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   // Printer Type [bluetooth, usb, network]
//   var defaultPrinterType = PrinterType.bluetooth;
//   var _isBle = false;
//   var _reconnect = false;
//   var _isConnected = false;
//   var printerManager = PrinterManager.instance;
//   var devices = <BluetoothPrinter>[];
//   StreamSubscription<PrinterDevice>? _subscription;
//   StreamSubscription<BTStatus>? _subscriptionBtStatus;
//   StreamSubscription<USBStatus>? _subscriptionUsbStatus;
//   BTStatus _currentStatus = BTStatus.none;
//   // _currentUsbStatus is only supports on Android
//   // ignore: unused_field
//   USBStatus _currentUsbStatus = USBStatus.none;
//   List<int>? pendingTask;
//   String _ipAddress = '';
//   String _port = '9100';
//   final _ipController = TextEditingController();
//   final _portController = TextEditingController();
//   BluetoothPrinter? selectedPrinter;

//   @override
//   void initState() {
//     if (Platform.isWindows) defaultPrinterType = PrinterType.usb;
//     super.initState();
//     _portController.text = _port;
//     _scan();

//     // subscription to listen change status of bluetooth connection
//     _subscriptionBtStatus =
//         PrinterManager.instance.stateBluetooth.listen((status) {
//       log(' ----------------- status bt $status ------------------ ');
//       _currentStatus = status;
//       if (status == BTStatus.connected) {
//         setState(() {
//           _isConnected = true;
//         });
//       }
//       if (status == BTStatus.none) {
//         setState(() {
//           _isConnected = false;
//         });
//       }
//       if (status == BTStatus.connected && pendingTask != null) {
//         if (Platform.isAndroid) {
//           Future.delayed(const Duration(milliseconds: 1000), () {
//             PrinterManager.instance
//                 .send(type: PrinterType.bluetooth, bytes: pendingTask!);
//             pendingTask = null;
//           });
//         } else if (Platform.isIOS) {
//           PrinterManager.instance
//               .send(type: PrinterType.bluetooth, bytes: pendingTask!);
//           pendingTask = null;
//         }
//       }
//     });
//     //  PrinterManager.instance.stateUSB is only supports on Android
//     _subscriptionUsbStatus = PrinterManager.instance.stateUSB.listen((status) {
//       log(' ----------------- status usb $status ------------------ ');
//       _currentUsbStatus = status;
//       if (Platform.isAndroid) {
//         if (status == USBStatus.connected && pendingTask != null) {
//           Future.delayed(const Duration(milliseconds: 1000), () {
//             PrinterManager.instance
//                 .send(type: PrinterType.usb, bytes: pendingTask!);
//             pendingTask = null;
//           });
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     _subscriptionBtStatus?.cancel();
//     _subscriptionUsbStatus?.cancel();
//     _portController.dispose();
//     _ipController.dispose();
//     super.dispose();
//   }

//   // method to scan devices according PrinterType
//   void _scan() {
//     devices.clear();
//     _subscription = printerManager
//         .discovery(type: defaultPrinterType, isBle: _isBle)
//         .listen((device) {
//       devices.add(BluetoothPrinter(
//         deviceName: device.name,
//         address: device.address,
//         isBle: _isBle,
//         vendorId: device.vendorId,
//         productId: device.productId,
//         typePrinter: defaultPrinterType,
//       ));
//       setState(() {});
//     });
//   }

//   void setPort(String value) {
//     if (value.isEmpty) value = '9100';
//     _port = value;
//     var device = BluetoothPrinter(
//       deviceName: value,
//       address: _ipAddress,
//       port: _port,
//       typePrinter: PrinterType.network,
//       state: false,
//     );
//     selectDevice(device);
//   }

//   void setIpAddress(String value) {
//     _ipAddress = value;
//     var device = BluetoothPrinter(
//       deviceName: value,
//       address: _ipAddress,
//       port: _port,
//       typePrinter: PrinterType.network,
//       state: false,
//     );
//     selectDevice(device);
//   }

//   void selectDevice(BluetoothPrinter device) async {
//     if (selectedPrinter != null) {
//       if ((device.address != selectedPrinter!.address) ||
//           (device.typePrinter == PrinterType.usb &&
//               selectedPrinter!.vendorId != device.vendorId)) {
//         await PrinterManager.instance
//             .disconnect(type: selectedPrinter!.typePrinter);
//       }
//     }

//     selectedPrinter = device;
//     setState(() {});
//   }

//   Future _printReceiveTest() async {
//     List<int> bytes = [];

//     // Xprinter XP-N160I
//     final profile = await CapabilityProfile.load(name: 'TP806L');
//     // PaperSize.mm80 or PaperSize.mm58
//     final generator = Generator(PaperSize.mm80, profile);
//     // bytes += generator.setGlobalCodeTable('CP1252');
//     // bytes += generator.text('Test Print',
//     //     styles: const PosStyles(align: PosAlign.center));
//     // bytes += generator.text('Product 1');
//     //
//     // bytes = utf8.encode('مرحبا');
//     // bytes = generator.setGlobalCodeTable('ISO-8859-6');
//     bytes = utf8.encode('مرحبا');
//     // bytes += generator.text('Product 2');
//     _printEscPos(bytes, generator);
//   }

//   /// print ticket
//   void _printEscPos(List<int> bytes, Generator generator) async {
//     if (selectedPrinter == null) return;
//     var bluetoothPrinter = selectedPrinter!;

//     switch (bluetoothPrinter.typePrinter) {
//       case PrinterType.usb:
//         bytes += generator.feed(2);
//         bytes += generator.cut();
//         await printerManager.connect(
//             type: bluetoothPrinter.typePrinter,
//             model: UsbPrinterInput(
//                 name: bluetoothPrinter.deviceName,
//                 productId: bluetoothPrinter.productId,
//                 vendorId: bluetoothPrinter.vendorId));
//         pendingTask = null;
//         break;
//       case PrinterType.bluetooth:
//         bytes += generator.cut();
//         await printerManager.connect(
//             type: bluetoothPrinter.typePrinter,
//             model: BluetoothPrinterInput(
//                 name: bluetoothPrinter.deviceName,
//                 address: bluetoothPrinter.address!,
//                 isBle: bluetoothPrinter.isBle ?? false,
//                 autoConnect: _reconnect));
//         pendingTask = null;
//         if (Platform.isAndroid) pendingTask = bytes;
//         break;
//       case PrinterType.network:
//         bytes += generator.feed(2);
//         bytes += generator.cut();
//         await printerManager.connect(
//             type: bluetoothPrinter.typePrinter,
//             model: TcpPrinterInput(ipAddress: bluetoothPrinter.address!));
//         break;
//       default:
//     }
//     if (bluetoothPrinter.typePrinter == PrinterType.bluetooth &&
//         Platform.isAndroid) {
//       if (_currentStatus == BTStatus.connected) {
//         printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
//         pendingTask = null;
//       }
//     } else {
//       printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
//     }
//   }

//   // conectar dispositivo
//   _connectDevice() async {
//     _isConnected = false;
//     if (selectedPrinter == null) return;
//     switch (selectedPrinter!.typePrinter) {
//       case PrinterType.usb:
//         await printerManager.connect(
//             type: selectedPrinter!.typePrinter,
//             model: UsbPrinterInput(
//                 name: selectedPrinter!.deviceName,
//                 productId: selectedPrinter!.productId,
//                 vendorId: selectedPrinter!.vendorId));
//         _isConnected = true;
//         break;
//       case PrinterType.bluetooth:
//         await printerManager.connect(
//             type: selectedPrinter!.typePrinter,
//             model: BluetoothPrinterInput(
//                 name: selectedPrinter!.deviceName,
//                 address: selectedPrinter!.address!,
//                 isBle: selectedPrinter!.isBle ?? false,
//                 autoConnect: _reconnect));
//         break;
//       case PrinterType.network:
//         await printerManager.connect(
//             type: selectedPrinter!.typePrinter,
//             model: TcpPrinterInput(ipAddress: selectedPrinter!.address!));
//         _isConnected = true;
//         break;
//       default:
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Flutter Pos Plugin Platform example app'),
//         ),
//         body: Center(
//           child: Container(
//             height: double.infinity,
//             constraints: const BoxConstraints(maxWidth: 400),
//             child: SingleChildScrollView(
//               padding: EdgeInsets.zero,
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: selectedPrinter == null || _isConnected
//                                 ? null
//                                 : () {
//                                     _connectDevice();
//                                   },
//                             child: const Text("Connect",
//                                 textAlign: TextAlign.center),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: selectedPrinter == null || !_isConnected
//                                 ? null
//                                 : () {
//                                     if (selectedPrinter != null)
//                                       printerManager.disconnect(
//                                           type: selectedPrinter!.typePrinter);
//                                     setState(() {
//                                       _isConnected = false;
//                                     });
//                                   },
//                             child: const Text("Disconnect",
//                                 textAlign: TextAlign.center),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   DropdownButtonFormField<PrinterType>(
//                     value: defaultPrinterType,
//                     decoration: const InputDecoration(
//                       prefixIcon: Icon(
//                         Icons.print,
//                         size: 24,
//                       ),
//                       labelText: "Type Printer Device",
//                       labelStyle: TextStyle(fontSize: 18.0),
//                       focusedBorder: InputBorder.none,
//                       enabledBorder: InputBorder.none,
//                     ),
//                     items: <DropdownMenuItem<PrinterType>>[
//                       if (Platform.isAndroid || Platform.isIOS)
//                         const DropdownMenuItem(
//                           value: PrinterType.bluetooth,
//                           child: Text("bluetooth"),
//                         ),
//                       if (Platform.isAndroid || Platform.isWindows)
//                         const DropdownMenuItem(
//                           value: PrinterType.usb,
//                           child: Text("usb"),
//                         ),
//                       const DropdownMenuItem(
//                         value: PrinterType.network,
//                         child: Text("Wifi"),
//                       ),
//                     ],
//                     onChanged: (PrinterType? value) {
//                       setState(() {
//                         if (value != null) {
//                           setState(() {
//                             defaultPrinterType = value;
//                             selectedPrinter = null;
//                             _isBle = false;
//                             _isConnected = false;
//                             _scan();
//                           });
//                         }
//                       });
//                     },
//                   ),
//                   Visibility(
//                     visible: defaultPrinterType == PrinterType.bluetooth &&
//                         Platform.isAndroid,
//                     child: SwitchListTile.adaptive(
//                       contentPadding:
//                           const EdgeInsets.only(bottom: 20.0, left: 20),
//                       title: const Text(
//                         "This device supports ble (low energy)",
//                         textAlign: TextAlign.start,
//                         style: TextStyle(fontSize: 19.0),
//                       ),
//                       value: _isBle,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _isBle = value ?? false;
//                           _isConnected = false;
//                           selectedPrinter = null;
//                           _scan();
//                         });
//                       },
//                     ),
//                   ),
//                   Visibility(
//                     visible: defaultPrinterType == PrinterType.bluetooth &&
//                         Platform.isAndroid,
//                     child: SwitchListTile.adaptive(
//                       contentPadding:
//                           const EdgeInsets.only(bottom: 20.0, left: 20),
//                       title: const Text(
//                         "reconnect",
//                         textAlign: TextAlign.start,
//                         style: TextStyle(fontSize: 19.0),
//                       ),
//                       value: _reconnect,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _reconnect = value ?? false;
//                         });
//                       },
//                     ),
//                   ),
//                   Column(
//                       children: devices
//                           .map(
//                             (device) => ListTile(
//                               title: Text('${device.deviceName}'),
//                               subtitle: Platform.isAndroid &&
//                                       defaultPrinterType == PrinterType.usb
//                                   ? null
//                                   : Visibility(
//                                       visible: !Platform.isWindows,
//                                       child: Text("${device.address}")),
//                               onTap: () {
//                                 // do something
//                                 selectDevice(device);
//                               },
//                               leading: selectedPrinter != null &&
//                                       ((device.typePrinter == PrinterType.usb &&
//                                                   Platform.isWindows
//                                               ? device.deviceName ==
//                                                   selectedPrinter!.deviceName
//                                               : device.vendorId != null &&
//                                                   selectedPrinter!.vendorId ==
//                                                       device.vendorId) ||
//                                           (device.address != null &&
//                                               selectedPrinter!.address ==
//                                                   device.address))
//                                   ? const Icon(
//                                       Icons.check,
//                                       color: Colors.green,
//                                     )
//                                   : null,
//                               trailing: OutlinedButton(
//                                 onPressed: selectedPrinter == null ||
//                                         device.deviceName !=
//                                             selectedPrinter?.deviceName
//                                     ? null
//                                     : () async {
//                                         _printReceiveTest();
//                                       },
//                                 child: const Padding(
//                                   padding: EdgeInsets.symmetric(
//                                       vertical: 2, horizontal: 20),
//                                   child: Text("Print test ticket",
//                                       textAlign: TextAlign.center),
//                                 ),
//                               ),
//                             ),
//                           )
//                           .toList()),
//                   Visibility(
//                     visible: defaultPrinterType == PrinterType.network &&
//                         Platform.isWindows,
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 10.0),
//                       child: TextFormField(
//                         controller: _ipController,
//                         keyboardType:
//                             const TextInputType.numberWithOptions(signed: true),
//                         decoration: const InputDecoration(
//                           label: Text("Ip Address"),
//                           prefixIcon: Icon(Icons.wifi, size: 24),
//                         ),
//                         onChanged: setIpAddress,
//                       ),
//                     ),
//                   ),
//                   Visibility(
//                     visible: defaultPrinterType == PrinterType.network &&
//                         Platform.isWindows,
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 10.0),
//                       child: TextFormField(
//                         controller: _portController,
//                         keyboardType:
//                             const TextInputType.numberWithOptions(signed: true),
//                         decoration: const InputDecoration(
//                           label: Text("Port"),
//                           prefixIcon: Icon(Icons.numbers_outlined, size: 24),
//                         ),
//                         onChanged: setPort,
//                       ),
//                     ),
//                   ),
//                   Visibility(
//                     visible: defaultPrinterType == PrinterType.network &&
//                         Platform.isWindows,
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 10.0),
//                       child: OutlinedButton(
//                         onPressed: () async {
//                           if (_ipController.text.isNotEmpty)
//                             setIpAddress(_ipController.text);
//                           _printReceiveTest();
//                         },
//                         child: const Padding(
//                           padding:
//                               EdgeInsets.symmetric(vertical: 4, horizontal: 50),
//                           child: Text("Print test ticket",
//                               textAlign: TextAlign.center),
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class BluetoothPrinter {
//   int? id;
//   String? deviceName;
//   String? address;
//   String? port;
//   String? vendorId;
//   String? productId;
//   bool? isBle;

//   PrinterType typePrinter;
//   bool? state;

//   BluetoothPrinter(
//       {this.deviceName,
//       this.address,
//       this.port,
//       this.state,
//       this.vendorId,
//       this.productId,
//       this.typePrinter = PrinterType.bluetooth,
//       this.isBle = false});
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _info = "";
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  List<String> _options = [
    "permission bluetooth granted",
    "bluetooth enabled",
    "connection status",
    "update info"
  ];

  String _selectSize = "2";
  final _txtText = TextEditingController(text: "Hello developer");
  bool _progress = false;
  String _msjprogress = "";

  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            PopupMenuButton(
              elevation: 3.2,
              //initialValue: _options[1],
              onCanceled: () {
                print('You have not chossed anything');
              },
              tooltip: 'Menu',
              onSelected: (Object select) async {
                String sel = select as String;
                if (sel == "permission bluetooth granted") {
                  bool status =
                      await PrintBluetoothThermal.isPermissionBluetoothGranted;
                  setState(() {
                    _info = "permission bluetooth granted: $status";
                  });
                  //open setting permision if not granted permision
                } else if (sel == "bluetooth enabled") {
                  bool state = await PrintBluetoothThermal.bluetoothEnabled;
                  setState(() {
                    _info = "Bluetooth enabled: $state";
                  });
                } else if (sel == "update info") {
                  initPlatformState();
                } else if (sel == "connection status") {
                  final bool result =
                      await PrintBluetoothThermal.connectionStatus;
                  setState(() {
                    _info = "connection status: $result";
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return _options.map((String option) {
                  return PopupMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('info: $_info\n '),
                Text(_msj),
                Row(
                  children: [
                    Text("Type print"),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: optionprinttype,
                      items: options.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          optionprinttype = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        this.getBluetoots();
                      },
                      child: Row(
                        children: [
                          Visibility(
                            visible: _progress,
                            child: SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 1,
                                  backgroundColor: Colors.white),
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(_progress ? _msjprogress : "Search"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.disconnect : null,
                      child: Text("Disconnect"),
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.printTest : null,
                      child: Text("Test"),
                    ),
                  ],
                ),
                Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    child: ListView.builder(
                      itemCount: items.length > 0 ? items.length : 0,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            String mac = items[index].macAdress;
                            this.connect(mac);
                          },
                          title: Text('Name: ${items[index].name}'),
                          subtitle:
                              Text("macAddress: ${items[index].macAdress}"),
                        );
                      },
                    )),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: Column(children: [
                    Text(
                        "Text size without the library without external packets, print images still it should not use a library"),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _txtText,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Text",
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        DropdownButton<String>(
                          hint: Text('Size'),
                          value: _selectSize,
                          items: <String>['1', '2', '3', '4', '5']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: new Text(value),
                            );
                          }).toList(),
                          onChanged: (String? select) {
                            setState(() {
                              _selectSize = select.toString();
                            });
                          },
                        )
                      ],
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.printWithoutPackage : null,
                      child: Text("Print"),
                    ),
                  ]),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int porcentbatery = 0;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
      print("patformversion: $platformVersion");
      porcentbatery = await PrintBluetoothThermal.batteryLevel;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    print("bluetooth enabled: $result");
    if (result) {
      _msj = "Bluetooth enabled, please search and connect";
    } else {
      _msj = "Bluetooth not enabled";
    }

    setState(() {
      _info = platformVersion + " ($porcentbatery% battery)";
    });
  }

  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    /*await Future.forEach(listResult, (BluetoothInfo bluetooth) {
      String name = bluetooth.name;
      String mac = bluetooth.macAdress;
    });*/

    setState(() {
      _progress = false;
    });

    if (listResult.length == 0) {
      _msj =
          "There are no bluetoohs linked, go to settings and link the printer";
    } else {
      _msj = "Touch an item in the list to connect";
    }

    setState(() {
      items = listResult;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    print("state conected $result");
    if (result) connected = true;
    setState(() {
      _progress = false;
    });
  }

  Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("status disconnect $status");
  }

  Future<void> printTest() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      List<int> ticket = await testTicket();
      final result = await PrintBluetoothThermal.writeBytes(ticket);
      print("print test result:  $result");
    } else {
      //no conectado, reconecte
    }
  }

  Future<void> printString() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    if (conexionStatus) {
      String enter = '\n';
      await PrintBluetoothThermal.writeBytes(enter.codeUnits);
      //size of 1-5
      String text = "Hello";
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 1, text: text));
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 2, text: text + " size 2"));
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 3, text: text + " size 3"));
    } else {
      //desconectado
      print("desconectado bluetooth $conexionStatus");
    }
  }

  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    // final ByteData data = await rootBundle.load('assets/mylogo.jpg');
    // final Uint8List bytesImg = data.buffer.asUint8List();
    // img.Image? image = img.decodeImage(bytesImg);

    if (Platform.isIOS) {
      // Resizes the image to half its original size and reduces the quality to 80%
      // final resizedImage = img.copyResize(image!,
      //     width: image.width ~/ 1.3,
      //     height: image.height ~/ 1.3,
      //     interpolation: img.Interpolation.nearest);
      // final bytesimg = Uint8List.fromList(img.encodeJpg(resizedImage));
      //image = img.decodeImage(bytesimg);
    }

    //Using `ESC *`
    // bytes += generator.image(image!);
/*
    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ',
        styles: PosStyles(codeTable: 'CP1256'));
    bytes += generator.text('Special 1: ñÑ àÀ èÈ éÉ üÜ çÇ ôÔ',
        styles: PosStyles(codeTable: 'CP1256'));
    bytes += generator.text('Special 2: blåbærgrød',
        styles: PosStyles(codeTable: 'CP1256'));

    bytes += generator.text('Bold text', styles: PosStyles(bold: true));
    bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: PosStyles(underline: true), linesAfter: 1);
    bytes +=
        generator.text('Align left', styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: '',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);
*/
    //barcode
    bytes = utf8.encode('');
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    //QR code
    bytes += generator.qrcode('example.com');

    bytes += generator.text(
      'Text size %',
      styles: PosStyles(reverse: false, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      'Text size %',
      styles: PosStyles(reverse: true),
    );
    bytes += generator.text(
      'Text size 100%',
      styles: PosStyles(
        fontType: PosFontType.fontA,
      ),
    );
    bytes += generator.text(
      'Text size 200%',
      styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.feed(2);
    //bytes += generator.cut();
    return bytes;
  }

  Future<void> printWithoutPackage() async {
    //impresion sin paquete solo de PrintBluetoothTermal
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      String text = _txtText.text.toString() + "\n";
      List<int> ticket = [217, 132, 217, 138, 216, 171]; // utf8.encode('sss');

      print("decoded List: ${Uint8List.fromList(ticket)}");
      var a = Uint8List.sublistView(
          utf8.encode('ليث ليث ليث ليث ليث ليث') as TypedData);
      final result = await PrintBluetoothThermal.writeBytes(a);
      // bool result = await PrintBluetoothThermal.writeBytes(utf8.encode('سس'));
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 2, text: utf8.decode(a)));
      print("status print result: $result");
      print("encoded: ${utf8.encode('ليث')}");
      setState(() {
        _msj = "printed status: $result";
      });
    } else {
      //no conectado, reconecte
      setState(() {
        _msj = "no connected device";
      });
      print("no conectado");
    }
  }
}
