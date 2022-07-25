import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'myApp';
  const keyMasterKey = 'master';
  const keyParseServerUrl = 'http://localhost:1337/parse';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      masterKey: keyMasterKey, debug: true);

  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final todoController = TextEditingController();

  void addToDo() async {
    if (todoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Empty title"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await saveTodo(todoController.text);
    setState(() {
      todoController.clear();
    });
  }

  String objectId = '';

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parse Todo List"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
              padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      autocorrect: true,
                      textCapitalization: TextCapitalization.sentences,
                      controller: todoController,
                      decoration: const InputDecoration(
                          labelText: "New todo",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: Colors.white,
                        primary: Colors.blueAccent,
                      ),
                      onPressed: addToDo,
                      child: const Text("ADD")),
                ],
              )),
          Expanded(
            child: FutureBuilder<List<ParseObject>>(
                future: getTodo(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Center(
                        child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator()),
                      );
                    default:
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error..."),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text("No Data..."),
                        );
                      } else {
                        return ListView.builder(
                            padding: const EdgeInsets.only(top: 10.0),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              //*************************************
                              //Get Parse Object Values
                              final varTodo = snapshot.data![index];
                              final varTitle = varTodo.get('title');
                              final varDone = varTodo.get('done');
                              //*************************************

                              return ListTile(
                                title: Text(varTitle),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      varDone ? Colors.green : Colors.blue,
                                  foregroundColor: Colors.white,
                                  child:
                                      Icon(varDone ? Icons.check : Icons.error),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                        value: varDone,
                                        onChanged: (value) async {
                                          await updateTodo(
                                              varTodo.objectId!, value!);
                                          setState(() {
                                            //Refresh UI
                                          });
                                        }),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () async {
                                        await deleteTodo(varTodo.objectId!);
                                        setState(() {
                                          final snackBar = SnackBar(
                                            content: Text("Todo deleted!"),
                                            duration: Duration(seconds: 2),
                                          );
                                          ScaffoldMessenger.of(context)
                                            ..removeCurrentSnackBar()
                                            ..showSnackBar(snackBar);
                                        });
                                      },
                                    )
                                  ],
                                ),
                              );
                            });
                      }
                  }
                }),
          ),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton(
            onPressed: doSaveData,
            child: const Text('Save Data'),
          ),
          ElevatedButton(onPressed: doReadData, child: const Text('Read Data')),
          ElevatedButton(
              onPressed: doUpdateData, child: const Text('Update Data'))
        ],
      ),
    );
  }

  Future<void> saveTodo(String title) async {
    final todo = ParseObject('Todo')
      ..set('title', title)
      ..set('done', false);
    await todo.save();
  }

  Future<List<ParseObject>> getTodo() async {
    QueryBuilder<ParseObject> queryTodo =
        QueryBuilder<ParseObject>(ParseObject('Todo'));
    final ParseResponse apiResponce = await queryTodo.query();

    if (apiResponce.success && apiResponce.result != null) {
      return apiResponce.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  Future<void> updateTodo(String id, bool done) async {
    var todo = ParseObject('Todo')
      ..objectId = id
      ..set('done', done);
    await todo.save();
  }

  Future<void> deleteTodo(String id) async {
    var todo = ParseObject('Todo')..objectId = id;
    await todo.delete();
  }

  void doSaveData() async {
    var parseObject = ParseObject("DataTypes")
      ..set("stringField", "String")
      ..set("doubleField", 1.5)
      ..set("intField", 2)
      ..set("boolField", true)
      ..set("dateField", DateTime.now())
      ..set("jsonField", {"field1": "value1", "field2": "value2"})
      ..set("listStringField", ["a", "b", "c", "d"])
      ..set("listIntField", [0, 1, 2, 3, 4])
      ..set("listBoolField", [false, true, false])
      ..set("listJsonField", [
        {"field1": "value1", "field2": "value2"},
        {"field1": "value1", "field2": "value2"}
      ]);

    final ParseResponse parseResponse = await parseObject.save();

    if (parseResponse.success) {
      objectId = (parseResponse.results!.first as ParseObject).objectId!;
      showMessage('Object created: $objectId');
    } else {
      showMessage(
          'Object created with failed: ${parseResponse.error.toString()}');
    }
  }

  void doReadData() async {
    if (objectId.isEmpty) {
      showMessage('None objectId. Click button Save Date before.');
      return;
    }

    QueryBuilder<ParseObject> queryUsers =
        QueryBuilder<ParseObject>(ParseObject('DataTypes'))
          ..whereEqualTo('objectId', objectId);
    final ParseResponse parseResponse = await queryUsers.query();
    if (parseResponse.success && parseResponse.results != null) {
      final object = (parseResponse.results!.first) as ParseObject;
      print('stringField: ${object.get<String>('stringField')}');
      print('stringField: ${object.get<String>('stringField')}');
      print('doubleField: ${object.get<double>('doubleField')}');
      print('intField: ${object.get<int>('intField')}');
      print('boolField: ${object.get<bool>('boolField')}');
      print('dateField: ${object.get<DateTime>('dateField')}');
      print('jsonField: ${object.get<Map<String, dynamic>>('jsonField')}');
      print('listStringField: ${object.get<List>('listStringField')}');
      print('listNumberField: ${object.get<List>('listNumberField')}');
      print('listIntField: ${object.get<List>('listIntField')}');
      print('listBoolField: ${object.get<List>('listBoolField')}');
      print('listJsonField: ${object.get<List>('listJsonField')}');
    }
  }

  void doUpdateData() async {
    if (objectId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text('None objectId. Click Save before.')));
      return;
    }

    final parseObject = ParseObject("DataTypes")
      ..objectId = objectId
      ..set("intField", 3)
      ..setAddAllUnique("listStringField", ["e", "f", "g", "h"])
      ..setIncrement('intField', 1);

    final ParseResponse parseResponse = await parseObject.save();

    if (parseResponse.success) {
      showMessage('Object updated: $objectId');
    } else {
      showMessage(
          'Object updated with failed: ${parseResponse.error.toString()}');
    }
  }
}
