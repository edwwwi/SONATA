import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const String _dbName = 'icecream_shop.db';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    
    final appDocDir = await getApplicationSupportDirectory();
    final dbPath = join(appDocDir.path, filePath);
    
    // Create images folder alongside the database
    final imagesDir = Directory(join(appDocDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    // Automatic Daily Backup before opening the database
    await _performDailyBackup(appDocDir, dbPath);

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: _createDB,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE products ADD COLUMN color INTEGER');
          }
          if (oldVersion < 3) {
            await db.execute('DROP TABLE IF EXISTS stock_movements');
            await db.execute('''
              CREATE TABLE stock_movements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                product_name TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                previous_stock INTEGER NOT NULL,
                current_stock INTEGER NOT NULL,
                movement_type TEXT NOT NULL,
                remarks TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
              )
            ''');
          }
          if (oldVersion < 4) {
            await db.execute('ALTER TABLE products ADD COLUMN minimum_stock INTEGER NOT NULL DEFAULT 10');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_bill_number ON sales(bill_number)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items(product_id)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON stock_movements(product_id)');
          }
          if (oldVersion < 5) {
            await db.execute('ALTER TABLE settings ADD COLUMN telegram_enabled INTEGER NOT NULL DEFAULT 0');
            await db.execute('ALTER TABLE settings ADD COLUMN telegram_bot_token TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN telegram_chat_id TEXT');
          }
          if (oldVersion < 6) {
            await db.execute('ALTER TABLE settings ADD COLUMN email_enabled INTEGER NOT NULL DEFAULT 0');
            await db.execute('ALTER TABLE settings ADD COLUMN smtp_server TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN smtp_port TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN sender_email TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN sender_password_encrypted TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN recipient_email TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN report_time TEXT');
          }
          if (oldVersion < 7) {
            await db.execute('ALTER TABLE products ADD COLUMN company TEXT NOT NULL DEFAULT "Other"');
            await db.execute('ALTER TABLE products ADD COLUMN type TEXT NOT NULL DEFAULT "Ice Cream"');
          }
        },
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        category TEXT NOT NULL,
        company TEXT NOT NULL DEFAULT 'Other',
        type TEXT NOT NULL DEFAULT 'Ice Cream',
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        color INTEGER,
        minimum_stock INTEGER NOT NULL DEFAULT 10
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT NOT NULL,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previous_stock INTEGER NOT NULL,
        current_stock INTEGER NOT NULL,
        movement_type TEXT NOT NULL,
        remarks TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_pin TEXT NOT NULL,
        telegram_enabled INTEGER NOT NULL DEFAULT 0,
        telegram_bot_token TEXT,
        telegram_chat_id TEXT,
        email_enabled INTEGER NOT NULL DEFAULT 0,
        smtp_server TEXT,
        smtp_port TEXT,
        sender_email TEXT,
        sender_password_encrypted TEXT,
        recipient_email TEXT,
        report_time TEXT
      )
    ''');

    // Insert default PIN
    await db.execute('''
      INSERT INTO settings (owner_pin) VALUES ('1978')
    ''');

    // Create Analytics Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_bill_number ON sales(bill_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items(product_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON stock_movements(product_id)');
  }

  Future<void> _performDailyBackup(Directory appDocDir, String dbPath) async {
    try {
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) return; // Nothing to backup

      final backupDir = Directory(join(appDocDir.path, 'backup'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final dailyBackupPath = join(backupDir.path, 'POS_Backup_$dateStr.db');
      final dailyBackupFile = File(dailyBackupPath);

      if (!await dailyBackupFile.exists()) {
        await dbFile.copy(dailyBackupPath);
        
        // Trim backups to keep only the latest 30
        final List<FileSystemEntity> backups = backupDir.listSync()
            ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)); // newest first

        if (backups.length > 30) {
          for (var i = 30; i < backups.length; i++) {
            await backups[i].delete();
          }
        }
      }
    } catch (e) {
      print('Daily backup failed: $e');
    }
  }

  Future<bool> backupDatabase(String destinationFolder) async {
    try {
      final appDocDir = await getApplicationSupportDirectory();
      final dbPath = join(appDocDir.path, _dbName);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) return false;

      final dateStr = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
      final backupFileName = 'POS_Backup_$dateStr.db';
      final backupFilePath = join(destinationFolder, backupFileName);

      await dbFile.copy(backupFilePath);
      return true;
    } catch (e) {
      print('Backup failed: $e');
      return false;
    }
  }

  Future<bool> restoreDatabase(String sourceFilePath) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) return false;

      // Close current DB connection if open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final appDocDir = await getApplicationSupportDirectory();
      final dbPath = join(appDocDir.path, _dbName);
      final dbFile = File(dbPath);

      await sourceFile.copy(dbPath);
      return true;
    } catch (e) {
      print('Restore failed: $e');
      return false;
    }
  }
}
