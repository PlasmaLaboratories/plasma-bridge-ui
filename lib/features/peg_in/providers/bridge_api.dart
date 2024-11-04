import 'package:plasma_wallet/features/peg_in/logic/bridge_api_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bridge_api.g.dart';

@riverpod
class BridgeApi extends _$BridgeApi {
  @override
  BridgeApiInterface build() =>
      // TODO: Don't hardcode
      BridgeApiInterface(baseAddress: "http://localhost:5000");
}
