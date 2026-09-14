// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsService _$SettingsServiceFromJson(Map<String, dynamic> json) =>
    SettingsService()
      .._localeTag = json['_localeTag'] as String?
      .._themeMode = $enumDecode(_$ThemeModeEnumMap, json['_themeMode'])
      .._plantListLayout =
          $enumDecodeNullable(
            _$PlantListLayoutEnumMap,
            json['_plantListLayout'],
          ) ??
          PlantListLayout.rows
      .._wateringStatusPresentation =
          $enumDecodeNullable(
            _$WateringStatusPresentationEnumMap,
            json['_wateringStatusPresentation'],
          ) ??
          WateringStatusPresentation.informative;

Map<String, dynamic> _$SettingsServiceToJson(SettingsService instance) =>
    <String, dynamic>{
      '_localeTag': instance._localeTag,
      '_themeMode': _$ThemeModeEnumMap[instance._themeMode]!,
      '_plantListLayout': _$PlantListLayoutEnumMap[instance._plantListLayout]!,
      '_wateringStatusPresentation':
          _$WateringStatusPresentationEnumMap[instance
              ._wateringStatusPresentation]!,
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

const _$WateringStatusPresentationEnumMap = {
  WateringStatusPresentation.simple: 'simple',
  WateringStatusPresentation.informative: 'informative',
};
