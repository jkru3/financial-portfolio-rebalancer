import 'dart:convert';

import 'package:financial_portfolio/models/portfolio_entry.dart';
import 'package:financial_portfolio/models/stock.dart';
import 'package:financial_portfolio/providers/portfolio_provider.dart';
import 'package:financial_portfolio/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:financial_portfolio/views/financial_portfolio_app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

late final Box<PortfolioEntry> storage;
Future<void> main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PortfolioEntryAdapter());
  Hive.registerAdapter(StockAdapter());
  Hive.registerAdapter(StockTypeAdapter());
  // storage = await Hive.openBox('storage');

  const secureStorage =
      FlutterSecureStorage(); // create an instance of secure storage class from libraryc
  // if key not exists return null
  try {
    // try to read, may give PlatformException if not available
    final encryptionKeyString =
        await secureStorage.read(key: 'key'); // check for an existing key
    if (encryptionKeyString == null) {
      // if key does not exist (previous line gave null)
      final key = Hive
          .generateSecureKey(); // create new secure key for encrypted content
      await secureStorage.write(
        key: 'key',
        value: base64UrlEncode(key),
      ); // write the encoded key (under name "key") to secure storage
    }
  } catch (_) {
    // create new key if we get an exception from trying to read
    final key =
        Hive.generateSecureKey(); // create new secure key for encrypted content
    await secureStorage.write(
      key: 'key',
      value: base64UrlEncode(key),
    ); // write the encoded key (under name "key") to secure storage
  }
  final key = await secureStorage.read(
      key: 'key'); // read the encoded key out of secure storage
  final encryptionKeyUint8List = base64Url.decode(
      key!); // decode the key to a more usable byte array to use as the encryption cipher
  print('Encryption key Uint8List: $encryptionKeyUint8List');
  storage = await Hive.openBox(
      'storage', // open hive box with the previous line's byte array used as the encrytion cipher
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
  runApp(
    ChangeNotifierProvider(
        create: (context) => PortfolioProvider(storage), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Portfolio',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 18, 18),
      ),
      home: const FinancialPortfolioApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}
