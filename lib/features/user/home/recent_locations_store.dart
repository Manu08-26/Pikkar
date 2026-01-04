class RecentLocationsStore {
  static final List<Map<String, String>> _items = [];

  static List<Map<String, String>> get items => List.unmodifiable(_items);

  static void add(String name, String address) {
    _items.removeWhere((e) => e['name'] == name && e['address'] == address);
    _items.insert(0, {'name': name, 'address': address});
    if (_items.length > 6) {
      _items.removeLast();
    }
  }
}

