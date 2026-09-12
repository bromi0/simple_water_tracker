// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsService _$SettingsServiceFromJson(Map<String, dynamic> json) =>
    SettingsService()
      .._themeMode = $enumDecode(_$ThemeModeEnumMap, json['_themeMode'])
      .._plantListLayout =
          $enumDecodeNullable(
            _$PlantListLayoutEnumMap,
            json['_plantListLayout'],
          ) ??
          PlantListLayout.rows;

Map<String, dynamic> _$SettingsServiceToJson(SettingsService instance) =>
    <String, dynamic>{
      '_themeMode': _$ThemeModeEnumMap[instance._themeMode]!,
      '_plantListLayout': _$PlantListLayoutEnumMap[instance._plantListLayout]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$PlantListLayoutEnumMap = {
  PlantListLayout.rows: 'rows',
  PlantListLayout.grid: 'grid',
};
