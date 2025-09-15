typedef JsonMap = Map<String, dynamic>;

abstract class CommandNode {
  JsonMap toJson();
}

class ForwardNode implements CommandNode {
  final dynamic count; // int or placeholder string like "{{i}}"
  ForwardNode(this.count);
  @override
  JsonMap toJson() => {'type': 'forward', 'count': count};
}

class TurnNode implements CommandNode {
  final String direction; // turnRight | turnLeft | turnBack
  TurnNode(this.direction);
  @override
  JsonMap toJson() => {'type': direction};
}

class CollectNode implements CommandNode {
  final String color; // green | yellow
  final dynamic count;
  CollectNode({required this.color, required this.count});
  @override
  JsonMap toJson() => {'type': 'collect', 'color': color, 'count': count};
}

class PutBoxNode implements CommandNode {
  final dynamic count;
  PutBoxNode(this.count);
  @override
  JsonMap toJson() => {'type': 'putBox', 'count': count};
}

class TakeBoxNode implements CommandNode {
  final dynamic count;
  TakeBoxNode(this.count);
  @override
  JsonMap toJson() => {'type': 'takeBox', 'count': count};
}

class RepeatNode implements CommandNode {
  final dynamic count;
  final List<JsonMap> body;
  RepeatNode({required this.count, required this.body});
  @override
  JsonMap toJson() => {'type': 'repeat', 'count': count, 'body': body};
}

class RepeatRangeNode implements CommandNode {
  final String variable;
  final dynamic from;
  final dynamic to;
  final dynamic step;
  final List<JsonMap> body;
  RepeatRangeNode({
    required this.variable,
    required this.from,
    required this.to,
    required this.step,
    required this.body,
  });
  @override
  JsonMap toJson() => {
        'type': 'repeatRange',
        'variable': variable,
        'from': from,
        'to': to,
        'step': step,
        'body': body,
      };
}

class IfNode implements CommandNode {
  final JsonMap cond;
  final List<JsonMap> thenBody;
  final List<JsonMap>? elseBody;
  IfNode({required this.cond, required this.thenBody, this.elseBody});
  @override
  JsonMap toJson() => {
        'type': 'if',
        'cond': cond,
        'then': thenBody,
        if (elseBody != null) 'else': elseBody,
      };
}

class WhileNode implements CommandNode {
  final JsonMap cond;
  final List<JsonMap> body;
  WhileNode({required this.cond, required this.body});
  @override
  JsonMap toJson() => {'type': 'while', 'cond': cond, 'body': body};
}

class CallFunctionNode implements CommandNode {
  final String functionName;
  CallFunctionNode(this.functionName);
  @override
  JsonMap toJson() => {'type': 'callFunction', 'functionName': functionName};
}

// Logic/conditions
JsonMap condition(String function, bool check) => {
      'type': 'condition',
      'function': function,
      'check': check,
    };

JsonMap variableComparison(String variable, String operator, dynamic value) => {
      'type': 'variableComparison',
      'variable': variable,
      'operator': operator,
      'value': value,
    };

JsonMap andConditions(List<JsonMap> conditions) => {
      'type': 'and',
      'conditions': conditions,
    };

JsonMap orConditions(List<JsonMap> conditions) => {
      'type': 'or',
      'conditions': conditions,
    };


