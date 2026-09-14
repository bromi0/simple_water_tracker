// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String wateringNotificationTitle(String plantName) {
    return 'Water $plantName';
  }

  @override
  String get wateringNotificationBody => 'Your plant needs water.';

  @override
  String get testNotificationTitle => 'Watering reminder test';

  @override
  String get testNotificationBody => 'Notifications are working.';

  @override
  String get notificationChannelName => 'Watering reminders';

  @override
  String get notificationChannelDescription =>
      'Reminders to water your plants.';

  @override
  String get appTitle => 'Simply Water Plant';

  @override
  String get roomSuggestionLivingRoom => 'Living room';

  @override
  String get roomSuggestionBedroom => 'Bedroom';

  @override
  String get roomSuggestionKitchen => 'Kitchen';

  @override
  String get roomSuggestionDiningRoom => 'Dining room';

  @override
  String get roomSuggestionOffice => 'Office';

  @override
  String get roomSuggestionBalcony => 'Balcony';

  @override
  String get roomSuggestionHallway => 'Hallway';

  @override
  String get roomSuggestionPatio => 'Patio';

  @override
  String get roomSuggestionTerrace => 'Terrace';

  @override
  String get roomSuggestionPorch => 'Porch';

  @override
  String get roomSuggestionGarden => 'Garden';

  @override
  String get roomSuggestionGreenhouse => 'Greenhouse';

  @override
  String get roomSuggestionYard => 'Yard';

  @override
  String get settings => 'Settings';

  @override
  String get useGrid => 'Use two-column view';

  @override
  String get useRows => 'Use one-column view';

  @override
  String get wateringSchedule => 'Watering schedule';

  @override
  String get rooms => 'Rooms';

  @override
  String get addPlant => 'Add plant';

  @override
  String get plants => 'Plants';

  @override
  String get noRoom => 'No room';

  @override
  String get showPlants => 'Show plants';

  @override
  String get allPlants => 'All plants';

  @override
  String get manageRooms => 'Manage rooms';

  @override
  String get noPlantsYet => 'No plants yet';

  @override
  String get noPlantsHelp =>
      'Add your first plant to start tracking its watering.';

  @override
  String get noPlantsInRoomHelp =>
      'Add a plant or move one here from its editor.';

  @override
  String get chooseGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get photoSelectionFailed => 'Could not select that photo.';

  @override
  String get plantNameRequired => 'Enter a plant name.';

  @override
  String get plantSaveFailed => 'Could not save this plant.';

  @override
  String get deletePlantTitle => 'Delete plant?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get editPlant => 'Edit plant';

  @override
  String get deletePlant => 'Delete plant';

  @override
  String get plantName => 'Plant name';

  @override
  String get watering => 'Watering';

  @override
  String get decreaseWateringInterval => 'Decrease watering interval';

  @override
  String get increaseWateringInterval => 'Increase watering interval';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get photoUnavailable => 'Photo unavailable';

  @override
  String get wateringWeek => 'Watering week';

  @override
  String get testNotificationTooltip => 'Test notification in one minute';

  @override
  String get noReminders => 'No plants to remind you about.';

  @override
  String get testReminderScheduled =>
      'Test reminder scheduled for one minute from now.';

  @override
  String get notificationsOff =>
      'Notifications are off or unavailable. Check notification settings.';

  @override
  String get testReminderFailed =>
      'Could not schedule a test reminder. Try again.';

  @override
  String get today => 'Today';

  @override
  String get itemDetails => 'Item Details';

  @override
  String get moreInformation => 'More Information Here';

  @override
  String get pictureCaptureFailed => 'Could not take the picture. Try again.';

  @override
  String get plantAddFailed => 'Could not add this plant.';

  @override
  String get photoYourPlant => 'Photo your plant';

  @override
  String get plantNameSuggestionHelp => 'Leave blank to use this suggestion.';

  @override
  String get takingPicture => 'Taking picture...';

  @override
  String get cameraPermissionDenied => 'Camera permission denied';

  @override
  String get cameraPermissionRequired => 'Camera permission required';

  @override
  String get cameraUnavailable => 'Camera access unavailable';

  @override
  String get noCamera => 'No camera available';

  @override
  String get addWithoutPhoto => 'Add without photo';

  @override
  String get useCamera => 'Use camera';

  @override
  String get retryCamera => 'Retry camera';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get displayPicture => 'Display the Picture';

  @override
  String get room => 'Room';

  @override
  String get chooseRoom => 'Choose room';

  @override
  String get createRoom => 'Create room';

  @override
  String get roomReorderFailed => 'Could not reorder rooms.';

  @override
  String get suggestedPlaces => 'Suggested places';

  @override
  String get roomsHelp =>
      'Rooms are optional. Add a suggested place or create your own.';

  @override
  String get roomSaveFailed => 'Could not save this room.';

  @override
  String get renameRoom => 'Rename room';

  @override
  String get roomName => 'Room name';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get roomNameRequired => 'Enter a room name.';

  @override
  String get roomNameDuplicate => 'A room with that name already exists.';

  @override
  String get roomWillBeRemoved => 'This room will be removed.';

  @override
  String get roomDeleteFailed => 'Could not delete this room.';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get wateringStatus => 'Watering status';

  @override
  String get wateringStatusHelp =>
      'Choose whether plant cards include an estimated watering time.';

  @override
  String get simpleStatus => 'Simple';

  @override
  String get informativeStatus => 'Informative';

  @override
  String get notificationsEnabledDescription =>
      'Allowed by Android for watering notifications.';

  @override
  String get notificationsRequestableDescription =>
      'Notifications are off. Allow reminders when your plants need water.';

  @override
  String get notificationsSettingsRequiredDescription =>
      'Notifications are off. Enable them in Android settings.';

  @override
  String get notificationsChannelBlockedDescription =>
      'The watering notification category is off. Enable it in Android settings.';

  @override
  String get notificationsUnsupportedDescription =>
      'Notifications are currently available on Android only.';

  @override
  String get checkingNotificationSettings => 'Checking notification settings…';

  @override
  String get notifications => 'Notifications';

  @override
  String get retry => 'Retry';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get openNotificationSettings => 'Open Android notification settings';

  @override
  String get reminderUpdateFailed => 'Could not update reminders. Try again.';

  @override
  String get notificationSettingsReadFailed =>
      'Could not read notification settings. Try again.';

  @override
  String get androidSettingsOpenFailed => 'Could not open Android settings.';

  @override
  String get doingWell => 'Doing well';

  @override
  String get waterSoon => 'Water soon';

  @override
  String get needsWater => 'Needs water';

  @override
  String get waterNow => 'Water now';

  @override
  String get cameraUnavailableHelp =>
      'The camera may be unavailable or permission may have been denied.\nYou can still add this plant without a photo.';

  @override
  String roomFilterSemantics(String roomName) {
    return 'Room filter, $roomName, change room';
  }

  @override
  String roomAssignmentSemantics(String roomName) {
    return 'Room, $roomName, change room';
  }

  @override
  String noPlantsInRoom(String roomName) {
    return 'No plants in $roomName';
  }

  @override
  String waterPlant(String plantName) {
    return 'Water $plantName';
  }

  @override
  String undoWaterPlant(String plantName) {
    return 'Undo watering for $plantName';
  }

  @override
  String editNamedPlant(String plantName) {
    return 'Edit $plantName';
  }

  @override
  String noPlantPhoto(String plantName) {
    return 'No photo for $plantName';
  }

  @override
  String plantDeleteConfirmation(String plantName) {
    return '$plantName and its watering history will be removed.';
  }

  @override
  String wateringInterval(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Every $daysString days',
      one: 'Every $daysString day',
    );
    return '$_temp0';
  }

  @override
  String waterEveryDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Water every $daysString days',
      one: 'Water every $daysString day',
    );
    return '$_temp0';
  }

  @override
  String dayCount(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days',
      one: '$daysString day',
    );
    return '$_temp0';
  }

  @override
  String wateringStatusSemantics(String status) {
    return 'Watering status: $status';
  }

  @override
  String namedWateringStatus(String plantName, String status) {
    return '$plantName, $status';
  }

  @override
  String roomAddFailed(String roomName) {
    return 'Could not add $roomName.';
  }

  @override
  String plantCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString plants',
      one: '$countString plant',
    );
    return '$_temp0';
  }

  @override
  String deleteNamedRoom(String roomName) {
    return 'Delete $roomName';
  }

  @override
  String roomDeleteTitle(String roomName) {
    return 'Delete $roomName?';
  }

  @override
  String roomPlantsKept(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString plants will be kept without a room.',
      one: '$countString plant will be kept without a room.',
    );
    return '$_temp0';
  }

  @override
  String waterInHours(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Water in ~$hoursString h',
      one: 'Water in ~$hoursString h',
    );
    return '$_temp0';
  }

  @override
  String waterInDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Water in ~$daysString days',
      one: 'Water in ~$daysString day',
    );
    return '$_temp0';
  }

  @override
  String waterInHoursCompact(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '~${hoursString}h';
  }

  @override
  String waterInDaysCompact(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '~${daysString}d';
  }

  @override
  String waterInHoursSpoken(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Water in approximately $hoursString hours',
      one: 'Water in approximately $hoursString hour',
    );
    return '$_temp0';
  }

  @override
  String waterInDaysSpoken(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Water in approximately $daysString days',
      one: 'Water in approximately $daysString day',
    );
    return '$_temp0';
  }

  @override
  String wateringStatusWithEstimate(String status, String estimate) {
    return '$status, $estimate';
  }

  @override
  String visibleCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String get plantNameSuggestion1 => 'Blooming Azalea';

  @override
  String get plantNameSuggestion2 => 'Lush Fern';

  @override
  String get plantNameSuggestion3 => 'Evergreen Maple';

  @override
  String get plantNameSuggestion4 => 'Thriving Orchid';

  @override
  String get plantNameSuggestion5 => 'Vibrant Sunflower';

  @override
  String get plantNameSuggestion6 => 'Radiant Lily';

  @override
  String get plantNameSuggestion7 => 'Flourishing Rose';

  @override
  String get plantNameSuggestion8 => 'Verdant Daisy';

  @override
  String get plantNameSuggestion9 => 'Bountiful Poppy';

  @override
  String get plantNameSuggestion10 => 'Abundant Jasmine';
}
