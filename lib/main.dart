import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:marquee/marquee.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'soundpad_helper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'soundpad_helper 哔哩哔哩@谢必安_玄'),
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
  int crossAxisCount = 5;
  TextEditingController serverAddressController = TextEditingController();
  bool changing = false;
  int changingindex = 0;
  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadServerAddress();
  }

  void _loadServerAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('server_address');
    String? Count = prefs.getString('crossAxisCount');
    if (serverAddress != null) {
      setState(() {
        serverAddressController.text = serverAddress;
      });
    } else {
      serverAddressController.text = '192.168.2.123:24122';
    }
    if (Count != null) {
      setState(() {
        crossAxisCount = int.parse(Count);
      });
    } else {
      crossAxisCount = 5;
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
      items.add(GridItem(title: '标题', subtitle: subtitle));
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
          title: const Text('编辑控件'),
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
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('删除'),
              onPressed: () {
                setState(() {
                  items.removeAt(index);
                  _saveItems();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('保存'),
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
                        title: const Text('错误'),
                        content: const Text('按键重复，请重新输入'),
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
            TextButton(
              child: const Text('移动'),
              onPressed: () {
                setState(() {
                  changing = true;
                  changingindex = index;
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
    await prefs.setString('crossAxisCount', crossAxisCount.toString());
  }

  void _msg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 3),
    ));
  }

  void save_config() async {
    try {
      final response = await http.post(
        Uri.parse('http://' + serverAddressController.text + '/save_config'),
        body: jsonEncode(<String, dynamic>{
          'crossAxisCount': crossAxisCount,
          'items': items.map((item) {
            return {'title': item.title, 'subtitle': item.subtitle};
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        print('Success: ${response.body}');
        _msg('保存配置到服务器成功');
      } else {
        throw Exception('Failed to send post request');
      }
    } catch (e) {
      print('Failed to send stop request');
      _msg('保存配置到服务器失败\n' + e.toString());
    }
  }

  void load_config() async {
    try {
      final response = await http.get(
        Uri.parse('http://' + serverAddressController.text + '/load_config'),
      );

      if (response.statusCode == 200) {
        print('Success: ${response.body}');
        var data = jsonDecode(jsonDecode(response.body)["data"]);

        setState(() {
          crossAxisCount = data['crossAxisCount'];
          items = List<GridItem>.from(data['items'].map((item) {
            return GridItem(title: item['title'], subtitle: item['subtitle']);
          }));
        });
        _saveItems();
        _msg('从服务器加载配置成功');
      } else {
        throw Exception('Failed to send post request');
      }
    } catch (e) {
      _msg('从服务器加载配置失败\n' + e.toString());
    }
  }

  Widget _buildItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        if (changing) {
          setState(() {
            // items.insert(changingindex, items.removeAt(index));
            var temp = items[changingindex];
            if (changingindex < index) {
              for (int i = changingindex; i < index; i++) {
                items[i] = items[i + 1];
              }
            } else {
              for (int i = changingindex; i > index; i--) {
                items[i] = items[i - 1];
              }
            }
            items[index] = temp;
            _saveItems();
            changing = false;
          });
          return;
        }
        _sendPostRequest(items[index].subtitle);
      },
      onLongPress: () {
        if (changing) {
          setState(() {
            changing = false;
          });
          return;
        }
        _editItem(index);
      },
      child: Card(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double fontSize = constraints.maxWidth * 0.25;
            return Text(
              items[index].title,
              style: TextStyle(fontSize: fontSize),
              textAlign: TextAlign.center,
              softWrap: true,
            );
          },
        ),
      ),
    );
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
            title: changing
                ? const Text('请点击要移动到的位置,长按任一控件取消')
                : TextField(
                    controller: serverAddressController,
                    decoration: const InputDecoration(
                      // hintText: '请输入电脑显示的服务器地址',
                      labelText: '请输入电脑显示的服务器地址',
                    ),
                    onChanged: (value) {
                      _saveServerAddress();
                    },
                  ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () {
                  // save_config();
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('保存到服务器？'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('取消'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('保存'),
                              onPressed: () {
                                save_config();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      });
                },
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('从服务器加载？'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('取消'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('加载'),
                              onPressed: () {
                                load_config();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      });
                },
              ),
              PopupMenuButton<int>(
                onSelected: (value) {
                  _saveServerAddress();
                  setState(() {
                    crossAxisCount = value;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((int value) {
                    return PopupMenuItem<int>(
                      value: value,
                      child: Text('$value columns'),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          body: StaggeredGrid.count(
              crossAxisCount: crossAxisCount,
              children: List.generate(items.length, (index) {
                return _buildItem(context, index);
              })),
          floatingActionButton: FloatingActionButton(
            onPressed: _addItem,
            tooltip: '添加控件',
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
