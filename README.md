
## Getting started

```shell
flutter pub add sqflite_adapter
```

## Usage

create a table provider by extending the `TableProvider` class and implement the abstract methods. The `TableProvider` class provides a simple way to create a table schema and perform CRUD operations on the table.

```dart
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

```

create a new instance of the `SQLService` class and pass the table provider to the `tables` parameter. Then call the `initialize` method to initialize the database.

```dart

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

```

## Example Usage

```dart
sqlService.of<TodoTableProvider>().insert(TodoModel(id: '1', title: 'Buy milk', isDone: false));
//or
sqlService.insert<TodoModel>(TodoModel(id: '1', title: 'Buy milk', isDone: false));

//and use custom methods in the table provider
sqlService.of<TodoTableProvider>().getAll();
```

## Additional information

This package is a wrapper around the `sqflite` package to make it easier to use. It provides a simple way to create a table schema and perform CRUD operations on the table.
