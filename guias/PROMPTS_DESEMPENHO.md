# MyCarApp — Prompts da tela Desempenho (Força G + Velocímetro)

Criado em 01/11/2026. Prompt 1 (criação da tela), Prompt 2 (correções funcionais do primeiro teste, 03/11/2026) e Prompt 3 (igualar o visual à maquete, 03/11/2026), para o Claude Code.

## Situação

| Item | Situação |
|---|---|
| Maquete (retrato e paisagem) | Pronta (canvas "MyCarApp Acelerômetro") |
| Prompt 1 — Tela Desempenho | Executado (tela criada) |
| Prompt 2 — Correções: velocímetro com atraso e Força G que não calibra | Pronto para executar (rodar ANTES do Prompt 3) |
| Prompt 3 — Igualar o visual à maquete | Pronto para executar (rodar DEPOIS do Prompt 2) |
| Arquivos de referência do Prompt 3 (4 imagens + 2 fontes) | **Pendente** (Yuri copiar para o repositório, ver "Antes do Prompt 3") |
| 1. `flutter pub get` e `flutter gen-l10n` | **Pendente** (Yuri) |
| 2. Play Console: atualizar a Segurança dos dados (localização) | **Pendente** (Yuri) |
| 3. Remote Config: publicar `performance_enabled` (começar em `false`, ligar quando os testes manuais passarem) | **Pendente** (Yuri) |
| 4. Teste em pista ou local fechado: calibração com o celular fixo, radar, velocímetro ao vivo e 0–100 | **Em andamento** (1º teste em 03/11: velocímetro com atraso; Força G dizia "não foi possível"; visual diferente da maquete) |

## Como executar (padrão)

- Um único agente executa o prompt, sem subagentes.
- Não rodar o app, pub get, gen-l10n nem flutter analyze. O Yuri faz isso.

Chamada do Prompt 1:

```
Leia somente guias/PROMPTS_DESEMPENHO.md, seção "Como executar" e o "Prompt 1 — Tela Desempenho". Execute só esse prompt, sem usar subagentes.
```

Chamada do Prompt 2:

```
Leia somente guias/PROMPTS_DESEMPENHO.md, seção "Como executar" e o "Prompt 2 — Correções do primeiro teste". Execute só esse prompt, sem usar subagentes.
```

Chamada do Prompt 3:

```
Leia somente guias/PROMPTS_DESEMPENHO.md, seção "Como executar" e o "Prompt 3 — Igualar o visual à maquete". Execute só esse prompt, sem usar subagentes.
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

## Prompt 2 — Correções do primeiro teste

Contexto do teste (03/11/2026): o velocímetro respondeu com bastante atraso e a Força G não funcionou (a tela ficava dizendo "não foi possível"). Causas prováveis, que o Code deve confirmar no código:

- **Velocímetro:** o stream de GPS sem `intervalDuration` (no Android o padrão é bem mais lento que 1 s), provedor fundido misturando rede e GPS, e suavização pesada demais no ponteiro. Primeira posição ("cold start") também pode levar de 10 a 60 s.
- **Força G:** a calibração do Prompt 1 tinha 2 etapas e a segunda exigia uma aceleração real para frente, que com o carro parado (ou testando em casa) nunca acontece. Além disso, a primeira etapa falhava se o celular tremesse um pouco na mão.

```
Sem ler outros arquivos além dos citados: lib/screens/performance_screen.dart, lib/services/performance_service.dart, lib/models/performance_record.dart, lib/l10n/app_pt.arb, lib/l10n/app_en.arb (e pubspec.yaml só se precisar conferir a versão do geolocator ou do sensors_plus).

Objetivo: corrigir dois problemas do primeiro teste real da tela Desempenho: (A) o velocímetro responde com muito atraso; (B) a Força G não funciona e a tela mostra "não foi possível". Mantenha o layout, as cores e o resto do comportamento como estão.

A) Velocímetro com atraso
1. Em performance_service.dart, localizar o Geolocator.getPositionStream e definir as configurações por plataforma (defaultTargetPlatform):
   - Android: AndroidSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0, intervalDuration: const Duration(milliseconds: 500), forceLocationManager: true). Comentar em português o porquê: sem intervalDuration o Android usa um intervalo padrão bem maior que 1 s, e o provedor fundido pode misturar rede com GPS; forceLocationManager usa o GPS direto, cuja velocidade vem do efeito Doppler e é a mais fresca.
   - iOS/outros: AppleSettings(accuracy: LocationAccuracy.bestForNavigation, activityType: ActivityType.automotiveNavigation, distanceFilter: 0, pauseLocationUpdatesAutomatically: false).
   - Se com forceLocationManager: true não chegar nenhuma posição em 12 s, reiniciar o stream uma vez com forceLocationManager: false, e comentar isso.
2. Garantir que a velocidade vem SÓ do stream (nada de getCurrentPosition em Timer, nada de distanceFilter maior que 0).
3. Suavização: trocar qualquer média móvel ou filtro pesado por filtro exponencial leve com alfa adaptativo (alfa 0,65 quando a variação passa de 3 km/h, alfa 0,4 quando estável, e sem janela com mais de 2 amostras). Quando a velocidade crua for menor que 1 km/h, mostrar 0 direto, sem arrastar.
4. Ponteiro: animar com TweenAnimationBuilder de no máximo 300 ms (curva linear), para não somar atraso visual em cima do atraso do GPS.
5. Descartar amostras velhas: comparar position.timestamp com DateTime.now() e ignorar amostras com mais de 3 s de idade. Se position.speedAccuracy for maior que 3 m/s (e diferente de 0, que em alguns aparelhos significa "desconhecido"), marcar o GPS como "fraco", sem bloquear a leitura.
6. Estado do GPS visível no cartão "GPS" que já existe: "Buscando GPS…" até a primeira posição; "GPS fraco" quando position.accuracy for maior que 30 m ou speedAccuracy estiver alto; "GPS ok" nos demais casos. Texto com contraste total, sem opacidade.

B) Força G que não funciona
1. Procurar nos arquivos citados o texto "não foi possível" (e a chave correspondente nos .arb) e identificar em qual ponto do fluxo ele é disparado. Substituir por mensagens específicas, uma por causa, em pt e en:
   - Sem leituras do sensor (nenhum evento em 2 s ou erro no stream): "Este aparelho não está entregando leituras do acelerômetro."
   - Celular mexendo durante a calibração: "Segure o celular parado e fixo por 2 segundos." (aguardar a estabilidade em vez de falhar; só desistir depois de 10 s, com essa mensagem).
   - Posição incompatível com a opção escolhida (ver item 3): "A posição do celular não combina com a opção escolhida. Ajuste o suporte ou troque a opção."
2. Calibração em UM passo só. Remover totalmente a etapa de "acelerar levemente para frente". Ler accelerometerEventStream (SensorInterval.gameInterval) e calcular, em janela deslizante de 1,5 s, a média e o desvio-padrão do módulo do vetor. Considerar estável quando o desvio-padrão do módulo for menor que 0,15 m/s² e o módulo médio ficar entre 8,5 e 11 m/s². Ao ficar estável, guardar up = vetor médio normalizado (aponta para cima).
3. Eixo "para frente" vem da posição do celular, escolhida em dois botões (seletor segmentado) ao lado do botão Calibrar, guardada por veículo; padrão: "Em pé no suporte":
   - "Em pé no suporte (tela para o motorista)": f0 = (0, 0, -1) no referencial do aparelho (frente do carro = costas do celular).
   - "Deitado (tela para cima, topo para frente)": f0 = (0, 1, 0).
   Cálculo: forward = normalizar(f0 - (f0·up)·up); se o módulo de f0 - (f0·up)·up for menor que 0,3, falhar com a mensagem de posição incompatível. right = normalizar(forward × up). Aceleração longitudinal = a_lin · forward; lateral = a_lin · right; dividir por 9,80665 para obter g. Positivo à frente (acelera) e à direita; negativo = frenagem e esquerda. Comentar em português o referencial do Android (x à direita da tela, y para o topo, z saindo da tela) e a conta.
4. Autocalibração ao abrir a tela: assim que o celular ficar estável por 1,5 s, calibrar com a última opção de posição salva, sem o usuário precisar apertar nada. O botão "Calibrar" continua existindo e refaz tudo (zerando pico e rastro).
5. Sensor: usar userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval) como principal. Se não chegar nenhum evento em 2 s ou o stream der erro, cair para accelerometerEventStream (mesmo samplingPeriod) e obter a aceleração linear subtraindo um vetor de gravidade estimado por filtro passa-baixa (alfa 0,9) — e comentar isso. Guardar qual dos dois está em uso.
6. Enquanto não houver calibração, o radar não deve ficar "morto": mostrar o módulo da aceleração linear (força resultante) e a bolinha centralizada, com o texto "Calibrando…" ou "Segure o celular parado". Só mostrar erro depois do tempo limite do item 1.
7. Painel de diagnóstico: um toque longo no título "Desempenho" liga/desliga uma linha pequena, com texto claro e legível, abaixo dos painéis, mostrando: sensor em uso (linear ou bruto), taxa de leituras por segundo (Hz), situação da calibração, idade da última posição do GPS em segundos, precisão horizontal em metros e speedAccuracy. É para eu conferir em campo sem depender de adivinhação.

C) Geral
- Strings novas em pt e en nos dois .arb; não edite os app_localizations*.dart gerados.
- Mantenha os comentários existentes e comente em português o que mudar.
- Não rode o app, pub get, gen-l10n nem flutter analyze.
- No fim, liste os arquivos alterados e diga: (1) em que ponto exato do código o "não foi possível" era disparado e por qual condição; (2) quais configurações de GPS estavam em uso antes da mudança.
```

## Prompt 3 — Igualar o visual à maquete

Contexto (03/11/2026): no primeiro teste, a tela real ficou bem diferente da maquete aprovada: os números sem destaque (fonte padrão em vez da condensada em negrito, e tamanhos menores), o medidor de Força G grande demais e o velocímetro fora do lugar. A maquete é a fonte da verdade. As medidas abaixo foram tiradas diretamente dela (1 px da maquete = 1 dp).

### Antes do Prompt 3 (Yuri)

Copiar para o repositório do app, antes de rodar o prompt:

1. As 4 imagens de referência, para `guias/referencia/`:
   - `referencia_retrato.png` (390×844 dp, exportada em 2x)
   - `referencia_paisagem.png` (844×390 dp, exportada em 2x)
   - `referencia_recordes_retrato.png`
   - `referencia_recordes_paisagem.png`
2. As 2 fontes, para `assets/fonts/` (Barlow Condensed, licença OFL; o Code declara no pubspec.yaml):
   - `BarlowCondensed-SemiBold.ttf`
   - `BarlowCondensed-Bold.ttf`
3. Atualizar o `guias/PROMPTS_DESEMPENHO.md` do repositório com esta versão.

Rodar o Prompt 2 antes deste, se ainda não tiver rodado (o Prompt 3 parte da tela já com os ajustes dele).

```
Sem ler outros arquivos além dos citados: lib/screens/performance_screen.dart (e, se existirem, os widgets que ele importa em lib/widgets/performance/), pubspec.yaml (só os blocos flutter: fonts e flutter: assets), lib/l10n/app_pt.arb, lib/l10n/app_en.arb.

ANTES de mexer em qualquer código, abra e estude, uma por uma, as quatro imagens de referência: guias/referencia/referencia_retrato.png, guias/referencia/referencia_paisagem.png, guias/referencia/referencia_recordes_retrato.png e guias/referencia/referencia_recordes_paisagem.png. Cada imagem foi exportada em 2x: o retrato tem 390×844 dp lógicos e a paisagem 844×390 dp.

Objetivo: deixar a tela "Desempenho" VISUALMENTE IDÊNTICA à maquete (as imagens), nas duas orientações e nas duas visões (ao vivo e Recordes). Hoje o app ficou diferente: números pequenos e sem destaque, medidor de Força G grande demais e velocímetro fora do lugar. Refaça o layout (não remende) seguindo as medidas abaixo. NÃO mexa na lógica: sensores, GPS, calibração, teste 0–100, recordes, Remote Config, analytics e permissões continuam como estão. Mexa só na apresentação.

1. FONTE DOS NÚMEROS (é o que mais pesa no "destaque")
- Todos os números grandes (velocidade, força G, 0–60, 0–100, recordes, "112 km/h", "0,74 g") usam Barlow Condensed, peso 700, com FontFeature.tabularFigures().
- Declarar no pubspec.yaml, dentro do bloco flutter: (sem duplicar o que já existir):
    fonts:
      - family: BarlowCondensed
        fonts:
          - asset: assets/fonts/BarlowCondensed-SemiBold.ttf
            weight: 600
          - asset: assets/fonts/BarlowCondensed-Bold.ttf
            weight: 700
  Garantir que assets/fonts/ esteja coberto em flutter: assets: se necessário.
- Todo o resto do texto usa a fonte padrão do app (Inter, se já estiver no projeto). Não usar google_fonts: tem que funcionar sem internet, na pista.

2. ESCALA
- Definir um fator s e multiplicar por ele tamanhos de fonte, tamanhos dos medidores e paddings (as larguras continuam flexíveis, com Expanded):
  retrato: s = (largura / 390), limitado entre 0,85 e 1,3;
  paisagem: s = min(largura / 844, altura / 390), limitado entre 0,8 e 1,4.
- Alvos de toque nunca abaixo de 44 dp, mesmo com s menor que 1.
- Scaffold com fundo 0xFF16191E, SafeArea, ícones da barra de status claros (SystemUiOverlayStyle.light).

3. CORES (classe local PerformanceColors, sem mexer no AppColors)
fundo 0xFF16191E; painel 0xFF2B3038; linhas do radar 0xFF6B7686; texto principal branco; texto secundário 0xFFE3E8EF (peso mínimo w500, NUNCA com opacidade reduzida); dourado 0xFFD4A72C (AppColors.gold); dourado-claro 0xFFFFE7A3; contorno de botão 0xFF8FB4E8; texto sobre dourado 0xFF071B33.

4. CABEÇALHO (igual nas duas visões)
- Linha com itens centralizados verticalmente. Ícone do app 36×36, raio 9 (paisagem: 32×32, raio 8). Ao lado, coluna: "Desempenho" 18/w700, altura de linha 1,1 (paisagem: 16), e embaixo o nome do veículo 12/w500 cor secundária. Espaço entre os itens: 10 (paisagem: 12). A coluna do título cresce e empurra o resto para a direita.
- Botão "Recordes" (na visão de Recordes vira "Voltar"): altura mínima 44, padding horizontal 14 (paisagem: 16), raio 12, borda 2 na cor de contorno, fundo transparente, texto branco 13/w600.
- Selo PREMIUM: pílula totalmente arredondada, fundo dourado, texto 0xFF071B33, 12/w700, letterSpacing 0,96, padding 5 vertical e 10 horizontal.

5. RETRATO, VISÃO AO VIVO (390×844 dp)
- Padding da tela: 20 nos quatro lados. Espaço de 14 entre blocos principais (cabeçalho, conteúdo, aviso). Dentro do conteúdo, espaço de 12 entre as linhas de blocos.
- LINHA 1 — dois painéis lado a lado, mesma largura, espaço de 10 entre eles, mesma altura (esticar). ESQUERDA = Velocímetro, DIREITA = Força G. Cada painel: fundo painel, raio 18, padding (topo 12, direita 10, base 14, esquerda 10), coluna centralizada com espaço de 4:
  a) título "● VELOCÍMETRO" / "● FORÇA G": 12/w500, cor secundária, letterSpacing 0,96; o "●" em dourado.
  b) medidor de 156×156 (detalhes nos itens 7 e 8).
  c) número grande: Barlow 34/w700, altura de linha 1,0. No Velocímetro: velocidade máxima da sessão, em dourado, formato "112 km/h". Na Força G: força resultante em branco, formato "0,74 g".
  d) legenda 12 regular, cor dourado-claro: "máxima da sessão" / "força resultante".
- LINHA 2 — grade de 3 colunas iguais, espaço de 10, alturas iguais: Lateral (0,41 g, legenda "direita"), Aceleração (0,62 g, "à frente"), Pico da sessão (0,94 g, "curva dir."). Cada cartão: fundo painel, raio 14, padding 12, coluna com espaço de 2: rótulo 12/w500 cor secundária; valor Barlow 30/w700, altura 1,1, branco; legenda 12 regular dourado-claro. (Na maquete o rótulo "Pico da sessão" quebra em 2 linhas: pode quebrar.)
- LINHA 3 — mesma grade de 3 colunas: 0–60 km/h (3,92 s), 60–100 km/h (2,92 s) e GPS. O cartão GPS tem o rótulo "GPS" e, no lugar do valor, o estado em 14/w600, altura 1,5, dourado-claro: "Sinal forte", "Sinal fraco" ou "Buscando GPS…" (estes textos substituem os do Prompt 2).
- LINHA 4 — cartão "0–100 por combustível": fundo painel, raio 14, padding 12 vertical e 16 horizontal, coluna com espaço de 6. Título 13/w600 branco. Uma linha por combustível do veículo (na maquete Gasolina e Etanol), com o nome à esquerda (13 regular, cor secundária) e o tempo à direita (13/w600, branco), space-between.
- Espaço flexível que empurra o resto para baixo.
- Linha de botões, espaço de 10: "Calibrar" (flex 1, altura mínima 48, raio 12, borda 2 na cor de contorno, fundo transparente, texto branco 14/w600) e "MEDIR 0–100" (flex 2, mesma altura, raio 12, fundo dourado sem borda, texto 0xFF071B33 14/w700, letterSpacing 0,56).
- Aviso de segurança, 14 abaixo dos botões: borda 1 dourada, raio 12, padding 10 vertical e 12 horizontal, linha com itens alinhados ao topo e espaço de 10: ícone de alerta triangular 18×18, dourado, traço 2 (path 24×24: "M12 3 2 21h20L12 3Z", "M12 10v5" e "M12 18h.01"), com 1 de margem no topo; texto 12,5, altura 1,4, dourado-claro.

6. PAISAGEM, VISÃO AO VIVO (844×390 dp)
- Padding: 10 em cima e embaixo, 20 nas laterais. Espaço de 8 entre blocos.
- LINHA 1 — dois painéis lado a lado, mesma largura, espaço de 10, altura fixa 164, fundo painel, raio 16, padding 8 vertical e 14 horizontal. Cada painel é uma LINHA centralizada com espaço de 16: à esquerda o medidor, à direita uma coluna (espaço de 2) com título (mesmo estilo do retrato), número grande e legenda.
  - Velocímetro: medidor 170 de largura (ver item 7 sobre o recorte), número "112 km/h" Barlow 44/w700 altura 1,0 dourado, legenda "máxima da sessão".
  - Força G: radar 148×148, número "0,74 g" Barlow 52/w700 altura 1,0 branco, legenda "força resultante".
- LINHA 2 — faixa de 6 cartões iguais, espaço de 8: Lateral · dir. (0,41 g), Aceleração (0,62 g), Pico da sessão (0,94 g), 0–60 km/h (3,92 s), 0–100 gasolina (6,84 s), 0–100 etanol (6,61 s). Cada cartão: fundo painel, raio 12, padding 8 vertical e 10 horizontal, coluna com espaço de 1; rótulo 12/w500 cor secundária; valor Barlow 28/w700 altura 1,1 branco. (Os dois últimos cartões seguem os combustíveis do veículo.)
- Espaço flexível. LINHA FINAL (alinhada ao centro, espaço de 10): "Calibrar" largura 130, altura mínima 46, raio 12, borda 2; "MEDIR 0–100" largura 190, mesma altura, fundo dourado; e o aviso de segurança ocupando o resto da linha: borda 1 dourada, raio 10, padding 5 vertical e 10 horizontal, itens centralizados, espaço de 8, ícone 16×16, texto 12, altura 1,3, dourado-claro.

7. VELOCÍMETRO (CustomPainter; coordenadas em um viewBox de 168×168, escalar para o tamanho do medidor)
- Centro do arco em (84,110), raio 64, semicírculo superior de 180°, do ponto esquerdo (20,110) ao direito (148,110). Traço de 14, pontas arredondadas.
- Trilho: cor de fundo da tela (0xFF16191E). Arco do valor: dourado, do ponto esquerdo até o ângulo proporcional à velocidade na escala 0–160 km/h (87 km/h preenche 54,4% do arco). Se a velocidade passar de 150 km/h, mudar a escala para 0–240 e trocar o rótulo "160" por "240".
- Textos: a velocidade atual, centralizada em (84,104), Barlow 46/w700 branco; "km/h" centralizado em (84,124), 14 cor secundária; rótulos da escala "0" em (20,142) e "160" em (148,142), 13 cor secundária.
- Retrato: medidor de 156×156 (fator 156/168). Paisagem: 170 de largura; o conteúdo útil só ocupa a faixa vertical de y=36 a y=150 do viewBox, então recorte o desenho nessa faixa (altura útil de cerca de 115) para caber folgado no painel de 164.

8. RADAR DA FORÇA G (CustomPainter; viewBox de 300×300, escalar)
- Centro (150,150). Círculo externo raio 120, preenchido com 0xFF16191E, borda 3 na cor das linhas do radar. Anéis internos em raio 80 e 40, só contorno, traço 2,5. Cruz central: linha horizontal de x=30 a x=270 e vertical de y=30 a y=270, traço 2,5. Escala: 40 unidades = 0,5 g (anéis em 0,5 g, 1,0 g e 1,5 g).
- Rótulos 22, cor secundária, centralizados: "ACEL." em (150,22) e "FREIA" em (150,294).
- Posição da bolinha = centro + (lateral em g × 80 para a direita, aceleração em g × 80 para cima); limitar ao raio 120. Rastro: poligonal do centro até a bolinha (últimas posições), dourado, traço 5, opacidade 0,9, pontas e junções arredondadas. Marca do pico: círculo vazio de raio 9, traço 3 tracejado (4 de traço e 4 de espaço) em dourado-claro, na posição do pico da sessão. Bolinha: dourada, raio 16, com um miolo de raio 6 na cor 0xFF16191E.
- Tamanho: 156×156 no retrato e 148×148 na paisagem. NÃO maior que isso: é pequeno de propósito, o destaque é o número embaixo (ou ao lado).

9. VISÃO RECORDES
- Mesmo cabeçalho (botão vira "Voltar"). Retrato: lista em coluna com espaço de 10; paisagem: grade de 2 colunas com espaço de 10 (e 10 entre linhas), cartões alinhados ao topo.
- Cada cartão: fundo painel, raio 14, padding 14 vertical e 16 horizontal, linha centralizada com espaço de 14: à esquerda coluna que cresce (espaço de 2) com título 13/w600 branco e linha de detalhe 12/w500 cor secundária; à direita o valor Barlow 28/w700 dourado (paisagem: 30).
- Itens, na ordem: Melhor 0–100 km/h · Etanol · 12/10 · 6,61 s; Melhor 0–100 km/h · Gasolina · 12/10 · 6,84 s; Maior força G lateral · Curva à direita · 05/10 · 0,94 g; Maior frenagem · 100 a 0 km/h · 05/10 · 1,08 g; Velocidade máxima · Pista fechada · 28/09 · 148 km/h. Dados reais do veículo no lugar dos exemplos.
- Espaço flexível e, no fim, o mesmo aviso de segurança (retrato: igual ao do item 5; paisagem: padding 6 vertical e 12 horizontal, ícone 16, texto 12 em uma linha). Nesta visão não há os botões Calibrar e Medir.

10. AJUSTES EM RELAÇÃO AO PROMPT 2 (para a tela principal ficar igual à imagem)
- O seletor de posição do celular ("Em pé no suporte" / "Deitado") NÃO fica na tela principal. Mover para uma folha inferior (showModalBottomSheet) aberta pelo botão "Calibrar", com as duas opções (a salva vem marcada) e um botão "Calibrar agora". A tela principal não ganha nenhum controle extra.
- O diagnóstico (toque longo no título) só aparece quando ligado; desligado, a tela é idêntica à maquete. Quando ligado, é uma linha pequena (12, cor secundária) logo abaixo do cabeçalho.
- Mensagens como "Calibrando…" e "Segure o celular parado" entram no lugar da legenda do painel da Força G ("força resultante"), sem criar nova linha. Erros de sensor aparecem numa faixa fina acima do aviso de segurança, no mesmo estilo dele.

11. GERAL
- Textos novos em pt e en nos dois .arb (por exemplo, "Sinal forte", "Sinal fraco", "Buscando GPS…", "máxima da sessão", "força resultante", "Calibrar agora"); não edite os app_localizations*.dart gerados.
- Mantenha os comentários existentes e comente em português o que mudar. Se a tela ficar grande, separe os medidores em lib/widgets/performance/ (por exemplo speed_gauge.dart e g_force_radar.dart).
- Números grandes dentro de FittedBox(fit: BoxFit.scaleDown) para "148 km/h" nunca estourar o cartão; vírgula decimal e unidades com espaço ("0,74 g", "112 km/h", "3,92 s").
- Não rode o app, pub get, gen-l10n nem flutter analyze.
- No fim, liste os arquivos criados e alterados e, bloco por bloco (cabeçalho, painéis, linhas de cartões, botões, aviso, Recordes), diga o que não deu para igualar à imagem e por quê.
```

## Depois dos prompts (Yuri)

1. `flutter pub get` (fontes e pacotes) e `flutter gen-l10n` (strings novas).
2. Comparar a tela com as imagens da pasta `guias/referencia/`, nas duas orientações.
3. Testar o velocímetro ao ar livre, com céu aberto, esperando o "Sinal forte" aparecer antes de andar.
4. Testar a Força G com o celular fixo no suporte (escolher a posição na folha do "Calibrar") e conferir pelo diagnóstico (toque longo no título) se a taxa de leituras está estável.
