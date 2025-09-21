import 'package:flutter/material.dart';
import 'package:otto_mobile/services/microbit_ble_service.dart';

class MicrobitStatusWidget extends StatelessWidget {
  final MicrobitBleService bleService;
  final VoidCallback? onConnectPressed;
  final VoidCallback? onDisconnectPressed;

  const MicrobitStatusWidget({
    super.key,
    required this.bleService,
    this.onConnectPressed,
    this.onDisconnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: bleService.connectionStateStream,
      initialData: bleService.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isConnected ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: isConnected ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'micro:bit Connected' : 'micro:bit Disconnected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isConnected ? Colors.green[700] : Colors.red[700],
                ),
              ),
              if (isConnected && onDisconnectPressed != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDisconnectPressed,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red[700],
                  ),
                ),
              ] else if (!isConnected && onConnectPressed != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onConnectPressed,
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
