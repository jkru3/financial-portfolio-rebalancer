import 'package:financial_portfolio/models/portfolio_entry.dart';
import 'package:financial_portfolio/providers/portfolio_provider.dart';
import 'package:financial_portfolio/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class EditView extends StatefulWidget {
  final PortfolioEntry entry;

  const EditView({super.key, required this.entry});

  @override
  State<EditView> createState() => _EditViewState();
}

class _EditViewState extends State<EditView> {
  late double investedCash;
  late double cashToAdd;

  @override
  void initState() {
    super.initState();
    investedCash = widget.entry.stock.valuations.first * widget.entry.numShares;
    cashToAdd = investedCash;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 35, 35, 35),
        title: Text(widget.entry.stock.name,  style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Liquidate stock',
            onPressed: () {
              _deletePopBack(context);
            },
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            cashToAdd = investedCash; // Revert the changes when the back button is pressed
            _popBack(context);
          }
        },
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Invested amount input field',
              hint: 'Enter the amount you have invested',
              textField: true,
              child: Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  initialValue: investedCash.toStringAsFixed(2),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Invested Amount',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 177, 134, 241)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value != null && !RegExp(r'^\d*\.?\d{0,2}$').hasMatch(value)) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 50,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 35, 35, 35),
            ),
            onPressed: () => _popBack(context),
            child: const Text(
              'Update Invested Amount',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  _popBack(BuildContext context) {
    double difference = cashToAdd - investedCash;
    if (difference.abs() >= 1.00) {
      double numShares = cashToAdd / widget.entry.stock.valuations.first;
      PortfolioEntry newPortfolioEntry = PortfolioEntry.updateInvestment(
          widget.entry, widget.entry.stock, numShares, difference);
      Provider.of<PortfolioProvider>(context, listen: false)
          .upsertPortfolioEntry(newPortfolioEntry);
    }
    Navigator.pop(context);
  }

  _deletePopBack(BuildContext context) {
    if (widget.entry.stock.type != StockType.none &&
        widget.entry.stock.name != 'US Dollars') {
      Provider.of<PortfolioProvider>(context, listen: false)
          .removePortfolioEntry(widget.entry);
      Navigator.pop(context);
    }
  }
}
