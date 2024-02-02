import 'package:flutter/material.dart';
import 'package:sqflite_adapter/sqflite_adapter.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SQLService sqlService = await SQLService(
    tables: [
      TodoTableProvider()
    ],
    databaseName: 'todo.db'
  ).initialize();
  runApp(MyApp(sqlService: sqlService));
}

class MyApp extends StatelessWidget {
  final SQLService sqlService;
  const MyApp({super.key, required this.sqlService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', sqlService: sqlService),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final SQLService sqlService;
  const MyHomePage({super.key, required this.title, required this.sqlService});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<TodoModel> todos = [];

  _create() {
    final TodoModel todo = TodoModel(
      title: _controller.text,
      id: const Uuid().v4(),
    );
    widget.sqlService.insert<TodoModel>(todo).then((value) {
      setState(() {
        todos.add(todo);
        _controller.clear();
      });
    });
  }

  _toggle(TodoModel todo) => (bool? value) {
    setState(() {
      final newTodo = todo.copyWith(isDone: value);
      todos = todos.map((e) {
        if(e.id == todo.id) {
          return newTodo;
        }
        return e;
      }).toList();
      widget.sqlService.update<TodoModel>(newTodo);
    });
  };

  _clear() {
    setState(() {
      widget.sqlService.clear();
      todos.clear();
    });
  }

  @override
  void initState() {
    widget.sqlService.of<TodoTableProvider>().getAll().then((value) {
      setState(() {
        todos = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          ...todos.map((todo) {
            return ListTile(
              title: Text(todo.title),
              trailing: Checkbox(
                value: todo.isDone,
                onChanged: _toggle(todo)
              ),
            );
          }),
          TextField(
            controller: _controller,
          ),
          ElevatedButton(
            onPressed: _create,
            child: const Text('Create'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: _clear,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class TodoModel {
  final String id;
  final String title;
  final bool isDone;

  TodoModel({required this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
    );
  }

  TodoModel copyWith({String? id, String? title, bool? isDone}) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

class TodoTableProvider extends TableProvider<TodoModel> {
  final String tableName = 'todo';
  final String id = 'id';
  final String title = 'title';
  final String isDone = 'isDone';

  @override
  Future<void> insert(TodoModel model) {
    return db.insert(tableName, model.toMap());
  }

  @override
  Future<void> createTable() {
    return db.execute('CREATE TABLE $tableName ($id TEXT PRIMARY KEY, $title TEXT, $isDone INTEGER)');
  }

  @override
  Future<void> clear() {
    return db.delete(tableName);
  }

  @override
  Future<void> update(TodoModel model) {
    return db.update(tableName, model.toMap(), where: '$id = ?', whereArgs: [model.id]);
  }

  Future<List<TodoModel>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return TodoModel.fromMap(maps[i]);
    });
  }

}
