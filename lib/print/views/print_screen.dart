/*
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import '../../home_screen/controller/controller.dart';
import '../../home_screen/model/product_model.dart';
import '../controller/print_controller.dart';

class PrintScreen extends StatelessWidget {
  final List<Product> initialProducts;
  final double initialTotal;
  final String businessId;

  const PrintScreen({
    Key? key,
    required this.initialProducts,
    required this.initialTotal,
    required this.businessId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final printController = Get.put(PrintController(
      initialProducts: initialProducts,
      initialTotal: initialTotal,
      businessId: businessId,
    ));
    final productController = Get.find<ProductController>();

    // Sync cart data on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await printController.syncCartData(productController);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Receipt'),
      ),
      body: Column(
        children: [
          Obx(() {
            final printer = printController.selectedPrinter.value;
            if (printer == null) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<bool>(
              future: FlutterBluetoothPrinter.connect(printer.address),
              builder: (context, snapshot) {
                bool isConnected = snapshot.data ?? false;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Lottie.asset(
                          isConnected ? 'assets/active.json' : 'assets/inactive.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selected Printer: ${printer.name ?? printer.address}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          Obx(() {
            if (printController.isLoadingSettings.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (printController.errorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: ${printController.errorMessage.value}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: printController.fetchSystemSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              final settings = printController.systemSettings.value;
              final cartItems = productController.cartItems; // Use cartItems directly for API quantities
              if (settings == null) {
                return const Center(child: Text('Loading receipt data...'));
              }
              return Receipt(
                builder: (context) {
                  var now = DateTime.now();
                  var formatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
                  String formattedDate = formatter.format(now);
                  double discountAmt = (printController.totalAmount.value * 0.1).ceilToDouble();
                  double grandAmt = printController.totalAmount.value - discountAmt;
                  double givenAmount = 700.00;
                  double returnAmount = givenAmount - grandAmt;

                  List<String> splitText(String text, int maxLength) {
                    List<String> lines = [];
                    if (text.length <= maxLength) {
                      lines.add(text);
                      return lines;
                    }
                    while (text.isNotEmpty) {
                      if (text.length <= maxLength) {
                        lines.add(text);
                        break;
                      }
                      int splitIndex = text.substring(0, maxLength).lastIndexOf(' ');
                      if (splitIndex == -1 || splitIndex < maxLength ~/ 2) {
                        splitIndex = maxLength;
                      }
                      lines.add(text.substring(0, splitIndex));
                      text = text.substring(splitIndex).trim();
                    }
                    return lines;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          settings.firmName,
                          style: GoogleFonts.merriweather(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          'CONTACT : ${settings.firmContact1} ${settings.firmContact2}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          settings.billAddress,
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          'GSTIN : ${settings.billGstinNum}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            'INVOICE ID : ${productController.finalInvoiceId.value}',
                            style: TextStyle(fontSize: 17),
                          )),
                          /*Obx(() => Text(
                            productController.finalInvoiceId.value, // Dynamic final_invoice_id
                            style: TextStyle(fontSize: 17),
                          )),*/
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('DATE: $formattedDate', style: TextStyle(fontSize: 17)),
                      const SizedBox(height: 6),
                      Obx(() {
                        final customerName = productController.customerName.value;
                        final nameLines = splitText(customerName, 20);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: nameLines.map((line) => Text(
                            nameLines.first == line ? 'CUSTOMER NAME : $line' : line,
                            style: const TextStyle(fontSize: 16),
                          )).toList(),
                        );
                      }),
                      const SizedBox(height: 6),
                      Obx(() => Text(
                        'MOBILE : ${productController.customerMobileNumber.value}',
                        style: const TextStyle(fontSize: 17),
                      )),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '#',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              'ITEMS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              'AMOUNT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'QTY',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'TOTAL',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      ...cartItems.asMap().entries.expand((entry) {
                        int idx = entry.key;
                        Product product = entry.value;
                        double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                        final itemName = product.itemName ?? 'Unknown';
                        final itemNameLines = splitText(itemName, 20);
                        return itemNameLines.asMap().entries.map((lineEntry) {
                          int lineIdx = lineEntry.key;
                          String line = lineEntry.value;
                          return Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  lineIdx == 0 ? '${idx + 1}' : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  line,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  lineIdx == 0 ? '${(product.sellingPrice ?? 0).toStringAsFixed(2)}(1Kg)' : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  lineIdx == 0 ? 'x${product.quantity}' : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  lineIdx == 0 ? itemTotal.toStringAsFixed(2) : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          );
                        });
                      }),
                      const Divider(color: Colors.black),
                      const SizedBox(height: 10),
                      const Text('Total', style: TextStyle(fontSize: 19)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('General Items:', style: TextStyle(fontSize: 16)),
                          Text(
                            '${cartItems.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text(
                            'TOTAL:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                          ),
                          Text(
                            printController.totalAmount.value.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      const Divider(color: Colors.black),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DISCOUNT (10%):', style: TextStyle(fontSize: 16)),
                          Text(
                            discountAmt.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                          ),
                          Text(
                            grandAmt.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Given Amount:', style: TextStyle(fontSize: 16)),
                          Text(
                            givenAmount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('RETURN Amount:', style: TextStyle(fontSize: 16)),
                          Text(
                            returnAmount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Thank You.. Visit Again..!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  );
                },
                onInitialized: (controller) {
                  printController.setReceiptController(controller);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => printController.selectBluetoothDevice(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Select Device",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await printController.syncCartData(productController); // Sync before printing
                  await printController.printReceipt(context, productController);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Print",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/

/*
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:task/Constants/constants.dart';
import '../../home_screen/controller/controller.dart';
import '../../home_screen/model/product_model.dart';
import '../controller/print_controller.dart';

class PrintScreen extends StatelessWidget {
  final List<Product> initialProducts;
  final double initialTotal;
  final String businessId;

  const PrintScreen({
    Key? key,
    required this.initialProducts,
    required this.initialTotal,
    required this.businessId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final printController = Get.put(PrintController(
      initialProducts: initialProducts,
      initialTotal: initialTotal,
      businessId: businessId,
    ));
    final productController = Get.find<ProductController>();
    productController.fetchCartItems();                       // YESTERDAY
    // Sync cart data on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await printController.syncCartData(productController);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Receipt'),
      ),
      body: Column(
        children: [
          Obx(() {
            final printer = printController.selectedPrinter.value;
            if (printer == null) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<bool>(
              future: FlutterBluetoothPrinter.connect(printer.address),
              builder: (context, snapshot) {
                bool isConnected = snapshot.data ?? false;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Lottie.asset(
                          isConnected ? 'assets/active.json' : 'assets/inactive.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selected Printer: ${printer.name ?? printer.address}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          Obx(() {
            if (printController.isLoadingSettings.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (printController.errorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: ${printController.errorMessage.value}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: printController.fetchSystemSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              final settings = printController.systemSettings.value;
              final cartItems = productController.cartItems;
              if (settings == null) {
                return const Center(child: Text('Loading receipt data...'));
              }
              return Receipt(
                builder: (context) {
                  var now = DateTime.now();
                  var formatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
                  String formattedDate = formatter.format(now);
                  double discountAmt = (printController.totalAmount.value * 0.1).ceilToDouble();
                  double grandAmt = printController.totalAmount.value - discountAmt;
                  double givenAmount = 700.00;
                  double returnAmount = givenAmount - grandAmt;

                  List<String> splitText(String text, int maxLength) {
                    List<String> lines = [];
                    if (text.length <= maxLength) {
                      lines.add(text);
                      return lines;
                    }
                    while (text.isNotEmpty) {
                      if (text.length <= maxLength) {
                        lines.add(text);
                        break;
                      }
                      int splitIndex = text.substring(0, maxLength).lastIndexOf(' ');
                      if (splitIndex == -1 || splitIndex < maxLength ~/ 2) {
                        splitIndex = maxLength;
                      }
                      lines.add(text.substring(0, splitIndex));
                      text = text.substring(splitIndex).trim();
                    }
                    return lines;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image(
                          image: CachedNetworkImageProvider(
                            '${settings.billLogo}',
                          ),
                          height: 80,
                          width: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          settings.firmName,
                          style: GoogleFonts.merriweather(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      PrintConstants.spaceBetweenWidgets,

                      Center(
                        child: Text(
                          'CONTACT : ${settings.firmContact1} ${settings.firmContact2}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      PrintConstants.spaceBetweenWidgets,
                      /*Center(
                        child: Text(
                          settings.billAddress,
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),*/
                      Center(
                        child: Text(
                          settings.billAddress?.isNotEmpty == true
                              ? settings.billAddress!
                              : 'Not mentioned bill address',
                          style: GoogleFonts.merriweather(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      PrintConstants.spaceBetweenWidgets,

                      Center(
                        child: Text(
                          'GSTIN : ${settings.billGstinNum}',
                          style: PrintConstants.mainDetailsTextStyle,
                        ),
                      ),

                      PrintConstants.spaceBetweenWidgets,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            'INVOICE ID : ${productController.finalInvoiceId.value}',
                            style: PrintConstants.mainDetailsTextStyle,
                          )),
                        ],
                      ),

                      PrintConstants.spaceBetweenWidgets,

                      Text('DATE: $formattedDate', style: PrintConstants.mainDetailsTextStyle),

                      PrintConstants.spaceBetweenWidgets,

                      Obx(() {
                        final customerName = productController.customerName.value;
                        final nameLines = splitText(customerName, 20);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: nameLines.map((line) => Text(
                            nameLines.first == line ? 'CUSTOMER NAME : $line' : line,
                            style: PrintConstants.mainDetailsTextStyle,
                          )).toList(),
                        );
                      }),

                      PrintConstants.spaceBetweenWidgets,

                      Obx(() => Text(
                        'MOBILE : ${productController.customerMobileNumber.value}',
                        style: PrintConstants.mainDetailsTextStyle,
                      )),

                      PrintConstants.spaceBetweenWidgets,

                      Row(
                        children: const [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '#',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              'ITEMS',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              'AMOUNT',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'QTY',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'TOTAL',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      ...cartItems.asMap().entries.expand((entry) {
                        int idx = entry.key;
                        Product product = entry.value;
                        double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                        final itemName = product.itemName ?? 'Unknown';
                        final itemNameLines = splitText(itemName, 20);
                        return itemNameLines.asMap().entries.map((lineEntry) {
                          int lineIdx = lineEntry.key;
                          String line = lineEntry.value;
                          return Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  lineIdx == 0 ? '${idx + 1}' : '.',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  '$line', //(${product.sellingUnit!})
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  lineIdx == 0 ? '${(product.sellingPrice ?? 0).toStringAsFixed(2)}' : '',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  lineIdx == 0 ? 'x${product.quantity}' : '',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  lineIdx == 0 ? itemTotal.toStringAsFixed(2) : '',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                            ],
                          );
                        });
                      }),
                      const Divider(color: Colors.black),
                      PrintConstants.spaceBetweenWidgets,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end, // aligns text to the right
                        children: [
                          Text(
                            'Sub-Total: ${productController.totalAmount.value.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      //const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'General Items: ${cartItems.length}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          // Column for all amounts
                          /*Column(
                            crossAxisAlignment: CrossAxisAlignment.end, // aligns text to the right
                            children: [
                              Text(
                                'GST: ${productController.gstAmount.value.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 3,),
                              Text(
                                'Round-Off: ${productController.roundOff.value.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),*/
                        ],
                      ),
                      const Divider(color: Colors.black),

                      PrintConstants.spaceBetweenWidgets,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'GST: ${productController.gstAmount.value.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Round-Off: ${productController.roundOff.value.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 3,),
                              Text(
                                'Grand Total: ${productController.totalAmount.value + productController.gstAmount.value + productController.roundOff.value}',//${productController.computeGrandTotal}
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(color: Colors.black,),
                      PrintConstants.spaceBetweenWidgets,
                      /*Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            '${productController.totalAmount.value + productController.gstAmount.value + productController.roundOff.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ],
                      ),*/
                      const SizedBox(height: 15),
                      const Center(
                        child: Text(
                          'Thank You.. Visit Again..!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      SizedBox(height: 5),
                    ],
                  );
                },
                onInitialized: (controller) {
                  printController.setReceiptController(controller);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => printController.selectBluetoothDevice(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Select Device",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await printController.syncCartData(productController);
                  await printController.printReceipt(context, productController);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Print",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
/*
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import '../../home_screen/controller/controller.dart';
import '../../home_screen/model/product_model.dart';
import '../controller/print_controller.dart';

class PrintScreen extends StatelessWidget {
  final List<Product> initialProducts;
  final double initialTotal;
  final String businessId;

  const PrintScreen({
    Key? key,
    required this.initialProducts,
    required this.initialTotal,
    required this.businessId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final printController = Get.put(PrintController(
      initialProducts: initialProducts,
      initialTotal: initialTotal,
      businessId: businessId,
    ));
    final productController = Get.find<ProductController>();

    // Sync cart data on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await printController.syncCartData(productController);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Receipt'),
      ),
      body: Column(
        children: [
          Obx(() {
            final printer = printController.selectedPrinter.value;
            if (printer == null) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<bool>(
              future: FlutterBluetoothPrinter.connect(printer.address),
              builder: (context, snapshot) {
                bool isConnected = snapshot.data ?? false;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Lottie.asset(
                          isConnected ? 'assets/active.json' : 'assets/inactive.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selected Printer: ${printer.name ?? printer.address}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          Obx(() {
            if (printController.isLoadingSettings.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (printController.errorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: ${printController.errorMessage.value}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: printController.fetchSystemSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              final settings = printController.systemSettings.value;
              final cartItems = productController.cartItems; // Use cartItems directly for API quantities
              if (settings == null) {
                return const Center(child: Text('Loading receipt data...'));
              }
              return Receipt(
                builder: (context) {
                  var now = DateTime.now();
                  var formatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
                  String formattedDate = formatter.format(now);
                  double discountAmt = (printController.totalAmount.value * 0.1).ceilToDouble();
                  double grandAmt = printController.totalAmount.value - discountAmt;
                  double givenAmount = 700.00;
                  double returnAmount = givenAmount - grandAmt;

                  List<String> splitText(String text, int maxLength) {
                    List<String> lines = [];
                    if (text.length <= maxLength) {
                      lines.add(text);
                      return lines;
                    }
                    while (text.isNotEmpty) {
                      if (text.length <= maxLength) {
                        lines.add(text);
                        break;
                      }
                      int splitIndex = text.substring(0, maxLength).lastIndexOf(' ');
                      if (splitIndex == -1 || splitIndex < maxLength ~/ 2) {
                        splitIndex = maxLength;
                      }
                      lines.add(text.substring(0, splitIndex));
                      text = text.substring(splitIndex).trim();
                    }
                    return lines;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          settings.firmName,
                          style: GoogleFonts.merriweather(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          'CONTACT : ${settings.firmContact1} ${settings.firmContact2}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          settings.billAddress,
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          'GSTIN : ${settings.billGstinNum}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            'INVOICE ID : ${productController.finalInvoiceId.value}',
                            style: TextStyle(fontSize: 17),
                          )),
                          /*Obx(() => Text(
                            productController.finalInvoiceId.value, // Dynamic final_invoice_id
                            style: TextStyle(fontSize: 17),
                          )),*/
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('DATE: $formattedDate', style: TextStyle(fontSize: 17)),
                      const SizedBox(height: 6),
                      Obx(() {
                        final customerName = productController.customerName.value;
                        final nameLines = splitText(customerName, 20);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: nameLines.map((line) => Text(
                            nameLines.first == line ? 'CUSTOMER NAME : $line' : line,
                            style: const TextStyle(fontSize: 16),
                          )).toList(),
                        );
                      }),
                      const SizedBox(height: 6),
                      Obx(() => Text(
                        'MOBILE : ${productController.customerMobileNumber.value}',
                        style: const TextStyle(fontSize: 17),
                      )),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '#',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              'ITEMS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              'AMOUNT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'QTY',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'TOTAL',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      ...cartItems.asMap().entries.expand((entry) {
                        int idx = entry.key;
                        Product product = entry.value;
                        double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                        final itemName = product.itemName ?? 'Unknown';
                        final itemNameLines = splitText(itemName, 20);
                        return itemNameLines.asMap().entries.map((lineEntry) {
                          int lineIdx = lineEntry.key;
                          String line = lineEntry.value;
                          return Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  lineIdx == 0 ? '${idx + 1}' : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  line,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  lineIdx == 0 ? '${(product.sellingPrice ?? 0).toStringAsFixed(2)}(1Kg)' : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  lineIdx == 0 ? 'x${product.quantity}' : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  lineIdx == 0 ? itemTotal.toStringAsFixed(2) : '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          );
                        });
                      }),
                      const Divider(color: Colors.black),
                      const SizedBox(height: 10),
                      const Text('Total', style: TextStyle(fontSize: 19)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('General Items:', style: TextStyle(fontSize: 16)),
                          Text(
                            '${cartItems.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text(
                            'TOTAL:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                          ),
                          Text(
                            printController.totalAmount.value.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      const Divider(color: Colors.black),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DISCOUNT (10%):', style: TextStyle(fontSize: 16)),
                          Text(
                            discountAmt.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                          ),
                          Text(
                            grandAmt.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Given Amount:', style: TextStyle(fontSize: 16)),
                          Text(
                            givenAmount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('RETURN Amount:', style: TextStyle(fontSize: 16)),
                          Text(
                            returnAmount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Thank You.. Visit Again..!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  );
                },
                onInitialized: (controller) {
                  printController.setReceiptController(controller);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => printController.selectBluetoothDevice(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Select Device",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await printController.syncCartData(productController); // Sync before printing
                  await printController.printReceipt(context, productController);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Print",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:task/Constants/constants.dart';
import '../../home_screen/controller/controller.dart';
import '../../home_screen/model/product_model.dart';
import '../controller/print_controller.dart';

class PrintScreen extends StatelessWidget {
  final List<Product> initialProducts;
  final double initialTotal;
  final String businessId;

  const PrintScreen({
    Key? key,
    required this.initialProducts,
    required this.initialTotal,
    required this.businessId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final printController = Get.put(PrintController(
      initialProducts: initialProducts,
      initialTotal: initialTotal,
      businessId: businessId,
    ));
    final productController = Get.find<ProductController>();
    productController.fetchCartItems();

    // Sync cart data on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await printController.syncCartData(productController);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Receipt'),
      ),
      body: Column(
        children: [
          Obx(() {
            final printer = printController.selectedPrinter.value;
            if (printer == null) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<bool>(
              future: FlutterBluetoothPrinter.connect(printer.address),
              builder: (context, snapshot) {
                bool isConnected = snapshot.data ?? false;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Lottie.asset(
                          isConnected ? 'assets/active.json' : 'assets/inactive.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selected Printer: ${printer.name ?? printer.address}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          Obx(() {
            if (printController.isLoadingSettings.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (printController.errorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: ${printController.errorMessage.value}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: printController.fetchSystemSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              final settings = printController.systemSettings.value;
              final cartItems = productController.cartItems;
              if (settings == null) {
                return const Center(child: Text('Loading receipt data...'));
              }
              return Receipt(
                builder: (context) {
                  var now = DateTime.now();
                  var formatter = DateFormat('dd/MM/yyyy hh:mm a');
                  String formattedDate = formatter.format(now);

                  // Calculate totals
                  double subtotal = productController.totalAmount.value;
                  double gstAmount = productController.gstAmount.value;
                  double roundOff = productController.roundOff.value;
                  double grandTotal = subtotal + gstAmount + roundOff;

                  // Function to split text for 80mm width (approx 40 characters)
                  List<String> splitText(String text, {int maxLength = 40}) {
                    List<String> lines = [];
                    if (text.length <= maxLength) {
                      lines.add(text);
                      return lines;
                    }

                    List<String> words = text.split(' ');
                    String currentLine = '';

                    for (String word in words) {
                      if ((currentLine + word).length <= maxLength) {
                        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
                      } else {
                        if (currentLine.isNotEmpty) {
                          lines.add(currentLine);
                        }
                        // If a single word is longer than maxLength, split it
                        if (word.length > maxLength) {
                          for (int i = 0; i < word.length; i += maxLength) {
                            int end = i + maxLength;
                            if (end > word.length) end = word.length;
                            lines.add(word.substring(i, end));
                          }
                          currentLine = '';
                        } else {
                          currentLine = word;
                        }
                      }
                    }

                    if (currentLine.isNotEmpty) {
                      lines.add(currentLine);
                    }

                    return lines;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Logo - Reduced size for 80mm
                      if (settings.billLogo?.isNotEmpty == true)
                        Center(
                          child: Image(
                            image: CachedNetworkImageProvider('${settings.billLogo}'),
                            height: 60, // Reduced from 80
                            width: 160, // Reduced from 200
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 60,
                              width: 160,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 30),
                            ),
                          ),
                        ),

                      // Firm Name - Smaller font
                      Center(
                        child: Text(
                          splitText(settings.firmName, maxLength: 36).join('\n'),
                          style: GoogleFonts.merriweather(
                            fontSize: 16, // Reduced from 20
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Contact - Smaller font
                      Center(
                        child: Text(
                          'Contact: ${settings.firmContact1} ${settings.firmContact2}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Reduced from 15
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Address - Smaller font with line breaks
                      if (settings.billAddress?.isNotEmpty == true)
                        Center(
                          child: Text(
                            splitText(settings.billAddress!, maxLength: 36).join('\n'),
                            style: const TextStyle(
                              fontSize: 11, // Reduced from 15
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 4),

                      // GSTIN - Smaller font
                      Center(
                        child: Text(
                          'GSTIN: ${settings.billGstinNum}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Divider line
                      Container(
                        height: 1,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),

                      // Invoice ID and Date in single row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Expanded(
                            child: Text(
                              'Invoice: ${productController.finalInvoiceId.value}',
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                          const SizedBox(width: 8),
                          Text(
                            'Date: $formattedDate',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Customer Name - with wrapping
                      Obx(() {
                        final customerName = productController.customerName.value;
                        if (customerName.isNotEmpty) {
                          final nameLines = splitText(customerName, maxLength: 36);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: nameLines.map((line) => Text(
                              nameLines.first == line ? 'Customer: $line' : '  $line',
                              style: const TextStyle(fontSize: 11),
                            )).toList(),
                          );
                        }
                        return const SizedBox();
                      }),

                      // Mobile
                      Obx(() {
                        final mobile = productController.customerMobileNumber.value;
                        if (mobile.isNotEmpty) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Mobile: $mobile',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }
                        return const SizedBox();
                      }),
                      const SizedBox(height: 8),

                      // Table Header with adjusted widths for 80mm
                      Row(
                        children: const [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '#',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Items',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Qty',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Total',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      // Thin divider
                      Container(
                        height: 1,
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),

                      // Items List - Optimized for 80mm
                      ...cartItems.asMap().entries.expand((entry) {
                        int idx = entry.key;
                        Product product = entry.value;
                        double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                        final itemName = product.itemName ?? 'Unknown';
                        final itemNameLines = splitText(itemName, maxLength: 28); // Reduced for 80mm

                        return itemNameLines.asMap().entries.map((lineEntry) {
                          int lineIdx = lineEntry.key;
                          String line = lineEntry.value;

                          return Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  lineIdx == 0 ? '${idx + 1}' : '',
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  line,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  lineIdx == 0 ? 'x${product.quantity}' : '',
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  lineIdx == 0 ? itemTotal.toStringAsFixed(2) : '',
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          );
                        });
                      }),

                      // Divider after items
                      Container(
                        height: 1,
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),

                      // Totals Section - Compact layout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCompactAmountRow('Sub-Total', subtotal.toStringAsFixed(2)),
                          _buildCompactAmountRow('GST', gstAmount.toStringAsFixed(2)),
                          _buildCompactAmountRow('Round Off', roundOff.toStringAsFixed(2)),
                          const SizedBox(height: 4),
                          Container(
                            height: 1,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 4),
                          _buildCompactAmountRow(
                            'GRAND TOTAL',
                            grandTotal.toStringAsFixed(2),
                            isBold: true,
                            isGrandTotal: true,
                          ),
                        ],
                      ),

                      // Double divider for separation
                      Container(
                        height: 2,
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),

                      // Thank You Note - Smaller
                      const Center(
                        child: Text(
                          'Thank You! Visit Again',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Reduced from 22
                          ),
                        ),
                      ),

                      // Footer space
                      const SizedBox(height: 20),
                    ],
                  );
                },
                onInitialized: (controller) {
                  printController.setReceiptController(controller);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => printController.selectBluetoothDevice(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Select Device",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final printController = Get.find<PrintController>();
                  final productController = Get.find<ProductController>();

                  // Show the "Please wait… Printing..." dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.transparent,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      insetPadding: EdgeInsets.zero,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 12),
                              Text(
                                "Please wait… Printing...",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  // Sync cart and print
                  await printController.syncCartData(productController);
                  await printController.printReceipt(context, productController);

                  // Close the dialog after printing completes
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Print",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAmountRow(String label, String value, {
    bool isBold = false,
    bool isGrandTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isGrandTotal ? 12 : 11,
                color: isGrandTotal ? Colors.black : null,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isGrandTotal ? 12 : 11,
              color: isGrandTotal ? Colors.black : null,
            ),
          ),
        ],
      ),
    );
  }
}

/*
return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image(
                          image: CachedNetworkImageProvider(
                            '${settings.billLogo}',
                          ),
                          height: 80,
                          width: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          settings.firmName,
                          style: GoogleFonts.merriweather(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      PrintConstants.spaceBetweenWidgets,

                      Center(
                        child: Text(
                          'CONTACT : ${settings.firmContact1} ${settings.firmContact2}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      PrintConstants.spaceBetweenWidgets,
                      /*Center(
                        child: Text(
                          settings.billAddress,
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),*/
                      Center(
                        child: Text(
                          settings.billAddress?.isNotEmpty == true
                              ? settings.billAddress!
                              : 'Not mentioned bill address',
                          style: GoogleFonts.merriweather(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      PrintConstants.spaceBetweenWidgets,

                      Center(
                        child: Text(
                          'GSTIN : ${settings.billGstinNum}',
                          style: PrintConstants.mainDetailsTextStyle,
                        ),
                      ),

                      PrintConstants.spaceBetweenWidgets,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            'INVOICE ID : ${productController.finalInvoiceId.value}',
                            style: PrintConstants.mainDetailsTextStyle,
                          )),
                        ],
                      ),
                      PrintConstants.spaceBetweenWidgets,
                      Text('DATE: $formattedDate', style: PrintConstants.mainDetailsTextStyle),
                      PrintConstants.spaceBetweenWidgets,
                      Obx(() {
                        final customerName = productController.customerName.value;
                        final nameLines = splitText(customerName, 20);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: nameLines.map((line) => Text(
                            nameLines.first == line ? 'CUSTOMER NAME : $line' : line,
                            style: PrintConstants.mainDetailsTextStyle,
                          )).toList(),
                        );
                      }),

                      PrintConstants.spaceBetweenWidgets,

                      Obx(() => Text(
                        'MOBILE : ${productController.customerMobileNumber.value}',
                        style: PrintConstants.mainDetailsTextStyle,
                      )),

                      PrintConstants.spaceBetweenWidgets,

                      Row(
                        children: const [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '#',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              'ITEMS',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              'AMOUNT',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'QTY',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'TOTAL',
                              style: PrintConstants.itemsTextStyle,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      ...cartItems.asMap().entries.expand((entry) {
                        int idx = entry.key;
                        Product product = entry.value;
                        double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                        final itemName = product.itemName ?? 'Unknown';
                        final itemNameLines = splitText(itemName, 20);
                        return itemNameLines.asMap().entries.map((lineEntry) {
                          int lineIdx = lineEntry.key;
                          String line = lineEntry.value;
                          return Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  lineIdx == 0 ? '${idx + 1}' : '.',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  '$line', //(${product.sellingUnit!})
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  lineIdx == 0 ? '${(product.sellingPrice ?? 0).toStringAsFixed(2)}' : '',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  lineIdx == 0 ? 'x${product.quantity}' : '',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  lineIdx == 0 ? itemTotal.toStringAsFixed(2) : '',
                                  style: PrintConstants.itemsTextStyle,
                                ),
                              ),
                            ],
                          );
                        });
                      }),
                      const Divider(color: Colors.black),
                      PrintConstants.spaceBetweenWidgets,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // aligns text to the right
                        children: [
                          Text(
                            'General Items: ${cartItems.length}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sub-Total: ${productController.totalAmount.value.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black),
                      //const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          // Column for all amounts
                          /*Column(
                            crossAxisAlignment: CrossAxisAlignment.end, // aligns text to the right
                            children: [
                              Text(
                                'GST: ${productController.gstAmount.value.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 3,),
                              Text(
                                'Round-Off: ${productController.roundOff.value.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),*/
                      PrintConstants.spaceBetweenWidgets,

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'GST:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                productController.gstAmount.value.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Round-Off:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                productController.roundOff.value.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                (productController.totalAmount.value +
                                    productController.gstAmount.value +
                                    productController.roundOff.value)
                                    .toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(color: Colors.black,),
                      PrintConstants.spaceBetweenWidgets,
                      /*Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            '${productController.totalAmount.value + productController.gstAmount.value + productController.roundOff.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ],
                      ),*/
                      const SizedBox(height: 15),
                      const Center(
                        child: Text(
                          'Thank You.. Visit Again..!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      SizedBox(height: 5),
                    ],
                  );
 */