import 'package:flutter/material.dart';

/// Store frontend en memoria (sin backend).
/// TODO-BACKEND: reemplazar por ApplianceRepository (GET/POST/PUT/DELETE /appliances).
class ApplianceItemData {
  String id;
  String name;
  double powerW;
  double hoursPerDay;
  int quantity;
  ApplianceItemData({required this.id, required this.name, required this.powerW, required this.hoursPerDay, this.quantity = 1});

  double get kwhDay => powerW * hoursPerDay * quantity / 1000;
  double get kwhMonth => kwhDay * 30;
}

class AppliancesStore extends ChangeNotifier {
  AppliancesStore._();
  static final AppliancesStore instance = AppliancesStore._();

  final List<ApplianceItemData> _items = [];
  List<ApplianceItemData> get items => List.unmodifiable(_items);

  void add(ApplianceItemData item) {
    _items.add(item);
    notifyListeners();
  }

  void update(String id, ApplianceItemData updated) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i != -1) {
      _items[i] = updated;
      notifyListeners();
    }
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
