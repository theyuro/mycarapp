# MyCarApp — Prompt da tela Desempenho (Força G + Velocímetro)

Criado em 01/11/2026. Um único prompt, para o Claude Code.

## Como executar (padrão)

- Um único agente executa o prompt, sem subagentes.
- Não rodar o app, pub get, gen-l10n nem flutter analyze. O Yuri faz isso.

Chamada:

```
Leia somente guias/PROMPTS_DESEMPENHO.md, seção "Como executar" e o "Prompt 1 — Tela Desempenho". Execute só esse prompt, sem usar subagentes.
```

## Decisões da maquete (aprovadas em 01/11/2026)

- Os dois instrumentos ficam **sempre ligados** enquanto a tela estiver aberta, como num painel de carro: **Velocímetro à esquerda** (velocidade ao vivo pelo GPS) e **Força G à direita** (radar ao vivo). Não existe "iniciar sessão".
- O teste de 0–100 é um botão à parte ("Medir 0–100"), que usa o velocímetro já ligado.
- Fundo cinza-grafite, textos sem opacidade reduzida (nada de letra apagada).
- Recurso Premium, liberado por Remote Config (`performance_enabled`).

## Prompt 1 — Tela Desempenho

```
Sem ler outros arquivos além dos citados: pubspec.yaml, android/app/src/main/AndroidManifest.xml, lib/screens/home_screen.dart, lib/screens/lifetime_purchase_screen.dart, lib/services/free_plan_service.dart, lib/services/analytics_service.dart, lib/services/ads_config.dart, remoteconfig.template.json, lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

Objetivo: criar a tela "Desempenho" (Velocímetro + Força G, sempre ao vivo, e teste de 0–100) como recurso Premium. É uma tela de uso em pista ou local fechado. Nada de GPS em segundo plano.

Comportamento geral:
- Ao abrir a tela, os sensores e o GPS ligam sozinhos; ao sair (ou quando o app for para segundo plano), tudo desliga. Não há botão de iniciar ou parar sessão.
- Velocímetro (esquerda) e Força G (direita) atualizam o tempo todo.
- Botão "Medir 0–100" arma o teste de 0 a 100 km/h usando o velocímetro que já está ligado. Botão "Calibrar" (contorno) refaz a calibração dos eixos.
- "Pico da sessão" e "máxima da sessão" valem desde a abertura da tela e zeram ao calibrar ou ao reabrir a tela.

Layout (maquete aprovada pelo Yuri, em duas orientações):
- Retrato: cabeçalho (ícone do app, "Desempenho", nome do veículo ativo, botão "Recordes"/"Voltar", selo PREMIUM). Logo abaixo, dois painéis lado a lado: ESQUERDA = Velocímetro (arco com a velocidade ao vivo em km/h, ponto dourado "●" antes do título e, embaixo, a velocidade máxima da sessão em dourado); DIREITA = Força G (ponto dourado "●" antes do título; radar com anéis em 0,5 g, 1,0 g e 1,5 g, cruz central, bolinha dourada com rastro curto e marca tracejada do pico, e a força resultante embaixo). Abaixo dos painéis, em grade de 3 colunas: Lateral (com a direção), Aceleração, Pico da sessão; depois 0–60 km/h, 60–100 km/h e estado do GPS; depois um cartão "0–100 por combustível". No fim, botões "Calibrar" (contorno) e "MEDIR 0–100" (dourado), e o aviso de segurança.
- Paisagem: mesmos dois painéis em cima (gráfico à esquerda e número grande à direita dentro de cada painel), faixa de 6 cartões embaixo (Lateral, Aceleração, Pico, 0–60, 0–100 gasolina, 0–100 etanol) e, na última linha, os botões e o aviso lado a lado. Use LayoutBuilder/OrientationBuilder; permitir rotação só nesta tela (SystemChrome.setPreferredOrientations ao entrar e restaurar o que o app usa ao sair). Manter a tela ligada enquanto estiver aberta (wakelock_plus).
- "Recordes" troca o conteúdo por uma lista: melhor 0–100 por combustível, maior força G lateral, maior frenagem e velocidade máxima, cada um com data.
- Aviso fixo, sempre visível: "Use só em pista ou local fechado, respeitando a lei. Com o carro em movimento, não mexa no celular." Mostrar também um diálogo de aceite na primeira vez (guardado localmente).

Cores (criar uma classe local PerformanceColors no arquivo da tela, sem mexer no AppColors): fundo 0xFF16191E, painel 0xFF2B3038, linhas do radar 0xFF6B7686, texto principal branco, texto secundário 0xFFE3E8EF (nunca com opacidade reduzida, e peso mínimo w500), dourado AppColors.gold (0xFFD4A72C), dourado-claro 0xFFFFE7A3, contorno de botão 0xFF8FB4E8, texto sobre dourado 0xFF071B33. Números grandes em peso w700 com FontFeature.tabularFigures(). Só use Barlow Condensed se o google_fonts já estiver no projeto; senão, a fonte padrão do app. Toques com no mínimo 44 px.

Sensores e medição:
1. Arquivos novos: lib/screens/performance_screen.dart, lib/services/performance_service.dart, lib/models/performance_record.dart (ou o padrão de pasta que o projeto já usa).
2. Pacotes: sensors_plus, geolocator e wakelock_plus no pubspec.yaml (versões estáveis recentes; eu rodo o pub get).
3. Força G: userAccelerometerEventStream (sem gravidade), taxa ~50 Hz, com filtro passa-baixa e janela curta. Calibração pelo botão "Calibrar": com o celular parado e fixo no suporte, ler o accelerometerEventStream por 2 s e guardar o vetor da gravidade; depois pedir uma aceleração leve para frente por 2 s para definir o eixo longitudinal. Projetar a aceleração nos eixos longitudinal e lateral a partir dessa referência. Sem calibração válida, o radar fica parado no centro com o aviso "Calibre para começar", mas o velocímetro continua funcionando. Guardar a calibração localmente, por veículo.
4. Velocímetro: Geolocator.getPositionStream com precisão máxima, só em primeiro plano (sem serviço em segundo plano e sem ACCESS_BACKGROUND_LOCATION), usando Position.speed em km/h, com suavização leve para o ponteiro não tremer.
5. Teste 0–100 (botão "Medir 0–100"): máquina de estados parado (<2 km/h) → armado → medindo (cronômetro inicia quando passar de 3 km/h) → concluído ao atingir 100 km/h; registrar 0–60 e 60–100, com interpolação linear no cruzamento de 60 e 100 km/h. Cancelar se a velocidade voltar a zero antes do fim. Comentar no código que o GPS atualiza cerca de 1 vez por segundo e que os tempos são aproximados.
6. Pico: guardar na sessão o maior valor de força resultante, lateral e frenagem, e a velocidade máxima.
7. Combustível: antes de armar o 0–100, escolher o combustível usado, com as mesmas opções já usadas no formulário de abastecimento. Cada recorde guarda vehicleId, data, tipo, valor e combustível. Persistência em arquivo JSON local, no mesmo padrão do premium_upsell_service.
8. Permissão: só ACCESS_FINE_LOCATION no AndroidManifest. Pedir ao abrir a tela pela primeira vez, com um diálogo curto explicando que a localização só é usada enquanto a tela está aberta e que nada é enviado a servidores. Se negada, mostrar a velocidade como indisponível e deixar apenas a Força G funcionando.

Acesso e entrada:
9. lifetime_purchase_screen.dart: acrescentar PremiumFeature.performance (título, descrição e benefício nos .arb). No gratuito, o atalho abre openPremium(PremiumFeature.performance, source: 'performance_entry'); no Premium (AccessService.instance.premiumUnlocked), abre a tela.
10. home_screen.dart: adicionar um atalho discreto "Desempenho" seguindo o padrão dos atalhos que já existem.
11. Remote Config: novo parâmetro performance_enabled (booleano, padrão false), registrado em ads_config.dart e no remoteconfig.template.json; com false, o atalho não aparece. Assim dá para liberar aos poucos.
12. Analytics, pelo AnalyticsService (sem chamar o FirebaseAnalytics direto): performance_open e performance_run (result = completed, cancelled ou no_gps). Incluir as chaves que faltarem na lista fechada.

Strings em pt e en, nos dois .arb; não edite os app_localizations*.dart gerados. Mantenha os comentários existentes e comente em português o que mudar. Não rode o app, pub get, gen-l10n nem flutter analyze. No fim, liste os arquivos criados e alterados e lembre-me de: atualizar o formulário de Segurança dos dados na Play Console (localização aproximada e precisa, usada só em primeiro plano) e de publicar performance_enabled no Remote Config.
```

## Depois do prompt (Yuri)

1. `flutter pub get` e `flutter gen-l10n`.
2. Play Console: atualizar a Segurança dos dados (localização).
3. Remote Config: publicar `performance_enabled` (começar em `false`, ligar quando os testes manuais passarem).
4. Testar em pista ou local fechado: calibração com o celular fixo, radar, velocímetro ao vivo e 0–100.
