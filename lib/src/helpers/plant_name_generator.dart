import 'dart:math';

final _adjectives = [
  'Blooming',
  'Lush',
  'Evergreen',
  'Thriving',
  'Vibrant',
  'Radiant',
  'Flourishing',
  'Verdant',
  'Bountiful',
  'Abundant',
];

final _nouns = [
  'Azalea',
  'Fern',
  'Maple',
  'Orchid',
  'Sunflower',
  'Lily',
  'Rose',
  'Daisy',
  'Poppy',
  'Jasmine',
];

String generateRandomPlantName() {
  final adjective = _adjectives[Random().nextInt(_adjectives.length)];
  final noun = _nouns[Random().nextInt(_nouns.length)];
  return '$adjective $noun';
}
