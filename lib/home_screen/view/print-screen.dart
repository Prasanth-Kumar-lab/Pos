/*
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

import '../model/product_model.dart'; // For date formatting

class PrintScreen extends StatefulWidget {
  final List<Product> selectedProducts;
  final double totalAmount;

  const PrintScreen({
    Key? key,
    required this.selectedProducts,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  ReceiptController? controllerl;
  var _selectedPrinter; // Holds the selected printer device

  Future<void> _generateAndPrintPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) => pw.Center(
          child: pw.Text(
            'Hello World',
            style: pw.TextStyle(
              fontSize: 40,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Select Bluetooth Printer
  Future<void> _selectBluetoothDevice() async {
    final selected = await FlutterBluetoothPrinter.selectDevice(context);
    if (selected != null) {
      setState(() {
        _selectedPrinter = selected;
      });
      log("Selected device: ${_selectedPrinter.name}");
    } else {
      log("Device selection canceled.");
    }
  }

  /// Print to Selected Device
  Future<void> _printReceipt() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a printer first')),
      );
      return;
    }

    try {
      await controllerl?.print(
        address: _selectedPrinter.address,
        keepConnected: true,
        addFeeds: 4,
      );
    } catch (e) {
      log('Printing failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Receipt'),
      ),
      body: Column(
        children: [
          // DISPLAY SELECTED PRINTER ABOVE RECEIPT (not printed)
          if (_selectedPrinter != null)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Lottie animation (printer, loading, etc.)
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: Lottie.asset(
                      'assets/active.json', // Replace with your actual asset path
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10), // spacing between animation and text
                  Expanded(
                    child: Text(
                      'Selected Printer: ${_selectedPrinter.name ?? _selectedPrinter.address}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // RECEIPT - ONLY THIS PART IS PRINTED
          Expanded(
            child: Receipt(
              builder: (context) {
                // Dynamic date and time
                var now = DateTime.now();
                var formatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
                String formattedDate = formatter.format(now);

                // Calculate discount (10% as in reference, rounded up to match example)
                double discountAmt = (widget.totalAmount * 0.1).ceilToDouble();
                double grandAmt = widget.totalAmount - discountAmt;

                // Hardcode given amount and calculate return to roughly match reference style
                // (In a real app, add input for given amount; here fixed for constant parts)
                double givenAmount = 700.00;
                double returnAmount = givenAmount - grandAmt;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'SUVIDHA SUPER MART',
                        style: GoogleFonts.merriweather(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 3,),
                    Center(child: Text('KHAMMAM',
                      style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),)),
                    SizedBox(height: 5,),
                    Center(child: Text('CONTACT : 9402512345', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),)),
                    SizedBox(height: 5,),
                    Center(child: Text('GSTIN : 1234567800',style: TextStyle( fontSize: 14),)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('INVOICE ID : 187', style: TextStyle( fontSize: 14),), // Constant as in reference
                        Text('SOURCESSS', style: TextStyle( fontSize: 14),),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('DATE: $formattedDate', style: TextStyle( fontSize: 14),),
                    SizedBox(height: 6),
                    Text('CUSTOMER NAME : TESTW', style: TextStyle( fontSize: 14),),
                    SizedBox(height: 6),
                    Text('MOBILE : 9030650065', style: TextStyle( fontSize: 14),), // Constant
                    SizedBox(height: 10),
                    // Table header
                    Row(
                      children: [
                        Expanded(flex: 1, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                        Expanded(flex: 5, child: Text('ITEMS', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                        Expanded(flex: 4, child: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                        Expanded(flex: 2, child: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                        Expanded(flex: 3, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                      ],
                    ),
                    Divider(color: Colors.black,),
                    // Dynamic items
                    ...widget.selectedProducts.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Product product = entry.value;
                      double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                      return Row(
                        children: [
                          Expanded(flex: 1, child: Text('${idx + 1}', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                          Expanded(flex: 5, child: Text(product.itemName ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                          Expanded(flex: 4, child: Text('${(product.sellingPrice ?? 0).toStringAsFixed(2)}(1Kg)', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                          Expanded(flex: 2, child: Text('${product.quantity}Kg', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                          Expanded(flex: 3, child: Text(itemTotal.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                        ],
                      );
                    }),
                    Divider(color: Colors.black,),
                    SizedBox(height: 10),
                    Text('Total:', style: TextStyle(fontSize: 16),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('General Items:', style: TextStyle(fontSize: 14),),
                        Text('${widget.selectedProducts.length}', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),),
                        Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),),
                        Text(widget.totalAmount.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),),
                      ],
                    ),
                    SizedBox(height: 0),
                    Divider(color: Colors.black,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DISCOUNT (10%):', style: TextStyle(fontSize: 14),),
                        Text(discountAmt.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),),
                      ],
                    ),
                    Divider(color: Colors.black,),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                        Text(grandAmt.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Given Amount:', style: TextStyle(fontSize: 14),),
                        Text(givenAmount.toStringAsFixed(2), style: TextStyle(fontSize: 14),),
                      ],
                    ),
                    SizedBox(height: 5,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RETURN Amount:', style: TextStyle(fontSize: 14),),
                        Text(returnAmount.toStringAsFixed(2), style: TextStyle(fontSize: 14),),
                      ],
                    ),
                    SizedBox(height: 10),
                    Center(child: Text('Thank You.. Visit Again..!', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),)),
                    SizedBox(height: 5),
                    Center(child: Text('SUVIDHA SUPER MART', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),)),
                  ],
                );
              },
              onInitialized: (controller) {
                controllerl = controller;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _selectBluetoothDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text("Select Device", style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _printReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text("Print", style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/product_model.dart'; // For date formatting

class PrintScreen extends StatefulWidget {
  final List<Product> selectedProducts;
  final double totalAmount;

  const PrintScreen({
    Key? key,
    required this.selectedProducts,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  ReceiptController? controllerl;
  dynamic _selectedPrinter; // Holds the selected printer device

  @override
  void initState() {
    super.initState();
    // Load the previously selected printer from SharedPreferences
    _loadSelectedPrinter();
  }

  /// Load the selected printer from SharedPreferences
  Future<void> _loadSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('selected_printer_address');
    final name = prefs.getString('selected_printer_name');

    if (address != null) {
      setState(() {
        // Reconstruct a minimal printer object with address and name
        _selectedPrinter = _Printer(address: address, name: name);
      });
      log("Loaded saved printer: ${name ?? address}");
    }
  }

  /// Save the selected printer to SharedPreferences
  Future<void> _saveSelectedPrinter(dynamic printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_printer_address', printer.address);
    await prefs.setString('selected_printer_name', printer.name ?? '');
    log("Saved printer: ${printer.name ?? printer.address}");
  }

  Future<void> _generateAndPrintPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) => pw.Center(
          child: pw.Text(
            'Hello World',
            style: pw.TextStyle(
              fontSize: 40,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Select Bluetooth Printer
  Future<void> _selectBluetoothDevice() async {
    final selected = await FlutterBluetoothPrinter.selectDevice(context);
    if (selected != null) {
      setState(() {
        _selectedPrinter = selected;
      });
      await _saveSelectedPrinter(selected); // Save the selected printer
      log("Selected device: ${_selectedPrinter.name}");
    } else {
      log("Device selection canceled.");
    }
  }

  /// Print to Selected Device
  Future<void> _printReceipt() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a printer first')),
      );
      return;
    }

    try {
      await controllerl?.print(
        address: _selectedPrinter.address,
        keepConnected: true,
        addFeeds: 4,
      );
    } catch (e) {
      log('Printing failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Receipt'),
      ),
      body: Column(
        children: [
          // DISPLAY SELECTED PRINTER ABOVE RECEIPT (not printed)
          if (_selectedPrinter != null)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Lottie animation (printer, loading, etc.)
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: Lottie.asset(
                      'assets/active.json', // Replace with your actual asset path
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10), // spacing between animation and text
                  Expanded(
                    child: Text(
                      'Selected Printer: ${_selectedPrinter.name ?? _selectedPrinter.address}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // RECEIPT - ONLY THIS PART IS PRINTED
          Expanded(
            child: Receipt(
              builder: (context) {
                // Dynamic date and time
                var now = DateTime.now();
                var formatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
                String formattedDate = formatter.format(now);

                // Calculate discount (10% as in reference, rounded up to match example)
                double discountAmt = (widget.totalAmount * 0.1).ceilToDouble();
                double grandAmt = widget.totalAmount - discountAmt;

                // Hardcode given amount and calculate return to roughly match reference style
                double givenAmount = 700.00;
                double returnAmount = givenAmount - grandAmt;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'SUVIDHA SUPER MART',
                        style: GoogleFonts.merriweather(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Center(
                      child: Text(
                        'KHAMMAM',
                        style: GoogleFonts.merriweather(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'CONTACT : 9402512345',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'GSTIN : 1234567800',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('INVOICE ID : 187', style: TextStyle(fontSize: 14)),
                        Text('SOURCESSS', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('DATE: $formattedDate', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 6),
                    Text('CUSTOMER NAME : TESTW', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 6),
                    Text('MOBILE : 9030650065', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 10),
                    // Table header
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '#',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            'ITEMS',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'AMOUNT',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'QTY',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'TOTAL',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.black),
                    // Dynamic items
                    ...widget.selectedProducts.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Product product = entry.value;
                      double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                      return Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              product.itemName ?? 'Unknown',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              '${(product.sellingPrice ?? 0).toStringAsFixed(2)}(1Kg)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${product.quantity}Kg',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              itemTotal.toStringAsFixed(2),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      );
                    }),
                    Divider(color: Colors.black),
                    SizedBox(height: 10),
                    Text('Total:', style: TextStyle(fontSize: 16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('General Items:', style: TextStyle(fontSize: 14)),
                        Text(
                          '${widget.selectedProducts.length}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'TOTAL:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          widget.totalAmount.toStringAsFixed(2),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 0),
                    Divider(color: Colors.black),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DISCOUNT (10%):', style: TextStyle(fontSize: 14)),
                        Text(
                          discountAmt.toStringAsFixed(2),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Divider(color: Colors.black),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          grandAmt.toStringAsFixed(2),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Given Amount:', style: TextStyle(fontSize: 14)),
                        Text(
                          givenAmount.toStringAsFixed(2),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RETURN Amount:', style: TextStyle(fontSize: 14)),
                        Text(
                          returnAmount.toStringAsFixed(2),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Thank You.. Visit Again..!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'SUVIDHA SUPER MART',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                );
              },
              onInitialized: (controller) {
                controllerl = controller;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _selectBluetoothDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                "Select Device",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _printReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                "Print",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to mimic the printer object structure
class _Printer {
  final String address;
  final String? name;
  _Printer({required this.address, this.name});
}*/