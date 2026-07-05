/// Règles de capacité communes aux créneaux (menus et événements).
mixin SlotCapacity {
  int get capacity;
  int get reservedCount;

  int get remainingSpots => capacity - reservedCount;

  bool get isFull => remainingSpots <= 0;

  /// « Bientôt complet » : remplissage ≥ 90 %.
  bool get isAlmostFull => capacity > 0 && reservedCount / capacity >= 0.9;
}
