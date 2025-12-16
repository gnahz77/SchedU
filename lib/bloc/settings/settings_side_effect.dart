import 'package:equatable/equatable.dart';

abstract class SettingsSideEffectEvent extends Equatable {
  const SettingsSideEffectEvent();
  @override
  List<Object?> get props => [];
}

class SettingsNormalMessage extends SettingsSideEffectEvent {
  final String message;
  const SettingsNormalMessage(this.message);
  @override
  List<Object?> get props => [message];
}

class SettingsSuccessMessage extends SettingsSideEffectEvent {
  final String message;
  const SettingsSuccessMessage(this.message);
  @override
  List<Object?> get props => [message];
}

class SettingsErrorMessage extends SettingsSideEffectEvent {
  final String error;
  const SettingsErrorMessage(this.error);
  @override
  List<Object?> get props => [error];
}