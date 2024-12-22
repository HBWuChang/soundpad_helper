import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  int crossAxisCount = 2;

  @override
  void initState() {
    super.initState();
    _loadItems();
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
      items.add(GridItem(title: 'Title', subtitle: '按键，如‘F13’‘num4’'));
      _saveItems();
    });
  }

  void _editItem(int index) {
    TextEditingController titleController = TextEditingController(text: items[index].title);
    TextEditingController subtitleController = TextEditingController(text: items[index].subtitle);

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
                decoration: const InputDecoration(labelText: '按键，如‘F13’'),
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
    final response = await http.post(
      Uri.parse('http://192.168.2.123:24122/keyboard'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                  Text(items[index].title, style: const TextStyle(fontSize: 20)),
                  Text(items[index].subtitle, style: const TextStyle(fontSize: 16)),
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
    );
  }
}

class GridItem {
  String title;
  String subtitle;

  GridItem({required this.title, required this.subtitle});
}