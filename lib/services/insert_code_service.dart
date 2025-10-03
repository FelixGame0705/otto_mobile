import 'package:ottobit/core/services/storage_service.dart';
import 'package:ottobit/services/blockly_to_insertcode.dart';

class InsertCodeService {
  /// Build full main.py by inserting generated user route code into insertCode.py template
  static Future<String> buildMainPyFromLatestBlockly({String? wifiSsid, String? wifiPass, String? actionsRoomId}) async {
    final storage = ProgramStorageService();
    final program = await storage.loadFromPrefs();
    if (program == null) {
      throw Exception('No Blockly program found in storage');
    }
    // If challenge JSON attached, forward it
    final dynamic challenge = program['__challenge'];
    return BlocklyToInsertCode.generateFullScript(
      program,
      wifiSsid: wifiSsid,
      wifiPass: wifiPass,
      actionsRoomId: actionsRoomId,
      challengeJson: (challenge is Map<String, dynamic>) ? challenge : null,
    );
  }
}


