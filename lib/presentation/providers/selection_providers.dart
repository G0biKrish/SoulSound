import 'package:flutter_riverpod/flutter_riverpod.dart';

// State for whether selection mode is active
final isSelectionModeProvider = StateProvider<bool>((ref) => false);

// State for the set of selected song IDs
final selectedSongIdsProvider = StateProvider<Set<int>>((ref) => {});

// Helper notifier to manage selection logic easily
class SelectionNotifier extends StateNotifier<Set<int>> {
  SelectionNotifier(this.ref) : super({});

  final Ref ref;

  void toggleSelection(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
      if (state.isEmpty) {
        // Auto-exit mode if no items selected?
        // Optional: layout standard keeps mode until explicit exit or back.
        // User request didn't specify. Common pattern implies staying in mode or exiting.
        // We will keep mode active even if 0 selected, user might want to select others.
        // But if they unselect the last one manually, maybe keep it.
        // If they press a "Cancel" button (Back), then exit.
      }
    } else {
      state = {...state}..add(id);
    }
    ref.read(selectedSongIdsProvider.notifier).state = state;
  }

  void select(int id) {
    if (!state.contains(id)) {
      state = {...state, id};
      ref.read(selectedSongIdsProvider.notifier).state = state;
    }
  }

  void clear() {
    state = {};
    ref.read(selectedSongIdsProvider.notifier).state = {};
    ref.read(isSelectionModeProvider.notifier).state = false;
  }
}

final selectionManagerProvider =
    StateNotifierProvider<SelectionNotifier, Set<int>>((ref) {
  return SelectionNotifier(ref);
});
