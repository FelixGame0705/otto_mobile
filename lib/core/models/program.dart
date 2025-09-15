import 'dart:convert';

import 'package:equatable/equatable.dart';

class Program extends Equatable {
  final String version;
  final String programName;
  final List<FunctionDef> functions;
  final List<Map<String, dynamic>> actions;

  const Program({
    required this.version,
    required this.programName,
    this.functions = const [],
    this.actions = const [],
  });

  Program copyWith({
    String? version,
    String? programName,
    List<FunctionDef>? functions,
    List<Map<String, dynamic>>? actions,
  }) => Program(
        version: version ?? this.version,
        programName: programName ?? this.programName,
        functions: functions ?? this.functions,
        actions: actions ?? this.actions,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'programName': programName,
        'functions': functions.map((f) => f.toJson()).toList(),
        'actions': actions,
      };

  String toJsonString({bool pretty = false}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  @override
  List<Object?> get props => [version, programName, functions, actions];
}

class FunctionDef extends Equatable {
  final String name;
  final List<Map<String, dynamic>> body;

  const FunctionDef({required this.name, this.body = const []});

  Map<String, dynamic> toJson() => {
        'name': name,
        'body': body,
      };

  @override
  List<Object?> get props => [name, body];
}


