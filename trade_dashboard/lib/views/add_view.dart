import 'package:financial_portfolio/models/portfolio_entry.dart';
import 'package:financial_portfolio/models/stock.dart';
import 'package:financial_portfolio/providers/portfolio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddView extends StatefulWidget {
  final PortfolioEntry entry;

  const AddView({super.key, required this.entry});

  @override
  State<AddView> createState() => _AddViewState();
}

class _AddViewState extends State<AddView> {
  late Stock? stock;
  late double numShares;
  late double cashToAdd;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    stock = null;
    numShares = 0.0;
    cashToAdd = 0.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _popBack(BuildContext context) {
    if (stock != null) {
      double numShares = cashToAdd / stock!.valuations.first;
      PortfolioEntry newPortfolioEntry = PortfolioEntry.updateInvestment(
          widget.entry, stock!, numShares, cashToAdd);
      Provider.of<PortfolioProvider>(context, listen: false)
          .upsertPortfolioEntry(newPortfolioEntry);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 35, 35, 35),
        title: const Text('Add Stock', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _popBack(context),
          ),
        ],
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) {
          // Do nothing when back button is pressed
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Semantics(
            label: 'Stock selection dropdown',
            hint: 'Double tap to expand dropdown and select a stock',
            child: Container(
              margin: const EdgeInsets.only(top: 2.0, left: 2.0, right: 2.0, bottom: 20.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 35, 35, 35),
                borderRadius: BorderRadius.circular(2.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Stock>(
                  isExpanded: true,
                  value: stock,
                  iconSize: 24,
                  iconEnabledColor: Colors.white,
                  dropdownColor: const Color.fromARGB(255, 35, 35, 35),
                  style: const TextStyle(color: Colors.white), // Add this line
                  onChanged: (Stock? value) {
                    setState(() {
                      stock = value;
                    });
                  },
                  hint: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('Select a stock', style: TextStyle(color: Colors.white)),
                  ),
                  items: [
                      ...Provider.of<PortfolioProvider>(context, listen: false)
                          .tickerOptions
                          .values
                          .where((Stock stock) {
                        // first check if the stock is not already in the portfolio
                        // we only want to show stocks we haven't picked yet
                        return !Provider.of<PortfolioProvider>(context,
                                listen: false)
                            .entries
                            .any((entry) => entry.stock.ticker == stock.ticker);
                      }).map((Stock stock) {
                        return DropdownMenuItem<Stock>(
                          value: stock,
                          child: Text(
                              '${stock.name}; Projected change: ${stock.getProjection().toStringAsFixed(2)}%'),
                        );
                      }).toList()
                        ..sort((a, b) => (b.value?.getProjection() ?? 0.0)
                            .compareTo(a.value?.getProjection() ?? 0.0)),
                    ],
                ),
              ),
            ),
          ),
          Semantics(
            label: 'Investment amount input field',
            hint: 'Enter the amount you wish to invest',
            textField: true,
            child: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Investment Amount (optional)',
                  labelStyle: TextStyle(color: Colors.white),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 177, 134, 241)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    if (RegExp(r'^\d*\.?\d{0,2}$').hasMatch(value)) {
                      cashToAdd = double.parse(value);
                    } else {
                      cashToAdd = 0.0;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    ),
  ),
    );
  }
}