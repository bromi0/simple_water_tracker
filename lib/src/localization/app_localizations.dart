import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Settings language selector heading.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Follow the device's language preferences.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemLanguage;

  /// English language name, always written in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Russian language name, always written in Russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// Scheduled watering reminder title; plantName is user-owned text.
  ///
  /// In en, this message translates to:
  /// **'Water {plantName}'**
  String wateringNotificationTitle(String plantName);

  /// Scheduled watering reminder body.
  ///
  /// In en, this message translates to:
  /// **'Your plant needs water.'**
  String get wateringNotificationBody;

  /// Title of the in-app notification test.
  ///
  /// In en, this message translates to:
  /// **'Watering reminder test'**
  String get testNotificationTitle;

  /// Body of the in-app notification test.
  ///
  /// In en, this message translates to:
  /// **'Notifications are working.'**
  String get testNotificationBody;

  /// Android notification channel name.
  ///
  /// In en, this message translates to:
  /// **'Watering reminders'**
  String get notificationChannelName;

  /// Android notification channel description.
  ///
  /// In en, this message translates to:
  /// **'Reminders to water your plants.'**
  String get notificationChannelDescription;

  /// Application brand name; keep Simply Water Plant in every locale.
  ///
  /// In en, this message translates to:
  /// **'Simply Water Plant'**
  String get appTitle;

  /// No description provided for @roomSuggestionLivingRoom.
  ///
  /// In en, this message translates to:
  /// **'Living room'**
  String get roomSuggestionLivingRoom;

  /// No description provided for @roomSuggestionBedroom.
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get roomSuggestionBedroom;

  /// No description provided for @roomSuggestionKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get roomSuggestionKitchen;

  /// No description provided for @roomSuggestionDiningRoom.
  ///
  /// In en, this message translates to:
  /// **'Dining room'**
  String get roomSuggestionDiningRoom;

  /// No description provided for @roomSuggestionOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get roomSuggestionOffice;

  /// No description provided for @roomSuggestionBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get roomSuggestionBalcony;

  /// No description provided for @roomSuggestionHallway.
  ///
  /// In en, this message translates to:
  /// **'Hallway'**
  String get roomSuggestionHallway;

  /// No description provided for @roomSuggestionPatio.
  ///
  /// In en, this message translates to:
  /// **'Patio'**
  String get roomSuggestionPatio;

  /// No description provided for @roomSuggestionTerrace.
  ///
  /// In en, this message translates to:
  /// **'Terrace'**
  String get roomSuggestionTerrace;

  /// No description provided for @roomSuggestionPorch.
  ///
  /// In en, this message translates to:
  /// **'Porch'**
  String get roomSuggestionPorch;

  /// No description provided for @roomSuggestionGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get roomSuggestionGarden;

  /// No description provided for @roomSuggestionGreenhouse.
  ///
  /// In en, this message translates to:
  /// **'Greenhouse'**
  String get roomSuggestionGreenhouse;

  /// No description provided for @roomSuggestionYard.
  ///
  /// In en, this message translates to:
  /// **'Yard'**
  String get roomSuggestionYard;

  /// Application UI: settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Application UI: use grid.
  ///
  /// In en, this message translates to:
  /// **'Use two-column view'**
  String get useGrid;

  /// Application UI: use rows.
  ///
  /// In en, this message translates to:
  /// **'Use one-column view'**
  String get useRows;

  /// Application UI: watering schedule.
  ///
  /// In en, this message translates to:
  /// **'Watering schedule'**
  String get wateringSchedule;

  /// Application UI: rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// Application UI: add plant.
  ///
  /// In en, this message translates to:
  /// **'Add plant'**
  String get addPlant;

  /// Application UI: plants.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get plants;

  /// Application UI: no room.
  ///
  /// In en, this message translates to:
  /// **'No room'**
  String get noRoom;

  /// Application UI: show plants.
  ///
  /// In en, this message translates to:
  /// **'Show plants'**
  String get showPlants;

  /// Application UI: all plants.
  ///
  /// In en, this message translates to:
  /// **'All plants'**
  String get allPlants;

  /// Application UI: manage rooms.
  ///
  /// In en, this message translates to:
  /// **'Manage rooms'**
  String get manageRooms;

  /// Application UI: no plants yet.
  ///
  /// In en, this message translates to:
  /// **'No plants yet'**
  String get noPlantsYet;

  /// Application UI: no plants help.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant to start tracking its watering.'**
  String get noPlantsHelp;

  /// Application UI: no plants in room help.
  ///
  /// In en, this message translates to:
  /// **'Add a plant or move one here from its editor.'**
  String get noPlantsInRoomHelp;

  /// Application UI: choose gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseGallery;

  /// Application UI: take photo.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// Application UI: photo selection failed.
  ///
  /// In en, this message translates to:
  /// **'Could not select that photo.'**
  String get photoSelectionFailed;

  /// Application UI: plant name required.
  ///
  /// In en, this message translates to:
  /// **'Enter a plant name.'**
  String get plantNameRequired;

  /// Application UI: plant save failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this plant.'**
  String get plantSaveFailed;

  /// Application UI: delete plant title.
  ///
  /// In en, this message translates to:
  /// **'Delete plant?'**
  String get deletePlantTitle;

  /// Application UI: cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Application UI: delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Application UI: edit plant.
  ///
  /// In en, this message translates to:
  /// **'Edit plant'**
  String get editPlant;

  /// Application UI: delete plant.
  ///
  /// In en, this message translates to:
  /// **'Delete plant'**
  String get deletePlant;

  /// Application UI: plant name.
  ///
  /// In en, this message translates to:
  /// **'Plant name'**
  String get plantName;

  /// Application UI: watering.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get watering;

  /// Application UI: decrease watering interval.
  ///
  /// In en, this message translates to:
  /// **'Decrease watering interval'**
  String get decreaseWateringInterval;

  /// Application UI: increase watering interval.
  ///
  /// In en, this message translates to:
  /// **'Increase watering interval'**
  String get increaseWateringInterval;

  /// Application UI: save changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// Application UI: change photo.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// Application UI: photo unavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get photoUnavailable;

  /// Application UI: watering week.
  ///
  /// In en, this message translates to:
  /// **'Watering week'**
  String get wateringWeek;

  /// Application UI: test notification tooltip.
  ///
  /// In en, this message translates to:
  /// **'Test notification in one minute'**
  String get testNotificationTooltip;

  /// Application UI: no reminders.
  ///
  /// In en, this message translates to:
  /// **'No plants to remind you about.'**
  String get noReminders;

  /// Application UI: test reminder scheduled.
  ///
  /// In en, this message translates to:
  /// **'Test reminder scheduled for one minute from now.'**
  String get testReminderScheduled;

  /// Application UI: notifications off.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off or unavailable. Check notification settings.'**
  String get notificationsOff;

  /// Application UI: test reminder failed.
  ///
  /// In en, this message translates to:
  /// **'Could not schedule a test reminder. Try again.'**
  String get testReminderFailed;

  /// Application UI: today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Application UI: item details.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemDetails;

  /// Application UI: more information.
  ///
  /// In en, this message translates to:
  /// **'More Information Here'**
  String get moreInformation;

  /// Application UI: picture capture failed.
  ///
  /// In en, this message translates to:
  /// **'Could not take the picture. Try again.'**
  String get pictureCaptureFailed;

  /// Application UI: plant add failed.
  ///
  /// In en, this message translates to:
  /// **'Could not add this plant.'**
  String get plantAddFailed;

  /// Application UI: photo your plant.
  ///
  /// In en, this message translates to:
  /// **'Photo your plant'**
  String get photoYourPlant;

  /// Application UI: plant name suggestion help.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use this suggestion.'**
  String get plantNameSuggestionHelp;

  /// Application UI: taking picture.
  ///
  /// In en, this message translates to:
  /// **'Taking picture...'**
  String get takingPicture;

  /// Application UI: camera permission denied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// Application UI: camera permission required.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// Application UI: camera unavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera access unavailable'**
  String get cameraUnavailable;

  /// Application UI: no camera.
  ///
  /// In en, this message translates to:
  /// **'No camera available'**
  String get noCamera;

  /// Application UI: add without photo.
  ///
  /// In en, this message translates to:
  /// **'Add without photo'**
  String get addWithoutPhoto;

  /// Application UI: use camera.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get useCamera;

  /// Application UI: retry camera.
  ///
  /// In en, this message translates to:
  /// **'Retry camera'**
  String get retryCamera;

  /// Application UI: open app settings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// Application UI: display picture.
  ///
  /// In en, this message translates to:
  /// **'Display the Picture'**
  String get displayPicture;

  /// Application UI: room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// Application UI: choose room.
  ///
  /// In en, this message translates to:
  /// **'Choose room'**
  String get chooseRoom;

  /// Application UI: create room.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get createRoom;

  /// Application UI: room reorder failed.
  ///
  /// In en, this message translates to:
  /// **'Could not reorder rooms.'**
  String get roomReorderFailed;

  /// Application UI: suggested places.
  ///
  /// In en, this message translates to:
  /// **'Suggested places'**
  String get suggestedPlaces;

  /// Application UI: rooms help.
  ///
  /// In en, this message translates to:
  /// **'Rooms are optional. Add a suggested place or create your own.'**
  String get roomsHelp;

  /// Application UI: room save failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this room.'**
  String get roomSaveFailed;

  /// Application UI: rename room.
  ///
  /// In en, this message translates to:
  /// **'Rename room'**
  String get renameRoom;

  /// Application UI: room name.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomName;

  /// Application UI: create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Application UI: save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Application UI: room name required.
  ///
  /// In en, this message translates to:
  /// **'Enter a room name.'**
  String get roomNameRequired;

  /// Application UI: room name duplicate.
  ///
  /// In en, this message translates to:
  /// **'A room with that name already exists.'**
  String get roomNameDuplicate;

  /// Application UI: room will be removed.
  ///
  /// In en, this message translates to:
  /// **'This room will be removed.'**
  String get roomWillBeRemoved;

  /// Application UI: room delete failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this room.'**
  String get roomDeleteFailed;

  /// Application UI: system theme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// Application UI: light theme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// Application UI: dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// Application UI: watering status.
  ///
  /// In en, this message translates to:
  /// **'Watering status'**
  String get wateringStatus;

  /// Application UI: watering status help.
  ///
  /// In en, this message translates to:
  /// **'Choose whether plant cards include an estimated watering time.'**
  String get wateringStatusHelp;

  /// Application UI: simple status.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get simpleStatus;

  /// Application UI: informative status.
  ///
  /// In en, this message translates to:
  /// **'Informative'**
  String get informativeStatus;

  /// Application UI: notifications enabled description.
  ///
  /// In en, this message translates to:
  /// **'Allowed by Android for watering notifications.'**
  String get notificationsEnabledDescription;

  /// Application UI: notifications requestable description.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Allow reminders when your plants need water.'**
  String get notificationsRequestableDescription;

  /// Application UI: notifications settings required description.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Enable them in Android settings.'**
  String get notificationsSettingsRequiredDescription;

  /// Application UI: notifications channel blocked description.
  ///
  /// In en, this message translates to:
  /// **'The watering notification category is off. Enable it in Android settings.'**
  String get notificationsChannelBlockedDescription;

  /// Application UI: notifications unsupported description.
  ///
  /// In en, this message translates to:
  /// **'Notifications are currently available on Android only.'**
  String get notificationsUnsupportedDescription;

  /// Application UI: checking notification settings.
  ///
  /// In en, this message translates to:
  /// **'Checking notification settings…'**
  String get checkingNotificationSettings;

  /// Application UI: notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Application UI: retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Application UI: allow notifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// Application UI: open notification settings.
  ///
  /// In en, this message translates to:
  /// **'Open Android notification settings'**
  String get openNotificationSettings;

  /// Application UI: reminder update failed.
  ///
  /// In en, this message translates to:
  /// **'Could not update reminders. Try again.'**
  String get reminderUpdateFailed;

  /// Application UI: notification settings read failed.
  ///
  /// In en, this message translates to:
  /// **'Could not read notification settings. Try again.'**
  String get notificationSettingsReadFailed;

  /// Application UI: android settings open failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Android settings.'**
  String get androidSettingsOpenFailed;

  /// Application UI: doing well.
  ///
  /// In en, this message translates to:
  /// **'Doing well'**
  String get doingWell;

  /// Application UI: water soon.
  ///
  /// In en, this message translates to:
  /// **'Water soon'**
  String get waterSoon;

  /// Application UI: needs water.
  ///
  /// In en, this message translates to:
  /// **'Needs water'**
  String get needsWater;

  /// Application UI: water now.
  ///
  /// In en, this message translates to:
  /// **'Water now'**
  String get waterNow;

  /// Application UI: camera unavailable help.
  ///
  /// In en, this message translates to:
  /// **'The camera may be unavailable or permission may have been denied.\nYou can still add this plant without a photo.'**
  String get cameraUnavailableHelp;

  /// Accessible room filter action. roomName is a user-owned name or the localized collection label.
  ///
  /// In en, this message translates to:
  /// **'Room filter, {roomName}, change room'**
  String roomFilterSemantics(String roomName);

  /// Accessible room assignment action.
  ///
  /// In en, this message translates to:
  /// **'Room, {roomName}, change room'**
  String roomAssignmentSemantics(String roomName);

  /// Empty collection for a user-named room. Do not inflect the supplied name.
  ///
  /// In en, this message translates to:
  /// **'No plants in {roomName}'**
  String noPlantsInRoom(String roomName);

  /// Accessible watering action; supplied plant name is user content.
  ///
  /// In en, this message translates to:
  /// **'Water {plantName}'**
  String waterPlant(String plantName);

  /// Accessible undo action; supplied name is user content.
  ///
  /// In en, this message translates to:
  /// **'Undo watering for {plantName}'**
  String undoWaterPlant(String plantName);

  /// Accessible edit action.
  ///
  /// In en, this message translates to:
  /// **'Edit {plantName}'**
  String editNamedPlant(String plantName);

  /// Accessible missing-photo description.
  ///
  /// In en, this message translates to:
  /// **'No photo for {plantName}'**
  String noPlantPhoto(String plantName);

  /// Plant deletion confirmation. Preserve the supplied name.
  ///
  /// In en, this message translates to:
  /// **'{plantName} and its watering history will be removed.'**
  String plantDeleteConfirmation(String plantName);

  /// Editor watering interval in days.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Every {days} day} other{Every {days} days}}'**
  String wateringInterval(int days);

  /// Camera form watering interval in days.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Water every {days} day} other{Water every {days} days}}'**
  String waterEveryDays(int days);

  /// Slider value and accessible watering interval.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{{days} day} other{{days} days}}'**
  String dayCount(int days);

  /// Accessible prefix for a complete localized watering status.
  ///
  /// In en, this message translates to:
  /// **'Watering status: {status}'**
  String wateringStatusSemantics(String status);

  /// Accessible schedule card; status is a full localized phrase.
  ///
  /// In en, this message translates to:
  /// **'{plantName}, {status}'**
  String namedWateringStatus(String plantName, String status);

  /// Saving a suggested room failed.
  ///
  /// In en, this message translates to:
  /// **'Could not add {roomName}.'**
  String roomAddFailed(String roomName);

  /// Number of plants assigned to a room.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} plant} other{{count} plants}}'**
  String plantCount(int count);

  /// Accessible delete-room action.
  ///
  /// In en, this message translates to:
  /// **'Delete {roomName}'**
  String deleteNamedRoom(String roomName);

  /// Room deletion confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete {roomName}?'**
  String roomDeleteTitle(String roomName);

  /// Room deletion preserves these plants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} plant will be kept without a room.} other{{count} plants will be kept without a room.}}'**
  String roomPlantsKept(int count);

  /// Estimated time until watering, in hours; approximate, not an exact alarm time.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{Water in ~{hours} h} other{Water in ~{hours} h}}'**
  String waterInHours(int hours);

  /// Estimated time until watering, in days.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Water in ~{days} day} other{Water in ~{days} days}}'**
  String waterInDays(int days);

  /// Compact visual estimate on a small plant card. Translate the unit and approximation marker.
  ///
  /// In en, this message translates to:
  /// **'~{hours}h'**
  String waterInHoursCompact(int hours);

  /// Compact visual estimate on a small plant card.
  ///
  /// In en, this message translates to:
  /// **'~{days}d'**
  String waterInDaysCompact(int days);

  /// Spoken watering estimate; use full units, not abbreviations.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{Water in approximately {hours} hour} other{Water in approximately {hours} hours}}'**
  String waterInHoursSpoken(int hours);

  /// Spoken watering estimate.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Water in approximately {days} day} other{Water in approximately {days} days}}'**
  String waterInDaysSpoken(int days);

  /// Combines a translated urgency label with a full spoken estimate.
  ///
  /// In en, this message translates to:
  /// **'{status}, {estimate}'**
  String wateringStatusWithEstimate(String status, String estimate);

  /// Locale-formatted count in a compact badge.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String visibleCount(int count);

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Blooming Azalea'**
  String get plantNameSuggestion1;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Lush Fern'**
  String get plantNameSuggestion2;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Evergreen Maple'**
  String get plantNameSuggestion3;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Thriving Orchid'**
  String get plantNameSuggestion4;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Vibrant Sunflower'**
  String get plantNameSuggestion5;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Radiant Lily'**
  String get plantNameSuggestion6;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Flourishing Rose'**
  String get plantNameSuggestion7;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Verdant Daisy'**
  String get plantNameSuggestion8;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Bountiful Poppy'**
  String get plantNameSuggestion9;

  /// Complete random plant-name suggestion. Translate the entire phrase with correct grammatical agreement. Saved names are never retranslated.
  ///
  /// In en, this message translates to:
  /// **'Abundant Jasmine'**
  String get plantNameSuggestion10;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
