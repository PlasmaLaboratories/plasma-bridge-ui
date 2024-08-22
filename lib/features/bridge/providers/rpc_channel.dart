import 'package:brambldart/brambldart.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rpc_channel.g.dart';

@riverpod
class RpcChannel extends _$RpcChannel {
  @override
  RpcChannelState build() {
    // TODO: User Provided
    final channel = makeChannel("localhost", 9094, false);
    return RpcChannelState(nodeRpcChannel: channel, genusRpcChannel: channel);
  }
}

class RpcChannelState {
  final ClientChannelBase nodeRpcChannel;
  final ClientChannelBase genusRpcChannel;

  RpcChannelState(
      {required this.nodeRpcChannel, required this.genusRpcChannel});
}
