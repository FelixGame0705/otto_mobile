(function(){
  const C = Blockly;

  // Basic blocks
// Khai báo block "start" (màu vàng, gọn gàng, có tooltip, top-level only, single instance)
C.Blocks['start'] = {
  init: function () {
    this.appendDummyInput()
        .appendField('▶︎ Start'); // nhấn mạnh bắt đầu
    this.setPreviousStatement(false);        // không cho nối phía trên
    this.setNextStatement(true, null);       // cho phép nối phía dưới
    this.setInputsInline(true);              // bố cục gọn
    this.setColour(60);                      // vàng (hue ~60)
    this.setTooltip('Điểm bắt đầu của chương trình. Kết nối các khối ở phía dưới để chạy.');
    this.setHelpUrl('https://developers.google.com/blockly'); // có thể thay link docs riêng của bạn
  },

  onchange: function (e) {
    if (!this.workspace || this.isInFlyout) return;

    // 1) Đảm bảo luôn là top-level (không được gắn dưới block khác)
    if (this.getParent()) {
      this.unplug(false);     // tự tách khỏi parent nếu lỡ gắn vào
      this.bumpNeighbours();  // đẩy ra nhẹ để tránh chồng lấn
    }

    // 2) Đảm bảo chỉ có 1 block "start" trong workspace
    const allStarts = this.workspace.getAllBlocks(false).filter(b => b.type === 'start');
    if (allStarts.length > 1) {
      // Giữ lại block được tạo trước; xóa block mới hơn
      const oldest = allStarts.reduce((a, b) => (a.id < b.id ? a : b));
      if (this !== oldest) this.dispose(false);
    }
  }
};


  C.Blocks['forward'] = {
    init: function() {
      this.appendDummyInput().appendField('move forward');
      this.appendValueInput('COUNT').setCheck('Number').appendField('steps');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(160);
    }
  };

  C.Blocks['turn'] = {
    init: function() {
      this.appendDummyInput().appendField('turn')
        .appendField(new C.FieldDropdown([['right','turnRight'],['left','turnLeft'],['back','turnBack']]), 'DIR');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(160);
    }
  };

  C.Blocks['collect'] = {
    init: function () {
      // Hàng 1: tiêu đề + count (FieldNumber có sẵn)
      this.appendDummyInput()
          .appendField('collect')
          .appendField(new C.FieldNumber(1, 0, 999, 1), 'COUNT'); 
          // mặc định = 1, min=0, max=999, step=1 (bạn chỉnh theo ý)
  
      // Hàng 2: chọn màu
      this.appendDummyInput()
          .appendField(new C.FieldDropdown([
            ['green','green'],
            ['yellow','yellow']
          ]), 'COLOR');
  
      this.setInputsInline(true);
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
      this.setTooltip('Collect N items of a chosen color');
      this.setHelpUrl('');
    }
  };

  C.Blocks['repeat_simple'] = {
    init: function(){
      this.appendValueInput('COUNT').setCheck('Number').appendField('repeat');
      this.appendStatementInput('DO').appendField('do');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
    }
  };

  C.Blocks['repeat_range'] = {
    init: function(){
      this.appendDummyInput()
        .appendField('for')
        .appendField(new C.FieldDropdown([['i','i'],['a','a'],['b','b']]), 'VAR')
        .appendField('in range(');
      this.appendValueInput('FROM').setCheck('Number');
      this.appendDummyInput().appendField(',');
      this.appendValueInput('TO').setCheck('Number');
      this.appendDummyInput().appendField(',');
      this.appendValueInput('STEP').setCheck('Number');
      this.appendDummyInput().appendField(')');
      this.appendStatementInput('DO').appendField('do');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
    }
  };

  C.Blocks['if_color'] = {
    init: function(){
      this.appendDummyInput().appendField('if is')
        .appendField(new C.FieldDropdown([['green','isGreen'],['red','isRed'],['yellow','isYellow']]), 'FUNC');
      this.appendStatementInput('THEN').appendField('then');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(210);
    }
  };

  C.Blocks['while_color'] = {
    init: function(){
      this.appendDummyInput().appendField('while is')
        .appendField(new C.FieldDropdown([['green','isGreen'],['red','isRed'],['yellow','isYellow']]), 'FUNC');
      this.appendStatementInput('DO').appendField('do');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(210);
    }
  };

  C.Blocks['put_box'] = {
    init: function(){
      this.appendDummyInput().appendField('put box');
      this.appendValueInput('COUNT').setCheck('Number').appendField('count');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
    }
  };

  C.Blocks['take_box'] = {
    init: function(){
      this.appendDummyInput().appendField('take box');
      this.appendValueInput('COUNT').setCheck('Number').appendField('count');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
    }
  };

  // Simple math/variables helpers
  C.Blocks['batteryCount'] = {
    init: function(){ this.appendDummyInput().appendField('batteryCount'); this.setOutput(true, 'Number'); this.setColour(230); }
  };
  C.Blocks['getNumberBox'] = {
    init: function(){ this.appendDummyInput().appendField('getNumberBox'); this.setOutput(true, 'Number'); this.setColour(230); }
  };
  C.Blocks['warehouseCount'] = {
    init: function(){ this.appendDummyInput().appendField('warehouseCount'); this.setOutput(true, 'Number'); this.setColour(230); }
  };

  // Attach minimal toolbox content
  const toolbox = document.getElementById('toolbox');
  if (toolbox) {
    toolbox.innerHTML = `
<xml xmlns="https://developers.google.com/blockly/xml">
  <category name="Robot" colour="#a55">
    <block type="forward"></block>
    <block type="turn"></block>
    <block type="collect"></block>
    <block type="put_box"></block>
    <block type="take_box"></block>
  </category>
  <category name="Control" colour="#5ba55b">
    <block type="repeat_simple"></block>
    <block type="repeat_range"></block>
    <block type="if_color"></block>
    <block type="while_color"></block>
  </category>
  <category name="Sensors/Expr" colour="#5b80a5">
    <block type="batteryCount"></block>
    <block type="getNumberBox"></block>
    <block type="warehouseCount"></block>
    <block type="math_number"></block>
  </category>
</xml>`;
  }
})();


