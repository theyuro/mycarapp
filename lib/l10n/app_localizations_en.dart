// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginErrorConfig =>
      'We couldn\'t verify your Google sign-in. Please try again in a moment.';

  @override
  String get loginErrorInterrupted =>
      'Google sign-in was interrupted. Please try again.';

  @override
  String get loginErrorCanceledMaybe =>
      'Google sign-in was interrupted. If you picked an account, please try again in a moment.';

  @override
  String get loginErrorGeneric =>
      'Couldn\'t sign in with Google. Please try again.';

  @override
  String get errorCheckConnection => 'Check your connection and try again.';

  @override
  String get loginErrorOtherProvider =>
      'This account already uses a different sign-in method.';

  @override
  String get loginErrorCanceled => 'Google sign-in canceled.';

  @override
  String get appTagline => 'SMART VEHICLE MANAGEMENT';

  @override
  String get loginSigningIn => 'SIGNING IN...';

  @override
  String get loginWithGoogle => 'SIGN IN WITH GOOGLE';

  @override
  String get loginHint => 'Sign in with your Google account to use MyCarApp.';

  @override
  String get presentationSlogan =>
      'Technology that goes the distance with you.';

  @override
  String get footerDevelopedBy =>
      'Developed by Giles Desenvolvimento de Softwares';

  @override
  String get upsellSubscribe => 'SUBSCRIBE';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get upsellNoAdsTitle => 'No more ads';

  @override
  String get upsellNoAdsText =>
      'Go Premium and use MyCarApp without interruptions.';

  @override
  String get upsellBackupTitle => 'Your history, protected';

  @override
  String get upsellBackupText =>
      'Automatic cloud backup, including photos and documents.';

  @override
  String get upsellVehiclesTitle => 'Unlimited vehicles';

  @override
  String get upsellVehiclesText =>
      'Premium subscribers can add as many vehicles as they want.';

  @override
  String get upsellReceiptTitle => 'Automatic receipt scanning';

  @override
  String get upsellReceiptText =>
      'Photograph the receipt and let Premium fill in the fill-up for you.';

  @override
  String get upsellAdsTitle => 'Go ad-free';

  @override
  String get upsellAdsText => 'Go Premium and remove the ads.';

  @override
  String get upsellFuelingTitle => 'Fill-ups without ads';

  @override
  String get upsellFuelingText =>
      'Premium subscribers record every fill-up in the month without watching videos.';

  @override
  String get upsellMaintenanceTitle => 'Maintenance and expenses without ads';

  @override
  String get upsellMaintenanceText =>
      'Premium subscribers record them without watching videos.';

  @override
  String get upsellExpensesTitle => 'Reports by custom period';

  @override
  String get upsellExpensesText =>
      'Subscribe and compare your spending over any period, not just the app\'s defaults.';

  @override
  String get afterAdTitle => 'Tired of ads?';

  @override
  String get afterAdSubtitle => 'Get MyCarApp Premium';

  @override
  String afterAdPriceFrom(Object price) {
    return 'from $price/month';
  }

  @override
  String get subscriptionPlansAvailable => 'Monthly and yearly plans';

  @override
  String get afterAdSubscribe => 'GET PREMIUM';

  @override
  String get notNow => 'Not now';

  @override
  String get recoRatingText =>
      'Enjoying tracking your expenses? Tell us on the Play Store.';

  @override
  String get recoReferralText =>
      'Like MyCarApp? Refer a friend and they get a subscription discount.';

  @override
  String get recoRate => 'RATE';

  @override
  String get recoRefer => 'REFER';

  @override
  String get houseAdAuctionText =>
      'Real estate and vehicle auctions in ES, all in one place.';

  @override
  String get houseAdAuctionCta => 'SEE AUCTIONS';

  @override
  String get attachmentNotFound => 'Attachment not found.';

  @override
  String get attachmentOpenError => 'Couldn\'t open this attachment.';

  @override
  String get attachmentRemove => 'Remove attachment';

  @override
  String get attachmentTakePhoto => 'TAKE PHOTO';

  @override
  String get attachmentAttach => 'ATTACH';

  @override
  String get attachmentReading => 'READING RECEIPT...';

  @override
  String get attachmentReadReceipt => 'READ RECEIPT AND FILL IN';

  @override
  String get attachmentHint => 'Images and PDF files are accepted.';

  @override
  String establishmentCreate(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get fuelingNeedVehicle => 'Add a vehicle before your first fill-up.';

  @override
  String get fuelingNeedLitersAndPrice =>
      'Enter the liters and the amount paid.';

  @override
  String get fuelingOverfillTitle => 'Invalid fill-up';

  @override
  String fuelingOverfillMessage(String liters, String capacity) {
    return '$liters L entered for a $capacity L tank.';
  }

  @override
  String get quickFuelingAdded => 'Quick fill-up added';

  @override
  String get fuelingSaveError => 'Couldn\'t save the fill-up.';

  @override
  String get fuelingAdded => 'Fill-up added';

  @override
  String get quickFuelingTitle => 'Quick fill-up';

  @override
  String get liters => 'Liters';

  @override
  String get amountPaid => 'Amount paid';

  @override
  String get fullFueling => 'FULL FILL-UP FORM';

  @override
  String get featureNoAdsTitle => 'Go ad-free';

  @override
  String get featureNoAdsText =>
      'Premium subscribers use MyCarApp with no ads at all.';

  @override
  String get featureBackupTitle => 'Automatic cloud backup';

  @override
  String get featureBackupText =>
      'Everything is saved to your account automatically, including photos and documents. Switch phones without losing anything.';

  @override
  String get featureVehiclesTitle => 'More vehicles';

  @override
  String get featureVehiclesText =>
      'Premium subscribers can add as many vehicles as they want.';

  @override
  String get featureFuelingsTitle => 'Unlimited fill-ups';

  @override
  String get featureFuelingsText =>
      'Record every fill-up in the month without watching videos.';

  @override
  String get featureMaintenanceTitle => 'Unlimited maintenance and expenses';

  @override
  String get featureMaintenanceText =>
      'Record maintenance, expenses and alerts without watching videos.';

  @override
  String get featureReceiptScanTitle => 'Receipt scanning';

  @override
  String get featureReceiptScanText =>
      'Photograph the receipt and let MyCarApp fill in the fill-up for you.';

  @override
  String get featureStationRankingTitle => 'Full gas station ranking';

  @override
  String get featureStationRankingText =>
      'See the full ranking of the stations where your car goes the furthest.';

  @override
  String get featurePeriodReportsTitle => 'Reports by custom period';

  @override
  String get featurePeriodReportsText =>
      'Compare spending and fuel economy over any period, not just the app\'s defaults.';

  @override
  String get featureExportTitle => 'CSV and Excel export';

  @override
  String get featureExportText =>
      'Export your data as CSV or Excel whenever you want.';

  @override
  String get featurePdfTitle => 'PDF export';

  @override
  String get featurePdfText =>
      'Generate the report PDF without watching a video.';

  @override
  String get featureSyncTitle => 'Sync across devices';

  @override
  String get featureSyncText => 'Your data follows you when you switch phones.';

  @override
  String get premiumYouArePremium => 'You\'re Premium';

  @override
  String get premiumFreePlan => 'You\'re on the free plan';

  @override
  String get premiumActive => 'Your MyCarApp subscription is active.';

  @override
  String get premiumFreeIntro =>
      'All app features are free, with ads. Subscribe to go ad-free and get automatic backup.';

  @override
  String get loading => 'Loading...';

  @override
  String premiumOptionOffer(Object plan) {
    return '$plan · offer';
  }

  @override
  String get premiumWaitingPlay => 'WAITING FOR GOOGLE PLAY...';

  @override
  String get premiumSignInToSubscribe => 'SIGN IN TO SUBSCRIBE';

  @override
  String get premiumRestore => 'RESTORE SUBSCRIPTION';

  @override
  String get premiumBillingNote =>
      'Payment is processed by Google Play. The subscription renews automatically and can be canceled in the Play Store.';

  @override
  String get premiumBackToApp => 'BACK TO THE APP';

  @override
  String get benefitNoAds => 'No ads';

  @override
  String get benefitBackup =>
      'Automatic cloud backup, with photos and documents';

  @override
  String get benefitVehicles => 'Unlimited vehicles';

  @override
  String get benefitMaintenanceNoVideo =>
      'Maintenance and expenses without ads';

  @override
  String get benefitReceiptScan => 'Automatic receipt scanning';

  @override
  String get benefitStationRanking => 'Full gas station ranking';

  @override
  String get benefitExport => 'CSV, Excel and PDF export';

  @override
  String get subscriptionRestore => 'Restore purchase';

  @override
  String get subscriptionFreeTrialBadge => '7-DAY FREE TRIAL';

  @override
  String subscriptionSaveBadge(Object percent) {
    return 'SAVE $percent%';
  }

  @override
  String get subscriptionBilledMonthly => 'billed every month';

  @override
  String get subscriptionStartFreeTrial => 'START 7-DAY FREE TRIAL';

  @override
  String subscriptionSubscribeMonthly(Object price) {
    return 'SUBSCRIBE FOR $price/MONTH';
  }

  @override
  String subscriptionBillingTrial(Object price) {
    return 'Free for 7 days, then $price per year.';
  }

  @override
  String get subscriptionBillingAuto =>
      'Automatically renews. Cancel anytime in the Play Store.';

  @override
  String get planAnnual => 'Yearly plan';

  @override
  String get planMonthly => 'Monthly plan';

  @override
  String perYear(Object price) {
    return '$price/year';
  }

  @override
  String perMonth(Object price) {
    return '$price/month';
  }

  @override
  String priceOfferThen(Object price, Object renewal) {
    return '$price with the offer; then $renewal';
  }

  @override
  String get storeCommError =>
      'Couldn\'t complete communication with the store.';

  @override
  String get storeUnavailable => 'Google Play is not available on this device.';

  @override
  String get storeProductNotFound =>
      'Product not found. Check the ID in the Google Play Console.';

  @override
  String get storeNoPlans => 'No plans available for this account.';

  @override
  String get storeAccessError => 'Couldn\'t reach Google Play.';

  @override
  String get storeSignInToSubscribe =>
      'Sign in with your Google account to subscribe.';

  @override
  String get storePurchaseNotStarted => 'The purchase couldn\'t be started.';

  @override
  String get storePurchaseStartError => 'Couldn\'t start the purchase.';

  @override
  String get storeSignInToRestore =>
      'Sign in with your Google account to restore your subscription.';

  @override
  String get storeSearching => 'Looking for previous purchases...';

  @override
  String get storeRestored => 'Subscription restored.';

  @override
  String get storeValidatingRestore =>
      'Purchases found. Validating with Google Play...';

  @override
  String get storeRestoreError => 'Couldn\'t restore purchases.';

  @override
  String get storePending => 'Payment pending on Google Play.';

  @override
  String get storeNotCompleted => 'The purchase was not completed.';

  @override
  String get storeCanceled => 'Purchase canceled.';

  @override
  String get storeSameAccount =>
      'Sign in with the same account used to start the subscription.';

  @override
  String get storeNoVerificationData =>
      'Google Play didn\'t provide the validation data.';

  @override
  String get storeValidating => 'Validating subscription with Google Play...';

  @override
  String get storeActive => 'MyCarApp subscription active.';

  @override
  String get storeNotActive => 'The subscription is not active on Google Play.';

  @override
  String get storeValidationError =>
      'Couldn\'t validate the subscription. Try restoring again.';

  @override
  String get backupDone => 'Backup complete.';

  @override
  String get backupRestoreCloudTitle => 'Restore from cloud';

  @override
  String backupRestoreCloudConfirm(Object count) {
    return 'This brings the $count record(s) saved in the cloud, with photos and documents, to this phone. Records with the same id are updated; nothing on this phone is deleted.';
  }

  @override
  String backupRestoredCount(Object count) {
    return '$count record(s) restored.';
  }

  @override
  String get backupRestoreError => 'Couldn\'t restore. Check your connection.';

  @override
  String get backupReadError => 'Couldn\'t read this backup.';

  @override
  String get backupRestoreLegacyTitle => 'Restore old copy';

  @override
  String get backupLegacyNothingNew =>
      'This copy has nothing beyond what you already have on this phone.';

  @override
  String backupLegacyImpact(Object added, Object updated) {
    return 'This will add $added new record(s) and update $updated existing one(s). Nothing is deleted.';
  }

  @override
  String get backupLegacyRestored => 'Copy restored.';

  @override
  String get backupLegacyRestoreError => 'Couldn\'t restore this copy.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get restore => 'RESTORE';

  @override
  String get backupTitle => 'Backup and restore';

  @override
  String get backupRestoring => 'RESTORING...';

  @override
  String backupRestoreCloudButton(Object count) {
    return 'RESTORE FROM CLOUD ($count)';
  }

  @override
  String get backupLegacyHeader => 'OLD COPIES';

  @override
  String get backupLegacyHint =>
      'Made manually in earlier app versions. They don\'t include photos and documents.';

  @override
  String get backupAutoActive => 'Automatic backup on';

  @override
  String get backupSending => 'Uploading changes...';

  @override
  String get backupFirstSoon => 'The first backup starts in a moment.';

  @override
  String backupLastAt(Object date) {
    return 'Last backup on $date.';
  }

  @override
  String get backupWhatIsSaved =>
      'Vehicles, fill-ups, maintenance, expenses, places, photos, receipts and documents are saved to your account whenever you make a change.';

  @override
  String get backupUploading => 'UPLOADING...';

  @override
  String get backupNow => 'BACK UP NOW';

  @override
  String get backupIsPremium => 'Automatic backup is Premium';

  @override
  String get backupFreeExplain =>
      'On the free plan your data stays only on this phone. With Premium, everything is saved to the cloud automatically, including photos and documents, and comes back with you when you switch phones.';

  @override
  String get learnAboutPremium => 'SEE PREMIUM';

  @override
  String backupLegacyTileInfo(Object count, Object size) {
    return '$count record(s) • $size';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date at $time';
  }

  @override
  String get backupFailed =>
      'Couldn\'t finish the backup. Check your connection.';

  @override
  String get backupSignInToRestore => 'Sign in to restore your backup.';

  @override
  String get backupSignInRequired => 'Sign in to use cloud backup.';

  @override
  String get backupNotFound => 'Backup not found in storage.';

  @override
  String get signInRequired => 'Sign in to use this feature.';

  @override
  String get referralApplied =>
      'Code applied! The benefit is activated after the first payment.';

  @override
  String get referralApplyError =>
      'Couldn\'t apply this code. Check it and try again.';

  @override
  String get adminPremiumUpdated => 'Free Premium access updated.';

  @override
  String get adminPremiumUpdateError => 'Couldn\'t update the period.';

  @override
  String get accountTitle => 'My account';

  @override
  String get accountSignInBackup => 'Sign in to use cloud backup and support';

  @override
  String get accountSignInReferral => 'Sign in to use referrals and discounts';

  @override
  String get accountUser => 'User';

  @override
  String get supportTitle => 'Help, feedback and bugs';

  @override
  String get supportSubtitle => 'Send and track your requests';

  @override
  String get adminTitle => 'Test administration';

  @override
  String adminPremiumUntil(Object date) {
    return 'Free Premium until $date';
  }

  @override
  String get adminChangeDate => 'CHANGE DATE';

  @override
  String get referralYourCode => 'Your referral code';

  @override
  String get referralCopy => 'Copy code';

  @override
  String get referralCopied => 'Code copied.';

  @override
  String get referralInvite => 'Invite a friend';

  @override
  String referralShareText(Object code, Object url) {
    return 'I use MyCarApp to track my car expenses. Download it with my referral code $code and get 30% off the first year of yearly Premium: $url';
  }

  @override
  String get referralReceived => 'Got a code?';

  @override
  String get referralCodeLabel => 'Referral code';

  @override
  String get referralApplying => 'APPLYING...';

  @override
  String get referralApply => 'APPLY CODE';

  @override
  String get bestOffer => 'Best available offer';

  @override
  String get signOut => 'SIGN OUT';

  @override
  String get accountBackupPitch =>
      'Save everything to the cloud, with photos and documents, and lose nothing when you switch phones.';

  @override
  String backupDaysAgo(Object days) {
    return 'Last backup $days day(s) ago';
  }

  @override
  String backupLastOn(Object date) {
    return 'Last backup on $date';
  }

  @override
  String get offerClosedTest3m => '70% off for 3 months';

  @override
  String get offerClosedTestYear => '70% off the first year';

  @override
  String get offerFounders => '50% off the first year';

  @override
  String get offerReferral => '30% off the first year';

  @override
  String get offerReferralOld => '50% off for 3 months';

  @override
  String get offerYearlyTrial => '7-day free trial on the yearly plan';

  @override
  String get offerSpecial => 'Special MyCarApp offer';

  @override
  String get watchAndSave => 'WATCH VIDEO AND SAVE';

  @override
  String get freeLimitVehicleTitle => 'This vehicle is view-only';

  @override
  String get freeLimitVehicleText =>
      'On the free plan, only the first vehicle you added accepts new entries. Subscribe to Premium to add entries to every vehicle.';

  @override
  String get freeLimitFuelingTitle => 'Monthly fill-up limit';

  @override
  String freeLimitFuelingText(Object count) {
    return 'You\'ve already logged $count free fill-up(s) this month. Watch a video to save one more, or subscribe to Premium for unlimited fill-ups.';
  }

  @override
  String get freeLimitMaintenanceTitle => 'Unlocked by video';

  @override
  String get freeLimitMaintenanceText =>
      'On the free plan, each new maintenance entry is unlocked by watching a video. Subscribe to Premium to log entries without videos.';

  @override
  String get freeLimitExpenseTitle => 'Unlocked by video';

  @override
  String get freeLimitExpenseText =>
      'On the free plan, each new expense is unlocked by watching a video. Subscribe to Premium to log entries without videos.';

  @override
  String get vehicleViewOnlyBadge => 'View-only on the free plan';

  @override
  String stationNextUnlock(String date) {
    return 'Your best station will show up here again on $date. Subscribe to Premium to see the full ranking anytime.';
  }

  @override
  String get stationSeeFullRanking => 'SEE FULL RANKING (PREMIUM)';

  @override
  String get notSet => 'not set';

  @override
  String get exportSubject => 'MyCarApp export';

  @override
  String get exportText => 'Vehicle data exported by MyCarApp.';

  @override
  String get exportError => 'Couldn\'t export.';

  @override
  String get importConfirmTitle => 'Import data?';

  @override
  String get importConfirmText =>
      'A new vehicle will be created with the fill-ups and maintenance from the file. Your current data won\'t be overwritten.';

  @override
  String get importAction => 'IMPORT';

  @override
  String get importDone => 'Import complete';

  @override
  String importSummary(Object vehicle, Object fuelings, Object maintenances) {
    return '$vehicle\n$fuelings fill-up(s)\n$maintenances maintenance record(s)';
  }

  @override
  String get importError => 'Couldn\'t import.';

  @override
  String get exportTitle => 'Export data';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportCsvHint =>
      'Lightweight format, works with spreadsheets and MyCarApp.';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get exportExcelHint => 'XLSX spreadsheet ready to share or archive.';

  @override
  String get importOtherDevice => 'Import on another device';

  @override
  String get importOtherDeviceHint =>
      'Read a CSV or Excel file created by MyCarApp.';

  @override
  String get exportInfo =>
      'The export uses the active vehicle and includes its details, fill-ups and maintenance. Photos and receipts stay on the device for security.';

  @override
  String get vehiclesLoadError => 'Couldn\'t load vehicles.';

  @override
  String get vehicleAdded => 'Vehicle added';

  @override
  String vehicleNowActive(Object name) {
    return '$name is now the active vehicle.';
  }

  @override
  String get vehicleDeleteTitle => 'Delete vehicle?';

  @override
  String vehicleDeleteText(Object name) {
    return '$name\'s details and photos will be deleted from the device. Fill-ups already recorded are kept.';
  }

  @override
  String get deleteAction => 'DELETE';

  @override
  String get vehicleDeleted => 'Vehicle deleted.';

  @override
  String get vehicleDeleteError => 'Couldn\'t delete the vehicle.';

  @override
  String get vehiclesTitle => 'My vehicles';

  @override
  String get newVehicle => 'NEW VEHICLE';

  @override
  String get useThis => 'USE THIS';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get vehiclesEmptyTitle => 'No vehicles yet';

  @override
  String get vehiclesEmptyText =>
      'Add your first car or motorcycle to start recording fill-ups.';

  @override
  String get addVehicle => 'ADD VEHICLE';

  @override
  String placeArchived(Object name) {
    return '$name archived.';
  }

  @override
  String get placesNothingToOrganize => 'No places left to organize.';

  @override
  String placesOrganized(Object count) {
    return '$count place(s) organized.';
  }

  @override
  String get placesTitle => 'My places';

  @override
  String get placesOrganize => 'Organize my places';

  @override
  String get archive => 'Archive';

  @override
  String get placesEmptyTitle => 'No places yet.';

  @override
  String get placesEmptyText =>
      'Add gas stations and shops when recording a fill-up or maintenance, or organize places you already typed as text.';

  @override
  String get placesOrganizeButton => 'ORGANIZE MY PLACES';

  @override
  String get placeNew => 'New place';

  @override
  String get placeEdit => 'Edit place';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String get type => 'Type';

  @override
  String get placeBrand => 'Brand (optional)';

  @override
  String get placeAddress => 'Address (optional)';

  @override
  String get placeNeighborhood => 'Neighborhood (optional)';

  @override
  String get favorite => 'Favorite';

  @override
  String get placeFavoriteHint => 'Shows at the top of quick suggestions';

  @override
  String get saving => 'SAVING...';

  @override
  String get save => 'SAVE';

  @override
  String get placesOrganizeIntro =>
      'We found these names typed in older records. Select the ones that should become a structured place.';

  @override
  String placesGroupInfo(Object type, Object count) {
    return '$type · $count record(s)';
  }

  @override
  String get organizing => 'ORGANIZING...';

  @override
  String placesUnify(Object count) {
    return 'MERGE $count SELECTED';
  }

  @override
  String get notifCustomize => 'Customize notifications';

  @override
  String get notifCustomizeIntro =>
      'Choose which alerts you want on this device.';

  @override
  String get notifAll => 'All notifications';

  @override
  String get notifAllOn => 'All on';

  @override
  String get notifSomeOn => 'Some on';

  @override
  String get notifAllOff => 'All off';

  @override
  String get notifDisableAll => 'TURN ALL OFF';

  @override
  String get notifEnableAll => 'TURN ALL ON';

  @override
  String get notifNews => 'What\'s new and updates';

  @override
  String get notifMaintenance => 'Upcoming maintenance';

  @override
  String get notifFuelLow => 'Fuel close to 20%';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifClear => 'Clear notifications';

  @override
  String get notifEmpty => 'No notifications';

  @override
  String get docsLoadError => 'Couldn\'t load documents.';

  @override
  String get fileUnavailable => 'File unavailable.';

  @override
  String get docAttached => 'Document attached.';

  @override
  String get docAttachError => 'Couldn\'t attach the PDF.';

  @override
  String get docFileMissing => 'File not found. Attach the document again.';

  @override
  String get docNoPdfReader => 'No PDF reader is available on this device.';

  @override
  String get docDeleteTitle => 'Delete document?';

  @override
  String get docDeleteText => 'The copy stored in MyCarApp will be removed.';

  @override
  String get docDeleted => 'Document deleted.';

  @override
  String get docsTitle => 'Documents';

  @override
  String get docDriverLicense => 'Driver\'s license';

  @override
  String get docDriverLicenseHint => 'Digital driver\'s license (PDF)';

  @override
  String get docVehicle => 'Vehicle document';

  @override
  String get docSelectVehicle => 'Select a vehicle to attach its registration';

  @override
  String docVehicleOf(Object name) {
    return 'Registration for $name';
  }

  @override
  String get docAttachPdf => 'ATTACH PDF';

  @override
  String get docOpenPdf => 'OPEN PDF';

  @override
  String get docReplacePdf => 'Replace PDF';

  @override
  String get docsStorageNote =>
      'PDFs are copied to MyCarApp\'s internal storage and stay only on this device.';

  @override
  String get supportLoadError => 'Couldn\'t load your requests.';

  @override
  String get supportAdminTitle => 'Support desk · Admin';

  @override
  String get supportScreenTitle => 'Help and feedback';

  @override
  String get supportNew => 'NEW REQUEST';

  @override
  String get supportEmpty => 'No requests yet.';

  @override
  String supportSent(Object number) {
    return 'Request #$number sent.';
  }

  @override
  String get supportSendError => 'Couldn\'t send the request.';

  @override
  String get supportNewTitle => 'New request';

  @override
  String get supportFeedback => 'Feedback';

  @override
  String get supportBug => 'Bug';

  @override
  String get supportSubject => 'Subject';

  @override
  String get supportSubjectRequired => 'Enter a subject';

  @override
  String get supportDetails => 'Tell us what happened';

  @override
  String get supportDetailsHint =>
      'If it\'s a bug, describe the steps that led to it.';

  @override
  String get supportDetailsRequired => 'Please add more details';

  @override
  String get backupUploadingSend => 'SENDING...';

  @override
  String get supportSend => 'SEND REQUEST';

  @override
  String get supportReply => 'Support reply';

  @override
  String get status => 'Status';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get supportReplyToUser => 'Reply to user';

  @override
  String get supportSaveReply => 'SAVE REPLY';

  @override
  String get supportSignIn => 'Sign in to send and track requests.';

  @override
  String get expenseNeedVehicle => 'Add and select a vehicle first.';

  @override
  String get expenseSaved => 'Expense saved.';

  @override
  String get expenseDeleteTitle => 'Delete expense?';

  @override
  String expenseDeleteText(Object title) {
    return '$title will be removed from the history.';
  }

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get expenseAdd => 'ADD EXPENSE';

  @override
  String get expenseNeedVehicleFirst => 'Add a vehicle before adding expenses.';

  @override
  String get expensesEmpty =>
      'Add insurance, financing, lease, membership or any other expense.';

  @override
  String get expensesMonthlyRecurring => 'Recurring this month';

  @override
  String get expensesNextDue => 'Next due date';

  @override
  String expensesDueDay(Object day) {
    return 'Day $day';
  }

  @override
  String get expenseNew => 'New expense';

  @override
  String get expenseEdit => 'Edit expense';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get descriptionRequired => 'Enter a description';

  @override
  String get amount => 'Amount';

  @override
  String get invalidValue => 'Enter a valid amount';

  @override
  String get frequency => 'Frequency';

  @override
  String get expenseInstallments => 'Number of installments';

  @override
  String get expenseInstallmentsHint => 'Leave empty for an open-ended charge';

  @override
  String get expenseFirstDue => 'First due date';

  @override
  String get notes => 'Notes';

  @override
  String get expenseSave => 'SAVE EXPENSE';

  @override
  String installmentOf(Object current, Object total) {
    return '$current of $total';
  }

  @override
  String get maintLoadError => 'Couldn\'t load maintenance records.';

  @override
  String get maintDoneAdded => 'Completed maintenance added';

  @override
  String get maintNextAdded => 'Upcoming maintenance added';

  @override
  String get maintDeleteTitle => 'Delete maintenance?';

  @override
  String maintDeleteText(Object service) {
    return '$service will be permanently removed.';
  }

  @override
  String get maintDeleted => 'Maintenance deleted.';

  @override
  String get maintDeleteError => 'Couldn\'t delete the maintenance.';

  @override
  String get maintDone => 'Completed maintenance';

  @override
  String get maintDoneHint => 'Record service, shop and costs';

  @override
  String get maintNext => 'Upcoming maintenance';

  @override
  String get maintNextHint => 'Plan ahead even without history';

  @override
  String get maintTitle => 'Maintenance';

  @override
  String get maintTabDone => 'COMPLETED';

  @override
  String get maintTabNext => 'UPCOMING';

  @override
  String get maintNew => 'NEW MAINTENANCE';

  @override
  String get maintEmptyDone => 'No completed maintenance';

  @override
  String get maintEmptyNext => 'No upcoming maintenance planned';

  @override
  String get thisMonth => 'This month';

  @override
  String get total => 'Total';

  @override
  String get alerts => 'Alerts';

  @override
  String get maintNeedVehicle => 'Add and select a vehicle to see maintenance.';

  @override
  String get maintOverdue => 'Overdue';

  @override
  String get maintUpcoming => 'Upcoming';

  @override
  String get maintPlanned => 'Planned';

  @override
  String get historyLoadError => 'Couldn\'t load the history.';

  @override
  String get fuelingDeleteTitle => 'Delete fill-up?';

  @override
  String fuelingDeleteText(Object date) {
    return 'The record from $date will be permanently removed.';
  }

  @override
  String get fuelingDeleted => 'Fill-up deleted.';

  @override
  String get fuelingDeleteError => 'Couldn\'t delete the fill-up.';

  @override
  String get historyTitle => 'Fill-up history';

  @override
  String get fuelUp => 'FILL UP';

  @override
  String get historySpentMonth => 'Spent this month';

  @override
  String get averagePrice => 'Average price';

  @override
  String get historyTotalLiters => 'Total filled';

  @override
  String get historyRecords => 'Records';

  @override
  String get fuel => 'Fuel';

  @override
  String get fullTank => 'Full tank';

  @override
  String historyEmptyTitle(Object name) {
    return 'No fill-ups for $name';
  }

  @override
  String get historyEmptyText =>
      'Record liters, amount, mileage and full tank to track spending and fuel economy.';

  @override
  String get newFueling => 'NEW FILL-UP';

  @override
  String get historyNeedVehicle =>
      'Add and select a vehicle to see the history.';

  @override
  String get placeTypeStation => 'Gas station';

  @override
  String get placeTypeShop => 'Repair shop';

  @override
  String get placeTypeDealer => 'Dealership';

  @override
  String get placeTypeCarWash => 'Car wash';

  @override
  String get placeTypeInsurer => 'Insurance company';

  @override
  String get other => 'Other';

  @override
  String get expenseInsurance => 'Insurance';

  @override
  String get expenseCooperative => 'Mutual protection';

  @override
  String get expenseFinancing => 'Financing';

  @override
  String get expenseConsortium => 'Purchase pool';

  @override
  String get expenseOther => 'Other expense';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyYearly => 'Yearly';

  @override
  String get frequencyOnce => 'One-time payment';

  @override
  String get vehicleMotorcycle => 'Motorcycle';

  @override
  String get vehicleCar => 'Car';

  @override
  String get fuelGasoline => 'Gasoline';

  @override
  String get fuelEthanol => 'Ethanol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelNaturalGas => 'CNG';

  @override
  String get fuelElectric => 'Electric';

  @override
  String get fuelFlex => 'Flex-fuel';

  @override
  String get fuelHybrid => 'Hybrid';

  @override
  String get transmissionManual => 'Manual';

  @override
  String get transmissionAutomatic => 'Automatic';

  @override
  String get maintOilFilters => 'Oil and filters';

  @override
  String get maintEngine => 'Engine';

  @override
  String get maintBrakes => 'Brakes';

  @override
  String get maintSuspension => 'Suspension';

  @override
  String get maintTires => 'Tires';

  @override
  String get maintTransmission => 'Transmission';

  @override
  String get maintAirConditioning => 'Air conditioning';

  @override
  String get maintElectrical => 'Electrical';

  @override
  String get maintSteering => 'Steering';

  @override
  String get maintBelts => 'Belts';

  @override
  String get maintService => 'Scheduled service';

  @override
  String get maintOthers => 'Others';

  @override
  String get photoCarFront => 'Vehicle front';

  @override
  String get photoCarRear => 'Vehicle rear';

  @override
  String get photoLeftSide => 'Left side';

  @override
  String get photoRightSide => 'Right side';

  @override
  String get photoDashboard => 'Dashboard';

  @override
  String get photoSteeringWheel => 'Steering wheel';

  @override
  String get photoFrontLeftTire => 'Front left tire';

  @override
  String get photoFrontRightTire => 'Front right tire';

  @override
  String get photoRearLeftTire => 'Rear left tire';

  @override
  String get photoRearRightTire => 'Rear right tire';

  @override
  String get photoMotoFront => 'Motorcycle front';

  @override
  String get photoMotoRear => 'Motorcycle rear';

  @override
  String get photoHandlebar => 'Handlebar';

  @override
  String get photoFrontTire => 'Front tire';

  @override
  String get photoRearTire => 'Rear tire';

  @override
  String get photoExhaust => 'Exhaust';

  @override
  String get otherBrand => 'Other brand';

  @override
  String get otherModel => 'Other model';

  @override
  String get ocrReadError => 'Couldn\'t read the receipt. Try another photo.';

  @override
  String get ocrReviewTitle => 'Review recognized data';

  @override
  String get ocrStation => 'Station';

  @override
  String get ocrFueling => 'Fill-up';

  @override
  String get ocrTotalPrice => 'Total price';

  @override
  String get date => 'Date';

  @override
  String get ocrReviewHint => 'Review the fields before saving.';

  @override
  String get ocrNothing =>
      'Nothing was recognized. Try again in good light with the whole receipt visible.';

  @override
  String get ocrFill => 'FILL IN';

  @override
  String get fuelingNew => 'New fill-up';

  @override
  String get fuelingEdit => 'Edit fill-up';

  @override
  String get fuelingData => 'Fill-up details';

  @override
  String get totalValue => 'Total amount';

  @override
  String get mileage => 'Odometer (km)';

  @override
  String get fuelingMileageRequired => 'Required for the calculation';

  @override
  String get fuelingMileageInvalid => 'Enter a valid odometer reading';

  @override
  String get fuelingFullTankHint =>
      'Needed to calculate fuel economy accurately';

  @override
  String get tankCapacity => 'Total tank capacity';

  @override
  String get tankCapacityVehicleHint =>
      'Check the vehicle\'s manual. Used to calculate full-tank fuel economy';

  @override
  String get tankCapacityMissing =>
      'Add the tank capacity to the vehicle details to calculate fuel economy.';

  @override
  String get fuelingGaugeFull => 'Did the gauge show a full tank?';

  @override
  String get fuelingGaugeFullHint =>
      'Only real confirmations count toward estimated economy';

  @override
  String get optionalInfo => 'Optional information';

  @override
  String get receiptsSection => 'Receipts and proofs';

  @override
  String get fuelingSave => 'SAVE FILL-UP';

  @override
  String get notIdentified => 'Not identified';

  @override
  String get invalidValueShort => 'Invalid amount';

  @override
  String get maintSaveError => 'Couldn\'t save the maintenance.';

  @override
  String get maintSavedCalendarError =>
      'Maintenance saved. Couldn\'t finish the calendar reminder.';

  @override
  String get maintEdit => 'Edit maintenance';

  @override
  String get maintDoneShort => 'Completed';

  @override
  String get maintServiceDone => 'Service performed';

  @override
  String get maintServicePlanned => 'Planned service';

  @override
  String get maintServiceDescription => 'Service description';

  @override
  String get maintServiceExample => 'E.g.: Oil and filter change';

  @override
  String get maintServiceRequired => 'Enter the service';

  @override
  String get maintDateDone => 'Date performed';

  @override
  String get maintDatePlanned => 'Planned date';

  @override
  String get maintKmPlanned => 'Planned km';

  @override
  String get maintKmRequired => 'Enter the km';

  @override
  String get maintKmGreater => 'Must be higher than current';

  @override
  String get maintShop => 'Shop or mechanic (optional)';

  @override
  String get maintCosts => 'Costs';

  @override
  String get maintLabor => 'Labor';

  @override
  String get maintParts => 'Parts';

  @override
  String get maintNextKm => 'Next odometer reading';

  @override
  String get maintNextDate => 'Next date (optional)';

  @override
  String get maintCalendar => 'Phone calendar';

  @override
  String get maintAddToCalendar => 'Add to my calendar';

  @override
  String get maintCalendarHint => 'All-day event: MyCarApp Maintenance';

  @override
  String get maintNotesHint => 'Parts used, brands, warranties...';

  @override
  String get maintSave => 'SAVE MAINTENANCE';

  @override
  String get maintSaveNext => 'SAVE UPCOMING MAINTENANCE';

  @override
  String get notSetFem => 'Not set';

  @override
  String get calendarEventTitle => 'MyCarApp Maintenance';

  @override
  String get transferNoActiveVehicle => 'No active vehicle.';

  @override
  String get transferExcelError => 'Couldn\'t generate the Excel file.';

  @override
  String get transferUnknownFile => 'File not recognized by MyCarApp.';

  @override
  String get transferMissingVehicle => 'Vehicle missing.';

  @override
  String get transferInvalidCsv => 'Invalid CSV line.';

  @override
  String get transferEmptySheet => 'Empty spreadsheet.';

  @override
  String get storageVehiclesCorrupted =>
      'The local vehicles file is corrupted.';

  @override
  String get storagePhotoNotFound => 'Photo not found';

  @override
  String get storageFuelingsCorrupted =>
      'The local fill-ups file is corrupted.';

  @override
  String get storageMaintenanceCorrupted =>
      'The local maintenance file is corrupted.';

  @override
  String get storageExpensesCorrupted =>
      'The local expenses file is corrupted.';

  @override
  String get storagePlacesCorrupted => 'The local places file is corrupted.';

  @override
  String get docInvalidPdf => 'The selected file is not a valid PDF.';

  @override
  String get authAccountError => 'Couldn\'t access your Google account.';

  @override
  String get fieldRequired => 'Required field';

  @override
  String get vehicleSaveError =>
      'Couldn\'t save the vehicle. Please try again.';

  @override
  String get addVehicleTitle => 'Add vehicle';

  @override
  String get editVehicleTitle => 'Edit vehicle';

  @override
  String get vehicleIdentification => 'Identification';

  @override
  String get vehicleNickname => 'Vehicle nickname';

  @override
  String get vehicleNicknameMoto => 'E.g.: My motorcycle';

  @override
  String get vehicleNicknameCar => 'E.g.: My car';

  @override
  String get brand => 'Brand';

  @override
  String get brandName => 'Brand name';

  @override
  String get brandHint => 'Type the vehicle\'s brand';

  @override
  String get model => 'Model';

  @override
  String get modelName => 'Model name';

  @override
  String get modelHint => 'Type the vehicle\'s model';

  @override
  String get vehicleYear => 'Vehicle year';

  @override
  String get selectYear => 'Select the year';

  @override
  String get vehicleFeatures => 'Features';

  @override
  String get transmission => 'Transmission';

  @override
  String get currentMileage => 'Current odometer (km)';

  @override
  String get documentsByYear => 'Documents by year';

  @override
  String get vehiclePhotos => 'Vehicle photos';

  @override
  String get photoWhat => 'What\'s in the photo?';

  @override
  String get photoSelect => 'SELECT PHOTO';

  @override
  String get vehicleSave => 'SAVE VEHICLE';

  @override
  String get year => 'Year';

  @override
  String get docTaxPaid => 'Vehicle tax paid';

  @override
  String get docLicensingPaid => 'Registration renewed';

  @override
  String vehicleSaveErrorDetail(Object message) {
    return 'Couldn\'t save: $message';
  }

  @override
  String photoCount(Object count) {
    return '$count photo(s)';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportFuelTitle => 'Fuel spending';

  @override
  String get reportFuelSubtitle => 'Total spent and average price per liter';

  @override
  String get reportMaintTitle => 'Maintenance spending';

  @override
  String get reportMaintSubtitle => 'Completed maintenance only';

  @override
  String get period1Month => '1 month';

  @override
  String get period3Months => '3 months';

  @override
  String get period6Months => '6 months';

  @override
  String get period1Year => '1 year';

  @override
  String get period12Months => '12 months';

  @override
  String get periodAll => 'All';

  @override
  String get totalSpent => 'Total spent';

  @override
  String get reportNoFuelings => 'No fill-ups in this period.';

  @override
  String get monthlyBreakdown => 'MONTHLY BREAKDOWN';

  @override
  String get averageCost => 'Average cost';

  @override
  String get reportNoMaint => 'No completed maintenance in this period.';

  @override
  String reportMaintDoneOne(Object count) {
    return '$count maintenance completed';
  }

  @override
  String reportMaintDoneMany(Object count) {
    return '$count maintenance records completed';
  }

  @override
  String reportAverage(Object value) {
    return 'Average $value';
  }

  @override
  String fuelingCountOne(Object count) {
    return '$count fill-up';
  }

  @override
  String fuelingCountMany(Object count) {
    return '$count fill-ups';
  }

  @override
  String get reportConsumptionTitle => 'Estimated fuel economy';

  @override
  String get reportConsumptionSubtitle => 'Strict full-tank calculation';

  @override
  String get reportNeedVehicle =>
      'Add and select a vehicle to build the report.';

  @override
  String get reportLastConsumption => 'Last calculated economy';

  @override
  String get reportOverallAverage => 'Overall average';

  @override
  String get reportConfirmedTanks => 'Confirmed tanks';

  @override
  String get reportConsumptionHow =>
      'We only calculate between two fill-ups with odometer, tank capacity, full tank and confirmed gauge. Partial fill-ups in between count toward the liters.';

  @override
  String get reportConsumptionNeedTwo =>
      'At least two confirmed full tanks are needed to calculate fuel economy.';

  @override
  String get reportDiffPerFueling => 'DIFFERENCE PER FILL-UP';

  @override
  String reportLitersUsed(Object distance, Object liters) {
    return '$distance km • $liters L used';
  }

  @override
  String get reportBaseline => 'Baseline';

  @override
  String reportCapacityUsage(Object capacity, Object tanks) {
    return 'Capacity: $capacity L • Equivalent use: $tanks tank(s)';
  }

  @override
  String get sortCostPerKm => 'Cost per km';

  @override
  String get sortConsumption => 'Fuel economy';

  @override
  String get sortSpent => 'Amount spent';

  @override
  String get reportByStation => 'By gas station';

  @override
  String get reportByStationSubtitle => 'Where your car goes the furthest';

  @override
  String get reportStationRule =>
      'A result is assigned to a station only when every fill-up in that interval was at the same place with the same fuel.';

  @override
  String get reportStationEmpty =>
      'There are no complete intervals with a station yet to build this report.';

  @override
  String reportBestStation(Object name) {
    return 'Your best cost per km: $name';
  }

  @override
  String reportBestDetail(Object cost, Object consumption, Object count) {
    return '$cost/km • $consumption km/L • based on $count fill-up(s)';
  }

  @override
  String reportSecondPlace(Object name) {
    return 'Runner-up: $name';
  }

  @override
  String reportVsAverage(Object value) {
    return '$value% vs. average';
  }

  @override
  String get reportTotalCostPerKm => 'Total cost per km';

  @override
  String get reportTotalCostSubtitle =>
      'Fuel, maintenance and expenses combined';

  @override
  String get reportCostNeedTwo =>
      'At least two fill-ups with odometer readings in the period are needed for this report.';

  @override
  String get reportAnnualProjection => 'Yearly projection';

  @override
  String reportCostBreakdown(
    Object distance,
    Object total,
    Object fuel,
    Object maintenance,
    Object expenses,
  ) {
    return '$distance km driven • $total in total (fuel $fuel • maintenance $maintenance • expenses $expenses)';
  }

  @override
  String get reportProjectionNote =>
      'The yearly projection extends the monthly average of the selected period — it doesn\'t account for seasonality or one-off maintenance.';

  @override
  String get reportWorkshopUnknown => 'Shop not specified';

  @override
  String get reportByWorkshop => 'By repair shop';

  @override
  String get reportByWorkshopSubtitle => 'Where your maintenance money goes';

  @override
  String get reportCostPer1000 => 'Maintenance cost per 1,000 km';

  @override
  String get reportNoWorkshop => 'No maintenance with a shop in this period.';

  @override
  String get reportByWorkshopHeader => 'BY REPAIR SHOP';

  @override
  String get reportCompositionHeader => 'BREAKDOWN BY SERVICE TYPE';

  @override
  String get reportSameServiceHeader => 'SAME SERVICE, DIFFERENT SHOPS';

  @override
  String reportVisitsOne(Object count) {
    return '$count visit';
  }

  @override
  String reportVisitsMany(Object count) {
    return '$count visits';
  }

  @override
  String reportAvgTicket(Object value) {
    return 'average ticket $value';
  }

  @override
  String get reportRework =>
      'Possible rework: two visits of the same type within 30 days';

  @override
  String get homeCloudFoundTitle => 'Your data is in the cloud';

  @override
  String homeCloudFoundText(Object count) {
    return 'We found $count record(s) in your account backup, with photos and documents. Bring them to this phone?';
  }

  @override
  String get notNowUpper => 'NOT NOW';

  @override
  String get homeRestoring => 'Restoring your data...';

  @override
  String get homeRestoreLater =>
      'Couldn\'t restore right now. Try again in Account › Backup.';

  @override
  String get newsDocsTitle => 'MyCarApp updated';

  @override
  String get newsDocsText =>
      'PDF documents, upcoming maintenance and calendar integration are now available.';

  @override
  String get news134Title => 'MyCarApp: more complete and free';

  @override
  String get news134Text =>
      'Multiple vehicles, all gas stations, full reports and export are now free. Premium removes ads and backs up automatically to the cloud, including photos and documents.';

  @override
  String get news133Title => 'New MyCarApp version';

  @override
  String get news133Text =>
      'Simpler, more secure sign-in with your Google account, plus fixes and performance improvements.';

  @override
  String get maintOverdueTitle => 'Maintenance overdue';

  @override
  String get fuelLowTitle => 'Time to fill up';

  @override
  String fuelLowText(Object name) {
    return '$name is at about 20% of its estimated tank capacity.';
  }

  @override
  String get homeNeedVehicle => 'Add a vehicle first.';

  @override
  String get moreOptions => 'More options';

  @override
  String get rateApp => 'Rate the app';

  @override
  String get adsPrivacy => 'Ad privacy';

  @override
  String get activeVehicle => 'ACTIVE VEHICLE';

  @override
  String get selectVehicle => 'Select your vehicle';

  @override
  String get homeSpentMonth => 'Spent this month';

  @override
  String get homeLastConsumption => 'Last fuel economy';

  @override
  String get homeAveragePriceStations => 'Average price · see by station';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get homeMonthSpending => 'Monthly spending';

  @override
  String get nextMonth => 'Next month';

  @override
  String get homeMonthTotal => 'Monthly total';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get homeInsurance => 'Insurance and mutual protection';

  @override
  String get homeFinancing => 'Financing and purchase pool';

  @override
  String get homeOtherExpenses => 'Other expenses';

  @override
  String get homeSwipeMonths => 'Swipe to see other months';

  @override
  String get homeNewEntry => 'New entry';

  @override
  String get homeWhatToRecord => 'What do you want to record?';

  @override
  String get homeVehicleUse => 'VEHICLE USE';

  @override
  String get homeFuelingHint => 'Liters, amount, station and odometer';

  @override
  String get homeMaintHint => 'Completed service or upcoming maintenance';

  @override
  String get homeVehicleExpenses => 'VEHICLE EXPENSES';

  @override
  String get homeInsuranceEntry => 'Insurance or mutual protection';

  @override
  String get homeInsuranceHint =>
      'Vehicle protection and insurance installments';

  @override
  String get homeFinancingEntry => 'Financing or purchase pool';

  @override
  String get homeFinancingHint => 'Installments, due dates and progress';

  @override
  String get homeOtherHint => 'Parking, tolls, car wash and more';

  @override
  String daysCount(Object count) {
    return '$count days';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navFuelings => 'Fill-ups';

  @override
  String get navNew => 'New';

  @override
  String get navMore => 'More';

  @override
  String get forceUpdateTitle => 'Update MyCarApp';

  @override
  String get forceUpdateText =>
      'This version is no longer supported. Update to keep using the app; your data stays saved on your phone.';

  @override
  String get forceUpdateButton => 'UPDATE NOW';

  @override
  String adFreeMenuTitle(Object hours) {
    return 'Go ${hours}h without full-screen ads';
  }

  @override
  String get adFreeMenuSubtitle => 'Watch a short video. Banners still show.';

  @override
  String adFreeMenuActive(Object hours) {
    return 'No full-screen ads for ${hours}h more';
  }

  @override
  String get adFreeMenuActiveSubtitle => 'Banners still show.';

  @override
  String adFreeMenuAddMore(Object hours) {
    return 'Watch another video to add +${hours}h (max 9h)';
  }

  @override
  String afterAdRewarded(Object hours) {
    return 'Or watch a video and go ${hours}h without full-screen ads';
  }

  @override
  String get rewardedUnavailable =>
      'Video unavailable right now, try again later';

  @override
  String get rewardedNotEarned =>
      'Watch the video to the end to earn the ad-free period.';

  @override
  String rewardedEarned(Object hours) {
    return 'Done! No full-screen ads for ${hours}h. Banners still show.';
  }

  @override
  String get pdfExport => 'Export PDF';

  @override
  String get pdfFreeTitle => 'PDF report';

  @override
  String get pdfFreeText =>
      'On the free plan, each PDF report is unlocked by watching a video. Subscribe to Premium to generate it without videos.';

  @override
  String get pdfWatchAndGenerate => 'WATCH VIDEO AND GENERATE';

  @override
  String get pdfVideoNotEarned =>
      'Watch the video to the end to generate the PDF.';

  @override
  String get pdfShareSubject => 'MyCarApp report';

  @override
  String get pdfShareText => 'Vehicle report generated by MyCarApp.';

  @override
  String get pdfTitle => 'Vehicle report';

  @override
  String pdfPeriod(String period) {
    return 'Period: $period';
  }

  @override
  String pdfFooter(String date) {
    return 'Generated by MyCarApp on $date';
  }

  @override
  String get pdfVehicleSection => 'Vehicle';

  @override
  String get pdfSpendingSection => 'Spending';

  @override
  String get pdfLiters => 'Liters filled';

  @override
  String get pdfTotalAll => 'Total (fuel + maintenance)';

  @override
  String get pdfMonthCol => 'Month';

  @override
  String get pdfDistance => 'Distance in the period';

  @override
  String get pdfExpenses => 'Other expenses';

  @override
  String get pdfBestStation => 'Best station';

  @override
  String get pdfStationCol => 'Station';

  @override
  String get pdfFuelCol => 'Fuel';

  @override
  String get pdfFillUpsCol => 'Fill-ups';

  @override
  String get pdfMaintenanceList => 'Maintenance in the period';

  @override
  String get pdfDateCol => 'Date';

  @override
  String get pdfServiceCol => 'Service';

  @override
  String get pdfWorkshopCol => 'Shop';

  @override
  String get pdfCostCol => 'Cost';

  @override
  String get news140Title => 'MyCarApp Premium is here';

  @override
  String get news140Text =>
      'MyCarApp Premium is here: no ads, unlimited vehicles, maintenance and expenses without videos, receipt scanning, the full gas station ranking, reports by period, export and automatic backup. The free plan still tracks your fuel consumption, and all your records remain available.';

  @override
  String get surveyTitle => 'Before you go…';

  @override
  String get surveyText =>
      'What stopped you from subscribing now? It takes 5 seconds and helps improve MyCarApp.';

  @override
  String get surveyTooExpensive => 'Too expensive';

  @override
  String get surveyTooExpensiveHint =>
      'The price doesn\'t fit my budget right now';

  @override
  String get surveyStillExploring => 'I\'m still getting to know the app';

  @override
  String get surveyStillExploringHint =>
      'I want to use it more before deciding';

  @override
  String get surveyDontNeed => 'I don\'t need these features';

  @override
  String get surveyDontNeedHint => 'The free plan is enough for me';

  @override
  String get surveyPreferOneTime => 'I\'d rather pay once';

  @override
  String get surveyPreferOneTimeHint => 'I don\'t like subscriptions';

  @override
  String get surveyOther => 'Other reason';

  @override
  String get surveyOtherHint => 'None of the options above';

  @override
  String get surveySend => 'SEND ANSWER';

  @override
  String get surveyChooseOption => 'CHOOSE AN OPTION';

  @override
  String get surveySkip => 'Skip';

  @override
  String get surveyThanks =>
      'Thanks for your answer! You\'re still on the free plan, with all your records available.';

  @override
  String get exitOfferBadge => 'A ONE-TIME OFFER FOR YOU';

  @override
  String exitOfferTitle(int percent) {
    return 'We get it. How about $percent% off annual Premium?';
  }

  @override
  String get exitOfferTitleGeneric =>
      'We get it. How about a special discount on annual Premium?';

  @override
  String get exitOfferSubtitle =>
      'Valid only now and only once for this account.';

  @override
  String exitOfferExpiresIn(String time) {
    return 'Expires in $time';
  }

  @override
  String get exitOfferPlan => 'Annual Premium';

  @override
  String exitOfferFrom(String price) {
    return 'From $price to';
  }

  @override
  String get exitOfferFirstYear => 'for the 1st year';

  @override
  String exitOfferPerMonth(String price) {
    return 'That\'s $price per month';
  }

  @override
  String exitOfferButton(String price) {
    return 'GET IT FOR $price THE 1ST YEAR';
  }

  @override
  String exitOfferRenewal(String price) {
    return 'After the 1st year, it renews at $price per year. Cancel anytime on the Play Store.';
  }

  @override
  String get exitOfferNoThanks => 'No, thanks';

  @override
  String offerExitPercent(int percent) {
    return '$percent% off the 1st year';
  }

  @override
  String get offerExitGeneric => 'Special discount on the 1st year';

  @override
  String get stationPreliminaryBadge => 'Preliminary';

  @override
  String get stationPreliminaryNote =>
      'Preliminary value: it becomes final after 3 full-tank fill-ups at this station.';

  @override
  String get stationConsumptionAlert =>
      'Fuel economy very different from your average. It may be the fuel quality or an incomplete entry, such as a tank that wasn\'t full. Check this station\'s fill-ups.';
}
