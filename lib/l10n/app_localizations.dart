import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('pt'),
  ];

  /// No description provided for @loginErrorConfig.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível validar o acesso com Google. Tente novamente em alguns instantes.'**
  String get loginErrorConfig;

  /// No description provided for @loginErrorInterrupted.
  ///
  /// In pt, this message translates to:
  /// **'A entrada com Google foi interrompida. Tente novamente.'**
  String get loginErrorInterrupted;

  /// No description provided for @loginErrorCanceledMaybe.
  ///
  /// In pt, this message translates to:
  /// **'Entrada com Google interrompida. Se você escolheu uma conta, tente novamente em instantes.'**
  String get loginErrorCanceledMaybe;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar com Google. Tente novamente.'**
  String get loginErrorGeneric;

  /// No description provided for @errorCheckConnection.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão e tente novamente.'**
  String get errorCheckConnection;

  /// No description provided for @loginErrorOtherProvider.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta já usa outra forma de entrada.'**
  String get loginErrorOtherProvider;

  /// No description provided for @loginErrorCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Entrada com Google cancelada.'**
  String get loginErrorCanceled;

  /// No description provided for @appTagline.
  ///
  /// In pt, this message translates to:
  /// **'GESTÃO VEICULAR INTELIGENTE'**
  String get appTagline;

  /// No description provided for @loginSigningIn.
  ///
  /// In pt, this message translates to:
  /// **'ENTRANDO...'**
  String get loginSigningIn;

  /// No description provided for @loginWithGoogle.
  ///
  /// In pt, this message translates to:
  /// **'ENTRAR COM GOOGLE'**
  String get loginWithGoogle;

  /// No description provided for @loginHint.
  ///
  /// In pt, this message translates to:
  /// **'Entre com sua conta Google para usar o MyCarApp.'**
  String get loginHint;

  /// No description provided for @presentationSlogan.
  ///
  /// In pt, this message translates to:
  /// **'Tecnologia que acompanha o seu caminho.'**
  String get presentationSlogan;

  /// No description provided for @footerDevelopedBy.
  ///
  /// In pt, this message translates to:
  /// **'Desenvolvido por Giles Desenvolvimento de Softwares'**
  String get footerDevelopedBy;

  /// No description provided for @upsellSubscribe.
  ///
  /// In pt, this message translates to:
  /// **'ASSINAR'**
  String get upsellSubscribe;

  /// No description provided for @dismiss.
  ///
  /// In pt, this message translates to:
  /// **'Dispensar'**
  String get dismiss;

  /// No description provided for @upsellNoAdsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Chega de anúncios'**
  String get upsellNoAdsTitle;

  /// No description provided for @upsellNoAdsText.
  ///
  /// In pt, this message translates to:
  /// **'Assine o Premium e use o MyCarApp sem interrupções.'**
  String get upsellNoAdsText;

  /// No description provided for @upsellBackupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico protegido'**
  String get upsellBackupTitle;

  /// No description provided for @upsellBackupText.
  ///
  /// In pt, this message translates to:
  /// **'Backup automático na nuvem, com fotos e documentos.'**
  String get upsellBackupText;

  /// No description provided for @upsellReportsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novos relatórios'**
  String get upsellReportsTitle;

  /// No description provided for @upsellReportsText.
  ///
  /// In pt, this message translates to:
  /// **'Assinantes Premium recebem os novos relatórios do app.'**
  String get upsellReportsText;

  /// No description provided for @upsellUpdatesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações exclusivas'**
  String get upsellUpdatesTitle;

  /// No description provided for @upsellUpdatesText.
  ///
  /// In pt, this message translates to:
  /// **'Novidades lançadas primeiro para quem é Premium.'**
  String get upsellUpdatesText;

  /// No description provided for @upsellVehiclesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fotos e dados do veículo seguros'**
  String get upsellVehiclesTitle;

  /// No description provided for @upsellVehiclesText.
  ///
  /// In pt, this message translates to:
  /// **'Com o Premium, tudo vai para a nuvem automaticamente.'**
  String get upsellVehiclesText;

  /// No description provided for @upsellAdsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Use sem anúncios'**
  String get upsellAdsTitle;

  /// No description provided for @upsellAdsText.
  ///
  /// In pt, this message translates to:
  /// **'Assine o Premium e tire os anúncios do app.'**
  String get upsellAdsText;

  /// No description provided for @upsellFuelingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não perca seus abastecimentos'**
  String get upsellFuelingTitle;

  /// No description provided for @upsellFuelingText.
  ///
  /// In pt, this message translates to:
  /// **'Backup automático na nuvem, inclusive dos comprovantes.'**
  String get upsellFuelingText;

  /// No description provided for @upsellMaintenanceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Guarde o histórico de manutenção'**
  String get upsellMaintenanceTitle;

  /// No description provided for @upsellMaintenanceText.
  ///
  /// In pt, this message translates to:
  /// **'Com o backup automático, ele não se perde se o celular quebrar.'**
  String get upsellMaintenanceText;

  /// No description provided for @upsellExpensesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novos relatórios no Premium'**
  String get upsellExpensesTitle;

  /// No description provided for @upsellExpensesText.
  ///
  /// In pt, this message translates to:
  /// **'Assine e receba os novos relatórios e atualizações exclusivas.'**
  String get upsellExpensesText;

  /// No description provided for @afterAdTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cansou dos anúncios?'**
  String get afterAdTitle;

  /// No description provided for @afterAdSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Assine o MyCarApp Premium'**
  String get afterAdSubtitle;

  /// No description provided for @premiumPrices.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 15/mês ou R\$ 100/ano'**
  String get premiumPrices;

  /// No description provided for @afterAdSubscribe.
  ///
  /// In pt, this message translates to:
  /// **'ASSINAR O PREMIUM'**
  String get afterAdSubscribe;

  /// No description provided for @notNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get notNow;

  /// No description provided for @recoRatingText.
  ///
  /// In pt, this message translates to:
  /// **'Gostando de acompanhar seus gastos? Conta pra gente na Play Store.'**
  String get recoRatingText;

  /// No description provided for @recoReferralText.
  ///
  /// In pt, this message translates to:
  /// **'Curtiu o MyCarApp? Indique um amigo e ganhe desconto na assinatura.'**
  String get recoReferralText;

  /// No description provided for @recoRate.
  ///
  /// In pt, this message translates to:
  /// **'AVALIAR'**
  String get recoRate;

  /// No description provided for @recoRefer.
  ///
  /// In pt, this message translates to:
  /// **'INDICAR'**
  String get recoRefer;

  /// No description provided for @attachmentNotFound.
  ///
  /// In pt, this message translates to:
  /// **'O anexo não foi encontrado.'**
  String get attachmentNotFound;

  /// No description provided for @attachmentOpenError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir este anexo.'**
  String get attachmentOpenError;

  /// No description provided for @attachmentRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover anexo'**
  String get attachmentRemove;

  /// No description provided for @attachmentTakePhoto.
  ///
  /// In pt, this message translates to:
  /// **'TIRAR FOTO'**
  String get attachmentTakePhoto;

  /// No description provided for @attachmentAttach.
  ///
  /// In pt, this message translates to:
  /// **'ANEXAR'**
  String get attachmentAttach;

  /// No description provided for @attachmentReading.
  ///
  /// In pt, this message translates to:
  /// **'LENDO NOTA...'**
  String get attachmentReading;

  /// No description provided for @attachmentReadReceipt.
  ///
  /// In pt, this message translates to:
  /// **'LER NOTA E PREENCHER DADOS'**
  String get attachmentReadReceipt;

  /// No description provided for @attachmentHint.
  ///
  /// In pt, this message translates to:
  /// **'Imagens e arquivos PDF são aceitos.'**
  String get attachmentHint;

  /// No description provided for @establishmentCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar \"{name}\"'**
  String establishmentCreate(String name);

  /// No description provided for @fuelingNeedVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo antes do primeiro abastecimento.'**
  String get fuelingNeedVehicle;

  /// No description provided for @fuelingNeedLitersAndPrice.
  ///
  /// In pt, this message translates to:
  /// **'Informe os litros e o valor pago.'**
  String get fuelingNeedLitersAndPrice;

  /// No description provided for @fuelingOverfillTitle.
  ///
  /// In pt, this message translates to:
  /// **'Abastecimento inadequado'**
  String get fuelingOverfillTitle;

  /// No description provided for @fuelingOverfillMessage.
  ///
  /// In pt, this message translates to:
  /// **'{liters} L informados para um tanque de {capacity} L.'**
  String fuelingOverfillMessage(String liters, String capacity);

  /// No description provided for @quickFuelingAdded.
  ///
  /// In pt, this message translates to:
  /// **'Abastecimento rápido incluído'**
  String get quickFuelingAdded;

  /// No description provided for @fuelingSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar o abastecimento.'**
  String get fuelingSaveError;

  /// No description provided for @fuelingAdded.
  ///
  /// In pt, this message translates to:
  /// **'Abastecimento incluído'**
  String get fuelingAdded;

  /// No description provided for @quickFuelingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Abastecimento rápido'**
  String get quickFuelingTitle;

  /// No description provided for @liters.
  ///
  /// In pt, this message translates to:
  /// **'Litros'**
  String get liters;

  /// No description provided for @amountPaid.
  ///
  /// In pt, this message translates to:
  /// **'Valor pago'**
  String get amountPaid;

  /// No description provided for @fullFueling.
  ///
  /// In pt, this message translates to:
  /// **'ABASTECIMENTO COMPLETO'**
  String get fullFueling;

  /// No description provided for @featureNoAdsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Use sem anúncios'**
  String get featureNoAdsTitle;

  /// No description provided for @featureNoAdsText.
  ///
  /// In pt, this message translates to:
  /// **'Assinantes Premium usam o MyCarApp sem nenhum anúncio.'**
  String get featureNoAdsText;

  /// No description provided for @featureBackupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup automático na nuvem'**
  String get featureBackupTitle;

  /// No description provided for @featureBackupText.
  ///
  /// In pt, this message translates to:
  /// **'Tudo é salvo na sua conta automaticamente, inclusive fotos e documentos. Troque de celular sem perder nada.'**
  String get featureBackupText;

  /// No description provided for @featureReportsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novos relatórios'**
  String get featureReportsTitle;

  /// No description provided for @featureReportsText.
  ///
  /// In pt, this message translates to:
  /// **'Assinantes recebem os novos relatórios do MyCarApp.'**
  String get featureReportsText;

  /// No description provided for @featureUpdatesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações exclusivas'**
  String get featureUpdatesTitle;

  /// No description provided for @featureUpdatesText.
  ///
  /// In pt, this message translates to:
  /// **'Novidades lançadas primeiro, ou só, para assinantes Premium.'**
  String get featureUpdatesText;

  /// No description provided for @premiumYouArePremium.
  ///
  /// In pt, this message translates to:
  /// **'Você é Premium'**
  String get premiumYouArePremium;

  /// No description provided for @premiumFreePlan.
  ///
  /// In pt, this message translates to:
  /// **'Você está no plano gratuito'**
  String get premiumFreePlan;

  /// No description provided for @premiumActive.
  ///
  /// In pt, this message translates to:
  /// **'Sua assinatura do MyCarApp está ativa.'**
  String get premiumActive;

  /// No description provided for @premiumFreeIntro.
  ///
  /// In pt, this message translates to:
  /// **'Todos os recursos do app são gratuitos, com anúncios. Assine para usar sem anúncios e ter backup automático.'**
  String get premiumFreeIntro;

  /// No description provided for @loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loading;

  /// No description provided for @premiumOptionOffer.
  ///
  /// In pt, this message translates to:
  /// **'{plan} · oferta'**
  String premiumOptionOffer(Object plan);

  /// No description provided for @premiumWaitingPlay.
  ///
  /// In pt, this message translates to:
  /// **'AGUARDANDO GOOGLE PLAY...'**
  String get premiumWaitingPlay;

  /// No description provided for @premiumSignInToSubscribe.
  ///
  /// In pt, this message translates to:
  /// **'ENTRAR PARA ASSINAR'**
  String get premiumSignInToSubscribe;

  /// No description provided for @premiumRestore.
  ///
  /// In pt, this message translates to:
  /// **'RESTAURAR ASSINATURA'**
  String get premiumRestore;

  /// No description provided for @premiumBillingNote.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento processado pela Google Play. A assinatura tem renovação automática e pode ser cancelada pela Play Store.'**
  String get premiumBillingNote;

  /// No description provided for @premiumBackToApp.
  ///
  /// In pt, this message translates to:
  /// **'VOLTAR AO APP'**
  String get premiumBackToApp;

  /// No description provided for @benefitNoAds.
  ///
  /// In pt, this message translates to:
  /// **'Sem anúncios'**
  String get benefitNoAds;

  /// No description provided for @benefitBackup.
  ///
  /// In pt, this message translates to:
  /// **'Backup automático na nuvem, com fotos e documentos'**
  String get benefitBackup;

  /// No description provided for @planAnnual.
  ///
  /// In pt, this message translates to:
  /// **'Plano anual'**
  String get planAnnual;

  /// No description provided for @planMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Plano mensal'**
  String get planMonthly;

  /// No description provided for @perYear.
  ///
  /// In pt, this message translates to:
  /// **'{price}/ano'**
  String perYear(Object price);

  /// No description provided for @perMonth.
  ///
  /// In pt, this message translates to:
  /// **'{price}/mês'**
  String perMonth(Object price);

  /// No description provided for @priceOfferThen.
  ///
  /// In pt, this message translates to:
  /// **'{price} na oferta; depois {renewal}'**
  String priceOfferThen(Object price, Object renewal);

  /// No description provided for @storeCommError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a comunicação com a loja.'**
  String get storeCommError;

  /// No description provided for @storeUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Google Play não está disponível neste aparelho.'**
  String get storeUnavailable;

  /// No description provided for @storeProductNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Produto não encontrado. Confirme o ID no Google Play Console.'**
  String get storeProductNotFound;

  /// No description provided for @storeNoPlans.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum plano disponível para esta conta.'**
  String get storeNoPlans;

  /// No description provided for @storeAccessError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível acessar a Google Play.'**
  String get storeAccessError;

  /// No description provided for @storeSignInToSubscribe.
  ///
  /// In pt, this message translates to:
  /// **'Entre com sua conta Google para assinar.'**
  String get storeSignInToSubscribe;

  /// No description provided for @storePurchaseNotStarted.
  ///
  /// In pt, this message translates to:
  /// **'A compra não pôde ser iniciada.'**
  String get storePurchaseNotStarted;

  /// No description provided for @storePurchaseStartError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível iniciar a compra.'**
  String get storePurchaseStartError;

  /// No description provided for @storeSignInToRestore.
  ///
  /// In pt, this message translates to:
  /// **'Entre com sua conta Google para restaurar a assinatura.'**
  String get storeSignInToRestore;

  /// No description provided for @storeSearching.
  ///
  /// In pt, this message translates to:
  /// **'Procurando compras anteriores...'**
  String get storeSearching;

  /// No description provided for @storeRestored.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura restaurada.'**
  String get storeRestored;

  /// No description provided for @storeValidatingRestore.
  ///
  /// In pt, this message translates to:
  /// **'Compras consultadas. Validando com a Google Play...'**
  String get storeValidatingRestore;

  /// No description provided for @storeRestoreError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível restaurar as compras.'**
  String get storeRestoreError;

  /// No description provided for @storePending.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento pendente na Google Play.'**
  String get storePending;

  /// No description provided for @storeNotCompleted.
  ///
  /// In pt, this message translates to:
  /// **'A compra não foi concluída.'**
  String get storeNotCompleted;

  /// No description provided for @storeCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Compra cancelada.'**
  String get storeCanceled;

  /// No description provided for @storeSameAccount.
  ///
  /// In pt, this message translates to:
  /// **'Entre na mesma conta usada para iniciar a assinatura.'**
  String get storeSameAccount;

  /// No description provided for @storeNoVerificationData.
  ///
  /// In pt, this message translates to:
  /// **'A Google Play não forneceu os dados para validação.'**
  String get storeNoVerificationData;

  /// No description provided for @storeValidating.
  ///
  /// In pt, this message translates to:
  /// **'Validando assinatura com a Google Play...'**
  String get storeValidating;

  /// No description provided for @storeActive.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura MyCarApp ativa.'**
  String get storeActive;

  /// No description provided for @storeNotActive.
  ///
  /// In pt, this message translates to:
  /// **'A assinatura não está ativa na Google Play.'**
  String get storeNotActive;

  /// No description provided for @storeValidationError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível validar a assinatura. Tente restaurar novamente.'**
  String get storeValidationError;

  /// No description provided for @backupDone.
  ///
  /// In pt, this message translates to:
  /// **'Backup concluído.'**
  String get backupDone;

  /// No description provided for @backupRestoreCloudTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar da nuvem'**
  String get backupRestoreCloudTitle;

  /// No description provided for @backupRestoreCloudConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Isto traz os {count} registro(s) salvos na nuvem, com fotos e documentos, para este celular. Registros com o mesmo id são atualizados; nada deste celular é apagado.'**
  String backupRestoreCloudConfirm(Object count);

  /// No description provided for @backupRestoredCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} registro(s) restaurado(s).'**
  String backupRestoredCount(Object count);

  /// No description provided for @backupRestoreError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível restaurar. Verifique sua conexão.'**
  String get backupRestoreError;

  /// No description provided for @backupReadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler este backup.'**
  String get backupReadError;

  /// No description provided for @backupRestoreLegacyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar cópia antiga'**
  String get backupRestoreLegacyTitle;

  /// No description provided for @backupLegacyNothingNew.
  ///
  /// In pt, this message translates to:
  /// **'Esta cópia não tem nada além do que você já tem neste celular.'**
  String get backupLegacyNothingNew;

  /// No description provided for @backupLegacyImpact.
  ///
  /// In pt, this message translates to:
  /// **'Isto vai adicionar {added} registro(s) novo(s) e atualizar {updated} já existente(s). Nada é apagado.'**
  String backupLegacyImpact(Object added, Object updated);

  /// No description provided for @backupLegacyRestored.
  ///
  /// In pt, this message translates to:
  /// **'Cópia restaurada.'**
  String get backupLegacyRestored;

  /// No description provided for @backupLegacyRestoreError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível restaurar esta cópia.'**
  String get backupLegacyRestoreError;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'CANCELAR'**
  String get cancel;

  /// No description provided for @restore.
  ///
  /// In pt, this message translates to:
  /// **'RESTAURAR'**
  String get restore;

  /// No description provided for @backupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup e restauração'**
  String get backupTitle;

  /// No description provided for @backupRestoring.
  ///
  /// In pt, this message translates to:
  /// **'RESTAURANDO...'**
  String get backupRestoring;

  /// No description provided for @backupRestoreCloudButton.
  ///
  /// In pt, this message translates to:
  /// **'RESTAURAR DA NUVEM ({count})'**
  String backupRestoreCloudButton(Object count);

  /// No description provided for @backupLegacyHeader.
  ///
  /// In pt, this message translates to:
  /// **'CÓPIAS ANTIGAS'**
  String get backupLegacyHeader;

  /// No description provided for @backupLegacyHint.
  ///
  /// In pt, this message translates to:
  /// **'Feitas manualmente em versões anteriores do app. Não incluem fotos e documentos.'**
  String get backupLegacyHint;

  /// No description provided for @backupAutoActive.
  ///
  /// In pt, this message translates to:
  /// **'Backup automático ativo'**
  String get backupAutoActive;

  /// No description provided for @backupSending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando alterações...'**
  String get backupSending;

  /// No description provided for @backupFirstSoon.
  ///
  /// In pt, this message translates to:
  /// **'O primeiro backup começa em instantes.'**
  String get backupFirstSoon;

  /// No description provided for @backupLastAt.
  ///
  /// In pt, this message translates to:
  /// **'Último backup em {date}.'**
  String backupLastAt(Object date);

  /// No description provided for @backupWhatIsSaved.
  ///
  /// In pt, this message translates to:
  /// **'Veículos, abastecimentos, manutenções, despesas, locais, fotos, comprovantes e documentos são salvos na sua conta sempre que você faz uma alteração.'**
  String get backupWhatIsSaved;

  /// No description provided for @backupUploading.
  ///
  /// In pt, this message translates to:
  /// **'ENVIANDO...'**
  String get backupUploading;

  /// No description provided for @backupNow.
  ///
  /// In pt, this message translates to:
  /// **'FAZER BACKUP AGORA'**
  String get backupNow;

  /// No description provided for @backupIsPremium.
  ///
  /// In pt, this message translates to:
  /// **'Backup automático é Premium'**
  String get backupIsPremium;

  /// No description provided for @backupFreeExplain.
  ///
  /// In pt, this message translates to:
  /// **'No plano gratuito seus dados ficam só neste celular. Com o Premium, tudo é salvo na nuvem automaticamente, inclusive fotos e documentos, e volta com você ao trocar de aparelho.'**
  String get backupFreeExplain;

  /// No description provided for @learnAboutPremium.
  ///
  /// In pt, this message translates to:
  /// **'CONHECER O PREMIUM'**
  String get learnAboutPremium;

  /// No description provided for @backupLegacyTileInfo.
  ///
  /// In pt, this message translates to:
  /// **'{count} registro(s) • {size}'**
  String backupLegacyTileInfo(Object count, Object size);

  /// No description provided for @dateAtTime.
  ///
  /// In pt, this message translates to:
  /// **'{date} às {time}'**
  String dateAtTime(Object date, Object time);

  /// No description provided for @backupFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir o backup. Verifique sua conexão.'**
  String get backupFailed;

  /// No description provided for @backupSignInToRestore.
  ///
  /// In pt, this message translates to:
  /// **'Entre com sua conta para restaurar o backup.'**
  String get backupSignInToRestore;

  /// No description provided for @backupSignInRequired.
  ///
  /// In pt, this message translates to:
  /// **'Entre com sua conta para usar o backup em nuvem.'**
  String get backupSignInRequired;

  /// No description provided for @backupNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Backup não encontrado no Storage.'**
  String get backupNotFound;

  /// No description provided for @signInRequired.
  ///
  /// In pt, this message translates to:
  /// **'Entre na sua conta para usar este recurso.'**
  String get signInRequired;

  /// No description provided for @referralApplied.
  ///
  /// In pt, this message translates to:
  /// **'Código aplicado! O benefício será ativado após o primeiro pagamento.'**
  String get referralApplied;

  /// No description provided for @referralApplyError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível aplicar esse código. Verifique e tente novamente.'**
  String get referralApplyError;

  /// No description provided for @adminPremiumUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Acesso Premium gratuito atualizado.'**
  String get adminPremiumUpdated;

  /// No description provided for @adminPremiumUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o período.'**
  String get adminPremiumUpdateError;

  /// No description provided for @accountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minha conta'**
  String get accountTitle;

  /// No description provided for @accountSignInBackup.
  ///
  /// In pt, this message translates to:
  /// **'Entre para usar backup em nuvem e suporte'**
  String get accountSignInBackup;

  /// No description provided for @accountSignInReferral.
  ///
  /// In pt, this message translates to:
  /// **'Entre para usar indicações e descontos'**
  String get accountSignInReferral;

  /// No description provided for @accountUser.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get accountUser;

  /// No description provided for @supportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda, feedback e bugs'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Envie e acompanhe seus chamados'**
  String get supportSubtitle;

  /// No description provided for @adminTitle.
  ///
  /// In pt, this message translates to:
  /// **'Administração do teste'**
  String get adminTitle;

  /// No description provided for @adminPremiumUntil.
  ///
  /// In pt, this message translates to:
  /// **'Premium gratuito até {date}'**
  String adminPremiumUntil(Object date);

  /// No description provided for @adminChangeDate.
  ///
  /// In pt, this message translates to:
  /// **'ALTERAR DATA'**
  String get adminChangeDate;

  /// No description provided for @referralYourCode.
  ///
  /// In pt, this message translates to:
  /// **'Seu código de indicação'**
  String get referralYourCode;

  /// No description provided for @referralCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar código'**
  String get referralCopy;

  /// No description provided for @referralCopied.
  ///
  /// In pt, this message translates to:
  /// **'Código copiado.'**
  String get referralCopied;

  /// No description provided for @referralInvite.
  ///
  /// In pt, this message translates to:
  /// **'Convidar um amigo'**
  String get referralInvite;

  /// No description provided for @referralShareText.
  ///
  /// In pt, this message translates to:
  /// **'Uso o MyCarApp pra controlar os gastos do carro. Baixa com meu código de indicação {code} e ganha 30% de desconto no primeiro ano do Premium anual: {url}'**
  String referralShareText(Object code, Object url);

  /// No description provided for @referralReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebeu um código?'**
  String get referralReceived;

  /// No description provided for @referralCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de indicação'**
  String get referralCodeLabel;

  /// No description provided for @referralApplying.
  ///
  /// In pt, this message translates to:
  /// **'APLICANDO...'**
  String get referralApplying;

  /// No description provided for @referralApply.
  ///
  /// In pt, this message translates to:
  /// **'APLICAR CÓDIGO'**
  String get referralApply;

  /// No description provided for @bestOffer.
  ///
  /// In pt, this message translates to:
  /// **'Melhor oferta disponível'**
  String get bestOffer;

  /// No description provided for @signOut.
  ///
  /// In pt, this message translates to:
  /// **'SAIR DA CONTA'**
  String get signOut;

  /// No description provided for @accountBackupPitch.
  ///
  /// In pt, this message translates to:
  /// **'Salve tudo na nuvem, com fotos e documentos, e não perca nada ao trocar de celular.'**
  String get accountBackupPitch;

  /// No description provided for @backupDaysAgo.
  ///
  /// In pt, this message translates to:
  /// **'Último backup há {days} dia(s)'**
  String backupDaysAgo(Object days);

  /// No description provided for @backupLastOn.
  ///
  /// In pt, this message translates to:
  /// **'Último backup em {date}'**
  String backupLastOn(Object date);

  /// No description provided for @offerClosedTest3m.
  ///
  /// In pt, this message translates to:
  /// **'70% de desconto por 3 meses'**
  String get offerClosedTest3m;

  /// No description provided for @offerClosedTestYear.
  ///
  /// In pt, this message translates to:
  /// **'70% de desconto no primeiro ano'**
  String get offerClosedTestYear;

  /// No description provided for @offerFounders.
  ///
  /// In pt, this message translates to:
  /// **'50% de desconto no primeiro ano'**
  String get offerFounders;

  /// No description provided for @offerReferral.
  ///
  /// In pt, this message translates to:
  /// **'30% de desconto no primeiro ano'**
  String get offerReferral;

  /// No description provided for @offerReferralOld.
  ///
  /// In pt, this message translates to:
  /// **'50% de desconto por 3 meses'**
  String get offerReferralOld;

  /// No description provided for @offerSpecial.
  ///
  /// In pt, this message translates to:
  /// **'Oferta especial MyCarApp'**
  String get offerSpecial;

  /// No description provided for @notSet.
  ///
  /// In pt, this message translates to:
  /// **'não definida'**
  String get notSet;

  /// No description provided for @exportSubject.
  ///
  /// In pt, this message translates to:
  /// **'Exportação MyCarApp'**
  String get exportSubject;

  /// No description provided for @exportText.
  ///
  /// In pt, this message translates to:
  /// **'Dados do veículo exportados pelo MyCarApp.'**
  String get exportText;

  /// No description provided for @exportError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível exportar.'**
  String get exportError;

  /// No description provided for @importConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar informações?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmText.
  ///
  /// In pt, this message translates to:
  /// **'Um novo veículo será criado com os abastecimentos e manutenções do arquivo. Os dados atuais não serão sobrescritos.'**
  String get importConfirmText;

  /// No description provided for @importAction.
  ///
  /// In pt, this message translates to:
  /// **'IMPORTAR'**
  String get importAction;

  /// No description provided for @importDone.
  ///
  /// In pt, this message translates to:
  /// **'Importação concluída'**
  String get importDone;

  /// No description provided for @importSummary.
  ///
  /// In pt, this message translates to:
  /// **'{vehicle}\n{fuelings} abastecimento(s)\n{maintenances} manutenção(ões)'**
  String importSummary(Object vehicle, Object fuelings, Object maintenances);

  /// No description provided for @importError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível importar.'**
  String get importError;

  /// No description provided for @exportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar informações'**
  String get exportTitle;

  /// No description provided for @exportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvHint.
  ///
  /// In pt, this message translates to:
  /// **'Formato leve, compatível com planilhas e com o MyCarApp.'**
  String get exportCsvHint;

  /// No description provided for @exportExcel.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Excel'**
  String get exportExcel;

  /// No description provided for @exportExcelHint.
  ///
  /// In pt, this message translates to:
  /// **'Planilha XLSX pronta para compartilhar ou arquivar.'**
  String get exportExcelHint;

  /// No description provided for @importOtherDevice.
  ///
  /// In pt, this message translates to:
  /// **'Importar em outro aparelho'**
  String get importOtherDevice;

  /// No description provided for @importOtherDeviceHint.
  ///
  /// In pt, this message translates to:
  /// **'Leia um CSV ou Excel criado pelo MyCarApp.'**
  String get importOtherDeviceHint;

  /// No description provided for @exportInfo.
  ///
  /// In pt, this message translates to:
  /// **'A exportação utiliza o veículo ativo e inclui cadastro, abastecimentos e manutenções. Fotos e notas fiscais permanecem somente no aparelho por segurança.'**
  String get exportInfo;

  /// No description provided for @vehiclesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os veículos.'**
  String get vehiclesLoadError;

  /// No description provided for @vehicleAdded.
  ///
  /// In pt, this message translates to:
  /// **'Veículo incluído'**
  String get vehicleAdded;

  /// No description provided for @vehicleNowActive.
  ///
  /// In pt, this message translates to:
  /// **'{name} é o veículo ativo.'**
  String vehicleNowActive(Object name);

  /// No description provided for @vehicleDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir veículo?'**
  String get vehicleDeleteTitle;

  /// No description provided for @vehicleDeleteText.
  ///
  /// In pt, this message translates to:
  /// **'O cadastro e as fotos de {name} serão apagados do aparelho. Os abastecimentos já registrados serão preservados.'**
  String vehicleDeleteText(Object name);

  /// No description provided for @deleteAction.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR'**
  String get deleteAction;

  /// No description provided for @vehicleDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Veículo excluído.'**
  String get vehicleDeleted;

  /// No description provided for @vehicleDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir o veículo.'**
  String get vehicleDeleteError;

  /// No description provided for @vehiclesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meus veículos'**
  String get vehiclesTitle;

  /// No description provided for @newVehicle.
  ///
  /// In pt, this message translates to:
  /// **'NOVO VEÍCULO'**
  String get newVehicle;

  /// No description provided for @useThis.
  ///
  /// In pt, this message translates to:
  /// **'USAR ESTE'**
  String get useThis;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @vehiclesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum veículo cadastrado'**
  String get vehiclesEmptyTitle;

  /// No description provided for @vehiclesEmptyText.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre seu primeiro carro ou moto para começar a registrar abastecimentos.'**
  String get vehiclesEmptyText;

  /// No description provided for @addVehicle.
  ///
  /// In pt, this message translates to:
  /// **'CADASTRAR VEÍCULO'**
  String get addVehicle;

  /// No description provided for @placeArchived.
  ///
  /// In pt, this message translates to:
  /// **'{name} arquivado.'**
  String placeArchived(Object name);

  /// No description provided for @placesNothingToOrganize.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum local pendente de organização.'**
  String get placesNothingToOrganize;

  /// No description provided for @placesOrganized.
  ///
  /// In pt, this message translates to:
  /// **'{count} local(is) organizado(s).'**
  String placesOrganized(Object count);

  /// No description provided for @placesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meus locais'**
  String get placesTitle;

  /// No description provided for @placesOrganize.
  ///
  /// In pt, this message translates to:
  /// **'Organizar meus locais'**
  String get placesOrganize;

  /// No description provided for @archive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get archive;

  /// No description provided for @placesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum local cadastrado ainda.'**
  String get placesEmptyTitle;

  /// No description provided for @placesEmptyText.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre postos e oficinas ao lançar um abastecimento ou manutenção, ou organize os locais já digitados como texto.'**
  String get placesEmptyText;

  /// No description provided for @placesOrganizeButton.
  ///
  /// In pt, this message translates to:
  /// **'ORGANIZAR MEUS LOCAIS'**
  String get placesOrganizeButton;

  /// No description provided for @placeNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo local'**
  String get placeNew;

  /// No description provided for @placeEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar local'**
  String get placeEdit;

  /// No description provided for @name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome'**
  String get nameRequired;

  /// No description provided for @type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get type;

  /// No description provided for @placeBrand.
  ///
  /// In pt, this message translates to:
  /// **'Bandeira (opcional)'**
  String get placeBrand;

  /// No description provided for @placeAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço (opcional)'**
  String get placeAddress;

  /// No description provided for @placeNeighborhood.
  ///
  /// In pt, this message translates to:
  /// **'Bairro (opcional)'**
  String get placeNeighborhood;

  /// No description provided for @favorite.
  ///
  /// In pt, this message translates to:
  /// **'Favorito'**
  String get favorite;

  /// No description provided for @placeFavoriteHint.
  ///
  /// In pt, this message translates to:
  /// **'Fica no topo das sugestões rápidas'**
  String get placeFavoriteHint;

  /// No description provided for @saving.
  ///
  /// In pt, this message translates to:
  /// **'SALVANDO...'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR'**
  String get save;

  /// No description provided for @placesOrganizeIntro.
  ///
  /// In pt, this message translates to:
  /// **'Encontramos estes nomes digitados em lançamentos antigos. Selecione os que devem virar um local estruturado.'**
  String get placesOrganizeIntro;

  /// No description provided for @placesGroupInfo.
  ///
  /// In pt, this message translates to:
  /// **'{type} · {count} lançamento(s)'**
  String placesGroupInfo(Object type, Object count);

  /// No description provided for @organizing.
  ///
  /// In pt, this message translates to:
  /// **'ORGANIZANDO...'**
  String get organizing;

  /// No description provided for @placesUnify.
  ///
  /// In pt, this message translates to:
  /// **'UNIFICAR {count} SELECIONADO(S)'**
  String placesUnify(Object count);

  /// No description provided for @notifCustomize.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar notificações'**
  String get notifCustomize;

  /// No description provided for @notifCustomizeIntro.
  ///
  /// In pt, this message translates to:
  /// **'Escolha quais alertas deseja receber neste aparelho.'**
  String get notifCustomizeIntro;

  /// No description provided for @notifAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas as notificações'**
  String get notifAll;

  /// No description provided for @notifAllOn.
  ///
  /// In pt, this message translates to:
  /// **'Todas ativadas'**
  String get notifAllOn;

  /// No description provided for @notifSomeOn.
  ///
  /// In pt, this message translates to:
  /// **'Algumas ativadas'**
  String get notifSomeOn;

  /// No description provided for @notifAllOff.
  ///
  /// In pt, this message translates to:
  /// **'Todas desativadas'**
  String get notifAllOff;

  /// No description provided for @notifDisableAll.
  ///
  /// In pt, this message translates to:
  /// **'DESATIVAR TODAS'**
  String get notifDisableAll;

  /// No description provided for @notifEnableAll.
  ///
  /// In pt, this message translates to:
  /// **'ATIVAR TODAS'**
  String get notifEnableAll;

  /// No description provided for @notifNews.
  ///
  /// In pt, this message translates to:
  /// **'Novidades e atualizações'**
  String get notifNews;

  /// No description provided for @notifMaintenance.
  ///
  /// In pt, this message translates to:
  /// **'Próximas manutenções'**
  String get notifMaintenance;

  /// No description provided for @notifFuelLow.
  ///
  /// In pt, this message translates to:
  /// **'Combustível próximo de 20%'**
  String get notifFuelLow;

  /// No description provided for @notifTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notifTitle;

  /// No description provided for @notifClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar notificações'**
  String get notifClear;

  /// No description provided for @notifEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notificação'**
  String get notifEmpty;

  /// No description provided for @docsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os documentos.'**
  String get docsLoadError;

  /// No description provided for @fileUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo indisponível.'**
  String get fileUnavailable;

  /// No description provided for @docAttached.
  ///
  /// In pt, this message translates to:
  /// **'Documento anexado.'**
  String get docAttached;

  /// No description provided for @docAttachError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível anexar o PDF.'**
  String get docAttachError;

  /// No description provided for @docFileMissing.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo não foi encontrado. Anexe o documento novamente.'**
  String get docFileMissing;

  /// No description provided for @docNoPdfReader.
  ///
  /// In pt, this message translates to:
  /// **'Não há um leitor de PDF disponível no aparelho.'**
  String get docNoPdfReader;

  /// No description provided for @docDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir documento?'**
  String get docDeleteTitle;

  /// No description provided for @docDeleteText.
  ///
  /// In pt, this message translates to:
  /// **'A cópia armazenada no MyCarApp será removida.'**
  String get docDeleteText;

  /// No description provided for @docDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Documento excluído.'**
  String get docDeleted;

  /// No description provided for @docsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Documentos'**
  String get docsTitle;

  /// No description provided for @docDriverLicense.
  ///
  /// In pt, this message translates to:
  /// **'CNH-e'**
  String get docDriverLicense;

  /// No description provided for @docDriverLicenseHint.
  ///
  /// In pt, this message translates to:
  /// **'Carteira Nacional de Habilitação em PDF'**
  String get docDriverLicenseHint;

  /// No description provided for @docVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Documento do veículo'**
  String get docVehicle;

  /// No description provided for @docSelectVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um veículo para anexar o CRLV-e'**
  String get docSelectVehicle;

  /// No description provided for @docVehicleOf.
  ///
  /// In pt, this message translates to:
  /// **'CRLV-e de {name}'**
  String docVehicleOf(Object name);

  /// No description provided for @docAttachPdf.
  ///
  /// In pt, this message translates to:
  /// **'ANEXAR PDF'**
  String get docAttachPdf;

  /// No description provided for @docOpenPdf.
  ///
  /// In pt, this message translates to:
  /// **'ABRIR PDF'**
  String get docOpenPdf;

  /// No description provided for @docReplacePdf.
  ///
  /// In pt, this message translates to:
  /// **'Substituir PDF'**
  String get docReplacePdf;

  /// No description provided for @docsStorageNote.
  ///
  /// In pt, this message translates to:
  /// **'Os PDFs são copiados para o armazenamento interno do MyCarApp e permanecem somente neste aparelho.'**
  String get docsStorageNote;

  /// No description provided for @supportLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os chamados.'**
  String get supportLoadError;

  /// No description provided for @supportAdminTitle.
  ///
  /// In pt, this message translates to:
  /// **'Central de chamados · Admin'**
  String get supportAdminTitle;

  /// No description provided for @supportScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e feedback'**
  String get supportScreenTitle;

  /// No description provided for @supportNew.
  ///
  /// In pt, this message translates to:
  /// **'NOVO CHAMADO'**
  String get supportNew;

  /// No description provided for @supportEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum chamado aberto ainda.'**
  String get supportEmpty;

  /// No description provided for @supportSent.
  ///
  /// In pt, this message translates to:
  /// **'Chamado #{number} enviado.'**
  String supportSent(Object number);

  /// No description provided for @supportSendError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar o chamado.'**
  String get supportSendError;

  /// No description provided for @supportNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo chamado'**
  String get supportNewTitle;

  /// No description provided for @supportFeedback.
  ///
  /// In pt, this message translates to:
  /// **'Feedback'**
  String get supportFeedback;

  /// No description provided for @supportBug.
  ///
  /// In pt, this message translates to:
  /// **'Bug'**
  String get supportBug;

  /// No description provided for @supportSubject.
  ///
  /// In pt, this message translates to:
  /// **'Assunto'**
  String get supportSubject;

  /// No description provided for @supportSubjectRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o assunto'**
  String get supportSubjectRequired;

  /// No description provided for @supportDetails.
  ///
  /// In pt, this message translates to:
  /// **'Conte o que aconteceu'**
  String get supportDetails;

  /// No description provided for @supportDetailsHint.
  ///
  /// In pt, this message translates to:
  /// **'Se for um bug, descreva os passos até o problema.'**
  String get supportDetailsHint;

  /// No description provided for @supportDetailsRequired.
  ///
  /// In pt, this message translates to:
  /// **'Descreva com mais detalhes'**
  String get supportDetailsRequired;

  /// No description provided for @backupUploadingSend.
  ///
  /// In pt, this message translates to:
  /// **'ENVIANDO...'**
  String get backupUploadingSend;

  /// No description provided for @supportSend.
  ///
  /// In pt, this message translates to:
  /// **'ENVIAR CHAMADO'**
  String get supportSend;

  /// No description provided for @supportReply.
  ///
  /// In pt, this message translates to:
  /// **'Resposta do suporte'**
  String get supportReply;

  /// No description provided for @status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Aberto'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In pt, this message translates to:
  /// **'Resolvido'**
  String get statusResolved;

  /// No description provided for @supportReplyToUser.
  ///
  /// In pt, this message translates to:
  /// **'Resposta ao usuário'**
  String get supportReplyToUser;

  /// No description provided for @supportSaveReply.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR RESPOSTA'**
  String get supportSaveReply;

  /// No description provided for @supportSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Entre na sua conta para enviar e acompanhar chamados.'**
  String get supportSignIn;

  /// No description provided for @expenseNeedVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre e selecione um veículo primeiro.'**
  String get expenseNeedVehicle;

  /// No description provided for @expenseSaved.
  ///
  /// In pt, this message translates to:
  /// **'Despesa salva.'**
  String get expenseSaved;

  /// No description provided for @expenseDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir despesa?'**
  String get expenseDeleteTitle;

  /// No description provided for @expenseDeleteText.
  ///
  /// In pt, this message translates to:
  /// **'{title} será removida do histórico.'**
  String expenseDeleteText(Object title);

  /// No description provided for @expensesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get expensesTitle;

  /// No description provided for @expenseAdd.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR DESPESA'**
  String get expenseAdd;

  /// No description provided for @expenseNeedVehicleFirst.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo antes de adicionar despesas.'**
  String get expenseNeedVehicleFirst;

  /// No description provided for @expensesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre seguro, cooperativa, financiamento, consórcio ou outra despesa.'**
  String get expensesEmpty;

  /// No description provided for @expensesMonthlyRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Recorrentes no mês'**
  String get expensesMonthlyRecurring;

  /// No description provided for @expensesNextDue.
  ///
  /// In pt, this message translates to:
  /// **'Próximo vencimento'**
  String get expensesNextDue;

  /// No description provided for @expensesDueDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia {day}'**
  String expensesDueDay(Object day);

  /// No description provided for @expenseNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova despesa'**
  String get expenseNew;

  /// No description provided for @expenseEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar despesa'**
  String get expenseEdit;

  /// No description provided for @category.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get category;

  /// No description provided for @description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get description;

  /// No description provided for @descriptionRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma descrição'**
  String get descriptionRequired;

  /// No description provided for @amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get amount;

  /// No description provided for @invalidValue.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor válido'**
  String get invalidValue;

  /// No description provided for @frequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get frequency;

  /// No description provided for @expenseInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de parcelas'**
  String get expenseInstallments;

  /// No description provided for @expenseInstallmentsHint.
  ///
  /// In pt, this message translates to:
  /// **'Deixe vazio para uma cobrança sem prazo definido'**
  String get expenseInstallmentsHint;

  /// No description provided for @expenseFirstDue.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro vencimento'**
  String get expenseFirstDue;

  /// No description provided for @notes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get notes;

  /// No description provided for @expenseSave.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR DESPESA'**
  String get expenseSave;

  /// No description provided for @installmentOf.
  ///
  /// In pt, this message translates to:
  /// **'{current} de {total}'**
  String installmentOf(Object current, Object total);

  /// No description provided for @maintLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as manutenções.'**
  String get maintLoadError;

  /// No description provided for @maintDoneAdded.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção realizada incluída'**
  String get maintDoneAdded;

  /// No description provided for @maintNextAdded.
  ///
  /// In pt, this message translates to:
  /// **'Próxima manutenção incluída'**
  String get maintNextAdded;

  /// No description provided for @maintDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir manutenção?'**
  String get maintDeleteTitle;

  /// No description provided for @maintDeleteText.
  ///
  /// In pt, this message translates to:
  /// **'{service} será removida permanentemente.'**
  String maintDeleteText(Object service);

  /// No description provided for @maintDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção excluída.'**
  String get maintDeleted;

  /// No description provided for @maintDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir a manutenção.'**
  String get maintDeleteError;

  /// No description provided for @maintDone.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção realizada'**
  String get maintDone;

  /// No description provided for @maintDoneHint.
  ///
  /// In pt, this message translates to:
  /// **'Registrar serviço, oficina e custos'**
  String get maintDoneHint;

  /// No description provided for @maintNext.
  ///
  /// In pt, this message translates to:
  /// **'Próxima manutenção'**
  String get maintNext;

  /// No description provided for @maintNextHint.
  ///
  /// In pt, this message translates to:
  /// **'Planejar mesmo sem possuir histórico'**
  String get maintNextHint;

  /// No description provided for @maintTitle.
  ///
  /// In pt, this message translates to:
  /// **'Manutenções'**
  String get maintTitle;

  /// No description provided for @maintTabDone.
  ///
  /// In pt, this message translates to:
  /// **'REALIZADAS'**
  String get maintTabDone;

  /// No description provided for @maintTabNext.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMAS'**
  String get maintTabNext;

  /// No description provided for @maintNew.
  ///
  /// In pt, this message translates to:
  /// **'NOVA MANUTENÇÃO'**
  String get maintNew;

  /// No description provided for @maintEmptyDone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção realizada'**
  String get maintEmptyDone;

  /// No description provided for @maintEmptyNext.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma próxima manutenção planejada'**
  String get maintEmptyNext;

  /// No description provided for @thisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get thisMonth;

  /// No description provided for @total.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @alerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get alerts;

  /// No description provided for @maintNeedVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre e selecione um veículo para acessar as manutenções.'**
  String get maintNeedVehicle;

  /// No description provided for @maintOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencida'**
  String get maintOverdue;

  /// No description provided for @maintUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próxima'**
  String get maintUpcoming;

  /// No description provided for @maintPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Prevista'**
  String get maintPlanned;

  /// No description provided for @historyLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o histórico.'**
  String get historyLoadError;

  /// No description provided for @fuelingDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir abastecimento?'**
  String get fuelingDeleteTitle;

  /// No description provided for @fuelingDeleteText.
  ///
  /// In pt, this message translates to:
  /// **'O registro de {date} será removido permanentemente.'**
  String fuelingDeleteText(Object date);

  /// No description provided for @fuelingDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Abastecimento excluído.'**
  String get fuelingDeleted;

  /// No description provided for @fuelingDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir o abastecimento.'**
  String get fuelingDeleteError;

  /// No description provided for @historyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de abastecimentos'**
  String get historyTitle;

  /// No description provided for @fuelUp.
  ///
  /// In pt, this message translates to:
  /// **'ABASTECER'**
  String get fuelUp;

  /// No description provided for @historySpentMonth.
  ///
  /// In pt, this message translates to:
  /// **'Gasto no mês'**
  String get historySpentMonth;

  /// No description provided for @averagePrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço médio'**
  String get averagePrice;

  /// No description provided for @historyTotalLiters.
  ///
  /// In pt, this message translates to:
  /// **'Total abastecido'**
  String get historyTotalLiters;

  /// No description provided for @historyRecords.
  ///
  /// In pt, this message translates to:
  /// **'Registros'**
  String get historyRecords;

  /// No description provided for @fuel.
  ///
  /// In pt, this message translates to:
  /// **'Combustível'**
  String get fuel;

  /// No description provided for @fullTank.
  ///
  /// In pt, this message translates to:
  /// **'Tanque cheio'**
  String get fullTank;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum abastecimento de {name}'**
  String historyEmptyTitle(Object name);

  /// No description provided for @historyEmptyText.
  ///
  /// In pt, this message translates to:
  /// **'Registre litros, valor, quilometragem e tanque cheio para acompanhar gastos e consumo.'**
  String get historyEmptyText;

  /// No description provided for @newFueling.
  ///
  /// In pt, this message translates to:
  /// **'NOVO ABASTECIMENTO'**
  String get newFueling;

  /// No description provided for @historyNeedVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre e selecione um veículo para visualizar o histórico.'**
  String get historyNeedVehicle;

  /// No description provided for @placeTypeStation.
  ///
  /// In pt, this message translates to:
  /// **'Posto de combustível'**
  String get placeTypeStation;

  /// No description provided for @placeTypeShop.
  ///
  /// In pt, this message translates to:
  /// **'Oficina'**
  String get placeTypeShop;

  /// No description provided for @placeTypeDealer.
  ///
  /// In pt, this message translates to:
  /// **'Concessionária'**
  String get placeTypeDealer;

  /// No description provided for @placeTypeCarWash.
  ///
  /// In pt, this message translates to:
  /// **'Lava-jato'**
  String get placeTypeCarWash;

  /// No description provided for @placeTypeInsurer.
  ///
  /// In pt, this message translates to:
  /// **'Seguradora'**
  String get placeTypeInsurer;

  /// No description provided for @other.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get other;

  /// No description provided for @expenseInsurance.
  ///
  /// In pt, this message translates to:
  /// **'Seguro'**
  String get expenseInsurance;

  /// No description provided for @expenseCooperative.
  ///
  /// In pt, this message translates to:
  /// **'Cooperativa'**
  String get expenseCooperative;

  /// No description provided for @expenseFinancing.
  ///
  /// In pt, this message translates to:
  /// **'Financiamento'**
  String get expenseFinancing;

  /// No description provided for @expenseConsortium.
  ///
  /// In pt, this message translates to:
  /// **'Consórcio'**
  String get expenseConsortium;

  /// No description provided for @expenseOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra despesa'**
  String get expenseOther;

  /// No description provided for @frequencyMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get frequencyMonthly;

  /// No description provided for @frequencyYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get frequencyYearly;

  /// No description provided for @frequencyOnce.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento único'**
  String get frequencyOnce;

  /// No description provided for @vehicleMotorcycle.
  ///
  /// In pt, this message translates to:
  /// **'Moto'**
  String get vehicleMotorcycle;

  /// No description provided for @vehicleCar.
  ///
  /// In pt, this message translates to:
  /// **'Carro'**
  String get vehicleCar;

  /// No description provided for @fuelGasoline.
  ///
  /// In pt, this message translates to:
  /// **'Gasolina'**
  String get fuelGasoline;

  /// No description provided for @fuelEthanol.
  ///
  /// In pt, this message translates to:
  /// **'Etanol'**
  String get fuelEthanol;

  /// No description provided for @fuelDiesel.
  ///
  /// In pt, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelNaturalGas.
  ///
  /// In pt, this message translates to:
  /// **'GNV'**
  String get fuelNaturalGas;

  /// No description provided for @fuelElectric.
  ///
  /// In pt, this message translates to:
  /// **'Elétrico'**
  String get fuelElectric;

  /// No description provided for @fuelFlex.
  ///
  /// In pt, this message translates to:
  /// **'Flex'**
  String get fuelFlex;

  /// No description provided for @fuelHybrid.
  ///
  /// In pt, this message translates to:
  /// **'Híbrido'**
  String get fuelHybrid;

  /// No description provided for @transmissionManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get transmissionManual;

  /// No description provided for @transmissionAutomatic.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get transmissionAutomatic;

  /// No description provided for @maintOilFilters.
  ///
  /// In pt, this message translates to:
  /// **'Óleo e filtros'**
  String get maintOilFilters;

  /// No description provided for @maintEngine.
  ///
  /// In pt, this message translates to:
  /// **'Motor'**
  String get maintEngine;

  /// No description provided for @maintBrakes.
  ///
  /// In pt, this message translates to:
  /// **'Freios'**
  String get maintBrakes;

  /// No description provided for @maintSuspension.
  ///
  /// In pt, this message translates to:
  /// **'Suspensão'**
  String get maintSuspension;

  /// No description provided for @maintTires.
  ///
  /// In pt, this message translates to:
  /// **'Pneus'**
  String get maintTires;

  /// No description provided for @maintTransmission.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio'**
  String get maintTransmission;

  /// No description provided for @maintAirConditioning.
  ///
  /// In pt, this message translates to:
  /// **'Ar-condicionado'**
  String get maintAirConditioning;

  /// No description provided for @maintElectrical.
  ///
  /// In pt, this message translates to:
  /// **'Elétrica'**
  String get maintElectrical;

  /// No description provided for @maintSteering.
  ///
  /// In pt, this message translates to:
  /// **'Direção'**
  String get maintSteering;

  /// No description provided for @maintBelts.
  ///
  /// In pt, this message translates to:
  /// **'Correias'**
  String get maintBelts;

  /// No description provided for @maintService.
  ///
  /// In pt, this message translates to:
  /// **'Revisão'**
  String get maintService;

  /// No description provided for @maintOthers.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get maintOthers;

  /// No description provided for @photoCarFront.
  ///
  /// In pt, this message translates to:
  /// **'Frente do veículo'**
  String get photoCarFront;

  /// No description provided for @photoCarRear.
  ///
  /// In pt, this message translates to:
  /// **'Traseira do veículo'**
  String get photoCarRear;

  /// No description provided for @photoLeftSide.
  ///
  /// In pt, this message translates to:
  /// **'Lateral esquerda'**
  String get photoLeftSide;

  /// No description provided for @photoRightSide.
  ///
  /// In pt, this message translates to:
  /// **'Lateral direita'**
  String get photoRightSide;

  /// No description provided for @photoDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Painel'**
  String get photoDashboard;

  /// No description provided for @photoSteeringWheel.
  ///
  /// In pt, this message translates to:
  /// **'Volante'**
  String get photoSteeringWheel;

  /// No description provided for @photoFrontLeftTire.
  ///
  /// In pt, this message translates to:
  /// **'Pneu dianteiro esquerdo'**
  String get photoFrontLeftTire;

  /// No description provided for @photoFrontRightTire.
  ///
  /// In pt, this message translates to:
  /// **'Pneu dianteiro direito'**
  String get photoFrontRightTire;

  /// No description provided for @photoRearLeftTire.
  ///
  /// In pt, this message translates to:
  /// **'Pneu traseiro esquerdo'**
  String get photoRearLeftTire;

  /// No description provided for @photoRearRightTire.
  ///
  /// In pt, this message translates to:
  /// **'Pneu traseiro direito'**
  String get photoRearRightTire;

  /// No description provided for @photoMotoFront.
  ///
  /// In pt, this message translates to:
  /// **'Frente da moto'**
  String get photoMotoFront;

  /// No description provided for @photoMotoRear.
  ///
  /// In pt, this message translates to:
  /// **'Traseira da moto'**
  String get photoMotoRear;

  /// No description provided for @photoHandlebar.
  ///
  /// In pt, this message translates to:
  /// **'Guidão'**
  String get photoHandlebar;

  /// No description provided for @photoFrontTire.
  ///
  /// In pt, this message translates to:
  /// **'Pneu dianteiro'**
  String get photoFrontTire;

  /// No description provided for @photoRearTire.
  ///
  /// In pt, this message translates to:
  /// **'Pneu traseiro'**
  String get photoRearTire;

  /// No description provided for @photoExhaust.
  ///
  /// In pt, this message translates to:
  /// **'Escapamento'**
  String get photoExhaust;

  /// No description provided for @otherBrand.
  ///
  /// In pt, this message translates to:
  /// **'Outra marca'**
  String get otherBrand;

  /// No description provided for @otherModel.
  ///
  /// In pt, this message translates to:
  /// **'Outro modelo'**
  String get otherModel;

  /// No description provided for @ocrReadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler a nota. Tente outra foto.'**
  String get ocrReadError;

  /// No description provided for @ocrReviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conferir dados reconhecidos'**
  String get ocrReviewTitle;

  /// No description provided for @ocrStation.
  ///
  /// In pt, this message translates to:
  /// **'Posto'**
  String get ocrStation;

  /// No description provided for @ocrFueling.
  ///
  /// In pt, this message translates to:
  /// **'Abastecimento'**
  String get ocrFueling;

  /// No description provided for @ocrTotalPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço total'**
  String get ocrTotalPrice;

  /// No description provided for @date.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get date;

  /// No description provided for @ocrReviewHint.
  ///
  /// In pt, this message translates to:
  /// **'Revise os campos antes de salvar.'**
  String get ocrReviewHint;

  /// No description provided for @ocrNothing.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dado foi reconhecido. Tente fotografar novamente com boa luz e a nota inteira visível.'**
  String get ocrNothing;

  /// No description provided for @ocrFill.
  ///
  /// In pt, this message translates to:
  /// **'PREENCHER'**
  String get ocrFill;

  /// No description provided for @fuelingNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo abastecimento'**
  String get fuelingNew;

  /// No description provided for @fuelingEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar abastecimento'**
  String get fuelingEdit;

  /// No description provided for @fuelingData.
  ///
  /// In pt, this message translates to:
  /// **'Dados do abastecimento'**
  String get fuelingData;

  /// No description provided for @totalValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor total'**
  String get totalValue;

  /// No description provided for @mileage.
  ///
  /// In pt, this message translates to:
  /// **'Quilometragem'**
  String get mileage;

  /// No description provided for @fuelingMileageRequired.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatória para o cálculo'**
  String get fuelingMileageRequired;

  /// No description provided for @fuelingMileageInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma quilometragem válida'**
  String get fuelingMileageInvalid;

  /// No description provided for @fuelingFullTankHint.
  ///
  /// In pt, this message translates to:
  /// **'Necessário para calcular o consumo com precisão'**
  String get fuelingFullTankHint;

  /// No description provided for @tankCapacity.
  ///
  /// In pt, this message translates to:
  /// **'Capacidade total do tanque'**
  String get tankCapacity;

  /// No description provided for @tankCapacityHint.
  ///
  /// In pt, this message translates to:
  /// **'Consulte o manual do veículo'**
  String get tankCapacityHint;

  /// No description provided for @tankCapacityRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a capacidade do tanque'**
  String get tankCapacityRequired;

  /// No description provided for @fuelingGaugeFull.
  ///
  /// In pt, this message translates to:
  /// **'O marcador indicou tanque cheio?'**
  String get fuelingGaugeFull;

  /// No description provided for @fuelingGaugeFullHint.
  ///
  /// In pt, this message translates to:
  /// **'Somente confirmações reais entram no consumo estimado'**
  String get fuelingGaugeFullHint;

  /// No description provided for @optionalInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações opcionais'**
  String get optionalInfo;

  /// No description provided for @receiptsSection.
  ///
  /// In pt, this message translates to:
  /// **'Nota fiscal e comprovantes'**
  String get receiptsSection;

  /// No description provided for @fuelingSave.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ABASTECIMENTO'**
  String get fuelingSave;

  /// No description provided for @notIdentified.
  ///
  /// In pt, this message translates to:
  /// **'Não identificado'**
  String get notIdentified;

  /// No description provided for @invalidValueShort.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get invalidValueShort;

  /// No description provided for @maintSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a manutenção.'**
  String get maintSaveError;

  /// No description provided for @maintSavedCalendarError.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção salva. Não foi possível concluir o lembrete na agenda.'**
  String get maintSavedCalendarError;

  /// No description provided for @maintEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar manutenção'**
  String get maintEdit;

  /// No description provided for @maintDoneShort.
  ///
  /// In pt, this message translates to:
  /// **'Realizada'**
  String get maintDoneShort;

  /// No description provided for @maintServiceDone.
  ///
  /// In pt, this message translates to:
  /// **'Serviço realizado'**
  String get maintServiceDone;

  /// No description provided for @maintServicePlanned.
  ///
  /// In pt, this message translates to:
  /// **'Serviço previsto'**
  String get maintServicePlanned;

  /// No description provided for @maintServiceDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição do serviço'**
  String get maintServiceDescription;

  /// No description provided for @maintServiceExample.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Troca de óleo e filtro'**
  String get maintServiceExample;

  /// No description provided for @maintServiceRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o serviço'**
  String get maintServiceRequired;

  /// No description provided for @maintDateDone.
  ///
  /// In pt, this message translates to:
  /// **'Data realizada'**
  String get maintDateDone;

  /// No description provided for @maintDatePlanned.
  ///
  /// In pt, this message translates to:
  /// **'Data prevista'**
  String get maintDatePlanned;

  /// No description provided for @maintKmPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Km prevista'**
  String get maintKmPlanned;

  /// No description provided for @maintKmRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a km'**
  String get maintKmRequired;

  /// No description provided for @maintKmGreater.
  ///
  /// In pt, this message translates to:
  /// **'Maior que a atual'**
  String get maintKmGreater;

  /// No description provided for @maintShop.
  ///
  /// In pt, this message translates to:
  /// **'Oficina ou profissional (opcional)'**
  String get maintShop;

  /// No description provided for @maintCosts.
  ///
  /// In pt, this message translates to:
  /// **'Custos'**
  String get maintCosts;

  /// No description provided for @maintLabor.
  ///
  /// In pt, this message translates to:
  /// **'Mão de obra'**
  String get maintLabor;

  /// No description provided for @maintParts.
  ///
  /// In pt, this message translates to:
  /// **'Peças'**
  String get maintParts;

  /// No description provided for @maintNextKm.
  ///
  /// In pt, this message translates to:
  /// **'Próxima quilometragem'**
  String get maintNextKm;

  /// No description provided for @maintNextDate.
  ///
  /// In pt, this message translates to:
  /// **'Próxima data (opcional)'**
  String get maintNextDate;

  /// No description provided for @maintCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Agenda do telefone'**
  String get maintCalendar;

  /// No description provided for @maintAddToCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar à minha agenda'**
  String get maintAddToCalendar;

  /// No description provided for @maintCalendarHint.
  ///
  /// In pt, this message translates to:
  /// **'Evento de dia inteiro: MyCarApp Manutenção'**
  String get maintCalendarHint;

  /// No description provided for @maintNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Peças utilizadas, marcas, garantias...'**
  String get maintNotesHint;

  /// No description provided for @maintSave.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR MANUTENÇÃO'**
  String get maintSave;

  /// No description provided for @maintSaveNext.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR PRÓXIMA MANUTENÇÃO'**
  String get maintSaveNext;

  /// No description provided for @notSetFem.
  ///
  /// In pt, this message translates to:
  /// **'Não definida'**
  String get notSetFem;

  /// No description provided for @calendarEventTitle.
  ///
  /// In pt, this message translates to:
  /// **'MyCarApp Manutenção'**
  String get calendarEventTitle;

  /// No description provided for @transferNoActiveVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum veículo ativo.'**
  String get transferNoActiveVehicle;

  /// No description provided for @transferExcelError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao gerar Excel.'**
  String get transferExcelError;

  /// No description provided for @transferUnknownFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo não reconhecido pelo MyCarApp.'**
  String get transferUnknownFile;

  /// No description provided for @transferMissingVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Veículo ausente.'**
  String get transferMissingVehicle;

  /// No description provided for @transferInvalidCsv.
  ///
  /// In pt, this message translates to:
  /// **'Linha CSV inválida.'**
  String get transferInvalidCsv;

  /// No description provided for @transferEmptySheet.
  ///
  /// In pt, this message translates to:
  /// **'Planilha vazia.'**
  String get transferEmptySheet;

  /// No description provided for @storageVehiclesCorrupted.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo local de veículos está corrompido.'**
  String get storageVehiclesCorrupted;

  /// No description provided for @storagePhotoNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Foto não encontrada'**
  String get storagePhotoNotFound;

  /// No description provided for @storageFuelingsCorrupted.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo local de abastecimentos está corrompido.'**
  String get storageFuelingsCorrupted;

  /// No description provided for @storageMaintenanceCorrupted.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo local de manutenções está corrompido.'**
  String get storageMaintenanceCorrupted;

  /// No description provided for @storageExpensesCorrupted.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo local de despesas está corrompido.'**
  String get storageExpensesCorrupted;

  /// No description provided for @storagePlacesCorrupted.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo local de estabelecimentos está corrompido.'**
  String get storagePlacesCorrupted;

  /// No description provided for @docInvalidPdf.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo selecionado não é um PDF válido.'**
  String get docInvalidPdf;

  /// No description provided for @authAccountError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível acessar sua conta Google.'**
  String get authAccountError;

  /// No description provided for @fieldRequired.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get fieldRequired;

  /// No description provided for @vehicleSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar o veículo. Tente novamente.'**
  String get vehicleSaveError;

  /// No description provided for @addVehicleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar veículo'**
  String get addVehicleTitle;

  /// No description provided for @editVehicleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar veículo'**
  String get editVehicleTitle;

  /// No description provided for @vehicleIdentification.
  ///
  /// In pt, this message translates to:
  /// **'Identificação'**
  String get vehicleIdentification;

  /// No description provided for @vehicleNickname.
  ///
  /// In pt, this message translates to:
  /// **'Apelido do veículo'**
  String get vehicleNickname;

  /// No description provided for @vehicleNicknameMoto.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Minha moto'**
  String get vehicleNicknameMoto;

  /// No description provided for @vehicleNicknameCar.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Meu carro'**
  String get vehicleNicknameCar;

  /// No description provided for @brand.
  ///
  /// In pt, this message translates to:
  /// **'Marca'**
  String get brand;

  /// No description provided for @brandName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da marca'**
  String get brandName;

  /// No description provided for @brandHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite a marca do veículo'**
  String get brandHint;

  /// No description provided for @model.
  ///
  /// In pt, this message translates to:
  /// **'Modelo'**
  String get model;

  /// No description provided for @modelName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do modelo'**
  String get modelName;

  /// No description provided for @modelHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o modelo do veículo'**
  String get modelHint;

  /// No description provided for @vehicleYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano do veículo'**
  String get vehicleYear;

  /// No description provided for @selectYear.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o ano'**
  String get selectYear;

  /// No description provided for @vehicleFeatures.
  ///
  /// In pt, this message translates to:
  /// **'Características'**
  String get vehicleFeatures;

  /// No description provided for @transmission.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio'**
  String get transmission;

  /// No description provided for @currentMileage.
  ///
  /// In pt, this message translates to:
  /// **'Quilometragem atual'**
  String get currentMileage;

  /// No description provided for @documentsByYear.
  ///
  /// In pt, this message translates to:
  /// **'Documentação por ano'**
  String get documentsByYear;

  /// No description provided for @vehiclePhotos.
  ///
  /// In pt, this message translates to:
  /// **'Fotos do veículo'**
  String get vehiclePhotos;

  /// No description provided for @photoWhat.
  ///
  /// In pt, this message translates to:
  /// **'O que aparece na foto?'**
  String get photoWhat;

  /// No description provided for @photoSelect.
  ///
  /// In pt, this message translates to:
  /// **'SELECIONAR FOTO'**
  String get photoSelect;

  /// No description provided for @vehicleSave.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR VEÍCULO'**
  String get vehicleSave;

  /// No description provided for @year.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get year;

  /// No description provided for @docTaxPaid.
  ///
  /// In pt, this message translates to:
  /// **'IPVA pago'**
  String get docTaxPaid;

  /// No description provided for @docLicensingPaid.
  ///
  /// In pt, this message translates to:
  /// **'Licenciamento pago'**
  String get docLicensingPaid;

  /// No description provided for @vehicleSaveErrorDetail.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar: {message}'**
  String vehicleSaveErrorDetail(Object message);

  /// No description provided for @photoCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} foto(s)'**
  String photoCount(Object count);

  /// No description provided for @reportsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get reportsTitle;

  /// No description provided for @reportFuelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gastos com combustível'**
  String get reportFuelTitle;

  /// No description provided for @reportFuelSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Total gasto e preço médio por litro'**
  String get reportFuelSubtitle;

  /// No description provided for @reportMaintTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gastos com manutenções'**
  String get reportMaintTitle;

  /// No description provided for @reportMaintSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Somente manutenções realizadas'**
  String get reportMaintSubtitle;

  /// No description provided for @period1Month.
  ///
  /// In pt, this message translates to:
  /// **'1 mês'**
  String get period1Month;

  /// No description provided for @period3Months.
  ///
  /// In pt, this message translates to:
  /// **'3 meses'**
  String get period3Months;

  /// No description provided for @period6Months.
  ///
  /// In pt, this message translates to:
  /// **'6 meses'**
  String get period6Months;

  /// No description provided for @period1Year.
  ///
  /// In pt, this message translates to:
  /// **'1 ano'**
  String get period1Year;

  /// No description provided for @period12Months.
  ///
  /// In pt, this message translates to:
  /// **'12 meses'**
  String get period12Months;

  /// No description provided for @periodAll.
  ///
  /// In pt, this message translates to:
  /// **'Tudo'**
  String get periodAll;

  /// No description provided for @totalSpent.
  ///
  /// In pt, this message translates to:
  /// **'Total gasto'**
  String get totalSpent;

  /// No description provided for @reportNoFuelings.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum abastecimento neste período.'**
  String get reportNoFuelings;

  /// No description provided for @monthlyBreakdown.
  ///
  /// In pt, this message translates to:
  /// **'DETALHAMENTO POR MÊS'**
  String get monthlyBreakdown;

  /// No description provided for @averageCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo médio'**
  String get averageCost;

  /// No description provided for @reportNoMaint.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção realizada neste período.'**
  String get reportNoMaint;

  /// No description provided for @reportMaintDoneOne.
  ///
  /// In pt, this message translates to:
  /// **'{count} manutenção realizada'**
  String reportMaintDoneOne(Object count);

  /// No description provided for @reportMaintDoneMany.
  ///
  /// In pt, this message translates to:
  /// **'{count} manutenções realizadas'**
  String reportMaintDoneMany(Object count);

  /// No description provided for @reportAverage.
  ///
  /// In pt, this message translates to:
  /// **'Média {value}'**
  String reportAverage(Object value);

  /// No description provided for @fuelingCountOne.
  ///
  /// In pt, this message translates to:
  /// **'{count} abastecimento'**
  String fuelingCountOne(Object count);

  /// No description provided for @fuelingCountMany.
  ///
  /// In pt, this message translates to:
  /// **'{count} abastecimentos'**
  String fuelingCountMany(Object count);

  /// No description provided for @reportConsumptionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Consumo estimado'**
  String get reportConsumptionTitle;

  /// No description provided for @reportConsumptionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cálculo estrito por tanque cheio'**
  String get reportConsumptionSubtitle;

  /// No description provided for @reportNeedVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre e selecione um veículo para gerar o relatório.'**
  String get reportNeedVehicle;

  /// No description provided for @reportLastConsumption.
  ///
  /// In pt, this message translates to:
  /// **'Último consumo calculado'**
  String get reportLastConsumption;

  /// No description provided for @reportOverallAverage.
  ///
  /// In pt, this message translates to:
  /// **'Média geral'**
  String get reportOverallAverage;

  /// No description provided for @reportConfirmedTanks.
  ///
  /// In pt, this message translates to:
  /// **'Tanques confirmados'**
  String get reportConfirmedTanks;

  /// No description provided for @reportConsumptionHow.
  ///
  /// In pt, this message translates to:
  /// **'Só calculamos entre dois abastecimentos com quilometragem, capacidade informada, tanque cheio e marcador confirmado. Abastecimentos parciais no intervalo também entram na soma de litros.'**
  String get reportConsumptionHow;

  /// No description provided for @reportConsumptionNeedTwo.
  ///
  /// In pt, this message translates to:
  /// **'São necessários pelo menos dois tanques cheios confirmados para calcular o consumo.'**
  String get reportConsumptionNeedTwo;

  /// No description provided for @reportDiffPerFueling.
  ///
  /// In pt, this message translates to:
  /// **'DIFERENÇA POR ABASTECIMENTO'**
  String get reportDiffPerFueling;

  /// No description provided for @reportLitersUsed.
  ///
  /// In pt, this message translates to:
  /// **'{distance} km • {liters} L consumidos'**
  String reportLitersUsed(Object distance, Object liters);

  /// No description provided for @reportBaseline.
  ///
  /// In pt, this message translates to:
  /// **'Base de comparação'**
  String get reportBaseline;

  /// No description provided for @reportCapacityUsage.
  ///
  /// In pt, this message translates to:
  /// **'Capacidade: {capacity} L • Uso equivalente: {tanks} tanque(s)'**
  String reportCapacityUsage(Object capacity, Object tanks);

  /// No description provided for @sortCostPerKm.
  ///
  /// In pt, this message translates to:
  /// **'Custo por km'**
  String get sortCostPerKm;

  /// No description provided for @sortConsumption.
  ///
  /// In pt, this message translates to:
  /// **'Consumo'**
  String get sortConsumption;

  /// No description provided for @sortSpent.
  ///
  /// In pt, this message translates to:
  /// **'Valor gasto'**
  String get sortSpent;

  /// No description provided for @reportByStation.
  ///
  /// In pt, this message translates to:
  /// **'Por posto'**
  String get reportByStation;

  /// No description provided for @reportByStationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Onde seu carro rende mais'**
  String get reportByStationSubtitle;

  /// No description provided for @reportStationRule.
  ///
  /// In pt, this message translates to:
  /// **'Um resultado só é atribuído a um posto quando todos os abastecimentos daquele intervalo foram feitos no mesmo local e com o mesmo combustível.'**
  String get reportStationRule;

  /// No description provided for @reportStationEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há intervalos completos com posto informado para formar este relatório.'**
  String get reportStationEmpty;

  /// No description provided for @reportBestStation.
  ///
  /// In pt, this message translates to:
  /// **'Seu melhor custo por km: {name}'**
  String reportBestStation(Object name);

  /// No description provided for @reportSmallSample.
  ///
  /// In pt, this message translates to:
  /// **'{name} (amostra pequena)'**
  String reportSmallSample(Object name);

  /// No description provided for @reportBestDetail.
  ///
  /// In pt, this message translates to:
  /// **'{cost}/km • {consumption} km/L • baseado em {count} abastecimento(s)'**
  String reportBestDetail(Object cost, Object consumption, Object count);

  /// No description provided for @reportSecondPlace.
  ///
  /// In pt, this message translates to:
  /// **'2º colocado: {name}'**
  String reportSecondPlace(Object name);

  /// No description provided for @reportVsAverage.
  ///
  /// In pt, this message translates to:
  /// **'{value}% vs. média'**
  String reportVsAverage(Object value);

  /// No description provided for @smallSample.
  ///
  /// In pt, this message translates to:
  /// **'Amostra pequena'**
  String get smallSample;

  /// No description provided for @reportTotalCostPerKm.
  ///
  /// In pt, this message translates to:
  /// **'Custo total por km'**
  String get reportTotalCostPerKm;

  /// No description provided for @reportTotalCostSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Combustível, manutenções e despesas somados'**
  String get reportTotalCostSubtitle;

  /// No description provided for @reportCostNeedTwo.
  ///
  /// In pt, this message translates to:
  /// **'São necessários ao menos dois abastecimentos com quilometragem no período para calcular este relatório.'**
  String get reportCostNeedTwo;

  /// No description provided for @reportAnnualProjection.
  ///
  /// In pt, this message translates to:
  /// **'Projeção anual'**
  String get reportAnnualProjection;

  /// No description provided for @reportCostBreakdown.
  ///
  /// In pt, this message translates to:
  /// **'{distance} km rodados • {total} no total (combustível {fuel} • manutenção {maintenance} • despesas {expenses})'**
  String reportCostBreakdown(
    Object distance,
    Object total,
    Object fuel,
    Object maintenance,
    Object expenses,
  );

  /// No description provided for @reportProjectionNote.
  ///
  /// In pt, this message translates to:
  /// **'A projeção anual estende a média mensal do período selecionado — não considera sazonalidade nem manutenções pontuais fora do padrão.'**
  String get reportProjectionNote;

  /// No description provided for @reportWorkshopUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Oficina não informada'**
  String get reportWorkshopUnknown;

  /// No description provided for @reportByWorkshop.
  ///
  /// In pt, this message translates to:
  /// **'Por oficina'**
  String get reportByWorkshop;

  /// No description provided for @reportByWorkshopSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Onde seu dinheiro de manutenção vai'**
  String get reportByWorkshopSubtitle;

  /// No description provided for @reportCostPer1000.
  ///
  /// In pt, this message translates to:
  /// **'Custo de manutenção por 1.000 km'**
  String get reportCostPer1000;

  /// No description provided for @reportNoWorkshop.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção com oficina informada neste período.'**
  String get reportNoWorkshop;

  /// No description provided for @reportByWorkshopHeader.
  ///
  /// In pt, this message translates to:
  /// **'POR OFICINA'**
  String get reportByWorkshopHeader;

  /// No description provided for @reportCompositionHeader.
  ///
  /// In pt, this message translates to:
  /// **'COMPOSIÇÃO POR TIPO DE SERVIÇO'**
  String get reportCompositionHeader;

  /// No description provided for @reportSameServiceHeader.
  ///
  /// In pt, this message translates to:
  /// **'MESMO SERVIÇO, OFICINAS DIFERENTES'**
  String get reportSameServiceHeader;

  /// No description provided for @reportVisitsOne.
  ///
  /// In pt, this message translates to:
  /// **'{count} visita'**
  String reportVisitsOne(Object count);

  /// No description provided for @reportVisitsMany.
  ///
  /// In pt, this message translates to:
  /// **'{count} visitas'**
  String reportVisitsMany(Object count);

  /// No description provided for @reportAvgTicket.
  ///
  /// In pt, this message translates to:
  /// **'ticket médio {value}'**
  String reportAvgTicket(Object value);

  /// No description provided for @reportRework.
  ///
  /// In pt, this message translates to:
  /// **'Possível retrabalho: duas visitas do mesmo tipo em até 30 dias'**
  String get reportRework;

  /// No description provided for @homeCloudFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados estão na nuvem'**
  String get homeCloudFoundTitle;

  /// No description provided for @homeCloudFoundText.
  ///
  /// In pt, this message translates to:
  /// **'Encontramos {count} registro(s) no backup da sua conta, com fotos e documentos. Quer trazê-los para este celular?'**
  String homeCloudFoundText(Object count);

  /// No description provided for @notNowUpper.
  ///
  /// In pt, this message translates to:
  /// **'AGORA NÃO'**
  String get notNowUpper;

  /// No description provided for @homeRestoring.
  ///
  /// In pt, this message translates to:
  /// **'Restaurando seus dados...'**
  String get homeRestoring;

  /// No description provided for @homeRestoreLater.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível restaurar agora. Tente em Conta › Backup.'**
  String get homeRestoreLater;

  /// No description provided for @newsDocsTitle.
  ///
  /// In pt, this message translates to:
  /// **'MyCarApp atualizado'**
  String get newsDocsTitle;

  /// No description provided for @newsDocsText.
  ///
  /// In pt, this message translates to:
  /// **'Documentos em PDF, próximas manutenções e integração com a agenda já estão disponíveis.'**
  String get newsDocsText;

  /// No description provided for @news134Title.
  ///
  /// In pt, this message translates to:
  /// **'MyCarApp mais completo e gratuito'**
  String get news134Title;

  /// No description provided for @news134Text.
  ///
  /// In pt, this message translates to:
  /// **'Vários veículos, todos os postos, relatórios completos e exportação agora são gratuitos. O Premium remove os anúncios e faz backup automático na nuvem, inclusive de fotos e documentos.'**
  String get news134Text;

  /// No description provided for @news133Title.
  ///
  /// In pt, this message translates to:
  /// **'Nova versão do MyCarApp'**
  String get news133Title;

  /// No description provided for @news133Text.
  ///
  /// In pt, this message translates to:
  /// **'Login mais simples e seguro com sua conta Google, além de ajustes e melhorias de desempenho no sistema.'**
  String get news133Text;

  /// No description provided for @maintOverdueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção vencida'**
  String get maintOverdueTitle;

  /// No description provided for @fuelLowTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hora de abastecer'**
  String get fuelLowTitle;

  /// No description provided for @fuelLowText.
  ///
  /// In pt, this message translates to:
  /// **'{name} atingiu aproximadamente 20% da capacidade estimada do tanque.'**
  String fuelLowText(Object name);

  /// No description provided for @homeNeedVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo primeiro.'**
  String get homeNeedVehicle;

  /// No description provided for @moreOptions.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get moreOptions;

  /// No description provided for @rateApp.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar o app'**
  String get rateApp;

  /// No description provided for @adsPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade de anúncios'**
  String get adsPrivacy;

  /// No description provided for @activeVehicle.
  ///
  /// In pt, this message translates to:
  /// **'VEÍCULO ATIVO'**
  String get activeVehicle;

  /// No description provided for @selectVehicle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione seu veículo'**
  String get selectVehicle;

  /// No description provided for @homeSpentMonth.
  ///
  /// In pt, this message translates to:
  /// **'Saída neste mês'**
  String get homeSpentMonth;

  /// No description provided for @homeLastConsumption.
  ///
  /// In pt, this message translates to:
  /// **'Último consumo'**
  String get homeLastConsumption;

  /// No description provided for @homeAveragePriceStations.
  ///
  /// In pt, this message translates to:
  /// **'Preço médio · ver por posto'**
  String get homeAveragePriceStations;

  /// No description provided for @previousMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês anterior'**
  String get previousMonth;

  /// No description provided for @homeMonthSpending.
  ///
  /// In pt, this message translates to:
  /// **'Gastos do mês'**
  String get homeMonthSpending;

  /// No description provided for @nextMonth.
  ///
  /// In pt, this message translates to:
  /// **'Próximo mês'**
  String get nextMonth;

  /// No description provided for @homeMonthTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total do mês'**
  String get homeMonthTotal;

  /// No description provided for @maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get maintenance;

  /// No description provided for @homeInsurance.
  ///
  /// In pt, this message translates to:
  /// **'Seguro e cooperativa'**
  String get homeInsurance;

  /// No description provided for @homeFinancing.
  ///
  /// In pt, this message translates to:
  /// **'Financiamento e consórcio'**
  String get homeFinancing;

  /// No description provided for @homeOtherExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Outras despesas'**
  String get homeOtherExpenses;

  /// No description provided for @homeSwipeMonths.
  ///
  /// In pt, this message translates to:
  /// **'Arraste para ver outros meses'**
  String get homeSwipeMonths;

  /// No description provided for @homeNewEntry.
  ///
  /// In pt, this message translates to:
  /// **'Novo lançamento'**
  String get homeNewEntry;

  /// No description provided for @homeWhatToRecord.
  ///
  /// In pt, this message translates to:
  /// **'O que você deseja registrar?'**
  String get homeWhatToRecord;

  /// No description provided for @homeVehicleUse.
  ///
  /// In pt, this message translates to:
  /// **'USO DO VEÍCULO'**
  String get homeVehicleUse;

  /// No description provided for @homeFuelingHint.
  ///
  /// In pt, this message translates to:
  /// **'Litros, valor, posto e quilometragem'**
  String get homeFuelingHint;

  /// No description provided for @homeMaintHint.
  ///
  /// In pt, this message translates to:
  /// **'Serviço realizado ou próxima manutenção'**
  String get homeMaintHint;

  /// No description provided for @homeVehicleExpenses.
  ///
  /// In pt, this message translates to:
  /// **'DESPESAS DO VEÍCULO'**
  String get homeVehicleExpenses;

  /// No description provided for @homeInsuranceEntry.
  ///
  /// In pt, this message translates to:
  /// **'Seguro ou cooperativa'**
  String get homeInsuranceEntry;

  /// No description provided for @homeInsuranceHint.
  ///
  /// In pt, this message translates to:
  /// **'Proteção veicular e parcelas do seguro'**
  String get homeInsuranceHint;

  /// No description provided for @homeFinancingEntry.
  ///
  /// In pt, this message translates to:
  /// **'Financiamento ou consórcio'**
  String get homeFinancingEntry;

  /// No description provided for @homeFinancingHint.
  ///
  /// In pt, this message translates to:
  /// **'Parcelas, vencimentos e andamento'**
  String get homeFinancingHint;

  /// No description provided for @homeOtherHint.
  ///
  /// In pt, this message translates to:
  /// **'Estacionamento, pedágio, lavagem e outros'**
  String get homeOtherHint;

  /// No description provided for @daysCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias'**
  String daysCount(Object count);

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navFuelings.
  ///
  /// In pt, this message translates to:
  /// **'Abastecimentos'**
  String get navFuelings;

  /// No description provided for @navNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get navNew;

  /// No description provided for @navMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get navMore;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualize o MyCarApp'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateText.
  ///
  /// In pt, this message translates to:
  /// **'Esta versão não é mais compatível. Atualize para continuar usando o app; seus dados continuam salvos no celular.'**
  String get forceUpdateText;

  /// No description provided for @forceUpdateButton.
  ///
  /// In pt, this message translates to:
  /// **'ATUALIZAR AGORA'**
  String get forceUpdateButton;

  /// No description provided for @adFreeMenuTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ficar {hours}h sem anúncios em tela cheia'**
  String adFreeMenuTitle(Object hours);

  /// No description provided for @adFreeMenuSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Assista a um vídeo curto. Os banners continuam.'**
  String get adFreeMenuSubtitle;

  /// No description provided for @adFreeMenuActive.
  ///
  /// In pt, this message translates to:
  /// **'Sem anúncios em tela cheia por mais {hours}h'**
  String adFreeMenuActive(Object hours);

  /// No description provided for @adFreeMenuActiveSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Os banners continuam aparecendo.'**
  String get adFreeMenuActiveSubtitle;

  /// No description provided for @adFreeMenuAddMore.
  ///
  /// In pt, this message translates to:
  /// **'Assista a outro vídeo para somar +{hours}h (máx. 9h)'**
  String adFreeMenuAddMore(Object hours);

  /// No description provided for @afterAdRewarded.
  ///
  /// In pt, this message translates to:
  /// **'Ou assista a um vídeo e fique {hours}h sem anúncios em tela cheia'**
  String afterAdRewarded(Object hours);

  /// No description provided for @rewardedUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Vídeo indisponível no momento, tente mais tarde'**
  String get rewardedUnavailable;

  /// No description provided for @rewardedNotEarned.
  ///
  /// In pt, this message translates to:
  /// **'Assista ao vídeo até o fim para ganhar o período sem anúncios.'**
  String get rewardedNotEarned;

  /// No description provided for @rewardedEarned.
  ///
  /// In pt, this message translates to:
  /// **'Pronto! Sem anúncios em tela cheia por {hours}h. Os banners continuam.'**
  String rewardedEarned(Object hours);
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
