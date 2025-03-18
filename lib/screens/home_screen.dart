import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import '../widgets/invoice_preview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  Item? _selectedItem;
  final TextEditingController _quantityController = TextEditingController();
  final List<SelectedItem> _selectedItems = [];
  final ScrollController _scrollController = ScrollController();
  List<Item> items = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    fetchItemsFromFirestore();
  }

  @override
  void dispose() {
    _timer.cancel();
    _quantityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// **Fetch items from Firestore**
  Future<void> fetchItemsFromFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot snapshot = await firestore.collection('items').get();

      setState(() {
        items =
            snapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return Item(
                id: doc.id,
                name: data['name'],
                price: (data['price'] as num).toDouble(),
              );
            }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load items: $e";
      });
    }
  }

  void _addItemToList() {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an item')));
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() {
      _selectedItems.add(
        SelectedItem(
          item: _selectedItem!,
          quantity: quantity,
          total: _selectedItem!.price * quantity,
        ),
      );
      _selectedItem = null;
      _quantityController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// **Remove item from the list**
  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _showInvoicePreview() {
    showDialog(
      context: context,
      builder:
          (context) => InvoicePreview(
            items: _selectedItems,
            total: _totalAmount,
            date: _currentTime,
          ),
    );
  }

  double get _totalAmount =>
      _selectedItems.fold<double>(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "BillBro",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${_currentTime.toString().substring(0, 11)}",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Time: ${_currentTime.toString().substring(11, 16)}",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child:
                                isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : errorMessage.isNotEmpty
                                    ? Center(
                                      child: Text(
                                        errorMessage,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                    : DropdownButtonFormField<Item>(
                                      value: _selectedItem,
                                      decoration: InputDecoration(
                                        labelText: 'Select Item',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      items:
                                          items.map((Item item) {
                                            return DropdownMenuItem<Item>(
                                              value: item,
                                              child: Text(
                                                '${item.name} - ₹${item.price}',
                                                style: GoogleFonts.inter(),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (Item? value) {
                                        setState(() {
                                          _selectedItem = value;
                                        });
                                      },
                                    ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Qty',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _addItemToList,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text('Add to List', style: GoogleFonts.inter()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return ListTile(
                    
                    title: Text('${item.item.name} x ${item.quantity}'),
                    subtitle: Text('₹${item.item.price} each'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.total}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(15),
              color: Theme.of(context).colorScheme.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₹${_totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    onPressed: _showInvoicePreview,
                    label: const Text(
                      'Generate Bill',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
