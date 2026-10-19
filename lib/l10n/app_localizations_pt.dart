// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get loginErrorConfig =>
      'Não foi possível validar o acesso com Google. Tente novamente em alguns instantes.';

  @override
  String get loginErrorInterrupted =>
      'A entrada com Google foi interrompida. Tente novamente.';

  @override
  String get loginErrorCanceledMaybe =>
      'Entrada com Google interrompida. Se você escolheu uma conta, tente novamente em instantes.';

  @override
  String get loginErrorGeneric =>
      'Não foi possível entrar com Google. Tente novamente.';

  @override
  String get errorCheckConnection => 'Verifique sua conexão e tente novamente.';

  @override
  String get loginErrorOtherProvider =>
      'Esta conta já usa outra forma de entrada.';

  @override
  String get loginErrorCanceled => 'Entrada com Google cancelada.';

  @override
  String get appTagline => 'GESTÃO VEICULAR INTELIGENTE';

  @override
  String get loginSigningIn => 'ENTRANDO...';

  @override
  String get loginWithGoogle => 'ENTRAR COM GOOGLE';

  @override
  String get loginHint => 'Entre com sua conta Google para usar o MyCarApp.';

  @override
  String get presentationSlogan => 'Tecnologia que acompanha o seu caminho.';

  @override
  String get footerDevelopedBy =>
      'Desenvolvido por Giles Desenvolvimento de Softwares';

  @override
  String get upsellSubscribe => 'ASSINAR';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get upsellNoAdsTitle => 'Chega de anúncios';

  @override
  String get upsellNoAdsText =>
      'Assine o Premium e use o MyCarApp sem interrupções.';

  @override
  String get upsellBackupTitle => 'Seu histórico protegido';

  @override
  String get upsellBackupText =>
      'Backup automático na nuvem, com fotos e documentos.';

  @override
  String get upsellVehiclesTitle => 'Veículos ilimitados';

  @override
  String get upsellVehiclesText =>
      'Assinantes Premium cadastram quantos veículos quiserem.';

  @override
  String get upsellReceiptTitle => 'Leitura automática da nota fiscal';

  @override
  String get upsellReceiptText =>
      'Fotografe a nota e deixe o Premium preencher o abastecimento pra você.';

  @override
  String get upsellAdsTitle => 'Use sem anúncios';

  @override
  String get upsellAdsText => 'Assine o Premium e tire os anúncios do app.';

  @override
  String get upsellFuelingTitle => 'Abastecimentos sem vídeo';

  @override
  String get upsellFuelingText =>
      'Assinantes Premium registram todos os abastecimentos do mês sem assistir a vídeos.';

  @override
  String get upsellMaintenanceTitle => 'Manutenções e despesas sem vídeo';

  @override
  String get upsellMaintenanceText =>
      'Assinantes Premium registram sem precisar assistir a vídeos.';

  @override
  String get upsellExpensesTitle => 'Relatórios por período';

  @override
  String get upsellExpensesText =>
      'Assine e compare seus gastos em qualquer período, não só no padrão do app.';

  @override
  String get afterAdTitle => 'Cansou dos anúncios?';

  @override
  String get afterAdSubtitle => 'Assine o MyCarApp Premium';

  @override
  String afterAdPriceFrom(Object price) {
    return 'a partir de $price/mês';
  }

  @override
  String get subscriptionPlansAvailable => 'Planos mensal e anual';

  @override
  String get afterAdSubscribe => 'ASSINAR O PREMIUM';

  @override
  String get notNow => 'Agora não';

  @override
  String get recoRatingText =>
      'Gostando de acompanhar seus gastos? Conta pra gente na Play Store.';

  @override
  String get recoReferralText =>
      'Curtiu o MyCarApp? Indique um amigo e ganhe desconto na assinatura.';

  @override
  String get recoRate => 'AVALIAR';

  @override
  String get recoRefer => 'INDICAR';

  @override
  String get houseAdAuctionText =>
      'Leilões de imóveis e veículos do ES em um só lugar.';

  @override
  String get houseAdAuctionCta => 'VER LEILÕES';

  @override
  String get attachmentNotFound => 'O anexo não foi encontrado.';

  @override
  String get attachmentOpenError => 'Não foi possível abrir este anexo.';

  @override
  String get attachmentRemove => 'Remover anexo';

  @override
  String get attachmentTakePhoto => 'TIRAR FOTO';

  @override
  String get attachmentAttach => 'ANEXAR';

  @override
  String get attachmentReading => 'LENDO NOTA...';

  @override
  String get attachmentReadReceipt => 'LER NOTA E PREENCHER DADOS';

  @override
  String get attachmentHint => 'Imagens e arquivos PDF são aceitos.';

  @override
  String establishmentCreate(String name) {
    return 'Criar \"$name\"';
  }

  @override
  String get fuelingNeedVehicle =>
      'Cadastre um veículo antes do primeiro abastecimento.';

  @override
  String get fuelingNeedLitersAndPrice => 'Informe os litros e o valor pago.';

  @override
  String get fuelingOverfillTitle => 'Abastecimento inadequado';

  @override
  String fuelingOverfillMessage(String liters, String capacity) {
    return '$liters L informados para um tanque de $capacity L.';
  }

  @override
  String get quickFuelingAdded => 'Abastecimento rápido incluído';

  @override
  String get fuelingSaveError => 'Não foi possível salvar o abastecimento.';

  @override
  String get fuelingAdded => 'Abastecimento incluído';

  @override
  String get quickFuelingTitle => 'Abastecimento rápido';

  @override
  String get liters => 'Litros';

  @override
  String get amountPaid => 'Valor pago';

  @override
  String get fullFueling => 'ABASTECIMENTO COMPLETO';

  @override
  String get featureNoAdsTitle => 'Use sem anúncios';

  @override
  String get featureNoAdsText =>
      'Assinantes Premium usam o MyCarApp sem nenhum anúncio.';

  @override
  String get featureBackupTitle => 'Backup automático na nuvem';

  @override
  String get featureBackupText =>
      'Tudo é salvo na sua conta automaticamente, inclusive fotos e documentos. Troque de celular sem perder nada.';

  @override
  String get featureVehiclesTitle => 'Mais veículos';

  @override
  String get featureVehiclesText =>
      'Assinantes Premium cadastram quantos veículos quiserem.';

  @override
  String get featureFuelingsTitle => 'Abastecimentos ilimitados';

  @override
  String get featureFuelingsText =>
      'Registre todos os abastecimentos do mês sem precisar assistir a vídeos.';

  @override
  String get featureMaintenanceTitle => 'Manutenções e despesas sem limite';

  @override
  String get featureMaintenanceText =>
      'Registre manutenções, despesas e alertas sem assistir a vídeos.';

  @override
  String get featureReceiptScanTitle => 'Leitura de nota fiscal';

  @override
  String get featureReceiptScanText =>
      'Fotografe a nota e deixe o MyCarApp preencher o abastecimento pra você.';

  @override
  String get featureStationRankingTitle => 'Ranking completo de postos';

  @override
  String get featureStationRankingText =>
      'Veja o ranking completo dos postos onde seu carro rende mais.';

  @override
  String get featurePeriodReportsTitle => 'Relatórios por período';

  @override
  String get featurePeriodReportsText =>
      'Compare gastos e consumo em qualquer período, não só no padrão do app.';

  @override
  String get featureExportTitle => 'Exportação em CSV e Excel';

  @override
  String get featureExportText =>
      'Exporte seus dados em CSV ou Excel sempre que quiser.';

  @override
  String get featurePdfTitle => 'Exportação em PDF';

  @override
  String get featurePdfText =>
      'Gere o PDF do relatório sem precisar assistir a um vídeo.';

  @override
  String get featureSyncTitle => 'Sincronização entre aparelhos';

  @override
  String get featureSyncText =>
      'Seus dados acompanham você ao trocar de celular.';

  @override
  String get premiumYouArePremium => 'Você é Premium';

  @override
  String get premiumFreePlan => 'Você está no plano gratuito';

  @override
  String get premiumActive => 'Sua assinatura do MyCarApp está ativa.';

  @override
  String get premiumFreeIntro =>
      'Todos os recursos do app são gratuitos, com anúncios. Assine para usar sem anúncios e ter backup automático.';

  @override
  String get loading => 'Carregando...';

  @override
  String premiumOptionOffer(Object plan) {
    return '$plan · oferta';
  }

  @override
  String get premiumWaitingPlay => 'AGUARDANDO GOOGLE PLAY...';

  @override
  String get premiumSignInToSubscribe => 'ENTRAR PARA ASSINAR';

  @override
  String get premiumRestore => 'RESTAURAR ASSINATURA';

  @override
  String get premiumBillingNote =>
      'Pagamento processado pela Google Play. A assinatura tem renovação automática e pode ser cancelada pela Play Store.';

  @override
  String get premiumBackToApp => 'VOLTAR AO APP';

  @override
  String get benefitNoAds => 'Sem anúncios';

  @override
  String get benefitBackup =>
      'Backup automático na nuvem, com fotos e documentos';

  @override
  String get benefitVehicles => 'Veículos ilimitados';

  @override
  String get benefitMaintenanceNoVideo => 'Manutenções e despesas sem vídeo';

  @override
  String get benefitReceiptScan => 'Leitura automática da nota fiscal';

  @override
  String get benefitStationRanking => 'Ranking completo de postos';

  @override
  String get benefitExport => 'Exportação em CSV, Excel e PDF';

  @override
  String get subscriptionRestore => 'Restaurar compra';

  @override
  String get subscriptionFreeTrialBadge => '7 DIAS GRÁTIS';

  @override
  String subscriptionSaveBadge(Object percent) {
    return 'ECONOMIZE $percent%';
  }

  @override
  String get subscriptionBilledMonthly => 'cobrado todo mês';

  @override
  String get subscriptionStartFreeTrial => 'COMEÇAR 7 DIAS GRÁTIS';

  @override
  String subscriptionSubscribeMonthly(Object price) {
    return 'ASSINAR POR $price/MÊS';
  }

  @override
  String subscriptionBillingTrial(Object price) {
    return 'Grátis por 7 dias, depois $price por ano.';
  }

  @override
  String get subscriptionBillingAuto =>
      'Renovação automática. Cancele quando quiser na Play Store.';

  @override
  String get planAnnual => 'Plano anual';

  @override
  String get planMonthly => 'Plano mensal';

  @override
  String perYear(Object price) {
    return '$price/ano';
  }

  @override
  String perMonth(Object price) {
    return '$price/mês';
  }

  @override
  String priceOfferThen(Object price, Object renewal) {
    return '$price na oferta; depois $renewal';
  }

  @override
  String get storeCommError =>
      'Não foi possível concluir a comunicação com a loja.';

  @override
  String get storeUnavailable =>
      'Google Play não está disponível neste aparelho.';

  @override
  String get storeProductNotFound =>
      'Produto não encontrado. Confirme o ID no Google Play Console.';

  @override
  String get storeNoPlans => 'Nenhum plano disponível para esta conta.';

  @override
  String get storeAccessError => 'Não foi possível acessar a Google Play.';

  @override
  String get storeSignInToSubscribe =>
      'Entre com sua conta Google para assinar.';

  @override
  String get storePurchaseNotStarted => 'A compra não pôde ser iniciada.';

  @override
  String get storePurchaseStartError => 'Não foi possível iniciar a compra.';

  @override
  String get storeSignInToRestore =>
      'Entre com sua conta Google para restaurar a assinatura.';

  @override
  String get storeSearching => 'Procurando compras anteriores...';

  @override
  String get storeRestored => 'Assinatura restaurada.';

  @override
  String get storeValidatingRestore =>
      'Compras consultadas. Validando com a Google Play...';

  @override
  String get storeRestoreError => 'Não foi possível restaurar as compras.';

  @override
  String get storePending => 'Pagamento pendente na Google Play.';

  @override
  String get storeNotCompleted => 'A compra não foi concluída.';

  @override
  String get storeCanceled => 'Compra cancelada.';

  @override
  String get storeSameAccount =>
      'Entre na mesma conta usada para iniciar a assinatura.';

  @override
  String get storeNoVerificationData =>
      'A Google Play não forneceu os dados para validação.';

  @override
  String get storeValidating => 'Validando assinatura com a Google Play...';

  @override
  String get storeActive => 'Assinatura MyCarApp ativa.';

  @override
  String get storeNotActive => 'A assinatura não está ativa na Google Play.';

  @override
  String get storeValidationError =>
      'Não foi possível validar a assinatura. Tente restaurar novamente.';

  @override
  String get backupDone => 'Backup concluído.';

  @override
  String get backupRestoreCloudTitle => 'Restaurar da nuvem';

  @override
  String backupRestoreCloudConfirm(Object count) {
    return 'Isto traz os $count registro(s) salvos na nuvem, com fotos e documentos, para este celular. Registros com o mesmo id são atualizados; nada deste celular é apagado.';
  }

  @override
  String backupRestoredCount(Object count) {
    return '$count registro(s) restaurado(s).';
  }

  @override
  String get backupRestoreError =>
      'Não foi possível restaurar. Verifique sua conexão.';

  @override
  String get backupReadError => 'Não foi possível ler este backup.';

  @override
  String get backupRestoreLegacyTitle => 'Restaurar cópia antiga';

  @override
  String get backupLegacyNothingNew =>
      'Esta cópia não tem nada além do que você já tem neste celular.';

  @override
  String backupLegacyImpact(Object added, Object updated) {
    return 'Isto vai adicionar $added registro(s) novo(s) e atualizar $updated já existente(s). Nada é apagado.';
  }

  @override
  String get backupLegacyRestored => 'Cópia restaurada.';

  @override
  String get backupLegacyRestoreError =>
      'Não foi possível restaurar esta cópia.';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get restore => 'RESTAURAR';

  @override
  String get backupTitle => 'Backup e restauração';

  @override
  String get backupRestoring => 'RESTAURANDO...';

  @override
  String backupRestoreCloudButton(Object count) {
    return 'RESTAURAR DA NUVEM ($count)';
  }

  @override
  String get backupLegacyHeader => 'CÓPIAS ANTIGAS';

  @override
  String get backupLegacyHint =>
      'Feitas manualmente em versões anteriores do app. Não incluem fotos e documentos.';

  @override
  String get backupAutoActive => 'Backup automático ativo';

  @override
  String get backupSending => 'Enviando alterações...';

  @override
  String get backupFirstSoon => 'O primeiro backup começa em instantes.';

  @override
  String backupLastAt(Object date) {
    return 'Último backup em $date.';
  }

  @override
  String get backupWhatIsSaved =>
      'Veículos, abastecimentos, manutenções, despesas, locais, fotos, comprovantes e documentos são salvos na sua conta sempre que você faz uma alteração.';

  @override
  String get backupUploading => 'ENVIANDO...';

  @override
  String get backupNow => 'FAZER BACKUP AGORA';

  @override
  String get backupIsPremium => 'Backup automático é Premium';

  @override
  String get backupFreeExplain =>
      'No plano gratuito seus dados ficam só neste celular. Com o Premium, tudo é salvo na nuvem automaticamente, inclusive fotos e documentos, e volta com você ao trocar de aparelho.';

  @override
  String get learnAboutPremium => 'CONHECER O PREMIUM';

  @override
  String backupLegacyTileInfo(Object count, Object size) {
    return '$count registro(s) • $size';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date às $time';
  }

  @override
  String get backupFailed =>
      'Não foi possível concluir o backup. Verifique sua conexão.';

  @override
  String get backupSignInToRestore =>
      'Entre com sua conta para restaurar o backup.';

  @override
  String get backupSignInRequired =>
      'Entre com sua conta para usar o backup em nuvem.';

  @override
  String get backupNotFound => 'Backup não encontrado no Storage.';

  @override
  String get signInRequired => 'Entre na sua conta para usar este recurso.';

  @override
  String get referralApplied =>
      'Código aplicado! O benefício será ativado após o primeiro pagamento.';

  @override
  String get referralApplyError =>
      'Não foi possível aplicar esse código. Verifique e tente novamente.';

  @override
  String get adminPremiumUpdated => 'Acesso Premium gratuito atualizado.';

  @override
  String get adminPremiumUpdateError => 'Não foi possível atualizar o período.';

  @override
  String get accountTitle => 'Minha conta';

  @override
  String get accountSignInBackup => 'Entre para usar backup em nuvem e suporte';

  @override
  String get accountSignInReferral => 'Entre para usar indicações e descontos';

  @override
  String get accountUser => 'Usuário';

  @override
  String get supportTitle => 'Ajuda, feedback e bugs';

  @override
  String get supportSubtitle => 'Envie e acompanhe seus chamados';

  @override
  String get adminTitle => 'Administração do teste';

  @override
  String adminPremiumUntil(Object date) {
    return 'Premium gratuito até $date';
  }

  @override
  String get adminChangeDate => 'ALTERAR DATA';

  @override
  String get referralYourCode => 'Seu código de indicação';

  @override
  String get referralCopy => 'Copiar código';

  @override
  String get referralCopied => 'Código copiado.';

  @override
  String get referralInvite => 'Convidar um amigo';

  @override
  String referralShareText(Object code, Object url) {
    return 'Uso o MyCarApp pra controlar os gastos do carro. Baixa com meu código de indicação $code e ganha 30% de desconto no primeiro ano do Premium anual: $url';
  }

  @override
  String get referralReceived => 'Recebeu um código?';

  @override
  String get referralCodeLabel => 'Código de indicação';

  @override
  String get referralApplying => 'APLICANDO...';

  @override
  String get referralApply => 'APLICAR CÓDIGO';

  @override
  String get bestOffer => 'Melhor oferta disponível';

  @override
  String get signOut => 'SAIR DA CONTA';

  @override
  String get accountBackupPitch =>
      'Salve tudo na nuvem, com fotos e documentos, e não perca nada ao trocar de celular.';

  @override
  String backupDaysAgo(Object days) {
    return 'Último backup há $days dia(s)';
  }

  @override
  String backupLastOn(Object date) {
    return 'Último backup em $date';
  }

  @override
  String get offerClosedTest3m => '70% de desconto por 3 meses';

  @override
  String get offerClosedTestYear => '70% de desconto no primeiro ano';

  @override
  String get offerFounders => '50% de desconto no primeiro ano';

  @override
  String get offerReferral => '30% de desconto no primeiro ano';

  @override
  String get offerReferralOld => '50% de desconto por 3 meses';

  @override
  String get offerYearlyTrial => '7 dias grátis no plano anual';

  @override
  String get offerSpecial => 'Oferta especial MyCarApp';

  @override
  String get watchAndSave => 'ASSISTIR VÍDEO E SALVAR';

  @override
  String get freeLimitVehicleTitle => 'Este veículo é somente consulta';

  @override
  String get freeLimitVehicleText =>
      'No plano gratuito, só o primeiro veículo cadastrado aceita novos lançamentos. Assine o Premium para lançar em todos os seus veículos.';

  @override
  String get freeLimitFuelingTitle => 'Limite de abastecimentos do mês';

  @override
  String freeLimitFuelingText(Object count) {
    return 'Você já registrou $count abastecimento(s) gratuito(s) este mês. Assista a um vídeo para salvar mais um, ou assine o Premium para abastecimentos ilimitados.';
  }

  @override
  String get freeLimitMaintenanceTitle => 'Registro liberado por vídeo';

  @override
  String get freeLimitMaintenanceText =>
      'No plano gratuito, cada manutenção nova é liberada assistindo a um vídeo. Assine o Premium para registrar sem vídeos.';

  @override
  String get freeLimitExpenseTitle => 'Registro liberado por vídeo';

  @override
  String get freeLimitExpenseText =>
      'No plano gratuito, cada despesa nova é liberada assistindo a um vídeo. Assine o Premium para registrar sem vídeos.';

  @override
  String get vehicleViewOnlyBadge => 'Somente consulta no gratuito';

  @override
  String stationNextUnlock(String date) {
    return 'O melhor posto volta a aparecer aqui em $date. Assine o Premium para ver o ranking completo a qualquer momento.';
  }

  @override
  String get stationSeeFullRanking => 'VER RANKING COMPLETO (PREMIUM)';

  @override
  String get notSet => 'não definida';

  @override
  String get exportSubject => 'Exportação MyCarApp';

  @override
  String get exportText => 'Dados do veículo exportados pelo MyCarApp.';

  @override
  String get exportError => 'Não foi possível exportar.';

  @override
  String get importConfirmTitle => 'Importar informações?';

  @override
  String get importConfirmText =>
      'Um novo veículo será criado com os abastecimentos e manutenções do arquivo. Os dados atuais não serão sobrescritos.';

  @override
  String get importAction => 'IMPORTAR';

  @override
  String get importDone => 'Importação concluída';

  @override
  String importSummary(Object vehicle, Object fuelings, Object maintenances) {
    return '$vehicle\n$fuelings abastecimento(s)\n$maintenances manutenção(ões)';
  }

  @override
  String get importError => 'Não foi possível importar.';

  @override
  String get exportTitle => 'Exportar informações';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get exportCsvHint =>
      'Formato leve, compatível com planilhas e com o MyCarApp.';

  @override
  String get exportExcel => 'Exportar Excel';

  @override
  String get exportExcelHint =>
      'Planilha XLSX pronta para compartilhar ou arquivar.';

  @override
  String get importOtherDevice => 'Importar em outro aparelho';

  @override
  String get importOtherDeviceHint =>
      'Leia um CSV ou Excel criado pelo MyCarApp.';

  @override
  String get exportInfo =>
      'A exportação utiliza o veículo ativo e inclui cadastro, abastecimentos e manutenções. Fotos e notas fiscais permanecem somente no aparelho por segurança.';

  @override
  String get vehiclesLoadError => 'Não foi possível carregar os veículos.';

  @override
  String get vehicleAdded => 'Veículo incluído';

  @override
  String vehicleNowActive(Object name) {
    return '$name é o veículo ativo.';
  }

  @override
  String get vehicleDeleteTitle => 'Excluir veículo?';

  @override
  String vehicleDeleteText(Object name) {
    return 'O cadastro e as fotos de $name serão apagados do aparelho. Os abastecimentos já registrados serão preservados.';
  }

  @override
  String get deleteAction => 'EXCLUIR';

  @override
  String get vehicleDeleted => 'Veículo excluído.';

  @override
  String get vehicleDeleteError => 'Não foi possível excluir o veículo.';

  @override
  String get vehiclesTitle => 'Meus veículos';

  @override
  String get newVehicle => 'NOVO VEÍCULO';

  @override
  String get useThis => 'USAR ESTE';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get vehiclesEmptyTitle => 'Nenhum veículo cadastrado';

  @override
  String get vehiclesEmptyText =>
      'Cadastre seu primeiro carro ou moto para começar a registrar abastecimentos.';

  @override
  String get addVehicle => 'CADASTRAR VEÍCULO';

  @override
  String placeArchived(Object name) {
    return '$name arquivado.';
  }

  @override
  String get placesNothingToOrganize => 'Nenhum local pendente de organização.';

  @override
  String placesOrganized(Object count) {
    return '$count local(is) organizado(s).';
  }

  @override
  String get placesTitle => 'Meus locais';

  @override
  String get placesOrganize => 'Organizar meus locais';

  @override
  String get archive => 'Arquivar';

  @override
  String get placesEmptyTitle => 'Nenhum local cadastrado ainda.';

  @override
  String get placesEmptyText =>
      'Cadastre postos e oficinas ao lançar um abastecimento ou manutenção, ou organize os locais já digitados como texto.';

  @override
  String get placesOrganizeButton => 'ORGANIZAR MEUS LOCAIS';

  @override
  String get placeNew => 'Novo local';

  @override
  String get placeEdit => 'Editar local';

  @override
  String get name => 'Nome';

  @override
  String get nameRequired => 'Informe um nome';

  @override
  String get type => 'Tipo';

  @override
  String get placeBrand => 'Bandeira (opcional)';

  @override
  String get placeAddress => 'Endereço (opcional)';

  @override
  String get placeNeighborhood => 'Bairro (opcional)';

  @override
  String get favorite => 'Favorito';

  @override
  String get placeFavoriteHint => 'Fica no topo das sugestões rápidas';

  @override
  String get saving => 'SALVANDO...';

  @override
  String get save => 'SALVAR';

  @override
  String get placesOrganizeIntro =>
      'Encontramos estes nomes digitados em lançamentos antigos. Selecione os que devem virar um local estruturado.';

  @override
  String placesGroupInfo(Object type, Object count) {
    return '$type · $count lançamento(s)';
  }

  @override
  String get organizing => 'ORGANIZANDO...';

  @override
  String placesUnify(Object count) {
    return 'UNIFICAR $count SELECIONADO(S)';
  }

  @override
  String get notifCustomize => 'Personalizar notificações';

  @override
  String get notifCustomizeIntro =>
      'Escolha quais alertas deseja receber neste aparelho.';

  @override
  String get notifAll => 'Todas as notificações';

  @override
  String get notifAllOn => 'Todas ativadas';

  @override
  String get notifSomeOn => 'Algumas ativadas';

  @override
  String get notifAllOff => 'Todas desativadas';

  @override
  String get notifDisableAll => 'DESATIVAR TODAS';

  @override
  String get notifEnableAll => 'ATIVAR TODAS';

  @override
  String get notifNews => 'Novidades e atualizações';

  @override
  String get notifMaintenance => 'Próximas manutenções';

  @override
  String get notifFuelLow => 'Combustível próximo de 20%';

  @override
  String get notifTitle => 'Notificações';

  @override
  String get notifClear => 'Limpar notificações';

  @override
  String get notifEmpty => 'Nenhuma notificação';

  @override
  String get docsLoadError => 'Não foi possível carregar os documentos.';

  @override
  String get fileUnavailable => 'Arquivo indisponível.';

  @override
  String get docAttached => 'Documento anexado.';

  @override
  String get docAttachError => 'Não foi possível anexar o PDF.';

  @override
  String get docFileMissing =>
      'O arquivo não foi encontrado. Anexe o documento novamente.';

  @override
  String get docNoPdfReader =>
      'Não há um leitor de PDF disponível no aparelho.';

  @override
  String get docDeleteTitle => 'Excluir documento?';

  @override
  String get docDeleteText => 'A cópia armazenada no MyCarApp será removida.';

  @override
  String get docDeleted => 'Documento excluído.';

  @override
  String get docsTitle => 'Documentos';

  @override
  String get docDriverLicense => 'CNH-e';

  @override
  String get docDriverLicenseHint => 'Carteira Nacional de Habilitação em PDF';

  @override
  String get docVehicle => 'Documento do veículo';

  @override
  String get docSelectVehicle => 'Selecione um veículo para anexar o CRLV-e';

  @override
  String docVehicleOf(Object name) {
    return 'CRLV-e de $name';
  }

  @override
  String get docAttachPdf => 'ANEXAR PDF';

  @override
  String get docOpenPdf => 'ABRIR PDF';

  @override
  String get docReplacePdf => 'Substituir PDF';

  @override
  String get docsStorageNote =>
      'Os PDFs são copiados para o armazenamento interno do MyCarApp e permanecem somente neste aparelho.';

  @override
  String get supportLoadError => 'Não foi possível carregar os chamados.';

  @override
  String get supportAdminTitle => 'Central de chamados · Admin';

  @override
  String get supportScreenTitle => 'Ajuda e feedback';

  @override
  String get supportNew => 'NOVO CHAMADO';

  @override
  String get supportEmpty => 'Nenhum chamado aberto ainda.';

  @override
  String supportSent(Object number) {
    return 'Chamado #$number enviado.';
  }

  @override
  String get supportSendError => 'Não foi possível enviar o chamado.';

  @override
  String get supportNewTitle => 'Novo chamado';

  @override
  String get supportFeedback => 'Feedback';

  @override
  String get supportBug => 'Bug';

  @override
  String get supportSubject => 'Assunto';

  @override
  String get supportSubjectRequired => 'Informe o assunto';

  @override
  String get supportDetails => 'Conte o que aconteceu';

  @override
  String get supportDetailsHint =>
      'Se for um bug, descreva os passos até o problema.';

  @override
  String get supportDetailsRequired => 'Descreva com mais detalhes';

  @override
  String get backupUploadingSend => 'ENVIANDO...';

  @override
  String get supportSend => 'ENVIAR CHAMADO';

  @override
  String get supportReply => 'Resposta do suporte';

  @override
  String get status => 'Status';

  @override
  String get statusOpen => 'Aberto';

  @override
  String get statusInProgress => 'Em andamento';

  @override
  String get statusResolved => 'Resolvido';

  @override
  String get supportReplyToUser => 'Resposta ao usuário';

  @override
  String get supportSaveReply => 'SALVAR RESPOSTA';

  @override
  String get supportSignIn =>
      'Entre na sua conta para enviar e acompanhar chamados.';

  @override
  String get expenseNeedVehicle => 'Cadastre e selecione um veículo primeiro.';

  @override
  String get expenseSaved => 'Despesa salva.';

  @override
  String get expenseDeleteTitle => 'Excluir despesa?';

  @override
  String expenseDeleteText(Object title) {
    return '$title será removida do histórico.';
  }

  @override
  String get expensesTitle => 'Despesas';

  @override
  String get expenseAdd => 'ADICIONAR DESPESA';

  @override
  String get expenseNeedVehicleFirst =>
      'Cadastre um veículo antes de adicionar despesas.';

  @override
  String get expensesEmpty =>
      'Cadastre seguro, cooperativa, financiamento, consórcio ou outra despesa.';

  @override
  String get expensesMonthlyRecurring => 'Recorrentes no mês';

  @override
  String get expensesNextDue => 'Próximo vencimento';

  @override
  String expensesDueDay(Object day) {
    return 'Dia $day';
  }

  @override
  String get expenseNew => 'Nova despesa';

  @override
  String get expenseEdit => 'Editar despesa';

  @override
  String get category => 'Categoria';

  @override
  String get description => 'Descrição';

  @override
  String get descriptionRequired => 'Informe uma descrição';

  @override
  String get amount => 'Valor';

  @override
  String get invalidValue => 'Informe um valor válido';

  @override
  String get frequency => 'Frequência';

  @override
  String get expenseInstallments => 'Quantidade de parcelas';

  @override
  String get expenseInstallmentsHint =>
      'Deixe vazio para uma cobrança sem prazo definido';

  @override
  String get expenseFirstDue => 'Primeiro vencimento';

  @override
  String get notes => 'Observações';

  @override
  String get expenseSave => 'SALVAR DESPESA';

  @override
  String installmentOf(Object current, Object total) {
    return '$current de $total';
  }

  @override
  String get maintLoadError => 'Não foi possível carregar as manutenções.';

  @override
  String get maintDoneAdded => 'Manutenção realizada incluída';

  @override
  String get maintNextAdded => 'Próxima manutenção incluída';

  @override
  String get maintDeleteTitle => 'Excluir manutenção?';

  @override
  String maintDeleteText(Object service) {
    return '$service será removida permanentemente.';
  }

  @override
  String get maintDeleted => 'Manutenção excluída.';

  @override
  String get maintDeleteError => 'Não foi possível excluir a manutenção.';

  @override
  String get maintDone => 'Manutenção realizada';

  @override
  String get maintDoneHint => 'Registrar serviço, oficina e custos';

  @override
  String get maintNext => 'Próxima manutenção';

  @override
  String get maintNextHint => 'Planejar mesmo sem possuir histórico';

  @override
  String get maintTitle => 'Manutenções';

  @override
  String get maintTabDone => 'REALIZADAS';

  @override
  String get maintTabNext => 'PRÓXIMAS';

  @override
  String get maintNew => 'NOVA MANUTENÇÃO';

  @override
  String get maintEmptyDone => 'Nenhuma manutenção realizada';

  @override
  String get maintEmptyNext => 'Nenhuma próxima manutenção planejada';

  @override
  String get thisMonth => 'Este mês';

  @override
  String get total => 'Total';

  @override
  String get alerts => 'Alertas';

  @override
  String get maintNeedVehicle =>
      'Cadastre e selecione um veículo para acessar as manutenções.';

  @override
  String get maintOverdue => 'Vencida';

  @override
  String get maintUpcoming => 'Próxima';

  @override
  String get maintPlanned => 'Prevista';

  @override
  String get historyLoadError => 'Não foi possível carregar o histórico.';

  @override
  String get fuelingDeleteTitle => 'Excluir abastecimento?';

  @override
  String fuelingDeleteText(Object date) {
    return 'O registro de $date será removido permanentemente.';
  }

  @override
  String get fuelingDeleted => 'Abastecimento excluído.';

  @override
  String get fuelingDeleteError => 'Não foi possível excluir o abastecimento.';

  @override
  String get historyTitle => 'Histórico de abastecimentos';

  @override
  String get fuelUp => 'ABASTECER';

  @override
  String get historySpentMonth => 'Gasto no mês';

  @override
  String get averagePrice => 'Preço médio';

  @override
  String get historyTotalLiters => 'Total abastecido';

  @override
  String get historyRecords => 'Registros';

  @override
  String get fuel => 'Combustível';

  @override
  String get fullTank => 'Tanque cheio';

  @override
  String historyEmptyTitle(Object name) {
    return 'Nenhum abastecimento de $name';
  }

  @override
  String get historyEmptyText =>
      'Registre litros, valor, quilometragem e tanque cheio para acompanhar gastos e consumo.';

  @override
  String get newFueling => 'NOVO ABASTECIMENTO';

  @override
  String get historyNeedVehicle =>
      'Cadastre e selecione um veículo para visualizar o histórico.';

  @override
  String get placeTypeStation => 'Posto de combustível';

  @override
  String get placeTypeShop => 'Oficina';

  @override
  String get placeTypeDealer => 'Concessionária';

  @override
  String get placeTypeCarWash => 'Lava-jato';

  @override
  String get placeTypeInsurer => 'Seguradora';

  @override
  String get other => 'Outro';

  @override
  String get expenseInsurance => 'Seguro';

  @override
  String get expenseCooperative => 'Cooperativa';

  @override
  String get expenseFinancing => 'Financiamento';

  @override
  String get expenseConsortium => 'Consórcio';

  @override
  String get expenseOther => 'Outra despesa';

  @override
  String get frequencyMonthly => 'Mensal';

  @override
  String get frequencyYearly => 'Anual';

  @override
  String get frequencyOnce => 'Pagamento único';

  @override
  String get vehicleMotorcycle => 'Moto';

  @override
  String get vehicleCar => 'Carro';

  @override
  String get fuelGasoline => 'Gasolina';

  @override
  String get fuelEthanol => 'Etanol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelNaturalGas => 'GNV';

  @override
  String get fuelElectric => 'Elétrico';

  @override
  String get fuelFlex => 'Flex';

  @override
  String get fuelHybrid => 'Híbrido';

  @override
  String get transmissionManual => 'Manual';

  @override
  String get transmissionAutomatic => 'Automático';

  @override
  String get maintOilFilters => 'Óleo e filtros';

  @override
  String get maintEngine => 'Motor';

  @override
  String get maintBrakes => 'Freios';

  @override
  String get maintSuspension => 'Suspensão';

  @override
  String get maintTires => 'Pneus';

  @override
  String get maintTransmission => 'Câmbio';

  @override
  String get maintAirConditioning => 'Ar-condicionado';

  @override
  String get maintElectrical => 'Elétrica';

  @override
  String get maintSteering => 'Direção';

  @override
  String get maintBelts => 'Correias';

  @override
  String get maintService => 'Revisão';

  @override
  String get maintOthers => 'Outros';

  @override
  String get photoCarFront => 'Frente do veículo';

  @override
  String get photoCarRear => 'Traseira do veículo';

  @override
  String get photoLeftSide => 'Lateral esquerda';

  @override
  String get photoRightSide => 'Lateral direita';

  @override
  String get photoDashboard => 'Painel';

  @override
  String get photoSteeringWheel => 'Volante';

  @override
  String get photoFrontLeftTire => 'Pneu dianteiro esquerdo';

  @override
  String get photoFrontRightTire => 'Pneu dianteiro direito';

  @override
  String get photoRearLeftTire => 'Pneu traseiro esquerdo';

  @override
  String get photoRearRightTire => 'Pneu traseiro direito';

  @override
  String get photoMotoFront => 'Frente da moto';

  @override
  String get photoMotoRear => 'Traseira da moto';

  @override
  String get photoHandlebar => 'Guidão';

  @override
  String get photoFrontTire => 'Pneu dianteiro';

  @override
  String get photoRearTire => 'Pneu traseiro';

  @override
  String get photoExhaust => 'Escapamento';

  @override
  String get otherBrand => 'Outra marca';

  @override
  String get otherModel => 'Outro modelo';

  @override
  String get ocrReadError => 'Não foi possível ler a nota. Tente outra foto.';

  @override
  String get ocrReviewTitle => 'Conferir dados reconhecidos';

  @override
  String get ocrStation => 'Posto';

  @override
  String get ocrFueling => 'Abastecimento';

  @override
  String get ocrTotalPrice => 'Preço total';

  @override
  String get date => 'Data';

  @override
  String get ocrReviewHint => 'Revise os campos antes de salvar.';

  @override
  String get ocrNothing =>
      'Nenhum dado foi reconhecido. Tente fotografar novamente com boa luz e a nota inteira visível.';

  @override
  String get ocrFill => 'PREENCHER';

  @override
  String get fuelingNew => 'Novo abastecimento';

  @override
  String get fuelingEdit => 'Editar abastecimento';

  @override
  String get fuelingData => 'Dados do abastecimento';

  @override
  String get totalValue => 'Valor total';

  @override
  String get mileage => 'Quilometragem';

  @override
  String get fuelingMileageRequired => 'Obrigatória para o cálculo';

  @override
  String get fuelingMileageInvalid => 'Informe uma quilometragem válida';

  @override
  String get fuelingFullTankHint =>
      'Necessário para calcular o consumo com precisão';

  @override
  String get tankCapacity => 'Capacidade total do tanque';

  @override
  String get tankCapacityVehicleHint =>
      'Consulte o manual do veículo. Usada para calcular o consumo com tanque cheio';

  @override
  String get tankCapacityMissing =>
      'Informe a capacidade do tanque no cadastro do veículo para calcular o consumo.';

  @override
  String get fuelingGaugeFull => 'O marcador indicou tanque cheio?';

  @override
  String get fuelingGaugeFullHint =>
      'Somente confirmações reais entram no consumo estimado';

  @override
  String get optionalInfo => 'Informações opcionais';

  @override
  String get receiptsSection => 'Nota fiscal e comprovantes';

  @override
  String get fuelingSave => 'SALVAR ABASTECIMENTO';

  @override
  String get notIdentified => 'Não identificado';

  @override
  String get invalidValueShort => 'Valor inválido';

  @override
  String get maintSaveError => 'Não foi possível salvar a manutenção.';

  @override
  String get maintSavedCalendarError =>
      'Manutenção salva. Não foi possível concluir o lembrete na agenda.';

  @override
  String get maintEdit => 'Editar manutenção';

  @override
  String get maintDoneShort => 'Realizada';

  @override
  String get maintServiceDone => 'Serviço realizado';

  @override
  String get maintServicePlanned => 'Serviço previsto';

  @override
  String get maintServiceDescription => 'Descrição do serviço';

  @override
  String get maintServiceExample => 'Ex.: Troca de óleo e filtro';

  @override
  String get maintServiceRequired => 'Informe o serviço';

  @override
  String get maintDateDone => 'Data realizada';

  @override
  String get maintDatePlanned => 'Data prevista';

  @override
  String get maintKmPlanned => 'Km prevista';

  @override
  String get maintKmRequired => 'Informe a km';

  @override
  String get maintKmGreater => 'Maior que a atual';

  @override
  String get maintShop => 'Oficina ou profissional (opcional)';

  @override
  String get maintCosts => 'Custos';

  @override
  String get maintLabor => 'Mão de obra';

  @override
  String get maintParts => 'Peças';

  @override
  String get maintNextKm => 'Próxima quilometragem';

  @override
  String get maintNextDate => 'Próxima data (opcional)';

  @override
  String get maintCalendar => 'Agenda do telefone';

  @override
  String get maintAddToCalendar => 'Adicionar à minha agenda';

  @override
  String get maintCalendarHint => 'Evento de dia inteiro: MyCarApp Manutenção';

  @override
  String get maintNotesHint => 'Peças utilizadas, marcas, garantias...';

  @override
  String get maintSave => 'SALVAR MANUTENÇÃO';

  @override
  String get maintSaveNext => 'SALVAR PRÓXIMA MANUTENÇÃO';

  @override
  String get notSetFem => 'Não definida';

  @override
  String get calendarEventTitle => 'MyCarApp Manutenção';

  @override
  String get transferNoActiveVehicle => 'Nenhum veículo ativo.';

  @override
  String get transferExcelError => 'Falha ao gerar Excel.';

  @override
  String get transferUnknownFile => 'Arquivo não reconhecido pelo MyCarApp.';

  @override
  String get transferMissingVehicle => 'Veículo ausente.';

  @override
  String get transferInvalidCsv => 'Linha CSV inválida.';

  @override
  String get transferEmptySheet => 'Planilha vazia.';

  @override
  String get storageVehiclesCorrupted =>
      'O arquivo local de veículos está corrompido.';

  @override
  String get storagePhotoNotFound => 'Foto não encontrada';

  @override
  String get storageFuelingsCorrupted =>
      'O arquivo local de abastecimentos está corrompido.';

  @override
  String get storageMaintenanceCorrupted =>
      'O arquivo local de manutenções está corrompido.';

  @override
  String get storageExpensesCorrupted =>
      'O arquivo local de despesas está corrompido.';

  @override
  String get storagePlacesCorrupted =>
      'O arquivo local de estabelecimentos está corrompido.';

  @override
  String get docInvalidPdf => 'O arquivo selecionado não é um PDF válido.';

  @override
  String get authAccountError => 'Não foi possível acessar sua conta Google.';

  @override
  String get fieldRequired => 'Campo obrigatório';

  @override
  String get vehicleSaveError =>
      'Não foi possível salvar o veículo. Tente novamente.';

  @override
  String get addVehicleTitle => 'Cadastrar veículo';

  @override
  String get editVehicleTitle => 'Editar veículo';

  @override
  String get vehicleIdentification => 'Identificação';

  @override
  String get vehicleNickname => 'Apelido do veículo';

  @override
  String get vehicleNicknameMoto => 'Ex.: Minha moto';

  @override
  String get vehicleNicknameCar => 'Ex.: Meu carro';

  @override
  String get brand => 'Marca';

  @override
  String get brandName => 'Nome da marca';

  @override
  String get brandHint => 'Digite a marca do veículo';

  @override
  String get model => 'Modelo';

  @override
  String get modelName => 'Nome do modelo';

  @override
  String get modelHint => 'Digite o modelo do veículo';

  @override
  String get vehicleYear => 'Ano do veículo';

  @override
  String get selectYear => 'Selecione o ano';

  @override
  String get vehicleFeatures => 'Características';

  @override
  String get transmission => 'Câmbio';

  @override
  String get currentMileage => 'Quilometragem atual';

  @override
  String get documentsByYear => 'Documentação por ano';

  @override
  String get vehiclePhotos => 'Fotos do veículo';

  @override
  String get photoWhat => 'O que aparece na foto?';

  @override
  String get photoSelect => 'SELECIONAR FOTO';

  @override
  String get vehicleSave => 'SALVAR VEÍCULO';

  @override
  String get year => 'Ano';

  @override
  String get docTaxPaid => 'IPVA pago';

  @override
  String get docLicensingPaid => 'Licenciamento pago';

  @override
  String vehicleSaveErrorDetail(Object message) {
    return 'Não foi possível salvar: $message';
  }

  @override
  String photoCount(Object count) {
    return '$count foto(s)';
  }

  @override
  String get reportsTitle => 'Relatórios';

  @override
  String get reportFuelTitle => 'Gastos com combustível';

  @override
  String get reportFuelSubtitle => 'Total gasto e preço médio por litro';

  @override
  String get reportMaintTitle => 'Gastos com manutenções';

  @override
  String get reportMaintSubtitle => 'Somente manutenções realizadas';

  @override
  String get period1Month => '1 mês';

  @override
  String get period3Months => '3 meses';

  @override
  String get period6Months => '6 meses';

  @override
  String get period1Year => '1 ano';

  @override
  String get period12Months => '12 meses';

  @override
  String get periodAll => 'Tudo';

  @override
  String get totalSpent => 'Total gasto';

  @override
  String get reportNoFuelings => 'Nenhum abastecimento neste período.';

  @override
  String get monthlyBreakdown => 'DETALHAMENTO POR MÊS';

  @override
  String get averageCost => 'Custo médio';

  @override
  String get reportNoMaint => 'Nenhuma manutenção realizada neste período.';

  @override
  String reportMaintDoneOne(Object count) {
    return '$count manutenção realizada';
  }

  @override
  String reportMaintDoneMany(Object count) {
    return '$count manutenções realizadas';
  }

  @override
  String reportAverage(Object value) {
    return 'Média $value';
  }

  @override
  String fuelingCountOne(Object count) {
    return '$count abastecimento';
  }

  @override
  String fuelingCountMany(Object count) {
    return '$count abastecimentos';
  }

  @override
  String get reportConsumptionTitle => 'Consumo estimado';

  @override
  String get reportConsumptionSubtitle => 'Cálculo estrito por tanque cheio';

  @override
  String get reportNeedVehicle =>
      'Cadastre e selecione um veículo para gerar o relatório.';

  @override
  String get reportLastConsumption => 'Último consumo calculado';

  @override
  String get reportOverallAverage => 'Média geral';

  @override
  String get reportConfirmedTanks => 'Tanques confirmados';

  @override
  String get reportConsumptionHow =>
      'Só calculamos entre dois abastecimentos com quilometragem, capacidade informada, tanque cheio e marcador confirmado. Abastecimentos parciais no intervalo também entram na soma de litros.';

  @override
  String get reportConsumptionNeedTwo =>
      'São necessários pelo menos dois tanques cheios confirmados para calcular o consumo.';

  @override
  String get reportDiffPerFueling => 'DIFERENÇA POR ABASTECIMENTO';

  @override
  String reportLitersUsed(Object distance, Object liters) {
    return '$distance km • $liters L consumidos';
  }

  @override
  String get reportBaseline => 'Base de comparação';

  @override
  String reportCapacityUsage(Object capacity, Object tanks) {
    return 'Capacidade: $capacity L • Uso equivalente: $tanks tanque(s)';
  }

  @override
  String get sortCostPerKm => 'Custo por km';

  @override
  String get sortConsumption => 'Consumo';

  @override
  String get sortSpent => 'Valor gasto';

  @override
  String get reportByStation => 'Por posto';

  @override
  String get reportByStationSubtitle => 'Onde seu carro rende mais';

  @override
  String get reportStationRule =>
      'Um resultado só é atribuído a um posto quando todos os abastecimentos daquele intervalo foram feitos no mesmo local e com o mesmo combustível.';

  @override
  String get reportStationEmpty =>
      'Ainda não há intervalos completos com posto informado para formar este relatório.';

  @override
  String reportBestStation(Object name) {
    return 'Seu melhor custo por km: $name';
  }

  @override
  String reportBestDetail(Object cost, Object consumption, Object count) {
    return '$cost/km • $consumption km/L • baseado em $count abastecimento(s)';
  }

  @override
  String reportSecondPlace(Object name) {
    return '2º colocado: $name';
  }

  @override
  String reportVsAverage(Object value) {
    return '$value% vs. média';
  }

  @override
  String get reportTotalCostPerKm => 'Custo total por km';

  @override
  String get reportTotalCostSubtitle =>
      'Combustível, manutenções e despesas somados';

  @override
  String get reportCostNeedTwo =>
      'São necessários ao menos dois abastecimentos com quilometragem no período para calcular este relatório.';

  @override
  String get reportAnnualProjection => 'Projeção anual';

  @override
  String reportCostBreakdown(
    Object distance,
    Object total,
    Object fuel,
    Object maintenance,
    Object expenses,
  ) {
    return '$distance km rodados • $total no total (combustível $fuel • manutenção $maintenance • despesas $expenses)';
  }

  @override
  String get reportProjectionNote =>
      'A projeção anual estende a média mensal do período selecionado — não considera sazonalidade nem manutenções pontuais fora do padrão.';

  @override
  String get reportWorkshopUnknown => 'Oficina não informada';

  @override
  String get reportByWorkshop => 'Por oficina';

  @override
  String get reportByWorkshopSubtitle => 'Onde seu dinheiro de manutenção vai';

  @override
  String get reportCostPer1000 => 'Custo de manutenção por 1.000 km';

  @override
  String get reportNoWorkshop =>
      'Nenhuma manutenção com oficina informada neste período.';

  @override
  String get reportByWorkshopHeader => 'POR OFICINA';

  @override
  String get reportCompositionHeader => 'COMPOSIÇÃO POR TIPO DE SERVIÇO';

  @override
  String get reportSameServiceHeader => 'MESMO SERVIÇO, OFICINAS DIFERENTES';

  @override
  String reportVisitsOne(Object count) {
    return '$count visita';
  }

  @override
  String reportVisitsMany(Object count) {
    return '$count visitas';
  }

  @override
  String reportAvgTicket(Object value) {
    return 'ticket médio $value';
  }

  @override
  String get reportRework =>
      'Possível retrabalho: duas visitas do mesmo tipo em até 30 dias';

  @override
  String get homeCloudFoundTitle => 'Seus dados estão na nuvem';

  @override
  String homeCloudFoundText(Object count) {
    return 'Encontramos $count registro(s) no backup da sua conta, com fotos e documentos. Quer trazê-los para este celular?';
  }

  @override
  String get notNowUpper => 'AGORA NÃO';

  @override
  String get homeRestoring => 'Restaurando seus dados...';

  @override
  String get homeRestoreLater =>
      'Não foi possível restaurar agora. Tente em Conta › Backup.';

  @override
  String get newsDocsTitle => 'MyCarApp atualizado';

  @override
  String get newsDocsText =>
      'Documentos em PDF, próximas manutenções e integração com a agenda já estão disponíveis.';

  @override
  String get news134Title => 'MyCarApp mais completo e gratuito';

  @override
  String get news134Text =>
      'Vários veículos, todos os postos, relatórios completos e exportação agora são gratuitos. O Premium remove os anúncios e faz backup automático na nuvem, inclusive de fotos e documentos.';

  @override
  String get news133Title => 'Nova versão do MyCarApp';

  @override
  String get news133Text =>
      'Login mais simples e seguro com sua conta Google, além de ajustes e melhorias de desempenho no sistema.';

  @override
  String get maintOverdueTitle => 'Manutenção vencida';

  @override
  String get fuelLowTitle => 'Hora de abastecer';

  @override
  String fuelLowText(Object name) {
    return '$name atingiu aproximadamente 20% da capacidade estimada do tanque.';
  }

  @override
  String get homeNeedVehicle => 'Cadastre um veículo primeiro.';

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get rateApp => 'Avaliar o app';

  @override
  String get adsPrivacy => 'Privacidade de anúncios';

  @override
  String get activeVehicle => 'VEÍCULO ATIVO';

  @override
  String get selectVehicle => 'Selecione seu veículo';

  @override
  String get homeSpentMonth => 'Saída neste mês';

  @override
  String get homeLastConsumption => 'Último consumo';

  @override
  String get homeAveragePriceStations => 'Preço médio · ver por posto';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get homeMonthSpending => 'Gastos do mês';

  @override
  String get nextMonth => 'Próximo mês';

  @override
  String get homeMonthTotal => 'Total do mês';

  @override
  String get maintenance => 'Manutenção';

  @override
  String get homeInsurance => 'Seguro e cooperativa';

  @override
  String get homeFinancing => 'Financiamento e consórcio';

  @override
  String get homeOtherExpenses => 'Outras despesas';

  @override
  String get homeSwipeMonths => 'Arraste para ver outros meses';

  @override
  String get homeNewEntry => 'Novo lançamento';

  @override
  String get homeWhatToRecord => 'O que você deseja registrar?';

  @override
  String get homeVehicleUse => 'USO DO VEÍCULO';

  @override
  String get homeFuelingHint => 'Litros, valor, posto e quilometragem';

  @override
  String get homeMaintHint => 'Serviço realizado ou próxima manutenção';

  @override
  String get homeVehicleExpenses => 'DESPESAS DO VEÍCULO';

  @override
  String get homeInsuranceEntry => 'Seguro ou cooperativa';

  @override
  String get homeInsuranceHint => 'Proteção veicular e parcelas do seguro';

  @override
  String get homeFinancingEntry => 'Financiamento ou consórcio';

  @override
  String get homeFinancingHint => 'Parcelas, vencimentos e andamento';

  @override
  String get homeOtherHint => 'Estacionamento, pedágio, lavagem e outros';

  @override
  String daysCount(Object count) {
    return '$count dias';
  }

  @override
  String get navHome => 'Início';

  @override
  String get navFuelings => 'Abastecimentos';

  @override
  String get navNew => 'Novo';

  @override
  String get navMore => 'Mais';

  @override
  String get forceUpdateTitle => 'Atualize o MyCarApp';

  @override
  String get forceUpdateText =>
      'Esta versão não é mais compatível. Atualize para continuar usando o app; seus dados continuam salvos no celular.';

  @override
  String get forceUpdateButton => 'ATUALIZAR AGORA';

  @override
  String adFreeMenuTitle(Object hours) {
    return 'Ficar ${hours}h sem anúncios em tela cheia';
  }

  @override
  String get adFreeMenuSubtitle =>
      'Assista a um vídeo curto. Os banners continuam.';

  @override
  String adFreeMenuActive(Object hours) {
    return 'Sem anúncios em tela cheia por mais ${hours}h';
  }

  @override
  String get adFreeMenuActiveSubtitle => 'Os banners continuam aparecendo.';

  @override
  String adFreeMenuAddMore(Object hours) {
    return 'Assista a outro vídeo para somar +${hours}h (máx. 9h)';
  }

  @override
  String afterAdRewarded(Object hours) {
    return 'Ou assista a um vídeo e fique ${hours}h sem anúncios em tela cheia';
  }

  @override
  String get rewardedUnavailable =>
      'Vídeo indisponível no momento, tente mais tarde';

  @override
  String get rewardedNotEarned =>
      'Assista ao vídeo até o fim para ganhar o período sem anúncios.';

  @override
  String rewardedEarned(Object hours) {
    return 'Pronto! Sem anúncios em tela cheia por ${hours}h. Os banners continuam.';
  }

  @override
  String get pdfExport => 'Exportar PDF';

  @override
  String get pdfFreeTitle => 'Relatório em PDF';

  @override
  String get pdfFreeText =>
      'No plano gratuito, cada relatório em PDF é liberado assistindo a um vídeo. Assine o Premium para gerar sem vídeos.';

  @override
  String get pdfWatchAndGenerate => 'ASSISTIR VÍDEO E GERAR';

  @override
  String get pdfVideoNotEarned =>
      'Assista ao vídeo até o fim para gerar o PDF.';

  @override
  String get pdfShareSubject => 'Relatório MyCarApp';

  @override
  String get pdfShareText => 'Relatório do veículo gerado pelo MyCarApp.';

  @override
  String get pdfTitle => 'Relatório do veículo';

  @override
  String pdfPeriod(String period) {
    return 'Período: $period';
  }

  @override
  String pdfFooter(String date) {
    return 'Gerado pelo MyCarApp em $date';
  }

  @override
  String get pdfVehicleSection => 'Veículo';

  @override
  String get pdfSpendingSection => 'Gastos';

  @override
  String get pdfLiters => 'Litros abastecidos';

  @override
  String get pdfTotalAll => 'Total (combustível + manutenção)';

  @override
  String get pdfMonthCol => 'Mês';

  @override
  String get pdfDistance => 'Distância no período';

  @override
  String get pdfExpenses => 'Outras despesas';

  @override
  String get pdfBestStation => 'Melhor posto';

  @override
  String get pdfStationCol => 'Posto';

  @override
  String get pdfFuelCol => 'Combustível';

  @override
  String get pdfFillUpsCol => 'Abast.';

  @override
  String get pdfMaintenanceList => 'Manutenções do período';

  @override
  String get pdfDateCol => 'Data';

  @override
  String get pdfServiceCol => 'Serviço';

  @override
  String get pdfWorkshopCol => 'Oficina';

  @override
  String get pdfCostCol => 'Valor';

  @override
  String get news140Title => 'Chegou o MyCarApp Premium';

  @override
  String get news140Text =>
      'Chegou o MyCarApp Premium: sem anúncios, veículos ilimitados, manutenções e despesas sem vídeo, leitura da nota fiscal, ranking completo de postos, relatórios por período, exportação e backup automático. O plano gratuito continua com o controle de consumo, e todos os seus registros seguem disponíveis.';

  @override
  String get surveyTitle => 'Antes de você ir…';

  @override
  String get surveyText =>
      'O que fez você não assinar agora? Leva 5 segundos e ajuda a melhorar o MyCarApp.';

  @override
  String get surveyTooExpensive => 'Muito caro';

  @override
  String get surveyTooExpensiveHint =>
      'O preço não cabe no meu orçamento agora';

  @override
  String get surveyStillExploring => 'Ainda estou conhecendo o app';

  @override
  String get surveyStillExploringHint => 'Quero usar mais antes de decidir';

  @override
  String get surveyDontNeed => 'Não preciso desses recursos';

  @override
  String get surveyDontNeedHint => 'O plano gratuito já me atende';

  @override
  String get surveyPreferOneTime => 'Prefiro pagar uma vez só';

  @override
  String get surveyPreferOneTimeHint => 'Não gosto de assinatura';

  @override
  String get surveyOther => 'Outro motivo';

  @override
  String get surveyOtherHint => 'Nenhuma das opções acima';

  @override
  String get surveySend => 'ENVIAR RESPOSTA';

  @override
  String get surveyChooseOption => 'ESCOLHA UMA OPÇÃO';

  @override
  String get surveySkip => 'Pular';

  @override
  String get surveyThanks =>
      'Obrigado pela resposta! Você continua no plano gratuito, com todos os seus registros disponíveis.';

  @override
  String get exitOfferBadge => 'OFERTA ÚNICA PARA VOCÊ';

  @override
  String exitOfferTitle(int percent) {
    return 'Entendemos. Que tal $percent% de desconto no Premium anual?';
  }

  @override
  String get exitOfferTitleGeneric =>
      'Entendemos. Que tal um desconto especial no Premium anual?';

  @override
  String get exitOfferSubtitle =>
      'Válida só agora e uma única vez nesta conta.';

  @override
  String exitOfferExpiresIn(String time) {
    return 'Expira em $time';
  }

  @override
  String get exitOfferPlan => 'Premium anual';

  @override
  String exitOfferFrom(String price) {
    return 'De $price por';
  }

  @override
  String get exitOfferFirstYear => 'no 1º ano';

  @override
  String exitOfferPerMonth(String price) {
    return 'Equivale a $price por mês';
  }

  @override
  String exitOfferButton(String price) {
    return 'QUERO POR $price NO 1º ANO';
  }

  @override
  String exitOfferRenewal(String price) {
    return 'Depois do 1º ano, renova por $price por ano. Cancele quando quiser na Play Store.';
  }

  @override
  String get exitOfferNoThanks => 'Não, obrigado';

  @override
  String offerExitPercent(int percent) {
    return '$percent% de desconto no 1º ano';
  }

  @override
  String get offerExitGeneric => 'Desconto especial no 1º ano';

  @override
  String get stationPreliminaryBadge => 'Preliminar';

  @override
  String get stationPreliminaryNote =>
      'Valor preliminar: fica definitivo a partir de 3 abastecimentos com tanque cheio neste posto.';

  @override
  String get stationConsumptionAlert =>
      'Consumo muito diferente da sua média. Pode ser a qualidade do combustível ou um registro incompleto, como tanque não cheio. Confira os abastecimentos deste posto.';
}
