import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_providers.dart';

class ColorSet {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;

  const ColorSet({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

// Predefined elegant color sets
final List<ColorSet> colorSets = [
  const ColorSet(
    name: 'Deep Purple',
    primaryColor: Color(0xFF673AB7),
    secondaryColor: Color(0xFF03DAC6),
  ),
  const ColorSet(
    name: 'Ocean Blue',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF00BCD4),
  ),
  const ColorSet(
    name: 'Forest Green',
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF8BC34A),
  ),
  const ColorSet(
    name: 'Sunset Orange',
    primaryColor: Color(0xFFFF9800),
    secondaryColor: Color(0xFFFFC107),
  ),
  const ColorSet(
    name: 'Rose Pink',
    primaryColor: Color(0xFFE91E63),
    secondaryColor: Color(0xFFF06292),
  ),
  const ColorSet(
    name: 'Royal Purple',
    primaryColor: Color(0xFF9C27B0),
    secondaryColor: Color(0xFFBA68C8),
  ),
  const ColorSet(
    name: 'Teal Cyan',
    primaryColor: Color(0xFF009688),
    secondaryColor: Color(0xFF4DD0E1),
  ),
  const ColorSet(
    name: 'Amber Gold',
    primaryColor: Color(0xFFFFC107),
    secondaryColor: Color(0xFFFFD54F),
  ),
  const ColorSet(
    name: 'Indigo Blue',
    primaryColor: Color(0xFF3F51B5),
    secondaryColor: Color(0xFF7986CB),
  ),
  const ColorSet(
    name: 'Crimson Red',
    primaryColor: Color(0xFFD32F2F),
    secondaryColor: Color(0xFFEF5350),
  ),
  const ColorSet(
    name: 'Emerald Green',
    primaryColor: Color(0xFF00C853),
    secondaryColor: Color(0xFF69F0AE),
  ),
  const ColorSet(
    name: 'Violet Purple',
    primaryColor: Color(0xFF7B1FA2),
    secondaryColor: Color(0xFFAB47BC),
  ),
];

Future<void> showThemeColorPaletteDialog(BuildContext context, WidgetRef ref) async {
  final themeState = ref.read(themeProvider);
  final themeNotifier = ref.read(themeProvider.notifier);

  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      ColorSet? selectedSet;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Choose Theme Colors'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a color set that matches your style',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: colorSets.length,
                      itemBuilder: (context, index) {
                        final colorSet = colorSets[index];
                        final isSelected = selectedSet == colorSet;
                        final isCurrentSet = colorSet.primaryColor ==
                                themeState.primaryColor &&
                            colorSet.secondaryColor ==
                                themeState.secondaryColor;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedSet = colorSet;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : isCurrentSet
                                        ? Theme.of(context).colorScheme.secondary
                                        : Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.3),
                                width: isSelected ? 3 : isCurrentSet ? 2 : 1,
                              ),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Color preview
                                Container(
                                  height: 40,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        colorSet.primaryColor,
                                        colorSet.secondaryColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                // Color name
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    colorSet.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentSet)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedSet == null
                    ? null
                    : () async {
                        Navigator.of(dialogContext).pop();
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (confirmContext) => AlertDialog(
                            title: const Text('Apply Theme'),
                            content: Text(
                              'Apply "${selectedSet!.name}" color theme?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(confirmContext).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(confirmContext).pop(true),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          await themeNotifier.setPrimaryColor(
                            selectedSet!.primaryColor,
                          );
                          await themeNotifier.setSecondaryColor(
                            selectedSet!.secondaryColor,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Theme "${selectedSet!.name}" applied',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Select'),
              ),
            ],
          );
        },
      );
    },
  );
}

