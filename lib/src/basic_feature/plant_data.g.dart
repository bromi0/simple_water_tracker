// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlantData _$PlantDataFromJson(Map<String, dynamic> json) =>
    PlantData(
        name: json['name'] as String? ?? 'Unknown',
        waterLevel: (json['waterLevel'] as num?)?.toInt() ?? 100,
        color: json['color'] == null
            ? Colors.green
            : const ColorSerializer().fromJson((json['color'] as num).toInt()),
        wateringInterval: (json['wateringInterval'] as num?)?.toInt() ?? 3,
        wateringThreshold: (json['wateringThreshold'] as num?)?.toInt() ?? 35,
      )
      ..picturePath = json['picturePath'] as String?
      .._wateringHistory = (json['_wateringHistory'] as List<dynamic>)
          .map((e) => WateringRecord.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$PlantDataToJson(PlantData instance) => <String, dynamic>{
  'name': instance.name,
  'waterLevel': instance.waterLevel,
  'color': const ColorSerializer().toJson(instance.color),
  'wateringInterval': instance.wateringInterval,
  'picturePath': instance.picturePath,
  '_wateringHistory': instance._wateringHistory.map((e) => e.toJson()).toList(),
};

WateringRecord _$WateringRecordFromJson(Map<String, dynamic> json) =>
    WateringRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      previousWaterLevel: (json['previousWaterLevel'] as num).toInt(),
    );

Map<String, dynamic> _$WateringRecordToJson(WateringRecord instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'previousWaterLevel': instance.previousWaterLevel,
    };
