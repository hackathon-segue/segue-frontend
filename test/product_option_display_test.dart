import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/utils/product_option_display.dart';

void main() {
  test('product colors are displayed in English title case', () {
    expect(displayProductColor('오렌지 에이드'), 'Orange Aid');
    expect(displayProductColor('네이비'), 'Navy');
    expect(displayProductColor('다크브라운'), 'Dark Brown');
    expect(displayProductColor('카멜'), 'Camel');
    expect(displayProductColor('카키'), 'Khaki');
  });
}
