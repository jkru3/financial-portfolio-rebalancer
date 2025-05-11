import 'dart:async';

import 'package:financial_portfolio/models/portfolio.dart';
import 'package:financial_portfolio/models/portfolio_entry.dart';
import 'package:financial_portfolio/providers/portfolio_provider.dart';
import 'package:financial_portfolio/utils/enums.dart';
import 'package:financial_portfolio/views/add_view.dart';
import 'package:financial_portfolio/views/edit_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This is our HomeView
/// It is stateful so we can dynamically update cards at once!
class FinancialPortfolioApp extends StatefulWidget {
  const FinancialPortfolioApp({super.key});

  @override
  State<FinancialPortfolioApp> createState() => _FinancialPortfolioAppState();
}

class _FinancialPortfolioAppState extends State<FinancialPortfolioApp> {
  double _sliderValue = 0.0; // user selection, default 0

  @override
  initState() {
    super.initState();
    final singleUsePortfolioProvider =
        Provider.of<PortfolioProvider>(context, listen: false);
    singleUsePortfolioProvider.initializePortfolio();
    singleUsePortfolioProvider.updateStockData();
  }

  /// Cleans up the resources used by this object. This method is called when this State object will never build again.
  @override
  dispose() {
    super.dispose();
  }

  /// The `_navigateToNewEntry` method navigates to the `EntryView` for a given journal entry.
  /// It also updates the journal entry in the `JournalProvider` when the `EntryView` is popped.
  /// Parameters:
  ///  - entry: the journal entry we are rendering
  ///  - existingEntry: if true, we will go into EditView, if false, --AddView
  Future<void> _navigateToEntry(
      BuildContext context, PortfolioEntry entry, bool existingEntry) async {
    if (existingEntry) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditView(
                  entry:
                      entry))); // we call EditView if the entry already exists
    } else {
      await Navigator.push(context,
          MaterialPageRoute(builder: (context) => AddView(entry: entry)));
    }
    if (!context.mounted) return;

    PortfolioProvider portfolioProvider =
        Provider.of<PortfolioProvider>(context, listen: false);
    // we need to reinitialize the calculations with the new/updated entry
    await portfolioProvider.initializePortfolio();
  }

  /// this will create an individual card
  Widget _createListElementForEntry(BuildContext context,
      PortfolioEntry existingEntry, double adjustment, Portfolio portfolio) {
    Color textColor = Colors.white;
    Color positiveColor = Colors.lightGreenAccent[700]!;
    Color negativeColor = Colors.redAccent[200]!;

    TextStyle headingStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: textColor,
    );
    TextStyle bodyStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 16,
      color: textColor.withOpacity(0.9),
    );

    String money(double value) => '\$${value.toStringAsFixed(2)}';

    bool isUSDollars = existingEntry.stock.type == StockType.none &&
        existingEntry.stock.name == 'US Dollars';

    double projection = existingEntry.stock.getProjection();
    TextStyle projectionStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
      color: projection >= 0 ? positiveColor : negativeColor,
    );

    return ListTile(
      title: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 50, 50, 50),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUSDollars
                  ? existingEntry.stock.name
                  : '${existingEntry.stock.name} (${existingEntry.stock.getStockTypeString()})',
              style: headingStyle,
            ),
            const SizedBox(height: 4),
            Text('Invested Cash: ${money(existingEntry.getInvestedCash())}',
                style: bodyStyle),
            if (!isUSDollars)
              Text('All Time Returns: ${money(existingEntry.getReturns())}',
                  style: bodyStyle),
            if (!isUSDollars)
              Text(
                'Projected returns: ${projection.abs() == 0 ? '' : (projection > 0 ? '+' : '-')}${projection.abs().toStringAsFixed(2)}%',
                style: projectionStyle,
              ),
            const SizedBox(height: 4),
            Text(
              'Suggested Adjustment: ${adjustment.abs() < 0.009 ? '' : (adjustment > 0 ? '+' : '-')}${money(adjustment.abs())}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: adjustment.abs() < 0.009
                    ? textColor
                    : adjustment > 0
                        ? positiveColor
                        : negativeColor,
              ),
            ),
          ],
        ),
      ),
      // _navigateToEntry calls 'true' to go into EditView
      onTap: () => _navigateToEntry(context, existingEntry, true),
    );
  }

  /// This method is called when the user changes the slider value
  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        if (!portfolioProvider.portfolioIsInitialized) {
          return const CircularProgressIndicator();
        }
        Portfolio portfolio = portfolioProvider.portfolio;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            backgroundColor: const Color.fromARGB(255, 35, 35, 35),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                /// THIS IS HOW WE CAN SEE OUR RETURNS CHANGE
                /// 'Refresh' updates the projection of the stock on the fly
                /// the ONLY other time we refresh our projections is on startup
                label: 'Refresh stock data',
                button: true,
                enabled: true,
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () async {
                    await portfolioProvider.updateStockData();
                    setState(() {});
                  },
                  tooltip: 'Refresh Data',
                ),
              ),
            ),
            title: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 7, // space between the children horizontally
              runSpacing: 4, // space between the lines vertically
              children: [
                Image.asset('assets/i-money-logo.png', height: 40),
                const Text('iMoney Financial Portfolio',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Image.asset('assets/i-money-logo.png', height: 40),
              ],
            ),
            centerTitle: true,
            actions: <Widget>[
              Semantics(
                label: 'Add new stock',
                button: true,
                enabled: true,
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    PortfolioEntry newEntry = PortfolioEntry.create();
                    _navigateToEntry(context, newEntry, false);
                  },
                  tooltip: 'Add New Stock',
                ),
              ),
            ],
          ),
          body: Column(children: [
            Container(
              color: const Color.fromARGB(255, 35, 35, 35),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Total Invested: \$${portfolioProvider.portfolio.totalCapital.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  Text(
                      'Total Returns: \$${portfolioProvider.portfolio.totalReturns.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            /// This gets the adjusted value dynamically, and then sends it to _createListElementForEntry
            /// So we can add stuff display it in the UI cards for each stock!
            Expanded(
              child: ListView.builder(
                itemCount: portfolioProvider.entries.length,
                itemBuilder: (context, index) {
                  final entry = portfolioProvider.entries[index];
                  double adjustment = portfolio.getAdjustedInvestment(
                      entry.stock.getProjection(),
                      entry.stock.valuations.first * entry.numShares,
                      _sliderValue);
                  return _createListElementForEntry(
                      context, entry, adjustment, portfolio);
                },
              ),
            ),
          ]),
          bottomNavigationBar: Container(
            color: const Color.fromARGB(255, 30, 30, 30),
            padding: const EdgeInsets.all(0.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                'Current adjustment amount: ${_sliderValue}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
              // This is the Adjustment slider, which lets us dynamically change our adjustments
              Slider(
                value: _sliderValue,
                min: 0,
                max: 1,
                divisions: 100,
                label: _sliderValue.toStringAsFixed(2),
                onChanged: _onSliderChanged,
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 10), // Adjust this value to move the buttons down
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: portfolioProvider.canUndo()
                            ? () => portfolioProvider.undo()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 50, 50, 50),
                          foregroundColor: Colors.white,
                        ),
                        // Undo button
                        child: Text('Undo',
                            style: TextStyle(
                                color: portfolioProvider.canUndo()
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _sliderValue == 0
                            ? null
                            : () {
                                setState(() {
                                  double totalAdjustment = 0;
                                  for (PortfolioEntry entry
                                      in portfolioProvider.entries) {
                                    // We once again need to calculate the adjustment
                                    double adjustment =
                                        portfolio.getAdjustedInvestment(
                                            entry.stock.getProjection(),
                                            entry.stock.valuations.first *
                                                entry.numShares,
                                            _sliderValue);
                                    totalAdjustment += adjustment;
                                    // We ALSO need to know what the new number of shares is
                                    // since we are storing the number of shares and multiplying it by current the valuation
                                    // to get the actual value
                                    double newShares =
                                        entry.getAdjustedShares(adjustment);
                                    PortfolioEntry newEntry =
                                        PortfolioEntry.updateInvestment(entry,
                                            entry.stock, newShares, adjustment);
                                    portfolioProvider
                                        .upsertPortfolioEntry(newEntry);
                                  }
                                  _sliderValue =
                                      0.0; // Reset the slider value after every commit
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 50, 50, 50),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text('Commit Adjustments',
                            style: TextStyle(
                                color: _sliderValue > 0
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: portfolioProvider.canRedo()
                            ? () => portfolioProvider.redo()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 50, 50, 50),
                          foregroundColor: Colors.white,
                        ),
                        // Redo button
                        child: Text('Redo',
                            style: TextStyle(
                                color: portfolioProvider.canRedo()
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              )
            ]),
          ),
        );
      },
    );
  }
}
