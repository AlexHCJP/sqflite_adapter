
import 'package:sqflite/sqflite.dart';


abstract class TableProvider<T> {
  late Database db;

  TableProvider();
  void _initialize(db) => this.db = db;
  Future<void> createTable();
  Future<void> insert(T model) async {}
  Future<void> update(T model) async {}
  Future<void> clear() async {}
}


class SQLService {
  late Database database;
  final List<TableProvider> tables;
  final String databaseName;
  final int version;

  SQLService({
    required this.tables,
    required this.databaseName,
    this.version = 1
  });



  Future<SQLService> initialize() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + databaseName;
    await openDatabase(path, version: version,
      onCreate: (Database db, int version) async {
        for (var table in tables) {
          table._initialize(db);
          await table.createTable();
        }
      },
      onOpen: (Database db) async {
        for (var table in tables) {
          table._initialize(db);
        }
      },
    );
    return this;
  }

  Future<void> insert<T>(T model) async {
    for (var table in tables) {
      if (table is TableProvider<T>) {
        await table.insert(model);
      }
    }
  }

  Future<void> update<T>(T model) async {
    for (var table in tables) {
      if (table is TableProvider<T>) {
        await table.update(model);
      }
    }
  }

  Future<void> clear<T>() async {
    for (var table in tables) {
      if (table is TableProvider<T>) {
        await table.clear();
      }
    }
  }

  T of<T extends TableProvider>() {
    for (var table in tables) {
      if (table is T) {
        return table;
      }
    }
    throw Exception('Table not found');
  }
}
