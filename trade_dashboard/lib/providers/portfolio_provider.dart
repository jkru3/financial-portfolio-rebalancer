import 'package:financial_portfolio/models/portfolio.dart';
import 'package:financial_portfolio/models/portfolio_entry.dart';
import 'package:financial_portfolio/models/stock.dart';
import 'package:financial_portfolio/utils/stock_checker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PortfolioProvider extends ChangeNotifier {
  final Portfolio _portfolio;
  final List<Portfolio> _pastActions;
  final List<Portfolio> _futureActions;
  bool portfolioIsInitialized = false;
  Map<String, Stock> tickerOptions = {};

  PortfolioProvider(Box<PortfolioEntry> storage)
      : _portfolio = Portfolio(storage),
        _pastActions = [],
        _futureActions = [];

  Future<void> initializePortfolio() async {
    await _portfolio.initialize();
    portfolioIsInitialized = true;
    _pastActions.add(_portfolio.clone());
    notifyListeners();
  }

  Portfolio get portfolio => _portfolio;

  List<PortfolioEntry> get entries => _portfolio.entries;

  void upsertPortfolioEntry(PortfolioEntry entry) {
    _portfolio.upsertEntry(entry);
    if (entry.stock.name != 'US Dollars') {
      _pastActions.add(_portfolio.clone());
      _futureActions.clear();
    }
    notifyListeners();
  }

  Future<void> updateStockData() async {
    // NOTE: this can be changed to fetchStockData(); to call from API
    // however, there is a limit to only 25 calls per day!
    await StockChecker(this).testFetchStockData();
    _pastActions.clear();
    _futureActions.clear();
    notifyListeners();
  }

  void populateAndUpdateStocks(Map<String, Stock> stocks) {
    tickerOptions = stocks;

    for (var portfolioEntry in _portfolio.entries) {
      if (tickerOptions.entries.any(
          (mapEntry) => mapEntry.value.ticker == portfolioEntry.stock.ticker)) {
        portfolioEntry.stock = tickerOptions[portfolioEntry.stock.ticker]!;
      }
    }

    // Schedule the notification to occur after the current build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pastActions.clear();
      _futureActions.clear();
      notifyListeners();
    });
  }

  void removePortfolioEntry(PortfolioEntry entry) {
    _portfolio.removeEntry(entry);
    _pastActions.add(_portfolio.clone());
    _futureActions.clear();
    notifyListeners();
  }

  // We pop off a _pastActions
  // And add it to _futureActions
  // then notify
  undo() {
    if (canUndo()) {
      _futureActions.add(_pastActions.removeLast());
      _portfolio.copyFrom(_pastActions.last);
      notifyListeners();
    }
  }

  // We pop off a _futureActions
  // and add it to the _pastActions
  // then notify
  redo() {
    if (_futureActions.isNotEmpty) {
      _pastActions.add(_futureActions.removeLast());
      _portfolio.copyFrom(_pastActions.last);
      notifyListeners();
    }
  }

  clearAdjustments() {
    _futureActions.clear();
    _pastActions.clear();
    notifyListeners();
  }

  // Checks if there are any actions to undo.
  // Returns true if the list of past actions is not empty.
  bool canUndo() => _pastActions.isNotEmpty;

  // Checks if there are any actions to redo.
  // Returns true if the list of future actions is not empty.
  bool canRedo() => _futureActions.isNotEmpty;
}
