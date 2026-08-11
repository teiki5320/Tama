import 'package:flutter_test/flutter_test.dart';
import 'package:tama/core/theme.dart';

void main() {
  test('le thème applique les jetons Tama', () {
    final theme = buildTamaTheme();
    expect(theme.scaffoldBackgroundColor, TamaColors.background);
    expect(theme.colorScheme.primary, TamaColors.accent);
    expect(theme.colorScheme.surface, TamaColors.surface);
    expect(theme.colorScheme.onSurface, TamaColors.text);
  });
}
