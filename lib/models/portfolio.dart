import 'package:financial_portfolio/models/portfolio_entry.dart';
import 'package:financial_portfolio/utils/enums.dart';
import 'package:hive_flutter/hive_flutter.dart';

// contains a portfolio class for the entire application
class Portfolio {
  final List<PortfolioEntry> _entries;
  final Box<PortfolioEntry> _storage;

  late double minChange;
  late double totalChange;
  late double totalCapital;
  late double totalReturns;

  // TODO: implement Hive
  // Portfolio() : _entries = [PortfolioEntry.createCashEntry()];

  Portfolio(this._storage) : _entries = _storage.values.toList() {
    if (!_entries.any((entry) =>
        entry.stock.type == StockType.none &&
        entry.stock.name == 'US Dollars')) {
      _entries.insert(0, PortfolioEntry.createCashEntry());
    }
  }

  /// initializes new `Portfolio` with specified entries
  /// TODO: implement Hive
  Portfolio.withEntries(List<PortfolioEntry> entries, this._storage)
      : _entries = List<PortfolioEntry>.from(entries) {
    if (!_entries.any((entry) =>
        entry.stock.type == StockType.none &&
        entry.stock.name == 'US Dollars')) {
      _entries.insert(0, PortfolioEntry.createCashEntry());
    }
  }

  /// Getter `entries` returns a copy of the `_entries` list.
  List<PortfolioEntry> get entries => List<PortfolioEntry>.from(_entries);

  Future<void> upsertEntry(PortfolioEntry entry) async {
    try {
      final index =
          _entries.indexWhere((e) => e.stock.ticker == entry.stock.ticker);
      if (index == -1) {
        _entries.add(entry);
      } else {
        _entries[index] = entry;
      }
      await _storage.put(entry.stock.ticker, entry);
      if (_storage.isEmpty) {
        print("storage empty!");
      }
    } catch (e) {
      print('Error in upsertEntry: $e');
    }
  }

  // Removes an entry with ticker matching given PortfolioEntry (if found).
  void removeEntry(PortfolioEntry entry) {
    final index =
        _entries.indexWhere((e) => e.stock.ticker == entry.stock.ticker);
    if (index != -1) {
      _entries.removeAt(index);
    }
    _storage.delete(entry.stock.ticker);
  }

  Portfolio clone() => Portfolio.withEntries(_entries, _storage);

  Future<void> initialize() async {
    if (_entries.isEmpty) {
      minChange = 0.0;
      totalChange = 0.0;
      totalCapital = 0.0;
      totalReturns = 0.0;
    } else {
      minChange = _entries
          .map((entry) => entry.stock.getProjection())
          .reduce((a, b) => a < b ? a : b);
      totalChange = _entries.fold(0.0,
          (prev, entry) => prev + (entry.stock.getProjection() - minChange));
      totalCapital = _entries.fold(
          0.0,
          (prev, entry) =>
              prev + (entry.numShares * entry.stock.valuations.first));
      totalReturns = totalCapital -
          _entries.fold(
              0.0,
              (prev, entry) =>
                  prev +
                  entry.transactions.fold(
                      0.0, (prevTrans, currTrans) => prevTrans + currTrans));
    }
  }

  /// Calculates how much value should be adjusted from the current investment valuation
  /// User must have more than $5.00 to make an adjustment
  /// Parameters:
  ///  - projectedChange: a percentage
  ///  - investedCapital: the total capital currently invested
  ///  - alpha: a higher value means projectedChange will have a greater impact on the adjusted value
  /// Returns: 0 if there isn't enough entries to make adjustments, suggested adjustment otherwise
  double getAdjustedInvestment(
      double projectedChange, double investedCapital, double alpha) {
    if (totalCapital < 5.00 || _entries.length < 2) {
      return 0;
    } else {
      return (alpha * ((projectedChange - minChange) / totalChange) +
                  (1 - alpha) * (investedCapital / totalCapital)) *
              totalCapital -
          investedCapital;
    }
  }

  void copyFrom(Portfolio other) {
    _entries
      ..clear()
      ..addAll(other._entries.map((entry) => entry.clone()).toList());
    initialize();
  }
}
