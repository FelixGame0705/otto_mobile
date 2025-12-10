import 'package:flutter_test/flutter_test.dart';
import 'package:ottobit/services/compiler_service.dart';

void main() {
  test('repeatRange with placeholder {{i}} compiles and appears in Python', () {
    final service = CompilerService();
    final result = service.compileFromJsonLike({
      'version': '1.0.0',
      'programName': 't',
      'actions': [
        {
          'type': 'repeatRange',
          'variable': 'i',
          'from': 0,
          'to': 5,
          'step': 1,
          'body': [
            {'type': 'forward', 'count': '{{i}}'},
          ]
        }
      ]
    });
    expect(result.program.actions.first['type'], 'repeatRange');
    expect(result.pythonPreview.contains('for i in range(0, 5, 1):'), true);
    expect(result.pythonPreview.contains('forward({{i}})'), true);
  });

  test('and/or conditions stringify', () {
    final service = CompilerService();
    final result = service.compileFromJsonLike({
      'version': '1.0.0',
      'programName': 't',
      'actions': [
        {
          'type': 'if',
          'cond': {
            'type': 'or',
            'conditions': [
              {
                'type': 'and',
                'conditions': [
                  {'type': 'condition', 'function': 'isGreen', 'check': true},
                  {'type': 'variableComparison', 'variable': 'i', 'operator': '>=', 'value': 3}
                ]
              },
              {
                'type': 'and',
                'conditions': [
                  {'type': 'condition', 'function': 'isYellow', 'check': true}
                ]
              }
            ]
          },
          'then': [
            {'type': 'forward', 'count': 1}
          ]
        }
      ]
    });
    expect(result.pythonPreview.contains('if (isGreen()) and (i >= 3) or (isYellow()):'), true);
  });
}


