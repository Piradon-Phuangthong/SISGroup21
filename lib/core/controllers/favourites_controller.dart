import 'package:flutter/foundation.dart';

/// Simple in-memory favourites controller (singleton)
/// This manages favourite contact IDs and notifies listeners when changes occur
class FavouritesController extends ChangeNotifier {
  static final FavouritesController _instance = FavouritesController._internal();
  
  factory FavouritesController() {
    return _instance;
  }
  
  FavouritesController._internal();
  
  final Set<String> _favouriteContactIds = <String>{};
  
  /// Get all favourite contact IDs
  Set<String> get favouriteContactIds => Set.unmodifiable(_favouriteContactIds);
  
  /// Check if a contact is favourited
  bool isFavourite(String contactId) {
    return _favouriteContactIds.contains(contactId);
  }
  
  /// Toggle favourite status for a contact
  void toggleFavourite(String contactId) {
    if (_favouriteContactIds.contains(contactId)) {
      _favouriteContactIds.remove(contactId);
    } else {
      _favouriteContactIds.add(contactId);
    }
    notifyListeners();
  }
  
  /// Add a contact to favourites
  void addFavourite(String contactId) {
    if (!_favouriteContactIds.contains(contactId)) {
      _favouriteContactIds.add(contactId);
      notifyListeners();
    }
  }
  
  /// Remove a contact from favourites
  void removeFavourite(String contactId) {
    if (_favouriteContactIds.contains(contactId)) {
      _favouriteContactIds.remove(contactId);
      notifyListeners();
    }
  }
  
  /// Clear all favourites
  void clearAll() {
    _favouriteContactIds.clear();
    notifyListeners();
  }
}

