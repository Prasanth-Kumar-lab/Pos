import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../Controller/add_product_controller.dart';
import '../model/add_product_model.dart';
import '../model/list_product_category_fetch.dart';
import '../model/list_tax_model.dart';

class EditProductPage extends StatefulWidget {
  final AddProductsAPI product;

  const EditProductPage({super.key, required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _unitsController = TextEditingController();
  final _availabilityStatusController = TextEditingController();
  final _businessIdController = TextEditingController();
  final AddProductsController controller = Get.find<AddProductsController>();
  String? _selectedCategory;
  String? _selectedCgst;
  String? _selectedSgst;
  String? _selectedIgst;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers
    _productIdController.text = widget.product.productId ?? '';
    _productCodeController.text = widget.product.productCode ?? '';
    _itemNameController.text = widget.product.itemName ?? '';
    _sellingPriceController.text = widget.product.sellingPrice ?? '';
    _unitsController.text = widget.product.units ?? ''; // Ensure units is set
    _availabilityStatusController.text = widget.product.availabilityStatus ?? '';
    _businessIdController.text = controller.businessId ?? '';

    // Debug units value
    print('Units value from product: ${widget.product.units}');

    // Initialize dropdown values and ensure they are valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Validate Product Category
        final categoryNames = controller.categories
            .map((cat) => cat.catName)
            .toSet()
            .toList();
        _selectedCategory = categoryNames.contains(widget.product.productCat)
            ? widget.product.productCat
            : (categoryNames.isNotEmpty ? categoryNames.first : null);

        // Validate CGST
        final cgstValues = controller.taxes
            .where((tax) => tax.taxType.toLowerCase() == 'cgst')
            .map((tax) => tax.taxPercentage)
            .toSet()
            .toList();
        _selectedCgst = cgstValues.contains(widget.product.cgst)
            ? widget.product.cgst
            : (cgstValues.isNotEmpty ? cgstValues.first : null);

        // Validate SGST
        final sgstValues = controller.taxes
            .where((tax) => tax.taxType.toLowerCase() == 'sgst')
            .map((tax) => tax.taxPercentage)
            .toSet()
            .toList();
        _selectedSgst = sgstValues.contains(widget.product.sgst)
            ? widget.product.sgst
            : (sgstValues.isNotEmpty ? sgstValues.first : null);

        // Validate IGST
        final igstValues = controller.taxes
            .where((tax) => tax.taxType.toLowerCase() == 'igst')
            .map((tax) => tax.taxPercentage)
            .toSet()
            .toList();
        _selectedIgst = igstValues.contains(widget.product.igst)
            ? widget.product.igst
            : (igstValues.isNotEmpty ? igstValues.first : null);
      });
    });
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _productCodeController.dispose();
    _itemNameController.dispose();
    _sellingPriceController.dispose();
    _unitsController.dispose();
    _availabilityStatusController.dispose();
    _businessIdController.dispose();
    super.dispose();
  }

  void _updateProduct() {
    if (_formKey.currentState!.validate()) {
      final params = {
        'product_id': _productIdController.text,
        'product_code': _productCodeController.text,
        'product_cat': _selectedCategory ?? '',
        'item_name': _itemNameController.text,
        'selling_price': _sellingPriceController.text,
        'selling_unit': _unitsController.text,
        'cgst': _selectedCgst ?? '',
        'sgst': _selectedSgst ?? '',
        'igst': _selectedIgst ?? '',
        'availability_status': _availabilityStatusController.text,
        'business_id': _businessIdController.text,
      };
      controller.updateProduct(widget.product.productCode, params);
      Navigator.pop(context);
    }
  }

  Widget buildCircularBorderTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
    );
  }

  Widget _buildTaxDropdown({
    required String label,
    required String taxType,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Obx(() {
      final filteredTaxes = controller.taxes
          .where((tax) => tax.taxType.toLowerCase() == taxType.toLowerCase())
          .toList();
      final uniqueTaxPercentages = filteredTaxes
          .map((tax) => tax.taxPercentage)
          .toSet()
          .toList();

      // Debugging: Log available tax percentages
      print('$label available values: $uniqueTaxPercentages');
      print('$label selected value: $selectedValue');

      return DropdownButtonFormField2<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          prefixIcon: const Icon(Icons.account_balance_wallet),
        ),
        value: uniqueTaxPercentages.contains(selectedValue) ? selectedValue : null,
        hint: Text('Select $label'),
        items: uniqueTaxPercentages.map((taxPercentage) {
          return DropdownMenuItem<String>(
            value: taxPercentage,
            child: SizedBox(
              height: 40,
              child: Text(taxPercentage),
            ),
          );
        }).toList(),
        onChanged: (value) {
          onChanged(value);
          setState(() {}); // Ensure UI updates
        },
        validator: (value) => value == null ? 'Please select $label' : null,
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade300),
          ),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: MaterialStateProperty.all(6),
            thumbColor: MaterialStateProperty.all(Colors.grey),
          ),
        ),
        buttonStyleData: const ButtonStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
          height: 30,
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 24,
        ),
      );
    });
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Business Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            buildCircularBorderTextField(
              controller: _businessIdController,
              label: 'Business ID',
              icon: Icons.business,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              readOnly: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Product Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            buildCircularBorderTextField(
              controller: _productIdController,
              label: 'Product ID',
              icon: Icons.abc,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            buildCircularBorderTextField(
              controller: _productCodeController,
              label: 'Product Code',
              icon: Icons.qr_code,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Obx(() {
              final categoryNames = controller.categories
                  .map((cat) => cat.catName)
                  .toSet()
                  .toList();
              print('Category available values: $categoryNames');
              print('Category selected value: $_selectedCategory');

              return DropdownButtonFormField2<String>(
                decoration: InputDecoration(
                  labelText: 'Product Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                value: categoryNames.contains(_selectedCategory) ? _selectedCategory : null,
                hint: const Text('Select a category'),
                items: categoryNames.map((catName) {
                  return DropdownMenuItem<String>(
                    value: catName,
                    child: Text(catName),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  scrollbarTheme: ScrollbarThemeData(
                    radius: const Radius.circular(40),
                    thickness: MaterialStateProperty.all(6),
                    thumbColor: MaterialStateProperty.all(Colors.grey),
                  ),
                ),
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 30,
                ),
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Item Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            buildCircularBorderTextField(
              controller: _itemNameController,
              label: 'Item Name',
              icon: Icons.inventory,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            buildCircularBorderTextField(
              controller: _sellingPriceController,
              label: 'Selling Price',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            buildCircularBorderTextField(
              controller: _unitsController,
              label: 'Units',
              icon: Icons.confirmation_number,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              keyboardType: TextInputType.text, // Allow text for units (e.g., "kg", "pcs")
            ),
            const SizedBox(height: 24),
            const Text(
              'Tax Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTaxDropdown(
              label: 'CGST',
              taxType: 'CGST',
              selectedValue: _selectedCgst,
              onChanged: (value) {
                setState(() {
                  _selectedCgst = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTaxDropdown(
              label: 'SGST',
              taxType: 'SGST',
              selectedValue: _selectedSgst,
              onChanged: (value) {
                setState(() {
                  _selectedSgst = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTaxDropdown(
              label: 'IGST',
              taxType: 'IGST',
              selectedValue: _selectedIgst,
              onChanged: (value) {
                setState(() {
                  _selectedIgst = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            buildCircularBorderTextField(
              controller: _availabilityStatusController,
              label: 'Availability Status',
              icon: Icons.check_circle_outline,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _updateProduct,
                  icon: Icon(Icons.update, color: Colors.blueGrey.shade900),
                  label: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(150, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.cancel, color: Colors.blueGrey.shade900),
                  label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(150, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildFormFields(),
        ),
      ),
    );
  }
}