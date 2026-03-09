import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class LocalDatabase {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  _initDb() async {
    String path = join(await getDatabasesPath(), 'wms_local.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabela para armazenar ações offline (coletas, inventário, etc)
        await db.execute('''
          CREATE TABLE offline_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT,
            dados TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<int> saveAction(String tipo, Map<String, dynamic> dados) async {
    final dbClient = await db;
    return await dbClient.insert('offline_actions', {
      'tipo': tipo,
      'dados': json.encode(dados),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final dbClient = await db;
    return await dbClient.query('offline_actions', orderBy: 'id ASC');
  }

  Future<void> deleteAction(int id) async {
    final dbClient = await db;
    await dbClient.delete('offline_actions', where: 'id = ?', whereArgs: [id]);
  }
}
