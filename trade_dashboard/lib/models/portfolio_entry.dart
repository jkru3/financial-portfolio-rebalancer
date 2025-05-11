import 'package:financial_portfolio/models/stock.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'portfolio_entry.g.dart';

@HiveType(typeId: 16)
class PortfolioEntry {
  @HiveField(1)
  Stock stock;
  @HiveField(2)
  final double numShares;
  @HiveField(3)
  final List<double> transactions;
  @HiveField(4)
  final List<DateTime> updatedAt;

  PortfolioEntry(
      {required this.updatedAt,
      required this.stock,
      required this.numShares,
      required this.transactions});

  /// Factory constructor for creating a new `PortfolioEntry` with the current timestamp
  /// AND an empty list of transactions
  PortfolioEntry.create()
      : updatedAt = [DateTime.now()],
        stock = Stock(),
        numShares = 0,
        transactions = [];

  PortfolioEntry.createCashEntry()
      : updatedAt = [DateTime.now()],
        stock = Stock.createCashStock(),
        numShares = 0,
        transactions = [];

  /// updates when a stock is chosen and user or updates their holdings
  PortfolioEntry.updateInvestment(PortfolioEntry entry, Stock newStock,
      double newNumShares, double newTransaction)
      : updatedAt = List.from(entry.updatedAt),
        stock = newStock,
        numShares = newNumShares,
        transactions = List.from(entry.transactions) {
    transactions.add(newTransaction);
    updatedAt.add(DateTime.now());
  }

  PortfolioEntry clone() {
    return PortfolioEntry(
      updatedAt: List<DateTime>.from(updatedAt),
      stock: stock.clone(), // Assuming Stock class has a clone method
      numShares: numShares,
      transactions: List<double>.from(transactions),
    );
  }

  double getAdjustedShares(double adjustment) {
    if (stock.valuations.first == 0) return 0; // Prevent division by zero
    return ((numShares * stock.valuations.first) + adjustment) /
        stock.valuations.first;
  }

  double getInvestedCash() => stock.valuations.first * numShares;

  double getAllTimeInvested() =>
      transactions.fold(0.0, (prev, curr) => prev + curr);

  double getReturns() => getInvestedCash() - getAllTimeInvested();
}
