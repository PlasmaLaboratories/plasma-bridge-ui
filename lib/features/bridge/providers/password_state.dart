import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'password_state.g.dart';

@riverpod
class PasswordState extends _$PasswordState {
  @override
  String build() => "password";
}
