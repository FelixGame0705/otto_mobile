import 'dart:convert';

import 'package:ottobit/models/program.dart';

class CompileResult {
  final Program program;
  final String pythonPreview;
  const CompileResult({required this.program, required this.pythonPreview});
}

class CompilerService {
  static const String defaultVersion = '1.0.0';

  CompileResult compileFromJsonLike(Map<String, dynamic> jsonLike) {
    // Expect jsonLike already follows schema keys: version, programName, functions, actions
    final version = (jsonLike['version'] as String?) ?? defaultVersion;
    final programName = (jsonLike['programName'] as String?) ?? 'program';
    final List functionsRaw = (jsonLike['functions'] as List?) ?? const [];
    final List actionsRaw = (jsonLike['actions'] as List?) ?? const [];

    // Basic validation per rules
    _validateNodes(actionsRaw);
    for (final f in functionsRaw) {
      if (f is Map<String, dynamic>) {
        _validateNodes((f['body'] as List?) ?? const []);
      }
    }

    final program = Program(
      version: version,
      programName: programName,
      functions: functionsRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (m) => FunctionDef(
              name: m['name'] as String,
              body: (m['body'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [],
            ),
          )
          .toList(),
      actions: actionsRaw.whereType<Map<String, dynamic>>().toList(),
    );

    final python = _toPython(program);
    return CompileResult(program: program, pythonPreview: python);
  }

  void _validateNodes(List nodes) {
    for (final n in nodes) {
      if (n is! Map<String, dynamic>) continue;
      final type = n['type'];
      if (type == 'forward' || type == 'collect' || type == 'putBox' || type == 'takeBox' || type == 'repeat') {
        final count = n['count'];
        if (!_isCountValid(count)) {
          throw ArgumentError('Invalid count: $count');
        }
        if (type == 'collect') {
          final color = n['color'];
          if (color != 'green' && color != 'yellow') {
            throw ArgumentError('Invalid color: $color');
          }
        }
      } else if (type == 'repeatRange') {
        final step = n['step'];
        if (step is num && step == 0) {
          throw ArgumentError('repeatRange.step must not be 0');
        }
      }

      // Recurse into bodies
      if (n['body'] is List) _validateNodes(n['body'] as List);
      if (n['then'] is List) _validateNodes(n['then'] as List);
      if (n['else'] is List) _validateNodes(n['else'] as List);
      if (n['conditions'] is List) {
        for (final c in (n['conditions'] as List)) {
          if (c is Map<String, dynamic>) {
            if (c['conditions'] is List) _validateNodes(c['conditions'] as List);
          }
        }
      }
    }
  }

  bool _isCountValid(dynamic count) {
    if (count == null) return false;
    if (count is num) return count >= 0;
    if (count is String) return RegExp(r'^\{\{[a-zA-Z_]\w*\}\}$').hasMatch(count);
    return false;
  }

  String _toPython(Program p) {
    final b = StringBuffer();
    for (final f in p.functions) {
      b.writeln('def ${f.name}():');
      if (f.body.isEmpty) {
        b.writeln('    pass');
      } else {
        _emitPythonNodes(b, f.body, indent: 1);
      }
      b.writeln();
    }
    _emitPythonNodes(b, p.actions, indent: 0);
    return b.toString();
  }

  void _emitPythonNodes(StringBuffer b, List<Map<String, dynamic>> nodes, {required int indent}) {
    String ind(int n) => '  ' * n;
    for (final n in nodes) {
      final type = n['type'];
      switch (type) {
        case 'forward':
          b.writeln(ind(indent) + 'forward(${_pyVal(n['count'])})');
          break;
        case 'turnRight':
          b.writeln(ind(indent) + 'turnRight()');
          break;
        case 'turnLeft':
          b.writeln(ind(indent) + 'turnLeft()');
          break;
        case 'turnBack':
          b.writeln(ind(indent) + 'turnBack()');
          break;
        case 'collect':
          b.writeln(ind(indent) + 'collect(${_pyVal(n['count'])}, ${jsonEncode(n['color'])})');
          break;
        case 'putBox':
          b.writeln(ind(indent) + 'putBox(${_pyVal(n['count'])})');
          break;
        case 'takeBox':
          b.writeln(ind(indent) + 'takeBox(${_pyVal(n['count'])})');
          break;
        case 'repeat':
          b.writeln(ind(indent) + 'for count in range(${_pyVal(n['count'])}):');
          _emitPythonNodes(b, (n['body'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [], indent: indent + 1);
          break;
        case 'repeatRange':
          final v = n['variable'] ?? 'i';
          b
            ..write(ind(indent))
            ..write('for ')
            ..write('$v')
            ..writeln(' in range(${_pyVal(n['from'])}, ${_pyVal(n['to'])}, ${_pyVal(n['step'])}):');
          _emitPythonNodes(b, (n['body'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [], indent: indent + 1);
          break;
        case 'if':
          b.writeln(ind(indent) + 'if ${_emitCondition(n['cond'])}:');
          _emitPythonNodes(b, (n['then'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [], indent: indent + 1);
          final elseBody = (n['else'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
          if (elseBody.isNotEmpty) {
            b.writeln(ind(indent) + 'else:');
            _emitPythonNodes(b, elseBody, indent: indent + 1);
          }
          break;
        case 'while':
          b.writeln(ind(indent) + 'while ${_emitCondition(n['cond'])}:');
          _emitPythonNodes(b, (n['body'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [], indent: indent + 1);
          break;
        case 'callFunction':
          b.writeln(ind(indent) + (n['functionName'] as String) + '()');
          break;
        default:
          // Unknown node -> comment for visibility
          b.writeln(ind(indent) + '# unknown: ' + jsonEncode(n));
      }
    }
  }

  String _emitCondition(dynamic cond) {
    if (cond is! Map<String, dynamic>) return 'False';
    final type = cond['type'];
    switch (type) {
      case 'condition':
        final fn = cond['function'];
        final check = cond['check'] == true;
        return (check ? '' : 'not ') + (fn as String) + '()';
      case 'variableComparison':
        final v = cond['variable'];
        final op = cond['operator'];
        final val = _pyVal(cond['value']);
        return '$v $op $val';
      case 'and':
        final List parts = (cond['conditions'] as List?) ?? const [];
        return parts.map((c) => '(' + _emitCondition(c as Map<String, dynamic>) + ')').join(' and ');
      case 'or':
        final List parts = (cond['conditions'] as List?) ?? const [];
        return parts.map((c) => '(' + _emitCondition(c as Map<String, dynamic>) + ')').join(' or ');
      default:
        return 'False';
    }
  }

  String _pyVal(dynamic v) {
    if (v is String) return v; // may be placeholder like {{i}} or token
    return jsonEncode(v);
  }

  static Map<String, dynamic> sampleProgram() => {
        'version': '1.0.0',
        'programName': 'move_5_steps_turn_right_demo',
        'actions': [
          {'type': 'forward', 'count': 5},
          {'type': 'turnRight'},
          {'type': 'forward', 'count': 5},
          {'type': 'turnRight'},
          {'type': 'forward', 'count': 5},
          {'type': 'collect', 'color': 'yellow', 'count': 1},
        ],
      };
}

