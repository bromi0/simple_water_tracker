// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlantData _$PlantDataFromJson(Map<String, dynamic> json) => PlantData(
      name: json['name'] as String? ?? 'Unknown',
      waterLevel: json['waterLevel'] as int? ?? 100,
      color: json['color'] == null
          ? Colors.green
          : const ColorSerializer().fromJson(json['color'] as int),
      wateringInterval: json['wateringInterval'] as int? ?? 7,
    )
      ..picturePath = json['picturePath'] as String?
      .._wateringHistory = (json['_wateringHistory'] as List<dynamic>)
          .map((e) => WateringRecord.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$PlantDataToJson(PlantData instance) => <String, dynamic>{
      'name': instance.name,
      'waterLevel': instance.waterLevel,
      'wateringInterval': instance.wateringInterval,
      'picturePath': instance.picturePath,
      '_wateringHistory':
          instance._wateringHistory.map((e) => e.toJson()).toList(),
    };

WateringRecord _$WateringRecordFromJson(Map<String, dynamic> json) =>
    WateringRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      previousWaterLevel: json['previousWaterLevel'] as int,
    );

Map<String, dynamic> _$WateringRecordToJson(WateringRecord instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'previousWaterLevel': instance.previousWaterLevel,
    };
