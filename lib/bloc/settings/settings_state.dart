import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:schedu/model/app_settings.dart';
import 'package:schedu/model/section_time.dart';

class SettingsState extends Equatable {
  final bool loading;
  final AppSettings appSettings;

  const SettingsState({
    this.loading = false,
    this.appSettings = const AppSettings(),
  });

  SettingsState copyWith({
    bool? loading,
    AppSettings? appSettings,
  }) {
    return SettingsState(
      loading: loading ?? this.loading,
      appSettings: appSettings ?? this.appSettings,
    );
  }

  @override
  List<Object?> get props => [appSettings];
}
