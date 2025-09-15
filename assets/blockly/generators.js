(function(){
  const gens = {};

  function numFrom(block, name){
    const target = block.getInputTargetBlock(name);
    if (!target) return 0;
    if (target.type === 'math_number') return Number(target.getFieldValue('NUM'));
    if (target.type === 'batteryCount') return 'batteryCount';
    if (target.type === 'getNumberBox') return 'getNumberBox';
    if (target.type === 'warehouseCount') return 'warehouseCount';
    return 0;
  }

  function nodeStart(block){ return { type: 'start' }; }
  function nodeForward(block){ return { type: 'forward', count: numFrom(block, 'COUNT') }; }
  function nodeTurn(block){ return { type: block.getFieldValue('DIR') }; }
  function nodeCollect(block){ return { type: 'collect', color: block.getFieldValue('COLOR'), count: numFrom(block, 'COUNT') }; }
  function nodePut(block){ return { type: 'putBox', count: numFrom(block, 'COUNT') }; }
  function nodeTake(block){ return { type: 'takeBox', count: numFrom(block, 'COUNT') }; }
  function nodeRepeat(block){
    return { type: 'repeat', count: numFrom(block, 'COUNT'), body: statementToList(block, 'DO') };
  }
  function nodeRepeatRange(block){
    const variable = block.getFieldValue('VAR');
    return { type: 'repeatRange', variable, from: numFrom(block, 'FROM'), to: numFrom(block, 'TO'), step: numFrom(block, 'STEP'), body: statementToList(block, 'DO') };
  }
  function nodeIfColor(block){
    const func = block.getFieldValue('FUNC');
    return { type: 'if', cond: { type:'condition', function: func, check: true }, then: statementToList(block, 'THEN') };
  }
  function nodeWhileColor(block){
    const func = block.getFieldValue('FUNC');
    return { type: 'while', cond: { type:'condition', function: func, check: true }, body: statementToList(block, 'DO') };
  }

  function blockToNode(block){
    switch(block.type){
      case 'start': return nodeStart(block);
      case 'forward': return nodeForward(block);
      case 'turn': return nodeTurn(block);
      case 'collect': return nodeCollect(block);
      case 'put_box': return nodePut(block);
      case 'take_box': return nodeTake(block);
      case 'repeat_simple': return nodeRepeat(block);
      case 'repeat_range': return nodeRepeatRange(block);
      case 'if_color': return nodeIfColor(block);
      case 'while_color': return nodeWhileColor(block);
      default: return null;
    }
  }

  function statementToList(block, name){
    const target = block.getInputTargetBlock(name);
    const list = [];
    let cur = target;
    while (cur) {
      const node = blockToNode(cur);
      if (node) list.push(node);
      cur = cur.getNextBlock();
    }
    return list;
  }

  gens.toJSON = function(workspace){
    const topBlocks = workspace.getTopBlocks(true);
    const actions = [];
    for (const b of topBlocks) {
      const n = blockToNode(b);
      if (n) actions.push(n);
    }
    return { version: '1.0.0', programName: 'program', actions };
  };

  gens.toPython = function(workspace){
    const program = gens.toJSON(workspace);
    function pyVal(v){ return typeof v === 'string' ? v : JSON.stringify(v); }
    const lines = [];
    function emit(nodes, indent){
      const ind = '  '.repeat(indent);
      for (const n of nodes) {
        switch(n.type){
          case 'start': lines.push(ind + 'start()'); break;
          case 'forward': lines.push(ind + `forward(${pyVal(n.count)})`); break;
          case 'turnRight': lines.push(ind + 'turnRight()'); break;
          case 'turnLeft': lines.push(ind + 'turnLeft()'); break;
          case 'turnBack': lines.push(ind + 'turnBack()'); break;
          case 'collect': lines.push(ind + `collect(${pyVal(n.count)}, ${JSON.stringify(n.color)})`); break;
          case 'putBox': lines.push(ind + `putBox(${pyVal(n.count)})`); break;
          case 'takeBox': lines.push(ind + `takeBox(${pyVal(n.count)})`); break;
          case 'repeat':
            lines.push(ind + `for count in range(${pyVal(n.count)}):`);
            emit(n.body || [], indent + 1);
            break;
          case 'repeatRange':
            const v = n.variable || 'i';
            lines.push(ind + `for ${v} in range(${pyVal(n.from)}, ${pyVal(n.to)}, ${pyVal(n.step)}):`);
            emit(n.body || [], indent + 1);
            break;
          case 'if':
            lines.push(ind + 'if isGreen():');
            emit(n.then || [], indent + 1);
            break;
          case 'while':
            lines.push(ind + 'while isGreen():');
            emit(n.body || [], indent + 1);
            break;
        }
      }
    }
    emit(program.actions, 0);
    return lines.join('\n');
  };

  window.generators = gens;
})();


