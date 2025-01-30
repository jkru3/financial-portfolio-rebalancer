import 'package:hive_flutter/hive_flutter.dart';

part 'enums.g.dart';

// TODO: something for a future implementation...
@HiveType(typeId: 14)
enum StockType {
  @HiveField(1)
  none, // this one is a special 'stock type'. it is un-deletable.
  @HiveField(2)
  basicMaterials,
  @HiveField(3)
  communicationServices,
  @HiveField(4)
  consumerDiscretionary,
  @HiveField(5)
  consumerStaples,
  @HiveField(6)
  energy,
  @HiveField(7)
  financial,
  @HiveField(8)
  healthcare,
  @HiveField(9)
  industrials,
  @HiveField(10)
  realEstate,
  @HiveField(11)
  technology,
  @HiveField(12)
  utilities,
}

// this is a simple means of storing some legitimate stock information
// however in the future it would be better to store this in a more appropriate file type (csv)
enum StockTicker {
  BHB('Bar Harbor Bankshares', StockType.basicMaterials),
  GOOG('Alphabet Inc.', StockType.communicationServices),
  AMZN('Amazon.com Inc.', StockType.consumerDiscretionary),
  PG('Procter & Gamble Co.', StockType.consumerStaples),
  FSLR('First Solar, Inc.', StockType.energy),
  JPM('JPMorgan Chase & Co.', StockType.financial),
  JNJ('Johnson & Johnson', StockType.healthcare),
  GE('General Electric Company', StockType.industrials),
  AMT('American Tower Corporation', StockType.realEstate),
  AAPL('Apple Inc.', StockType.technology),
  DUK('Duke Energy Corporation', StockType.utilities);

  final String name;
  final StockType stockType;

  const StockTicker(this.name, this.stockType);
}

// This removes the 'StockTicker.' enum prefix so we are left with a string representation of the ticker
extension StockTickerExtension on StockTicker {
  String get ticker {
    return toString().split('.').last;
  }
}
