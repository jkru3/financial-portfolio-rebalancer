import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:financial_portfolio/models/stock.dart';
import 'package:financial_portfolio/providers/portfolio_provider.dart';
import 'package:financial_portfolio/utils/enums.dart';
import 'package:http/http.dart' as http;

class StockChecker {
  final PortfolioProvider portfolioProvider;

  StockChecker(this.portfolioProvider);

  /// Don't delete this, we will use for testing!
  Future<void> testFetchStockData() async {
    Map<String, Stock> stocks = {};
    print('updating stock data with test values...');

    for (var stockTicker in StockTicker.values) {
      List<double> valuations = _generateSimilarValuations();

      stocks[stockTicker.ticker] = Stock(
        ticker: stockTicker.ticker,
        name: stockTicker.name,
        type: stockTicker.stockType,
        valuations: valuations,
      );
    }

    portfolioProvider.populateAndUpdateStocks(stocks);
  }

  // Another test method. We'll rely on this if the API call fails
  List<double> _generateSimilarValuations() {
    Random random = Random();
    double baseValue =
        random.nextDouble() * 1000; // Base random value between 0 and 1000
    List<double> valuations = [];

    for (int i = 0; i < 10; i++) {
      // Generate a variation up to ±50 around the base value
      double variation =
          (random.nextDouble() * 100) - 50; // Variation between -50 and +50
      double newValue = baseValue + variation;
      // Ensure the new value stays within the 0 to 1000 range
      newValue = newValue.clamp(0.0, 1000.0);
      valuations.add(newValue);
    }
    return valuations;
  }

  List<double> _extractClosingValues(Map<String, dynamic> jsonData) {
    Map<String, dynamic> timeSeries = jsonData['Time Series (Daily)'];
    List<double> closingValues = [];

    timeSeries.forEach((date, values) {
      double close = double.parse(values['4. close']);
      closingValues.add(close);
    });
    return closingValues;
  }

  Future<void> fetchStockData() async {
    var client = http.Client();
    Map<String, Stock> updatedStocks = SplayTreeMap();
    try {
      // for every stock in the stocks
      for (StockTicker stockTicker in StockTicker.values) {
        // create a new stock to push onto the list of updated stocks
        final gridResponse = await client.get(Uri.parse(
            'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=${stockTicker.ticker}&apikey=SLKVJHW3KRDT5X3J'));
        final gridParsed = (jsonDecode(gridResponse.body));
        final List<double> closingPrices = _extractClosingValues(gridParsed);
        Stock updatedStock = Stock(
          ticker: stockTicker.ticker,
          name: stockTicker.name,
          valuations: closingPrices,
        );
        updatedStocks.update(
            updatedStock.name,
            (_) =>
                updatedStock, // Provide a function that returns the updated stock
            ifAbsent: () =>
                updatedStock // This handles the case where the stock isn't already in the map
            );
      }
    } catch (err) {
      print(
          'API ran out of tokens. Switching to mock valuations. See error -> $err');
      for (StockTicker stockTicker in StockTicker.values) {
        Stock updatedStock = Stock(
            ticker: stockTicker.ticker,
            name: stockTicker.name,
            valuations: _generateSimilarValuations());
        updatedStocks.update(
            updatedStock.name,
            (_) =>
                updatedStock, // Provide a function that returns the updated stock
            ifAbsent: () =>
                updatedStock // This handles the case where the stock isn't already in the map
            );
      }
    } finally {
      client.close();
    }
    portfolioProvider.populateAndUpdateStocks(updatedStocks);
  }
}
