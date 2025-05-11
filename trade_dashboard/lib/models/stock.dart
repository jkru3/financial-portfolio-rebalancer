// This object is updated every time the app is initialized or refreshed. No need to store any state
import 'package:financial_portfolio/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'stock.g.dart';

@HiveType(typeId: 15)
class Stock {
  @HiveField(1)
  final String ticker;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final StockType type;
  @HiveField(4)
  final List<double> valuations;

  Stock(
      {this.ticker = 'NA',
      this.name = 'Not Available',
      this.type = StockType.none,
      this.valuations = const []});

  Stock.createCashStock(
      {this.ticker = '',
      this.name = 'US Dollars',
      this.type = StockType.none,
      this.valuations = const [1.0]});

  /// this occurs every time we are refreshing the valuations and projections (API calls, refresh, init, etc...)
  Stock.update(Stock entry, List<double> newValuations)
      : ticker = entry.ticker,
        name = entry.name,
        type = entry.type,
        valuations = newValuations;

  Stock clone() {
    return Stock(
      ticker: ticker,
      name: name,
      type: type,
      valuations: List<double>.from(valuations),
    );
  }

  // Calculate the EMA based projection returned as a percentage
  double getProjection() {
    if (valuations.isEmpty || valuations.first == 0) {
      return 0.0; // If no historical prices are available, return 0
    }

    int n = valuations.length;

    // Smoothing factor, typically, 2 / (N + 1) for an N-day EMA
    double alpha = 2.0 / (n + 1);

    // Calculate the initial EMA (which is the first price for simplicity)
    double ema = valuations[0];

    // Calculate the EMA for the rest of the data
    for (int i = 1; i < n; i++) {
      ema = alpha * valuations[i] + (1 - alpha) * ema;
    }

    // Calculate the percentage change
    return ((ema - valuations.first) / valuations.first) * 100;
  }

  Color getStockTypeColor() {
    return switch (type) {
      StockType.basicMaterials => Colors.brown[900]!,
      StockType.communicationServices => Colors.indigo[900]!,
      StockType.consumerDiscretionary => Colors.deepPurple[700]!,
      StockType.consumerStaples => Colors.green[900]!,
      StockType.energy => Colors.red[900]!,
      StockType.financial => Colors.yellow[800]!,
      StockType.healthcare => Colors.blue[900]!,
      StockType.industrials => Colors.grey[800]!,
      StockType.realEstate => Colors.deepOrange[900]!,
      StockType.technology => Colors.blueGrey[900]!,
      StockType.utilities => Colors.teal[900]!,
      StockType.none => Colors.black,
    };
  }

  String getStockTypeString() {
    return switch (type) {
      StockType.basicMaterials => "Basic Materials",
      StockType.communicationServices => "Communication Services",
      StockType.consumerDiscretionary => "Consumer Discretionary",
      StockType.consumerStaples => "Consumer Staples",
      StockType.energy => "Energy",
      StockType.financial => "Financial",
      StockType.healthcare => "Healthcare",
      StockType.industrials => "Industrials",
      StockType.realEstate => "Real Estate",
      StockType.technology => "Technology",
      StockType.utilities => "Utilities",
      StockType.none => "None",
    };
  }
}
