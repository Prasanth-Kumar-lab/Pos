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
  final List<Product> selectedProducts;
  final double totalAmount;
  final String businessId;

  const PrintScreen({
    Key? key,
    required this.selectedProducts,
    required this.totalAmount,
    required this.businessId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final printController = Get.put(PrintController(
      selectedProducts: selectedProducts,
      totalAmount: totalAmount,
      businessId: businessId, // Pass businessId
    ));

    final productController = Get.find<ProductController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Receipt'),
      ),
      body: Column(
        children: [
          // DISPLAY SELECTED PRINTER ABOVE RECEIPT (not printed)
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
          // LOADING/ERROR HANDLING FOR SETTINGS (new)
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
          // RECEIPT - ONLY THIS PART IS PRINTED
          Expanded(
            child: Obx(() { // Wrap in Obx to react to systemSettings changes
              final settings = printController.systemSettings.value;
              if (settings == null) {
                return const Center(child: Text('Loading receipt data...'));
              }
              return Receipt(
                builder: (context) {
                  var now = DateTime.now();
                  var formatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
                  String formattedDate = formatter.format(now);
                  double discountAmt = (totalAmount * 0.1).ceilToDouble();
                  double grandAmt = totalAmount - discountAmt;
                  double givenAmount = 700.00;
                  double returnAmount = givenAmount - grandAmt;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic shop name from quote_id
                      /*Center(
                        child: Text(
                          settings.quoteId, // Dynamic: was 'SUVIDHA SUPER MART'
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Center(
                        child: Text('Prefix: ${settings.billPrefix}', // Dynamic: was 'SUVIDHA SUPER MART'
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),*/
                      // Dynamic firm name below quote
                      Center(
                        child: Text(
                          settings.firmName, // Dynamic: was hardcoded
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Dynamic contact from firm_contact1 and firm_contact2
                      Center(
                        child: Text(
                          'CONTACT : ${settings.firmContact1} ${settings.firmContact2}', // Dynamic: was 'CONTACT : 9402512345'
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Dynamic address from bill_address
                      Center(
                        child: Text(
                          settings.billAddress, // Dynamic: was 'KHAMMAM'
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Dynamic GSTIN from bill_gstin_num
                      Center(
                        child: Text(
                          'GSTIN : ${settings.billGstinNum}', // Dynamic: was 'GSTIN : 1234567800'
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // bill_logo can be added here if you want to display an image
                      // e.g., if (settings.billLogo.isNotEmpty) Image.network(settings.billLogo, height: 50),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            'INVOICE ID : ${productController.finalInvoiceId.value}',
                            style: const TextStyle(fontSize: 14),
                          )),
                          const Text('SOURCESSS', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('DATE: $formattedDate', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 6),
                      Obx(() => Text(
                        'CUSTOMER NAME : ${productController.customerName.value}',
                        style: const TextStyle(fontSize: 14),
                      )),
                      const SizedBox(height: 6),
                      Obx(() => Text(
                        'MOBILE : ${productController.customerMobileNumber.value}',
                        style: const TextStyle(fontSize: 14),
                      )),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
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
                      const Divider(color: Colors.black),
                      ...selectedProducts.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Product product = entry.value;
                        double itemTotal = (product.sellingPrice ?? 0) * product.quantity;
                        return Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                product.itemName ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                '${(product.sellingPrice ?? 0).toStringAsFixed(2)}(1Kg)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'x${product.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                itemTotal.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        );
                      }),
                      const Divider(color: Colors.black),
                      const SizedBox(height: 10),
                      const Text('Total:', style: TextStyle(fontSize: 16)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('General Items:', style: TextStyle(fontSize: 14)),
                          Text(
                            '${selectedProducts.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text(
                            'TOTAL:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            totalAmount.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      const Divider(color: Colors.black),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DISCOUNT (10%):', style: TextStyle(fontSize: 14)),
                          Text(
                            discountAmt.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            grandAmt.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Given Amount:', style: TextStyle(fontSize: 14)),
                          Text(
                            givenAmount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('RETURN Amount:', style: TextStyle(fontSize: 14)),
                          Text(
                            returnAmount.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Thank You.. Visit Again..!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Dynamic shop name again at bottom
                    ],
                  );
                },
                onInitialized: (controller) {
                  Get.find<PrintController>().setReceiptController(controller);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
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
              onPressed: () => printController.printReceipt(context),
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
    );
  }
}