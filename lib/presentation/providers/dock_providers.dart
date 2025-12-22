import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dock_item.dart';

final dockItemsProvider = StateNotifierProvider<DockItemsNotifier, List<DockItem>>((ref) {
  return DockItemsNotifier();
});

class DockItemsNotifier extends StateNotifier<List<DockItem>> {
  DockItemsNotifier() : super(_defaultDockItems) {
    _loadOrder();
  }

  static const List<DockItem> _defaultDockItems = [
    DockItem(
      originalIndex: 0,
      icon: Icons.music_note,
      label: 'Songs',
    ),
    DockItem(
      originalIndex: 1,
      icon: Icons.person,
      label: 'Artists',
    ),
    DockItem(
      originalIndex: 2,
      icon: Icons.album,
      label: 'Albums',
    ),
    DockItem(
      originalIndex: 3,
      icon: Icons.queue_music,
      label: 'Genres',
    ),
    DockItem(
      originalIndex: 4,
      icon: Icons.playlist_play,
      label: 'Playlists',
    ),
  ];

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = prefs.getString('dock_items_order');
    if (orderJson != null) {
      try {
        final List<dynamic> order = jsonDecode(orderJson);
        final orderedItems = order.map((index) {
          return _defaultDockItems.firstWhere(
            (item) => item.originalIndex == index,
            orElse: () => _defaultDockItems[index as int],
          );
        }).toList();
        state = orderedItems;
      } catch (e) {
        state = List.from(_defaultDockItems);
      }
    }
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = state.map((item) => item.originalIndex).toList();
    await prefs.setString('dock_items_order', jsonEncode(order));
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<DockItem>.from(state);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
    _saveOrder();
  }
}

