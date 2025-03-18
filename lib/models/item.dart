class Item {
  final String id;
  final String name;
  final double price;

  Item({
    required this.id,
    required this.name,
    required this.price,
  });
}

class SelectedItem {
  final Item item;
  final int quantity;
  final double total;

  SelectedItem({
    required this.item,
    required this.quantity,
    required this.total,
  });
}

final List<Item> dummyItems = [
  Item(id: '1', name: 'Item 1', price: 100.0),
  Item(id: '2', name: 'Item 2', price: 150.0),
  Item(id: '3', name: 'Item 3', price: 200.0),
  Item(id: '4', name: 'Item 4', price: 250.0),
];