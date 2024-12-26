import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<GridItem> items = [];
  int crossAxisCount = 4;
  TextEditingController serverAddressController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadServerAddress();
  }

  void _loadServerAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('server_address');
    if (serverAddress != null) {
      setState(() {
        serverAddressController.text = serverAddress;
      });
    } else {
      serverAddressController.text = '192.168.2.123:24122';
    }
  }

  void _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedItems = prefs.getStringList('grid_items');
    if (savedItems != null) {
      setState(() {
        items = savedItems.map((item) {
          Map<String, dynamic> json = jsonDecode(item);
          return GridItem(title: json['title'], subtitle: json['subtitle']);
        }).toList();
      });
    }
  }

  void _saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedItems = items.map((item) {
      return jsonEncode({'title': item.title, 'subtitle': item.subtitle});
    }).toList();
    await prefs.setStringList('grid_items', savedItems);
  }

  void _addItem() {
    setState(() {
      // 随机生成一个没有重复数字的不包括0的9位数
      String subtitle = '';
      do {
        var tt = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
        tt.shuffle();
        subtitle = tt.join();
        bool hasZero = false;
        bool hasDuplicate = false;
        for (int i = 0; i < subtitle.length; i++) {
          if (subtitle[i] == '0') {
            hasZero = true;
            break;
          }
          for (int j = i + 1; j < subtitle.length; j++) {
            if (subtitle[i] == subtitle[j]) {
              hasDuplicate = true;
              break;
            }
          }
          if (hasZero || hasDuplicate) {
            break;
          }
        }
        if (!hasZero && !hasDuplicate) {
          break;
        }
      } while (true);
      items.add(GridItem(title: 'Title', subtitle: subtitle));
      _saveItems();
    });
  }

  void _editItem(int index) {
    TextEditingController titleController =
        TextEditingController(text: items[index].title);
    TextEditingController subtitleController =
        TextEditingController(text: items[index].subtitle);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: '按键，如123456789'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  items.removeAt(index);
                  _saveItems();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                bool hasDuplicate = false;
                for (int i = 0; i < items.length; i++) {
                  if (i == index) {
                    continue;
                  }
                  if (items[i].subtitle == subtitleController.text) {
                    hasDuplicate = true;
                    break;
                  }
                }
                if (hasDuplicate) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text('Subtitle already exists'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }
                setState(() {
                  items[index].title = titleController.text;
                  items[index].subtitle = subtitleController.text;
                  _saveItems();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendPostRequest(String subtitle) async {
    try {
      final response = await http.post(
        Uri.parse('http://' + serverAddressController.text + '/keyboard'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'key': subtitle,
        }),
      );

      if (response.statusCode == 200) {
        print('Success: ${response.body}');
      } else {
        throw Exception('Failed to send post request');
      }
    } catch (e) {
      print('Failed to send post request');
    }
  }

  void _sendStopRequest() async {
    try {
      final response = await http.post(
        Uri.parse('http://' + serverAddressController.text + '/stop'),
      );

      if (response.statusCode == 200) {
        print('Success: ${response.body}');
      } else {
        throw Exception('Failed to send post request');
      }
    } catch (e) {
      print('Failed to send stop request');
    }
  }

  void _saveServerAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_address', serverAddressController.text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) => {
              _sendStopRequest(),
            },
        child: Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: serverAddressController,
              decoration: const InputDecoration(
                hintText: 'Enter server address',
              ),
              onChanged: (value) {
                _saveServerAddress();
              },
            ),
            actions: <Widget>[
              PopupMenuButton<int>(
                onSelected: (value) {
                  setState(() {
                    crossAxisCount = value;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return [2, 3, 4].map((int value) {
                    return PopupMenuItem<int>(
                      value: value,
                      child: Text('$value columns'),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          body: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _sendPostRequest(items[index].subtitle);
                },
                onLongPress: () {
                  _editItem(index);
                },
                child: Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Text(items[index].title,
                      //     style: const TextStyle(fontSize: 20)),
                      Container(
                        height: 30,
                        child: Marquee(
                          text: items[index].title,
                          style: TextStyle(fontSize: 20),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 20.0,
                          velocity: 50.0,
                          pauseAfterRound: Duration(seconds: 1),
                          startPadding: 10.0,
                          accelerationDuration: Duration(seconds: 1),
                          accelerationCurve: Curves.linear,
                          decelerationDuration: Duration(milliseconds: 500),
                          decelerationCurve: Curves.easeOut,
                        ),
                      ),
                      Text(items[index].subtitle,
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addItem,
            tooltip: 'Add Item',
            child: const Icon(Icons.add),
          ),
        ));
  }
}

class GridItem {
  String title;
  String subtitle;

  GridItem({required this.title, required this.subtitle});
}
