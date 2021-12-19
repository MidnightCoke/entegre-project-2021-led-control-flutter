import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class LedControl extends StatefulWidget {
  final BluetoothDevice server;

  const LedControl({this.server});

  @override
  _LedControl createState() => new _LedControl();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _LedControl extends State<LedControl> {
  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages;
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;
  bool redLightSwitch = false;
  bool greenLightSwitch = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally.');
        } else {
          print('Disconnected remotely.');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect the device.');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting with ' + widget.server.name + '...')
              : isConnected
                  ? Text('Connected with ' + widget.server.name)
                  : Text('No Device was Connected '))),
      body: Container(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Red Light", style: TextStyle(fontSize: 21.0)),
              SizedBox(
                height: 15.0,
              ),
              Transform.scale(
                scale: 2.0,
                child: Switch(
                  value: redLightSwitch,
                  onChanged: (value) {
                    setState(() {
                      redLightSwitch = value;
                      print(redLightSwitch);
                      redLightSwitch ? _sendMessage('1') : _sendMessage('0');
                    });
                  },
                  activeTrackColor: Colors.red,
                  activeColor: Colors.red[100],
                ),
              ),
              SizedBox(
                height: 125.0,
              ),
              Text(
                "Green Light",
                style: TextStyle(fontSize: 21.0),
              ),
              SizedBox(
                height: 15.0,
              ),
              Transform.scale(
                scale: 2.0,
                child: Switch(
                  value: greenLightSwitch,
                  onChanged: (value) {
                    setState(() {
                      greenLightSwitch = value;
                      print(greenLightSwitch);
                      greenLightSwitch ? _sendMessage('3') : _sendMessage('2');
                    });
                  },
                  activeTrackColor: Colors.green,
                  activeColor: Colors.green[100],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Error Exception
        setState(() {});
      }
    }
  }
}
