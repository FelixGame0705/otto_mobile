import 'dart:convert';
import 'dart:math';

class BlocklyToInsertCode {
  // Embedded insertCode.py template
  static const String _insertCodeTemplate = r'''
from microbit import *
import music

UART_BAUDRATE = 115200
UART_TX_PIN = pin14
UART_RX_PIN = pin13
WIFI_TIMEOUT_MS = 10000
RESPONSE_TIMEOUT_MS = 8000
RESPONSE_CHECK_INTERVAL = 50
MAX_RESPONSE_CHECKS = 40
WIFI_SSID = "Your WiFi SSID"
WIFI_PASS = "Your WiFi Password"

# Action queue to record steps: f,r,l,b and final v/d
ACTION_QUEUE = []

# Actions API (HTTPS) - Will be injected from environment
ACTIONS_API_HOST = "163.227.230.168"
ACTIONS_API_PORT = 3000
ACTIONS_API_PATH = "/sendActions"
ACTIONS_ROOM_ID = "room-199"

def append_action(code):
    try:
        # cap queue to last 64 items
        if len(ACTION_QUEUE) >= 64:
            del ACTION_QUEUE[0]
        ACTION_QUEUE.append(code)
    except:
        pass

def resp_has(resp, keys):
    try:
        for k in keys:
            if k in resp:
                return True
    except:
        pass
    return False

class Halt(Exception):
    pass

class Robot:
    MOTOR_DRIVER_ADDR = 0x08
    MPU6050_ADDR = 0x68
    GYRO_Z_REG = 0x47
    LINE_SENSOR_PIN = pin1
    M1A, M1B, M2A, M2B = 5, 6, 7, 8
    DEFAULT_GO_SPEED = 110
    DEFAULT_TURN_SPEED = 110
    LINE_THRESHOLD_ABOVE = 941
    LINE_THRESHOLD_NORMAL = 81

    def __init__(self):
        self.RA, self.MA = self.MOTOR_DRIVER_ADDR, self.MPU6050_ADDR
        self.MPG = self.GYRO_Z_REG
        self.LP = self.LINE_SENSOR_PIN
        self.gs, self.ts = self.DEFAULT_GO_SPEED, self.DEFAULT_TURN_SPEED
        self.TA, self.TN = self.LINE_THRESHOLD_ABOVE, self.LINE_THRESHOLD_NORMAL
        self.SP = (self.TA + self.TN) // 2
        self.kp = 0.12
        self.kd = 0.06
        self.max_corr = 70
        self.prev_lv = self.SP
        self.seek_overshoot = 8
        self.seek_timeout_ms = 1500
        self.seek_turn_speed = 110
        self.cross_overshoot_ms = 500
        self.cross_overshoot_speed = 80
        self.ca = 0.0
        self.go = 0.0
        self.init_mpu()
        self.stop()
        display.show(Image.HAPPY)
        sleep(500)

    def check_abort(self):
        if button_b.was_pressed():
            self.clear_all()
            display.show(Image.SKULL)
            sleep(500)
            reset()

    def wr(self, r, d):
        try:
            i2c.write(self.RA, bytes([r, d]))
        except:
            pass

    def rd(self, a):
        try:
            i2c.write(self.MA, bytes([a]))
            d = i2c.read(self.MA, 2)
            v = (d[0] << 8) + d[1]
            return -((65535 - v) + 1) if v >= 0x8000 else v
        except:
            return 0

    def init_mpu(self):
        try:
            i2c.write(self.MA, bytes([0x6B, 0]))
            sleep(100)
            total = 0
            for _ in range(20):
                total += self.rd(self.MPG) / 131.0
                sleep(10)
            self.go = total / 20.0
        except:
            pass

    def gyro(self):
        return self.rd(self.MPG) / 131.0 - self.go

    def _gyro_turn_to(self, target_angle, stop_fine_if_line=True, line_check_samples=3):
        direction = 1 if (target_angle - self.ca + 540) % 360 - 180 > 0 else -1
        st = running_time()
        lt = st
        a = self.ca
        while True:
            if button_b.was_pressed():
                self.clear_all()
                display.show(Image.SKULL)
                sleep(500)
                reset()
                
            ct = running_time()
            dt = (ct - lt) / 1000.0
            a += self.gyro() * dt
            while a > 180: a -= 360
            while a < -180: a += 360
            ae = target_angle - a
            if ae > 180: ae -= 360
            elif ae < -180: ae += 360

            if abs(ae) < 5:
                break

            ts = self.ts if abs(ae) > 30 else (75 if abs(ae) > 15 else 60)
            if direction > 0:
                self.motors(-ts, ts)
            else:
                self.motors(ts, -ts)

            lt = ct
            if (ct - st) > 3000:
                break
            sleep(10)
        self.stop()

        self.ca = a
 
    def line(self):
        return self.LP.read_analog()

    def motors(self, left, right):
        if left >= 0:
            self.wr(self.M1A, min(255, left))
            self.wr(self.M1B, 0)
        else:
            self.wr(self.M1A, 0)
            self.wr(self.M1B, min(255, -left))

        if right >= 0:
            self.wr(self.M2A, min(255, right))
            self.wr(self.M2B, 0)
        else:
            self.wr(self.M2A, 0)
            self.wr(self.M2B, min(255, -right))

    def stop(self):
        self.wr(self.M1A, 0)
        self.wr(self.M1B, 0)
        self.wr(self.M2A, 0)
        self.wr(self.M2B, 0)
        display.show(Image.SQUARE_SMALL)

    def emergency_stop(self):
        self.clear_all()
        display.show(Image.SKULL)
        sleep(500)
        reset()

    def clear_all(self):
        self.stop()
        self.ca = 0.0
        display.clear()
        sleep(100)

    def clamp(self, v, lo, hi):
        return lo if v < lo else (hi if v > hi else v)

    def follow_corr(self, lv):
        error = self.SP - lv
        dterm = (self.prev_lv - lv)
        corr = int(self.kp * error + self.kd * dterm)
        self.prev_lv = lv
        return self.clamp(corr, -self.max_corr, self.max_corr)

    def forward(self, timeout_ms=3000, speed=None, stop_on_cross=True):
        move_speed = self.gs if speed is None else int(speed)
        display.show(Image.ARROW_S)
        start = running_time()
        initial_on_cross = self.line() > self.TA
        cross_armed = (not stop_on_cross) or (not initial_on_cross)
        while True:
            if button_b.was_pressed():
                self.clear_all()
                display.show(Image.SKULL)
                sleep(500)
                reset()
            if (running_time() - start) > int(timeout_ms):
                break
            lv = self.line()
            if stop_on_cross and not cross_armed and lv <= self.TA:
                cross_armed = True
            if lv > self.TA:
                if stop_on_cross and cross_armed:
                    if self.cross_overshoot_ms > 0:
                        creep_spd = min(move_speed, self.cross_overshoot_speed)
                        self.motors(creep_spd, creep_spd)
                        sleep(self.cross_overshoot_ms)
                    self.stop()
                    sleep(60)
                    break
                self.motors(move_speed, move_speed)
                sleep(120)
                continue
            if lv > self.TN:
                corr = self.follow_corr(lv)
                L = self.clamp(move_speed - corr, 0, 255)
                R = self.clamp(move_speed + corr, 0, 255)
                self.motors(L, R)
            else:
                corr = self.follow_corr(lv)
                L = self.clamp(move_speed - corr, 0, 255)
                R = self.clamp(move_speed + corr, 0, 255)
                self.motors(L, R)
            sleep(10)
        self.stop()
        sleep(80)
        return True

    def turn_to_line(self, left=True, base_angle=90):
        if left:
            display.show(Image.ARROW_E)
        else:
            display.show(Image.ARROW_W)
        angle = base_angle if left else -base_angle
        ta = self.ca + (angle - self.seek_overshoot if angle > 0 else angle + self.seek_overshoot)
        while ta > 180: ta -= 360
        while ta < -180: ta += 360
        self._gyro_turn_to(ta, stop_fine_if_line=True, line_check_samples=3)

        st = running_time()
        ts = self.seek_turn_speed
        if left:
            self.motors(-ts, ts)
        else:
            self.motors(ts, -ts)

        while running_time() - st < self.seek_timeout_ms:
            if button_b.was_pressed():
                self.clear_all()
                display.show(Image.SKULL)
                sleep(500)
                reset()
                
            lv = self.line()
            if self.TN < lv < self.TA:
                break
            sleep(8)

        self.stop()
        return True


    def left(self):
        return self.turn_to_line(left=True, base_angle=90)

    def right(self):
        return self.turn_to_line(left=False, base_angle=90)

    def back(self):
        return self.turn_to_line(left=True, base_angle=180)

    def collect(self, n=1, color=None):
        col = str(color or "").lower()
        
        for _ in range(int(n)):
            c = _cell_counts()
            if c.get(col, 0) > 0:
                c[col] -= 1
                try:
                    _victory_collected[col] += 1
                    if col not in ("yellow", "green", "red", "blue"):
                        return
                    # Append action based on color
                    if col == "yellow":
                        append_action('collectYellow')
                    elif col == "red":
                        append_action('collectRed')
                    elif col == "blue":
                        append_action('collectBlue')
                    elif col == "green":
                        append_action('collectGreen')
                except:
                    pass
        for _ in range(int(n)):
            if button_b.was_pressed():
                self.emergency_stop()
                
            music.play(music.BA_DING, pin=pin0, wait=False)
            sleep(300)
        sleep(100)

    def start_sound(self):
        if button_b.was_pressed():
            self.emergency_stop()
            
        music.play(music.POWER_UP, pin=pin0, wait=False)
        sleep(500)

    def finish_sound(self):
        if button_b.was_pressed():
            self.emergency_stop()
            
        music.play(music.POWER_DOWN, pin=pin0, wait=False)
        sleep(500)

def run_route(r):
    def forward(n=1, timeout_ms=3000, speed=None, stop_on_cross=True):
        for _ in range(int(n)):
            append_action('forward')
            if not r.forward(timeout_ms=timeout_ms, speed=speed, stop_on_cross=stop_on_cross):
                return False
            dx, dy = _dir_to_delta(robot_state["dir"])
            robot_state["x"] += dx
            robot_state["y"] += dy
        return True

    def turnLeft(n=1):
        append_action('turnLeft')
        if not r.left():
            return False
        robot_state["dir"] = (robot_state["dir"] - 1) % 4
        return True

    def turnRight(n=1):
        append_action('turnRight')
        if not r.right():
            return False
        robot_state["dir"] = (robot_state["dir"] + 1) % 4
        return True

    def turnBack(n=1):
        append_action('turnBack')
        if not r.back():
            return False
        robot_state["dir"] = (robot_state["dir"] + 2) % 4
        return True

    def collect(n=1, color=None):
        r.collect(n, color)  # collect() will append the appropriate action
        return True

    def startSound():
        r.start_sound()
        return True

    def finishSound():
        r.finish_sound()
        return True

    user_route(forward, turnLeft, turnRight, turnBack, collect, startSound, finishSound)
    return True

challengeJson = {
    "robot": {"tile": {"x": 1, "y": 1}, "direction": "east"},
    "batteries": [{
        "tiles": [
            {"x": 3, "y": 1, "count": 1, "type": "yellow", "spread": 1.0, "allowedCollect": False}
        ]
    }],
    "victory": {"byType": [{"red": 0, "yellow": 2, "green": 0}]},
    "statement": ["forward", "collect"],
    "minCards": 2,
    "maxCards": 3
}

robot_state = {
    "x": challengeJson["robot"]["tile"]["x"],
    "y": challengeJson["robot"]["tile"]["y"],
    "dir": {"north":0, "east":1, "south":2, "west":3}.get(challengeJson["robot"]["direction"].lower(), 1)
}

_battery_map = {}
for group in challengeJson.get("batteries", []):
    for t in group.get("tiles", []):
        key = (t["x"], t["y"])
        entry = _battery_map.get(key, {"yellow":0, "red":0, "green":0, "allowed":True})
        col = t.get("type", "yellow")
        entry[col] = entry.get(col, 0) + int(t.get("count", 1))
        entry["allowed"] = bool(t.get("allowedCollect", True)) and entry.get("allowed", True)
        _battery_map[key] = entry

def _dir_to_delta(d):
    return [(0, -1), (1, 0), (0, 1), (-1, 0)][d % 4]

def _cell_counts():
    return _battery_map.get((robot_state["x"], robot_state["y"]), {"yellow":0, "red":0, "green":0, "allowed":True})

def isGreen():
    c = _cell_counts()
    return c.get("green", 0) > 0

def isYellow():
    c = _cell_counts()
    return c.get("yellow", 0) > 0

def isRed():
    c = _cell_counts()
    return c.get("red", 0) > 0

_victory_required = {"yellow":0, "red":0, "green":0}
for v in challengeJson.get("victory", {}).get("byType", []):
    for k in ("yellow", "red", "green"):
        try:
            _victory_required[k] += int(v.get(k, 0))
        except:
            pass
_victory_collected = {"yellow":0, "red":0, "green":0}

def _check_victory():
    return (
        _victory_collected["yellow"] == _victory_required["yellow"] and
        _victory_collected["red"] == _victory_required["red"] and
        _victory_collected["green"] == _victory_required["green"]
    )

def user_route(forward, turnLeft, turnRight, turnBack, collect, startSound, finishSound):
    startSound()

    forward(2)
    collect(1, "yellow") 
    
    forward(1)
    if _check_victory():
        display.show(Image.YES)
    else:
        display.show(Image.NO)
    finishSound()

class UARTComm:
    def __init__(self):
        uart.init(baudrate=UART_BAUDRATE, tx=UART_TX_PIN, rx=UART_RX_PIN)
    def clear_buffer(self):
        while uart.any():
            uart.read()
    def send_command(self, command):
        self.clear_buffer()
        uart.write(command)
        sleep(100)  # Wait 100ms for command to be sent
        return self._read_response()
    def _read_response(self):
        response = ""
        got_data = False
        for _ in range(MAX_RESPONSE_CHECKS):
            if uart.any():
                data = uart.read()
                if data:
                    got_data = True
                    try:
                        response += data.decode()
                    except:
                        pass
            sleep(RESPONSE_CHECK_INTERVAL)
        return response, got_data
    def send_line(self, line):
        self.clear_buffer()
        try:
            uart.write(line + "\r\n")
        except:
            uart.write(line)
            uart.write("\r\n")
        sleep(150)
        return self._read_response()
    def write_raw(self, data):
        try:
            if isinstance(data, str):
                uart.write(data)
            else:
                uart.write(bytes(data))
        except:
            pass
    def read_for(self, duration_ms=1500):
        response = ""
        end_t = running_time() + int(duration_ms)
        while running_time() < end_t:
            if uart.any():
                data = uart.read()
                if data:
                    try:
                        response += data.decode()
                    except:
                        pass
            sleep(20)
        return response
    
def handle_wifi_connection(timeout_ms=3000):
    display.show(Image.ALL_CLOCKS, loop=True, wait=False)
    # Check AT
    resp, _ = uart_comm.send_line("AT")
    if not resp_has(resp, ("OK",)):
        display.scroll("WIFI FAIL")
        display.show(Image.SAD)
        return False
    # Set station mode
    uart_comm.send_line("AT+CWMODE=1")
    # Already connected?
    resp, _ = uart_comm.send_line("AT+CWJAP?")
    if (WIFI_SSID in resp) and resp_has(resp, ("GOT IP", "OK")):
        display.scroll("WIFI OK")
        display.show(Image.HAPPY)
        return True
    # Join AP (short wait)
    display.scroll("JOIN AP")
    join_cmd = 'AT+CWJAP="{}","{}"'.format(WIFI_SSID, WIFI_PASS)
    resp, _ = uart_comm.send_line(join_cmd)
    resp += uart_comm.read_for(timeout_ms)
    if resp_has(resp, ("WIFI CONNECTED", "GOT IP", "OK")):
        display.scroll("WIFI OK")
        display.show(Image.HAPPY)
        return True
    else:
        display.scroll("WIFI FAIL")
        display.show(Image.SAD)
        return False

def send_actions_queue():
    display.show(Image.ALL_CLOCKS, loop=True, wait=False)
    actions_json = ('"' + '","'.join(ACTION_QUEUE) + '"') if len(ACTION_QUEUE) > 0 else ''
    body = '{"id":"' + ACTIONS_ROOM_ID + '","actions":[' + actions_json + ']}'
    req = (
        "POST {} HTTP/1.1\r\n".format(ACTIONS_API_PATH) +
        "Host: {}\r\n".format(ACTIONS_API_HOST) +
        "accept: */*\r\n" +
        "Content-Type: application/json\r\n" +
        "Content-Length: {}\r\n".format(len(body)) +
        "Connection: close\r\n\r\n" +
        body
    )
    # Open TLS connection (SSL)
    resp, _ = uart_comm.send_line('AT+CIPSTART="TCP","{}",{}'.format(ACTIONS_API_HOST, ACTIONS_API_PORT))
    resp += uart_comm.read_for(3000)
    if not resp_has(resp, ("CONNECT", "OK")):
        display.scroll("S FAIL")
        return False
    # Send request length
    resp, _ = uart_comm.send_line("AT+CIPSEND={}".format(len(req)))
    resp += uart_comm.read_for(1500)
    if not resp_has(resp, (">",)):
        display.scroll("S FAIL")
        uart_comm.send_line("AT+CIPCLOSE")
        return False
    # Send HTTP request
    uart_comm.write_raw(req)
    http_resp = uart_comm.read_for(3000)
    uart_comm.send_line("AT+CIPCLOSE")
    if resp_has(http_resp, ("HTTP/1.1",)):
        display.scroll("S OK")
        try:
            ACTION_QUEUE[:] = []
        except:
            pass
        return True
    display.scroll("S FAIL")
    return False

r = Robot()
uart_comm = UARTComm()
isConnected = handle_wifi_connection(20000)
if isConnected:
    display.scroll("READY")
else:
    display.scroll("NO WIFI")
while True:
    if button_a.was_pressed():
        if isConnected:
            run_route(r)
            display.clear()
            if len(ACTION_QUEUE) > 0:
                try:
                    send_actions_queue()
                except:
                    pass
        else:
            display.scroll("NO WIFI")
        
    elif button_b.was_pressed():
        isConnected = handle_wifi_connection(20000)
        if isConnected:
            display.scroll("READY")
        else:
            display.scroll("NO WIFI")
    sleep(100)
''';

  static String generateFullScript(
    Map<String, dynamic> programJson, {
    String? wifiSsid,
    String? wifiPass,
    String? actionsRoomId,
    Map<String, dynamic>? challengeJson,
  }) {
    final userRoute = generatePython(programJson);
    // Extract only the def user_route block from generated code
    final lines = userRoute.split('\n');
    final start = lines.indexWhere((l) => l.trimLeft().startsWith('def user_route('));
    if (start == -1) return _insertCodeTemplate; // fallback
    // Collect body lines with indentation
    final body = <String>[];
    for (int i = start + 1; i < lines.length; i++) {
      final l = lines[i];
      if (l.isEmpty) continue;
      final leading = l.length - l.trimLeft().length;
      if (leading < 4) break; // deindent => end of function
      body.add(l);
    }
    // Replace in template
    String template = _insertCodeTemplate;
    if (challengeJson != null && challengeJson.isNotEmpty) {
      // Replace default challengeJson block with API-provided one, converting booleans to Python case
      final challengePattern = RegExp(r"^challengeJson\s*=\s*\{[\s\S]*?^\}\n", multiLine: true);
      final jsonStr = jsonEncode(challengeJson);
      final pyStr = _jsonToPythonBoolean(jsonStr);
      final replacement = 'challengeJson = ' + pyStr + '\n\n';
      template = template.replaceFirst(challengePattern, replacement);
    }
    final tpl = template.split('\n');
    final defIdx = tpl.indexWhere((l) => l.trimLeft().startsWith('def user_route('));
    if (defIdx == -1) return _insertCodeTemplate + '\n\n' + userRoute;
    final result = <String>[];
    result.addAll(tpl.take(defIdx + 1));
    // Insert new body
    result.addAll(body);
    // Skip old body until we hit a blank line followed by next top-level or class/def
    int j = defIdx + 1;
    for (; j < tpl.length; j++) {
      final t = tpl[j];
      if (t.trimLeft().startsWith('class ') || t.trimLeft().startsWith('def ')) {
        break;
    }
    }
    if (j < tpl.length) result.addAll(tpl.skip(j));
    final script = result.join('\n');
    return _applyOverrides(script, wifiSsid: wifiSsid, wifiPass: wifiPass, actionsRoomId: actionsRoomId);
  }

  static String _applyOverrides(
    String script, {
    String? wifiSsid,
    String? wifiPass,
    String? actionsRoomId,
  }) {
    String s = script;
    if (wifiSsid != null && wifiSsid.isNotEmpty) {
      s = s.replaceAll(RegExp(r'^WIFI_SSID\s*=\s*".*?"', multiLine: true), 'WIFI_SSID = "' + wifiSsid.replaceAll('"', '\\"') + '"');
    }
    if (wifiPass != null && wifiPass.isNotEmpty) {
      s = s.replaceAll(RegExp(r'^WIFI_PASS\s*=\s*".*?"', multiLine: true), 'WIFI_PASS = "' + wifiPass.replaceAll('"', '\\"') + '"');
    }
    if (actionsRoomId != null && actionsRoomId.isNotEmpty) {
      s = s.replaceAll(RegExp(r'^ACTIONS_ROOM_ID\s*=\s*".*?"', multiLine: true), 'ACTIONS_ROOM_ID = "' + actionsRoomId.replaceAll('"', '\\"') + '"');
    }
    return s;
  }

  static String _jsonToPythonBoolean(String json) {
    // Convert true/false to True/False when not inside quotes
    String s = json;
    s = s.replaceAllMapped(RegExp(r'(?<![A-Za-z0-9_"])true(?![A-Za-z0-9_"])'), (_) => 'True');
    s = s.replaceAllMapped(RegExp(r'(?<![A-Za-z0-9_"])false(?![A-Za-z0-9_"])'), (_) => 'False');
    return s;
  }
  static String generatePython(Map<String, dynamic> programJson) {
    final StringBuffer out = StringBuffer();

    // Emit user-defined functions first
    final List functions = (programJson['functions'] as List?) ?? const [];
    for (final f in functions.whereType<Map<String, dynamic>>()) {
      final name = (f['name'] as String?)?.trim();
      final body = (f['body'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
      if (name == null || name.isEmpty) continue;
      out.writeln('def ' + name + '():');
      if (body.isEmpty) {
        out.writeln('    pass');
      } else {
        _emitNodes(out, body, indent: 1);
      }
      out.writeln();
    }

    // Emit main user route
    out.writeln('def user_route(forward, turnLeft, turnRight, turnBack, collect, startSound, finishSound):');
    out.writeln('    startSound()');
    final List actions = (programJson['actions'] as List?) ?? const [];
    if (actions.isEmpty) {
      out.writeln('    pass');
    } else {
      _emitNodes(out, actions.whereType<Map<String, dynamic>>().toList(), indent: 1);
    }
    out.writeln('    if _check_victory():');
    out.writeln('        display.show(Image.YES)');
    out.writeln('    else:');
    out.writeln('        display.show(Image.NO)');
    out.writeln('    finishSound()');
    return out.toString();
  }

  static void _emitNodes(StringBuffer out, List<Map<String, dynamic>> nodes, {required int indent}) {
    String ind(int n) => '    ' * n;
    for (final n in nodes) {
      final t = n['type'] as String?;
      switch (t) {
        case 'forward':
          out.writeln(ind(indent) + 'forward(' + _pyVal(n['count']) + ');');
          break;
        case 'turnRight':
          out.writeln(ind(indent) + 'turnRight();');
          break;
        case 'turnLeft':
          out.writeln(ind(indent) + 'turnLeft();');
          break;
        case 'turnBack':
          out.writeln(ind(indent) + 'turnBack();');
          break;
        case 'collect':
          final color = jsonEncode(n['color']);
          final count = _pyVal(n['count']);
          out.writeln(ind(indent) + 'collect(' + count +',' + color + ');');
          break;
        case 'putBox':
          out.writeln(ind(indent) + 'putBox(' + _pyVal(n['count']) + ');');
          break;
        case 'takeBox':
          out.writeln(ind(indent) + 'takeBox(' + _pyVal(n['count']) + ')');
          break;
        case 'repeat':
          out.writeln(ind(indent) + 'for _ in range(' + _pyVal(n['count']) + '):');
          _emitNodes(out, _list(n['body']), indent: indent + 1);
          break;
        case 'repeatRange':
          final v = (n['variable'] as String?)?.trim();
          final varName = (v == null || v.isEmpty) ? 'i' : v;
          // Use standard Python for-range for simplicity
          out.writeln(ind(indent) + 'for ' + varName + ' in range(' + _pyVal(n['from']) + ', ' + _pyVal(n['to']) + ', ' + _pyVal(n['step']) + '):');
          _emitNodes(out, _list(n['body']), indent: indent + 1);
          break;
        case 'if':
          out.writeln(ind(indent) + 'if ' + _emitCond(n['cond']) + ':');
          _emitNodes(out, _list(n['then']), indent: indent + 1);
          final elseBody = _list(n['else']);
          if (elseBody.isNotEmpty) {
            out.writeln(ind(indent) + 'else:');
            _emitNodes(out, elseBody, indent: indent + 1);
          }
          break;
        case 'if_else_if':
          final List conditions = (n['conditions'] as List?) ?? const [];
          final List thens = (n['thens'] as List?) ?? const [];
          if (conditions.isNotEmpty) {
            out.writeln(ind(indent) + 'if ' + _emitCond(conditions.first) + ':');
            _emitNodes(out, _toNodeList(thens.isNotEmpty ? thens.first : const []), indent: indent + 1);
            for (int i = 1; i < conditions.length; i++) {
              out.writeln(ind(indent) + 'elif ' + _emitCond(conditions[i]) + ':');
              _emitNodes(out, _toNodeList(i < thens.length ? thens[i] : const []), indent: indent + 1);
            }
            final elseBody = _list(n['else']);
            if (elseBody.isNotEmpty) {
              out.writeln(ind(indent) + 'else:');
              _emitNodes(out, elseBody, indent: indent + 1);
            }
          }
          break;
        case 'while':
          out.writeln(ind(indent) + 'while ' + _emitCond(n['cond']) + ':');
          _emitNodes(out, _list(n['body']), indent: indent + 1);
          break;
        case 'callFunction':
          final fn = (n['functionName'] as String?) ?? 'myFunction1';
          out.writeln(ind(indent) + fn + '()');
          break;
        default:
          out.writeln(ind(indent) + '# unknown: ' + jsonEncode(n));
      }
    }
  }

  static List<Map<String, dynamic>> _toNodeList(dynamic v) {
    if (v is List) {
      return v.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  static List<Map<String, dynamic>> _list(dynamic v) => _toNodeList(v);

  static String _pyVal(dynamic v) {
    if (v is String) return v;
    return jsonEncode(v);
  }

  static String _emitCond(dynamic cond) {
    if (cond is! Map<String, dynamic>) return 'False';
    final t = cond['type'];
    switch (t) {
      case 'condition':
        final fn = (cond['function'] as String?) ?? 'isGreen';
        final check = cond['check'] == true;
        return (check ? '' : 'not ') + fn + '()';
      case 'variableComparison':
        final v = cond['variable'] ?? 'x';
        final opRaw = (cond['operator'] as String?) ?? '==' ;
        final op = _mapOp(opRaw);
        final val = _pyVal(cond['value']);
        return '$v $op $val';
      case 'and':
        final List parts = (cond['conditions'] as List?) ?? const [];
        return parts.map((c) => '(' + _emitCond(c as Map<String, dynamic>) + ')').join(' and ');
      case 'or':
        final List parts = (cond['conditions'] as List?) ?? const [];
        return parts.map((c) => '(' + _emitCond(c as Map<String, dynamic>) + ')').join(' or ');
      default:
        return 'False';
    }
  }

  static String _mapOp(String op) {
    switch (op) {
      case 'EQ':
        return '==';
      case 'NEQ':
        return '!=';
      case 'LT':
        return '<';
      case 'GT':
        return '>';
      case 'LTE':
        return '<=';
      case 'GTE':
        return '>=';
      default:
        return op; // Assume already a Python operator
    }
  }

  /// Tạo room ID ngẫu nhiên cho Socket.IO (rút gọn)
  static String generateRoomId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999);
    // Chỉ lấy 4 chữ số cuối của timestamp để rút gọn (vì đã có "room-")
    final shortTimestamp = timestamp.toString().substring(timestamp.toString().length - 4);
    return 'room-$shortTimestamp$randomNum';
  }
}


