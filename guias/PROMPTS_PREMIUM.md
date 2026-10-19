# MyCarApp — Fila de prompts do Premium (Claude Code)

Atualizada em 19/10/2026. Um prompt por vez, na ordem; o próximo só depois que o anterior terminar.

## Como executar (padrão)

- Um único agente executa cada prompt, sem subagentes.
- Não rodar o app, testes, deploy nem `flutter analyze`. O Yuri testa.

Chamada de cada prompt (o Claude manda já com o nome preenchido):

```
Leia somente guias/PROMPTS_PREMIUM.md, seção "Como executar" e o "Prompt N — <nome>". Execute só esse prompt, sem usar subagentes. Não execute os outros prompts.
```

| # | Prompt | Situação |
|---|---|---|
| 0 | Analytics: navegação, toques e funil de compra | Concluído em 18/10/2026 |
| 0b | Analytics: restauração sem resultado | Concluído |
| 1 | Servidor: ofertas, teste grátis e indicação | Concluído (falta deploy e testes das functions) |
| 2 | Base de acesso e regras do gratuito | Concluído |
| 3 | Tela de assinatura (igual à maquete) | Concluído em 19/10/2026 (falta gen-l10n e revisão do diff) |
| 4 | Limites nas telas | Concluído em 19/10/2026 (falta revisão do diff) |
| 4b | Ajuste do relatório por posto (melhor posto a cada 30 dias, sem vídeo) | Concluído em 19/10/2026 |
| 5 | Relatório em PDF | Concluído em 19/10/2026 (falta pub get e gen-l10n) |
| 6 | Eventos do gratuito, anúncios e novidades | Concluído em 19/10/2026 (falta gen-l10n e Remote Config) |
| 7 | Questionário e oferta de saída (60%) | Concluído em 19/10/2026 (falta gen-l10n, deploy das functions e tag na Play) |
| 8 | Consumo preliminar por posto (Premium) | Concluído em 19/10/2026 (falta gen-l10n e Remote Config) |
| 9 | Ajustes da conferência da rodada única | Concluído em 19/10/2026 (falta pub get) |
| 10 | Build e deploy (Flutter + Firebase) | Concluído em 19/10/2026 (falta Play Console e app bundle) |

Removido: antigo prompt 8 (tela inicial no Analytics), coberto pelas correções do prompt 0.

Depois de tudo, com o Yuri: `flutter pub get`, `flutter gen-l10n`, deploy das functions (após 1 e 7) e publicar no Remote Config `free_max_vehicles`, `free_fuelings_per_month`, `free_station_unlock_days` = 30, `interstitial_grace_records` = 2 e `app_open_chance_percent` = 25 (detalhes na "Conferência da rodada única", no fim). Revisão com o Opus (só o diff): prompts 1 e 7.

---

## Prompt 0b — Analytics: restauração sem resultado

```
Sem ler outros arquivos além dos citados: lib/services/access_service.dart, lib/services/analytics_service.dart.

Hoje o purchase_restore pedido pelo botão fica sem evento em dois casos. Corrigir:
1. Nada para restaurar: quando a restauração for pedida pelo botão, iniciar uma espera de 15 segundos. Se nenhuma compra com PurchaseStatus.restored chegar nesse tempo, registrar purchase_restore com result = 'not_found' e apagar a marcação do botão. Se chegar, cancelar a espera.
2. Falha na validação durante a restauração pedida pelo botão: registrar purchase_restore com result = 'error' no catch de _verifyAndComplete, só quando a marcação do botão estiver ativa.
Cada restauração pelo botão gera um único purchase_restore: restored, not_active, not_found, error ou not_signed_in.

Mantenha os comentários existentes. Não rode o app nem o flutter analyze.
```

## Prompt 1 — Servidor: ofertas, teste grátis e indicação

```
Sem ler outros arquivos além dos citados: functions/index.js, functions/subscription_logic.js, functions/subscription_logic.test.js.

Contexto: a oferta de fundador foi desativada na Play. Ofertas ativas: closed-test-yr-70 e closed-test-3m-70 (testers), referral-yr-30 (indicação, anual) e yearly-7daysfree (7 dias grátis no anual; a própria Play só mostra para quem nunca teve a assinatura).

1. getPromotionEligibility: montar availableOfferTags nesta ordem: closed-test-yr-70 e closed-test-3m-70 (se testerEligible), referral-yr-30 (se referralOfferEligible ou referralRewardCredits > 0) e yearly-7daysfree para todos. Remover first-1000-annual-pl e a lógica de fundador (founderLimit e leitura de counters/subscribers). Manter founderSpotsRemaining na resposta, sempre 0, para não quebrar versões antigas do app.
2. subscription_logic.js: subscriptionValues passa a devolver também inFreeTrial (true quando a assinatura está na fase gratuita). Usar lineItems[].offerPhase da API subscriptionsv2 se vier na resposta; se não vier, considerar teste quando offerId === 'yearly-7daysfree' e ainda não passaram 7 dias desde subscription.startTime.
3. persistSubscription: gravar firstPaidAt e creditar a indicação (pending_payment → rewarded e referralRewardCredits + 1) só quando values.active && !values.inFreeTrial. O crédito sai na primeira cobrança real, que chega pela notificação de renovação já tratada em googlePlaySubscriptionNotification. Remover founderNumber e o incremento de counters/subscribers.
4. Atualizar subscription_logic.test.js com casos de inFreeTrial, com e sem offerPhase.

Mantenha os comentários existentes e comente em português o que mudar. Não rode testes nem faça deploy; eu faço isso.
```

## Prompt 2 — Base de acesso e regras do gratuito

```
Sem ler outros arquivos além dos citados: lib/services/access_service.dart, lib/screens/lifetime_purchase_screen.dart, lib/services/ads_config.dart, lib/services/ads_service.dart, remoteconfig.template.json, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

Objetivo: preparar a base do novo gratuito × Premium, sem mexer ainda nas telas.

1. access_service.dart: remover o teste local de 14 dias (trialDuration, _trialStartedAt, _lastSeenAt, trialRemaining, trialDaysRemaining, trialActive, hasAccess e o arquivo access.json com _stateFile, _loadState e _saveState). Em _refreshSubscriptionOptions, quando não houver oferta preferida nem seleção anterior, pré-selecionar o anual sem oferta (hoje cai no mensal).
2. lifetime_purchase_screen.dart: remover a classe AccessGate (não é usada em nenhuma tela). Trocar o enum PremiumFeature por: noAds, vehicles, fuelings, maintenance (manutenções, despesas e alertas), receiptScan, stationRanking, periodReports, export (CSV/Excel), pdf, backup, sync. Remover reports e updates. Se openPremium ainda não aceitar {String source = 'unknown'}, acrescentar e repassar à SubscriptionScreen, sem quebrar o evento de Analytics que já existe ali.
3. Criar lib/services/free_plan_service.dart com as regras do gratuito (AccessService.instance.premiumUnlocked libera tudo):
   - maxVehicles (padrão 1);
   - fuelingsPerMonth (padrão 3), contados no mês corrente; acima disso, cada novo abastecimento é liberado por vídeo premiado;
   - manutenção e despesa: cada novo registro liberado por vídeo premiado;
   - receiptScan, stationRanking completo, periodReports, export e backup: só Premium;
   - pdf: Premium, ou vídeo premiado a cada exportação;
   - melhor posto (sem vídeo): liberado no máximo 1 vez a cada stationUnlockDays (padrão 30) e visível enquanto o app ficar aberto (até o processo encerrar), com a data da última liberação guardada localmente no mesmo padrão de arquivo JSON do premium_upsell_service. *(Ajustado na rodada 4b: antes era o pior posto após vídeo premiado, a cada 7 dias.)*
   Os números vêm do Remote Config (free_max_vehicles, free_fuelings_per_month, free_station_unlock_days), registrados nos padrões de ads_config.dart e no remoteconfig.template.json.
4. ads_service.dart: criar unlockWithRewarded(), que mostra o vídeo premiado e devolve true só se a recompensa foi ganha, sem conceder as horas sem anúncio do fluxo atual. Se não houver anúncio disponível (sem rede, sem consentimento ou sem estoque), devolver true para não travar o usuário.
5. Títulos e descrições dos novos PremiumFeature nos dois .arb (pt e en). Não edite os app_localizations*.dart gerados; eu rodo o gen-l10n.

Mantenha os comentários existentes e comente em português o que mudar. Não rode o app nem o flutter analyze.
```

## Prompt 3 — Tela de assinatura (igual à maquete)

```
Sem ler outros arquivos além dos citados: lib/screens/lifetime_purchase_screen.dart, lib/services/access_service.dart, lib/theme/app_colors.dart, lib/widgets/premium_after_ad_sheet.dart, lib/widgets/premium_upsell_banner.dart, lib/widgets/house_ad_banner.dart, lib/screens/backup_screen.dart, lib/screens/account_screen.dart, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

Preços na Play: monthly-v1 R$ 6,99 e yearly-v1 R$ 49,90 no Brasil; fora do Brasil, US$ 4,00 e US$ 20,00, com a Play convertendo para a moeda local. Por isso nenhum preço, moeda ou porcentagem pode ser fixo: a economia sai 40% no Brasil e 58% fora, sempre calculada do ProductDetails. Ofertas: yearly-7daysfree (7 dias grátis no anual), referral-yr-30 e closed-test-*.

1. SubscriptionOption (access_service.dart): expor priceMicros, renewalMicros e currencyCode, lidos das pricingPhases do GooglePlayProductDetails. O hasFreeTrial já existe (criado junto com o Analytics); reaproveitar.
2. Refazer o layout da SubscriptionScreen (substituindo os ChoiceChip):
   - cabeçalho AppColors.navy com o X (fechar) à esquerda e "Restaurar compra" à direita (AppColors.goldLight); no centro, o ícone do app (assets/mycarapp_icon.png, 72 px, cantos de 18 px), o título do PremiumFeature em branco e a descrição em cinza claro;
   - cartão branco com a lista de benefícios reais (sem anúncios, veículos ilimitados, manutenções e despesas sem vídeo, leitura automática da nota fiscal, ranking completo de postos, exportação CSV, Excel e PDF, backup automático na nuvem), cada um com check azul (AppColors.blue) e o recurso que abriu a tela em primeiro;
   - dois cartões de plano selecionáveis, um embaixo do outro. Anual: selos "7 DIAS GRÁTIS" (quando houver teste) e "ECONOMIZE X%", à direita o equivalente mensal em destaque e "R$ X por ano" embaixo. Mensal: "R$ X/mês" e "cobrado todo mês". O selecionado tem borda AppColors.blue de 2 px;
   - botão dourado (AppColors.gold, texto AppColors.navy): "COMEÇAR 7 DIAS GRÁTIS" no anual com teste, "ASSINAR POR R$ X/MÊS" no mensal, "ASSINAR" nos demais casos;
   - texto de cobrança embaixo: "Grátis por 7 dias, depois R$ X por ano. Renovação automática. Cancele quando quiser na Play Store." (sem teste, sem a primeira frase);
   - "Agora não" em azul, que fecha a tela.
   Nenhum preço digitado: equivalente mensal = anual ÷ 12 e economia = 1 − anual ÷ (12 × mensal base), formatados na moeda da Play.
3. premium_after_ad_sheet.dart e o texto reserva da tela: parar de usar premiumPrices ("R$ 15/mês ou R$ 100/ano"). Mostrar "a partir de R$ X/mês", calculado do anual, quando a loja já carregou; senão, um texto sem preço. Remover premiumPrices dos .arb.
4. premium_upsell_banner.dart: reescrever os textos dos banners com benefícios reais (sem "Novos relatórios" e "Atualizações exclusivas") e apontar cada um para o PremiumFeature novo.
5. account_screen.dart, _offerName: adicionar 'yearly-7daysfree' → "7 dias grátis no plano anual".
6. Manter os ui_tap de Analytics e os source que já existem nos openPremium (subscription_plan, subscribe, subscription_close).

Strings em pt e en. Mantenha os comentários existentes e comente em português o que mudar. Não rode o app nem o flutter analyze.
```

## Prompt 4 — Limites nas telas

```
Sem ler outros arquivos além dos citados: lib/services/free_plan_service.dart, lib/screens/vehicles_screen.dart, lib/screens/vehicle_registration_screen.dart, lib/screens/home_screen.dart, lib/screens/fueling_form_screen.dart, lib/screens/maintenance_form_screen.dart, lib/screens/expenses_screen.dart, lib/screens/reports_screen.dart, lib/screens/data_transfer_screen.dart, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

Aplicar as regras do FreePlanService (Premium passa direto em tudo). Regra geral: o limite vale para criar, nunca para ver; nenhum dado já registrado fica escondido.

1. Veículos: no gratuito, ao tentar cadastrar além de maxVehicles, abrir openPremium(PremiumFeature.vehicles, source: 'limit_vehicles'). Se o usuário já tiver mais de 1 veículo, só o primeiro cadastrado aceita registros novos; os outros ficam só para consulta, com aviso e botão para o Premium.
2. fueling_form_screen.dart: ao salvar um abastecimento novo além de fuelingsPerMonth no mês, mostrar um diálogo com "Assistir vídeo e salvar" (unlockWithRewarded) e "Conhecer o Premium". Editar abastecimento existente continua livre. O botão de ler nota fiscal (scanReceipt) abre openPremium(PremiumFeature.receiptScan) no gratuito.
3. Manutenção e despesa: o mesmo diálogo a cada registro novo. Ver e editar continuam livres, e os alertas das manutenções já cadastradas continuam funcionando.
4. reports_screen.dart:
   - _StationReportCard: no gratuito, mostra só o melhor posto, sem vídeo, liberado na abertura do relatório quando já passaram stationUnlockDays (30) desde a última liberação, e visível até o app encerrar. Fora da janela, o card mostra só o aviso de quando o melhor posto volta e o botão para o Premium. O ranking completo abre openPremium(PremiumFeature.stationRanking). *(Ajustado na rodada 4b: antes era "Ver o pior posto (vídeo)".)*
   - Relatórios por período: no gratuito, trocar de período abre openPremium(PremiumFeature.periodReports); a visão padrão atual continua visível.
   - Relatórios por oficina e custo por km continuam livres; corrija os comentários "100% Premium" desses cards, que estão desatualizados.
5. data_transfer_screen.dart: exportar CSV/Excel é Premium (openPremium(PremiumFeature.export)); se houver importação, ela continua livre.
6. Manter os ui_tap de Analytics que já existem nesses botões.

Strings em pt e en. Mantenha os comentários existentes e comente em português o que mudar. Não rode o app nem o flutter analyze.
```

**Resultado (4 feito, não revisado ainda):**
- `free_plan_service.dart`: novo `canRegisterForVehicle(vehicles, vehicleId)` — sem Premium, com mais de 1 veículo cadastrado, só o de `createdAt` mais antigo aceita lançamentos novos.
- `vehicles_screen.dart`: FAB e `openForm()` bloqueiam cadastro novo além de `maxVehicles` (`openPremium(vehicles, 'limit_vehicles')`); cada card de veículo sem `canRegister` mostra aviso laranja "Somente consulta no gratuito" com botão para o Premium. Edição e exclusão continuam livres em todos os veículos.
- `home_screen.dart`: chama `FreePlanService.instance.initialize()` no `initState` (lê a data da última liberação do posto; desde a 4b, do melhor posto).
- `fueling_form_screen.dart`: `save()` (só para registro novo) verifica o veículo e, acima de `fuelingsPerMonth` no mês, abre o diálogo "Assistir vídeo e salvar" / "Conhecer o Premium". `scanReceipt()` abre `openPremium(receiptScan)` no gratuito.
- `maintenance_form_screen.dart` e `expenses_screen.dart`: mesmo diálogo a cada registro novo (sem Premium), usando `unlockMaintenanceWithRewarded`/`unlockExpenseWithRewarded`; editar continua livre.
- `reports_screen.dart`:
  - `_StationReportCard`: no gratuito mostra só o pior posto (por custo/km), bloqueado até assistir ao vídeo (`unlockWorstStation`); link para o ranking completo abre `openPremium(stationRanking)`. Premium continua com o card completo (período, ordenação, ranking). **Substituído na 4b:** agora é o melhor posto, sem vídeo (`unlockBestStationIfDue` na abertura do relatório, `bestStationUnlocked` na sessão).
  - Trocar o período dos relatórios de combustível e manutenção fora do padrão (1 mês) abre `openPremium(periodReports)` no gratuito; o período padrão continua livre e visível.
  - Comentários "100% Premium" de `_CostPerKmCard` e `_WorkshopReportCard` corrigidos (esses dois relatórios são livres).
- `data_transfer_screen.dart`: exportar CSV/Excel abre `openPremium(export)` no gratuito; importar continua livre.

Pendente (fora do escopo deste prompt, mas necessário antes de liberar): `AdsService.instance.loadRewarded()` não é pré-carregado ao abrir essas telas — o primeiro desbloqueio tende a aguardar o vídeo carregar ou liberar sem ele, dependendo do fallback do `AdsService`.

## Prompt 5 — Relatório em PDF

```
Sem ler outros arquivos além dos citados: pubspec.yaml, lib/screens/reports_screen.dart, lib/services/data_transfer_service.dart, lib/services/free_plan_service.dart, lib/services/analytics_service.dart, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

Criar o relatório em PDF do veículo:
1. Adicionar o pacote pdf ao pubspec.yaml (versão estável recente). Eu rodo o flutter pub get.
2. Criar lib/services/pdf_report_service.dart, que gera um PDF do período selecionado com: dados do veículo, consumo médio, gastos totais e por mês, custo por km, postos e lista de manutenções. Reaproveitar os cálculos que já existem em reports_screen.dart, sem duplicar a lógica. No gratuito, a parte de postos mostra só o melhor posto quando ele estiver liberado na sessão (FreePlanService.bestStationUnlocked), como na tela; senão, fica de fora.
3. Botão "Exportar PDF" no reports_screen.dart: o Premium gera direto; no gratuito, diálogo com "Assistir vídeo e gerar" (unlockWithRewarded) e "Conhecer o Premium" (openPremium(PremiumFeature.pdf)). Compartilhar o arquivo com share_plus, como na exportação CSV. Registrar AnalyticsService.tap('export_pdf').

Strings em pt e en. Mantenha os comentários existentes e comente em português o que mudar. Não rode o app nem o flutter analyze.
```

## Prompt 6 — Eventos do gratuito, anúncios e novidades

```
Sem ler outros arquivos além dos citados: lib/services/analytics_service.dart, lib/services/free_plan_service.dart, lib/services/ads_config.dart, lib/services/ads_service.dart, remoteconfig.template.json, lib/screens/notifications_screen.dart, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

1. Eventos pelo AnalyticsService, sem chamar o FirebaseAnalytics direto (o funil de compra já existe; não duplicar):
   - premium_feature_blocked (feature) no FreePlanService, quando negar;
   - rewarded_unlock (feature, result) em unlockWithRewarded.
   Se alguma chave nova for necessária, incluir na lista fechada do AnalyticsService.
2. Anúncios: app_open_chance_percent passa a ter padrão 25. Criar o parâmetro interstitial_grace_records (padrão 2): nenhum intersticial nem anúncio de abertura até o usuário ter salvo mais abastecimentos que esse número. Registrar em ads_config.dart e no remoteconfig.template.json.
3. Novidades: criar a entrada da próxima versão no mesmo padrão de news134Title/news134Text e exibi-la onde as novidades já aparecem. Texto em pt: "Chegou o MyCarApp Premium: sem anúncios, veículos ilimitados, manutenções e despesas sem vídeo, leitura da nota fiscal, ranking completo de postos, relatórios por período, exportação e backup automático. O plano gratuito continua com o controle de consumo, e todos os seus registros seguem disponíveis." Fazer também a versão em en.

Mantenha os comentários existentes e comente em português o que mudar. Não rode o app nem o flutter analyze.
```

## Prompt 7 — Questionário e oferta de saída (60%)

```
Sem ler outros arquivos além dos citados: functions/index.js, lib/services/access_service.dart, lib/services/analytics_service.dart, lib/screens/lifetime_purchase_screen.dart, lib/screens/account_screen.dart, lib/theme/app_colors.dart, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

Contexto: existe na Play a oferta exitlag no yearly-v1 (60% de desconto no 1º ano, critério determinado pelo desenvolvedor). Ela só pode aparecer para quem respondeu "Muito caro" no questionário, uma única vez por conta, por 10 minutos, e só para contas com menos de 30 dias.

Servidor (functions/index.js):
1. Nova função callable claimExitOffer (mesmas opções de autenticação e App Check da getPromotionEligibility). Ler users/{uid}: negar ({granted: false}) se existir firstPaidAt, se existir exitOfferClaimedAt ou se createdAt tiver mais de 30 dias. Se não, em transação, gravar exitOfferClaimedAt = agora e exitOfferExpiresAt = agora + 10 minutos e devolver {granted: true, expiresAt}.
2. getPromotionEligibility: enquanto exitOfferExpiresAt > agora e não houver firstPaidAt, colocar exitlag no início de availableOfferTags.

App:
3. Ao fechar a SubscriptionScreen sem assinar (X, "Agora não" ou voltar), se o usuário não for Premium, abrir lib/widgets/subscription_survey_sheet.dart (arquivo novo), no máximo 1 vez a cada 7 dias (data guardada localmente). É uma folha inferior com o título "Antes de você ir…", o texto "O que fez você não assinar agora? Leva 5 segundos e ajuda a melhorar o MyCarApp." e 5 opções de escolha única, cada uma com rótulo e dica:
   - too_expensive: "Muito caro" / "O preço não cabe no meu orçamento agora"
   - still_exploring: "Ainda estou conhecendo o app" / "Quero usar mais antes de decidir"
   - dont_need: "Não preciso desses recursos" / "O plano gratuito já me atende"
   - prefer_one_time: "Prefiro pagar uma vez só" / "Não gosto de assinatura"
   - other: "Outro motivo" / "Nenhuma das opções acima"
   Botão "ENVIAR RESPOSTA" (desabilitado com "ESCOLHA UMA OPÇÃO" até escolher) e "Pular". Sem campo de texto.
4. Registrar AnalyticsService.event('survey_answer', {reason}) ou event('survey_skip'). Nenhum texto do usuário é enviado.
5. Se reason == too_expensive: chamar claimExitOffer. Se granted, chamar refreshSubscriptionOffers() e abrir lib/screens/exit_offer_screen.dart (arquivo novo). Nos demais casos, mostrar uma tela curta de agradecimento ("Obrigado pela resposta! Você continua no plano gratuito, com todos os seus registros disponíveis.") com o botão "VOLTAR AO APP".
6. ExitOfferScreen, fundo AppColors.navy:
   - X à esquerda;
   - selo dourado "OFERTA ÚNICA PARA VOCÊ";
   - título "Entendemos. Que tal 60% de desconto no Premium anual?" e a linha "Válida só agora e uma única vez nesta conta.";
   - contador "Expira em mm:ss", calculado a partir do expiresAt devolvido pelo servidor, nunca de um tempo local;
   - cartão branco com "Premium anual", "De R$ X por" (preço de renovação riscado), o preço da oferta em destaque com "no 1º ano", "Equivale a R$ Y por mês" e 4 benefícios;
   - botão dourado "QUERO POR R$ X NO 1º ANO", que seleciona a opção exitlag e chama buySubscription;
   - texto "Depois do 1º ano, renova por R$ X por ano. Cancele quando quiser na Play Store." e o link "Não, obrigado".
   Todos os valores vêm do ProductDetails. Quando o contador chegar a zero, fechar a tela, chamar refreshSubscriptionOffers() e registrar exit_offer_expired.
7. Eventos pelo AnalyticsService: exit_offer_view, exit_offer_accept, exit_offer_decline, exit_offer_expired (incluir as chaves que faltarem na lista fechada).
8. account_screen.dart, _offerName: adicionar 'exitlag' → "60% de desconto no 1º ano".

Strings em pt e en. Mantenha os comentários existentes e comente em português o que mudar. Não rode o app, testes nem deploy, nem o flutter analyze.
```

---

## Conferência da rodada única (19/10/2026)

Executada por um único agente (Opus 5.5), sem subagentes e sem a revisão Sonnet/Opus do padrão. O Prompt 4 já estava concluído e não foi refeito. Nada foi rodado (app, testes, deploy, `flutter analyze`).

### Arquivos por etapa

**4b — Ajuste do relatório por posto**
- `lib/services/free_plan_service.dart`: pior posto após vídeo → melhor posto sem vídeo. Novos `bestStationUnlocked` (Premium ou sessão liberada), `unlockBestStationIfDue()` (libera se já passaram `stationUnlockDays`, grava a data e marca a sessão, só em memória) e `nextBestStationUnlockAt`. Removidos `unlockWorstStation`/`worstStationUnlocked`. A chave do JSON passou a `lastBestStationUnlockAt` (a antiga é ignorada).
- `lib/screens/reports_screen.dart`: `load()` chama `unlockBestStationIfDue()`; o card gratuito mostra `_StationHighlight` só com o melhor posto ou, fora da janela, o aviso `stationNextUnlock` com a data + botão do ranking completo. Removidos o botão de vídeo, `_watchForWorstStation` e `_WorstStationHighlight`.
- `lib/services/ads_config.dart` e `remoteconfig.template.json`: `free_station_unlock_days` = 30.
- `lib/l10n/app_pt.arb`, `app_en.arb`: removidas `stationLockedText`, `stationWatchButton`, `stationWorstLabel`; nova `stationNextUnlock`.
- Este guia: Prompts 2, 4 (e o resultado do 4) e 5 atualizados com a regra nova.

**5 — Relatório em PDF**
- `pubspec.yaml`: `pdf: ^3.11.3`.
- `lib/services/pdf_report_service.dart` (novo): `PdfReportData` + `PdfReportService.build()` (A4, MultiPage), salva em arquivo temporário.
- `lib/screens/reports_screen.dart`: os cálculos viraram funções de topo usadas pela tela e pelo PDF (`_inLastMonths`, `_monthlyFuelExpenses`, `_monthlyMaintenanceExpenses`, `_aggregateStations`, `_overallConsumption`, `_byCostPerKm`, `_costPerKmSummary`, `_workshopName`); botão PDF na AppBar; `_exportPdf()` com o diálogo do gratuito; `_pdfData()`; compartilhamento com `SharePlus`; `AnalyticsService.tap('export_pdf')`.
- `lib/services/free_plan_service.dart`: `pdfAllowed`.
- `.arb`: strings `pdf*`.

**6 — Eventos, anúncios e novidades**
- `lib/services/free_plan_service.dart`: `premium_feature_blocked {feature}` em cada regra que nega (`_allowedOrBlocked`); `feature` repassado ao vídeo.
- `lib/services/ads_service.dart`: `unlockWithRewarded({feature})` registra `rewarded_unlock {feature, result}` (earned, not_earned, unavailable, show_failed, busy); carência `_inGracePeriod()` no pré-carregamento, no registro de atividade e no anúncio de abertura.
- `lib/services/ads_config.dart` e `remoteconfig.template.json`: `app_open_chance_percent` = 25; novo `interstitial_grace_records` = 2.
- `lib/screens/home_screen.dart`: novidade `update-2026-10-v1-4-0`.
- `.arb`: `news140Title`, `news140Text`.
- `analytics_service.dart` não mudou: `feature`, `result`, `reason`, `source`, `plan` e `offer_tag` já estavam na lista fechada.

**7 — Questionário e oferta de saída**
- `functions/index.js`: nova callable `claimExitOffer` (App Check, transação, 10 min, 1 vez por conta, conta com menos de 30 dias e sem `firstPaidAt`); `getPromotionEligibility` põe `exitlag` em primeiro durante a janela.
- `lib/services/access_service.dart`: `SubscriptionOption.discountPercent`, `AccessService.exitOfferTag`, `exitOfferOption`, `claimExitOffer()`.
- `lib/screens/lifetime_purchase_screen.dart`: ao fechar sem assinar, `maybeShowSubscriptionSurvey`; `formatStorePrice` público.
- `lib/widgets/subscription_survey_sheet.dart` (novo): questionário, limite de 7 dias (`subscription_survey.json`), `survey_answer`/`survey_skip`, pedido da oferta e agradecimento.
- `lib/screens/exit_offer_screen.dart` (novo): oferta com contador a partir do `expiresAt` do servidor e eventos `exit_offer_view/accept/decline/expired`.
- `lib/screens/account_screen.dart`: `_offerName` com `exitlag` (percentual calculado da Play).
- `.arb`: strings `survey*`, `exitOffer*`, `offerExit*`.

### Decisões tomadas e o que ficou de fora
- **Melhor posto só gasta a janela quando há posto atribuído:** a liberação na abertura do relatório só acontece se algum intervalo de consumo tiver posto. Assim quem ainda não tem dados de posto não perde os 30 dias.
- **Período do PDF:** o PDF usa o período do relatório de combustível (no gratuito, sempre 1 mês). A parte de postos usa o período do card de postos, para mostrar o mesmo posto que a tela.
- **Fonte do PDF:** usa a Helvetica padrão do pacote, que só cobre o Latin-1. Os caracteres fora dele são trocados (espaço fino → espaço, • → ·, outros → ?). Moedas com símbolo fora do Latin-1 (₹, ₩ etc.) sairiam com "?". Para resolver, embutir uma TTF nos assets.
- **Botão do PDF:** ícone na AppBar com tooltip "Exportar PDF", sem botão de texto.
- **`premium_feature_blocked`:** fica no máximo 1 evento a cada 30 s por recurso, porque algumas regras são lidas a cada rebuild (ranking de postos, veículo só para consulta). Isso conta exibições de bloqueio, não só toques.
- **Carência dos anúncios:** conta os abastecimentos salvos de todos os veículos. No pré-carregamento, o registro em andamento soma +1, como se fosse um abastecimento. Se a leitura falhar, a carência é considerada encerrada.
- **Novidades:** elas aparecem no `home_screen.dart` (`refreshNotifications`), não no `notifications_screen.dart` citado no prompt; por isso editei o `home_screen.dart`. Chamei a versão de 1.4.0 (`news140*`), mas o `pubspec.yaml` continua em 1.3.6+13. A novidade antiga `news134` ("vários veículos… agora são gratuitos") ainda é criada para quem instala do zero e contradiz o plano novo. Avaliar se ela deve sair.
- **Percentuais:** a tela de saída e o `_offerName` calculam o desconto a partir dos micros da Play. Sem a opção carregada, aparece um texto sem número. As outras ofertas da conta já tinham o percentual fixo no `.arb`; não mexi nelas.
- **Oferta de saída sem opção na Play:** se o servidor conceder a janela mas a Play não devolver a opção com a tag `exitlag`, o usuário vê o agradecimento em vez da oferta.
- **Contador da oferta:** usa o `expiresAt` do servidor contra o relógio do aparelho (não compensa diferença de relógio). Com a tela de pagamento da Play aberta, a tela da oferta só fecha depois que a compra termina.
- **Cores do PDF:** `navy`/`muted` copiadas de `AppColors` (o pacote pdf não usa `Color` do Flutter).
- **Tabela:** os Prompts 0b, 1 e 2 continuam "Pendente" na tabela, embora o código deles pareça presente (`free_plan_service.dart`, `inFreeTrial`). Não foram verificados nesta rodada.
- Não verifiquei a compilação. Os pontos com mais risco: a API `pw.TableHelper.fromTextArray` (pdf ≥ 3.10), `SharePlus.instance.share(ShareParams(...))` (share_plus ≥ 11) e o padrão constante `AccessService.exitOfferTag` no `switch` de `_offerName`.

### Antes de testar (considerando os prompts 0 a 7)
1. `flutter pub get` (pacote `pdf`).
2. `flutter gen-l10n` (strings dos Prompts 2, 3, 4, 4b, 5, 6 e 7; removidas `premiumPrices`, `stationLockedText`, `stationWatchButton`, `stationWorstLabel`).
3. `flutter analyze` e os testes das functions (`subscription_logic.test.js`, Prompt 1).
4. Deploy das functions: `getPromotionEligibility` (Prompts 1 e 7), `persistSubscription`/`verifyAndroidSubscription` (Prompt 1) e a nova `claimExitOffer` (Prompt 7, com App Check obrigatório).
5. Play Console: a oferta `exitlag` do `yearly-v1` precisa ter a **tag de oferta** `exitlag` (o app filtra por tag, não por ID). O mesmo vale para `yearly-7daysfree`, `referral-yr-30` e `closed-test-*`.
6. Remote Config: publicar `free_max_vehicles` = 1, `free_fuelings_per_month` = 3, `free_station_unlock_days` = **30**, `interstitial_grace_records` = 2 e `app_open_chance_percent` = 25 (ou importar o `remoteconfig.template.json`).
7. Testes manuais sugeridos: melhor posto (1ª abertura libera; reabrir o app dentro de 30 dias mostra o aviso), PDF no gratuito (vídeo) e no Premium, carência (sem anúncio até o 3º abastecimento) e o fluxo "Muito caro" com uma conta nova (menos de 30 dias e nunca paga), incluindo a expiração do contador.

---

## Prompt 8 — Consumo preliminar por posto (Premium)

```
Sem ler outros arquivos além dos citados: lib/screens/reports_screen.dart, lib/services/pdf_report_service.dart, lib/services/ads_config.dart, remoteconfig.template.json, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

Consumo por posto no Premium (o gratuito continua com a regra do melhor posto a cada 30 dias):
1. Hoje o consumo de um posto só aparece a partir do 3º abastecimento com tanque cheio nele. No Premium, mostrar já a partir do 1º abastecimento com tanque cheio que tenha consumo calculável (com um tanque cheio anterior registrado).
2. Com 1 ou 2 abastecimentos válidos no posto, mostrar o valor com o selo "Preliminar" e a explicação: "Valor preliminar: fica definitivo a partir de 3 abastecimentos com tanque cheio neste posto." A partir de 3, sem selo, como hoje.
3. Alerta de discrepância: se o consumo do posto, preliminar ou definitivo, ficar mais de station_consumption_alert_percent (padrão 25) acima ou abaixo da média geral do veículo, mostrar o alerta: "Consumo muito diferente da sua média. Pode ser a qualidade do combustível ou um registro incompleto, como tanque não cheio. Confira os abastecimentos deste posto."
4. Ranking: postos preliminares aparecem com o selo. O destaque de melhor posto usa só postos definitivos; se ainda não houver nenhum, usa o melhor preliminar, com o selo.
5. Registrar station_consumption_alert_percent nos padrões de ads_config.dart e no remoteconfig.template.json.
6. Se lib/services/pdf_report_service.dart existir, levar o selo "Preliminar" e o alerta também para a parte de postos do PDF.

Strings em pt e en, nos dois .arb; não edite os app_localizations*.dart gerados. Mantenha os comentários existentes e comente em português o que mudar. Não rode o app nem o flutter analyze.
```

## Prompt 9 — Ajustes da conferência da rodada única

```
Sem ler outros arquivos além dos citados: pubspec.yaml, lib/services/pdf_report_service.dart, lib/screens/home_screen.dart, lib/services/free_plan_service.dart, lib/services/ads_service.dart, lib/screens/fueling_form_screen.dart, lib/screens/maintenance_form_screen.dart, lib/screens/expenses_screen.dart, lib/screens/reports_screen.dart.

Ajustes apontados na "Conferência da rodada única":
1. Versão: pubspec.yaml de 1.3.6+13 para 1.4.0+14, para bater com a novidade news140.
2. Novidade antiga: parar de criar a news134 ("vários veículos… agora são gratuitos") para quem instala do zero, porque contradiz o plano novo. Quem já tem essa notificação salva continua com ela.
3. Fonte do PDF: registrar no pubspec.yaml os arquivos assets/fonts/NotoSans-Regular.ttf e assets/fonts/NotoSans-Bold.ttf (eu coloco os arquivos na pasta) e usá-los no PdfReportService como fonte base e negrito, removendo a troca de caracteres fora do Latin-1.
4. Vídeo premiado: chamar AdsService.instance.loadRewarded() ao abrir o formulário de abastecimento, o de manutenção, a tela de despesas e o relatório, só para usuário gratuito e só quando o FreePlanService indicar que o próximo registro (ou o PDF) vai precisar de vídeo.

Mantenha os comentários existentes e comente em português o que mudar. Não rode o app nem o flutter analyze.
```

## Prompt 10 — Build e deploy (Flutter + Firebase)

Exceção à regra "não rodar": neste prompt o agente roda os comandos abaixo. Continua proibido rodar o app (flutter run) e publicar na Play.

```
Use um único agente, sem subagentes. Projeto Firebase: myappcar-cd4ec. Rode na raiz do projeto, nesta ordem, e pare no primeiro erro que não for de compilação simples:

1. flutter pub get
2. flutter gen-l10n
3. flutter analyze. Corrija só erros (error) causados pelos Prompts 0 a 9, sem refatorar e sem mexer em avisos (warning/info). Rode de novo até não haver erros. Liste o que corrigiu.
4. Functions: em functions/, rode npm install, npm run check e npm test. Se um teste falhar, corrija o código ou o teste conforme a regra do Prompt 1 e rode de novo.
5. Confirme o projeto com firebase use myappcar-cd4ec e depois rode firebase deploy --only functions,firestore:rules. A nova função claimExitOffer exige App Check, como a getPromotionEligibility.
6. Remote Config, com cuidado: o deploy substitui o template inteiro do console.
   a. Baixe o atual com firebase remoteconfig:get -o remoteconfig.current.json.
   b. Junte ao remoteconfig.template.json, mantendo todos os parâmetros, condições e grupos que já existem no console e só acrescentando ou atualizando: free_max_vehicles = 1, free_fuelings_per_month = 3, free_station_unlock_days = 30, interstitial_grace_records = 2, app_open_chance_percent = 25 e station_consumption_alert_percent = 25.
   c. Mostre a diferença entre o atual e o resultado e PARE. Só rode firebase deploy --only remoteconfig depois que eu aprovar.
7. Não faça commit. No fim, atualize a tabela deste guia e acrescente uma seção "Resultado do deploy" com: correções do analyze, resultado dos testes, funções publicadas, diferença do Remote Config e o que ficou pendente para mim.
```

O que continua com o Yuri depois deste prompt:
- Play Console: conferir as tags das ofertas `exitlag`, `yearly-7daysfree`, `referral-yr-30` e `closed-test-*` (o app filtra por tag, não por ID).
- Gerar o app bundle 1.4.0+14 e enviar para teste interno quando os testes manuais passarem.

## Resultado do deploy

Prompt 10, executado em 19/10/2026 por um único agente. Não foi feito commit, o app não foi rodado e nada foi publicado na Play.

- **`flutter pub get` / `flutter gen-l10n`:** ok (entraram `pdf`, `barcode`, `bidi`, `image`, `qr` e `path_parsing`).
- **`flutter analyze`:** "No issues found!" (sem erros, avisos nem infos). Não houve correções.
- **Functions:** `npm install` e `npm run check` ok. `npm test`: 10 testes, 10 passaram e nenhum falhou. Nenhuma correção.
- **Deploy** (`firebase use myappcar-cd4ec`, `firebase deploy --only functions,firestore:rules`): regras do Firestore publicadas. Todas em `southamerica-east1`: `claimExitOffer` foi criada (com `enforceAppCheck: true`, como a `getPromotionEligibility`). Foram atualizadas `ensureUserProfile`, `getAppAccess`, `updatePremiumFreeUntil`, `importClosedTesters`, `createSupportTicket`, `listSupportTickets`, `updateSupportTicket`, `applyReferralCode`, `getPromotionEligibility`, `verifyAndroidSubscription` e `googlePlaySubscriptionNotification`.
- **Remote Config:** o template atual foi baixado em `remoteconfig.current.json` (só tem o grupo "Anúncios", sem condições). O `remoteconfig.template.json` já mantém tudo o que existe no console, então não precisou de alteração. Diferença em relação ao console:
  - novo `interstitial_grace_records` = 2 (Anúncios);
  - `app_open_chance_percent`: 50 → 25;
  - novo grupo "Plano gratuito": `free_max_vehicles` = 1, `free_fuelings_per_month` = 3, `free_station_unlock_days` = 30;
  - novo grupo "Relatórios": `station_consumption_alert_percent` = 25;
  - só a descrição de `interstitial_activities_per_show` mudou (agora cita a carência), o valor continua 1;
  - nada é removido.
- **Remote Config publicado** depois da aprovação do Yuri (`firebase deploy --only remoteconfig`). Conferido baixando de novo: são 14 parâmetros, com os valores acima. O `remoteconfig.current.json` foi apagado.

Pendente para o Yuri:
- Play Console (tags das ofertas) e app bundle 1.4.0+14, como descrito acima.
