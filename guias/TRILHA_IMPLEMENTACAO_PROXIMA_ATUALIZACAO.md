# Trilha de implementação — Próxima Atualização MyCarApp

> Documento de trabalho. Gerado a partir de `guias/MyCarApp_Guia_Proxima_Atualizacao.docx` (Guia de Planejamento v1.0) e do estado real do código em 2026-09-22.
> Objetivo: permitir retomar exatamente de onde parou, sem re-trabalho, mesmo em uma sessão nova sem memória da anterior.

## 0. Como retomar este trabalho

1. Leia a seção 2 (regras de negócio) — elas não mudam entre sessões.
2. Vá direto para a **Fase** em andamento (procure a primeira caixa `[ ]` não marcada, de cima para baixo, respeitando a ordem das fases).
3. Marque `[x]` cada item só depois de implementado **e** testado manualmente (build rodando).
4. Ao terminar uma fase inteira, marque o "Critério de saída" da fase antes de avançar.
5. Não pule fases com dependência não concluída (ver campo "Depende de" em cada fase).
6. Se abrir uma sessão nova para implementar, invoque o agente indicado na fase com um prompt que referencie este arquivo e o número da fase — não é preciso reexplicar o app inteiro.

---

## 1. Descobertas de arquitetura (não re-investigar)

- Projeto **não é repositório git** ainda (`git init` pendente, fora de escopo deste documento).
- Todos os dados hoje (`veículos, abastecimentos, despesas, manutenções, documentos`) são **arquivos JSON locais** (`lib/services/*_storage_service.dart`, padrão `dart:io` + `path_provider`). Não existe nenhum repositório em nuvem para dados do usuário ainda — isso é o que `GUIA_IMPLANTACAO_WEB_ASSINATURAS.md` propõe migrar.
- O único uso de Firestore/Cloud Functions hoje é em `lib/services/access_service.dart` (assinatura/entitlement) e `lib/services/account_cloud_service.dart` (wrappers de callable functions).
- Controle de acesso Premium já existe e é o ponto único a reutilizar: `AccessService.instance.hasAccess` (trial + assinatura + beta grátis) e `AccessService.instance.subscriptionActive`. **Toda nova gate de Premium deve usar esse serviço, nunca duplicar lógica.**
- Já existe sistema de indicação (`applyReferralCode`, coleções `referralCodes`/`referrals` em `functions/index.js`) que concede **desconto de 50% por 3 meses**, não Premium grátis. A Seção 5.4 do guia propõe algo diferente (Premium grátis por indicações). **Decisão registrada na Fase 7**: adaptar o mecanismo existente em vez de criar um segundo sistema de indicação.
- `lib/models/fueling_record.dart` já tem campo `station` como texto livre (`String? station`) — exatamente o problema descrito na Seção 1.1 do guia. Migração é necessária.
- `lib/services/data_transfer_service.dart` já faz export/import completo (JSON codificado em base64 dentro de CSV/Excel, via pacote `excel` e `share_plus`). **Não é o export "legível" (CSV por planilha) da Seção 4.3 do guia — são propósitos diferentes.** Reaproveitar a infraestrutura de share, não a de encoding.
- `lib/widgets/free_user_banner_ad.dart` é o padrão de referência para o **Banner de recomendação** (Seção 5): widget reativo a `AccessService`/estado, escondido quando não aplicável.
- `lib/screens/reports_screen.dart` já existe, single-tela, sem abas, calcula consumo km/l por abastecimento consecutivo (`_calculate`). É a base a evoluir para a arquitetura multi-aba da Seção 1.5 — **não recomeçar do zero**.
- `ReportsScreen` é aberta via `Navigator.push` a partir de um item de menu na Home (ícone `Icons.bar_chart_rounded`), não é aba da navegação inferior. Manter esse padrão de acesso.
- `AccountScreen` usa `ListTile` dentro de `Column`/cards — padrão a seguir para novos itens de Ajustes (Backup, Convidar amigo, Avaliar app, Armazenamento).
- Dependências **hoje inexistentes** que precisarão ser adicionadas conforme a fase: `url_launcher`, pacote de gráficos (`fl_chart` sugerido), pacote de PDF (`pdf` + `printing` sugeridos), pacote de compressão/WebP (`flutter_image_compress` sugerido) e `firebase_storage` (para backup em nuvem).

---

## 2. Regras de negócio fixadas pelo usuário (não são deduções — são decisão)

**Regra 1 — Tudo que for NUVEM precisa ser Premium.**
Qualquer funcionalidade que grave, leia ou sincronize dado do usuário em Firestore/Storage (fora do que já existe para entitlement) fica atrás de `AccessService.instance.hasAccess`. Isso vale mesmo que o dado em si pudesse "fazer sentido" grátis — o critério é a *nuvem*, não o dado.

**Regra 2 — Consumo por posto liberado para 1 posto no plano gratuito.**
O relatório "Consumo e custo por posto" (Seção 1.2 do guia) é a exceção: usuário gratuito enxerga a métrica para **exatamente 1 estabelecimento tipo posto** (não zero, não vários). Critério de seleção do posto exibido: o marcado como `favorito`; se não houver favorito, o posto com maior número de abastecimentos no período. Comparar mais de um posto, ranking, e o card "2º colocado" exigem Premium.

### 2.1 Decisões derivadas (registradas aqui para não precisar decidir de novo)

| Item do guia | Gratuito | Premium | Base da decisão |
|---|---|---|---|
| Estabelecimento (cadastro, CRUD local) | Sim, ilimitado, armazenado local | Sincronizado em nuvem entre aparelhos | Regra 1 — cadastro local não é nuvem |
| Relatório "Por posto" — 1 estabelecimento | Sim (Regra 2) | Comparação entre vários postos, ranking, gráfico de barras comparativo | Regra 2, explícita |
| Relatório "Por oficina" | Não | Sim | Não citado na exceção da Regra 2; tratado como recurso avançado |
| "Outros relatórios" (seção 1.4 completa) | Não | Sim | Mesma lógica; consistente com a sugestão do próprio guia (1.5) de export ser Premium |
| Exportar relatório em PDF/CSV (agregados) | Não | Sim | Sugestão explícita do guia (seção 1.5) |
| Export/Import genérico já existente (`data_transfer_service`) | Mantém como está hoje | — | Recurso pré-existente, fora do escopo desta atualização |
| Exportação manual CSV por módulo (seção 4.3, dado bruto, não relatório) | Sim, com limite de 6 meses | — | Sugestão explícita do guia |
| Exportação JSON completo para reimportação | Não | Sim | Ligado ao backup completo |
| Exportação PDF formatado (comprovante) | Não | Sim | Sugestão explícita do guia |
| Backup automático em nuvem | Não (nem existe) | Sim | Regra 1, direta |
| Sincronização entre aparelhos (qualquer dado) | Não | Sim | Regra 1, direta — já é a premissa do `GUIA_IMPLANTACAO_WEB` |

Se, na revisão, alguma linha da tabela acima estiver errada, corrija a tabela **antes** de implementar a fase correspondente — ela é a fonte da verdade para os gates de acesso.

---

## 3. Agentes definidos

Ao implementar, abrir cada frente com um subagente dedicado (Agent tool, `subagent_type: general-purpose` ou `fork` se continuando nesta mesma sessão), usando o prompt-base indicado. Isso mantém o contexto de cada frente pequeno e evita retrabalho cruzado.

| Agente | Escopo | Fases | Arquivos-chave |
|---|---|---|---|
| **AGENTE-MODELOS** | Entidade Estabelecimento, migração de texto livre, modelos novos | Fase 1 | `lib/models/`, `lib/services/*_storage_service.dart` |
| **AGENTE-RELATORIOS** | Telas, abas, gráficos, cache, cálculo agregado | Fases 2 e 3 | `lib/screens/reports_screen.dart`, novos widgets de relatório |
| **AGENTE-MARCA** | Rodapé institucional, link externo, analytics | Fase 4 | `lib/screens/login_screen.dart`, `lib/screens/account_screen.dart` |
| **AGENTE-PERFORMANCE** | Profiling RAM, pipeline de fotos, tela Armazenamento | Fase 5 | `lib/services/attachment_storage_service.dart`, `lib/services/document_storage_service.dart` |
| **AGENTE-BACKUP-NUVEM** | Backup automático Premium, restauração, export PDF | Fase 6 | `functions/`, novo `lib/services/cloud_backup_service.dart`, novo `lib/screens/backup_screen.dart` |
| **AGENTE-CRESCIMENTO** | Banner de recomendação, indicação, ASO | Fase 7 e 8 | novo `lib/widgets/recommendation_banner.dart`, `functions/index.js` (ajuste) |

Prompt-base sugerido ao spawnar: *"Leia `guias/TRILHA_IMPLEMENTACAO_PROXIMA_ATUALIZACAO.md`, seção [N]. Implemente apenas os itens não marcados dessa fase, seguindo as regras de negócio da seção 2. Ao concluir cada item, volte e marque a caixa correspondente no arquivo."*

---

## 4. Fases

### FASE 1 — Entidade Estabelecimento (pré-requisito) — AGENTE-MODELOS — ✅ CONCLUÍDA (2026-09-22)

Depende de: nada. **Bloqueava** as Fases 2 e 3 — desbloqueadas.

- [x] Criar `lib/models/establishment.dart`: campos `id, name, type (posto/oficina/concessionaria/lavaJato/seguradora/outro), brand?, address?, neighborhood?, favorite, active, createdAt, updatedAt`.
- [x] Criar `lib/services/establishment_storage_service.dart` seguindo exatamente o padrão de `expense_storage_service.dart` (JSON local, sem nuvem — Regra 1). Inclui `createQuick()` para o fluxo "+ Novo".
- [x] Adicionar campo de seleção com autocomplete no formulário de abastecimento (`fueling_form_screen.dart`, campo `station`) e no formulário de manutenção (`maintenance_form_screen.dart`, campo `workshop`), via widget reutilizável `lib/widgets/establishment_field.dart`.
- [x] Implementar chips de sugestão rápida (até 3 estabelecimentos mais usados recentemente, por frequência e recência) acima do campo, em ambos os formulários.
- [x] Implementar criação inline ("Criar '<nome>'" na lista de sugestões) sem sair da tela, pedindo só nome (tipo já é fixo pelo contexto do formulário: posto ou oficina).
- [x] Criar rotina de migração em `lib/services/establishment_migration_service.dart` + tela `lib/screens/establishments_screen.dart` (ação "Organizar meus locais", ícone de varinha na AppBar e botão no estado vazio).
- [x] Manter compatibilidade: `establishmentId` foi adicionado como campo novo em `FuelingRecord` e `MaintenanceRecord`; `station`/`workshop` (texto) continuam existindo e são a fonte de exibição para registros não migrados.
- [ ] Testar manualmente em aparelho/emulador real (build ainda não executado nesta sessão — `flutter analyze` e `flutter test` passaram limpos, mas não substituem teste manual de UI). **Próximo passo ao retomar.**

**Critério de saída:** atingido no código — todo novo lançamento de abastecimento/manutenção permite escolher um estabelecimento estruturado; registros antigos continuam exibindo o nome salvo mesmo sem migração. Falta apenas a validação manual em dispositivo.

**Decisões tomadas durante a implementação (registrar para não redecidir):**
- Agrupamento da migração usa **igualdade de texto normalizado** (`trim().toLowerCase()`), não similaridade fuzzy. É uma simplificação deliberada: correta e honesta, evita depender de biblioteca de similaridade não testada. Variações mais distantes (abreviações diferentes) ficam como grupos separados e podem ser unificadas manualmente depois editando o local.
- `VehicleExpense` (despesas recorrentes: seguro, financiamento, cooperativa, consórcio) **não recebeu campo de estabelecimento nesta fase** — o modelo não tem hoje nenhum campo de "local" e não é uma boa correspondência conceitual (são contas recorrentes, não visitas a um lugar físico). Se o produto quiser despesas avulsas vinculadas a um estabelecimento (ex.: pagamento único numa oficina), isso é trabalho novo, não coberto aqui.
- Novo item de menu "Meus locais" adicionado ao bottom sheet "Mais opções" da Home (`home_screen.dart`), ícone `Icons.place_outlined`, entre "Relatórios" e "Documentos". Tela: `EstablishmentsScreen` — lista, favoritar, arquivar, editar, criar manualmente (FAB) e organizar (ícone AppBar).
- `EstablishmentField` é o componente reutilizável (widget novo) usado tanto para posto quanto oficina — qualquer novo tipo de estabelecimento em formulário futuro deve reusar esse widget, não recriar campo de texto livre.

---

### FASE 2 — Relatório "Por posto" (gratuito, limitado a 1) — AGENTE-RELATORIOS — ✅ CONCLUÍDA (2026-09-22)

Depende de: Fase 1. **Frente prioritária** — é o diferencial competitivo citado no guia e a única exceção de nuvem-grátis não se aplica aqui (tudo local).

> **Descoberta importante ao iniciar esta fase:** `reports_screen.dart` já tinha uma primeira versão do ranking por posto (`_StationRankingCard`), 100% Premium, baseada só em texto livre normalizado. O trabalho desta fase foi evoluir essa base existente, não criar do zero.

- [x] `_stationAttribution` em `reports_screen.dart` agora prioriza `establishmentId` (Fase 1) e só cai para o texto normalizado em registros antigos não migrados.
- [x] Implementadas as 6 métricas da tabela da seção 1.2: consumo médio, preço médio/litro, custo por km, litros e valor total, nº de abastecimentos, variação vs. média geral do veículo no período (classe `_StationAggregate`).
- [x] Regra estatística implementada: `_StationAggregate.reliable` exige 4+ abastecimentos; abaixo disso, tanto o card gratuito quanto o destaque Premium mostram aviso de amostra pequena em vez de uma afirmação categórica.
- [x] Exclusão de medições inválidas: mantidas as regras já existentes (tanque não cheio, marcador não confirmado, capacidade ausente, odômetro não crescente, combustível/posto não uniforme no intervalo). **Não implementado**: teto numérico de "consumo fora de faixa plausível" — decisão registrada abaixo.
- [x] Filtro de período dedicado (3/6/12 meses/tudo, sem "1 mês" — conforme a seção 1.2 do guia) direto no card, sem precisar da arquitetura de abas completa da Fase 3.
- [x] **Gate gratuito x Premium implementado dentro do mesmo card** (`_StationReportCard`): gratuito calcula e mostra só 1 estabelecimento (favorito; se não houver favorito com medição no período, o mais usado) com todas as métricas; Premium mostra ranking completo, ordenável (custo/km, consumo, valor gasto), destaque 1º x 2º colocado e comparação em barras horizontais nativas.
- [x] Atalho "ver por posto" no card de combustível da Home (tile "Preço médio" agora é tocável e abre Relatórios).
- [ ] Navegação "tocar no nome do posto abre o perfil do estabelecimento com histórico" — **não implementada nesta fase**, decisão registrada abaixo.
- [x] Nenhum pacote de gráfico novo adicionado — decisão registrada abaixo.

**Critério de saída:** atingido no código — usuário gratuito com pelo menos 1 intervalo de consumo válido vê métricas completas do seu posto principal; usuário Premium vê ranking completo e ordenável entre todos os postos. Falta validação manual em dispositivo (mesma pendência da Fase 1).

**Decisões tomadas durante a implementação (registrar para não redecidir):**
- **Gráfico de barras sem `fl_chart`**: a comparação horizontal do guia foi implementada com widgets nativos (`Stack`/`Container` proporcional ao maior custo/km da lista), não com um pacote de terceiros. Motivo: nenhuma dependência nova foi validada com `flutter pub get`/build real nesta sessão (só `flutter analyze`/`flutter test`), então evitar dependência nova reduz risco. Se o produto quiser gráficos mais ricos depois (ex.: comparar tendência no tempo), aí sim vale avaliar `fl_chart`.
- **Perfil do estabelecimento com histórico**: adiado. Hoje só existe a tela de gerenciamento (`EstablishmentsScreen`, Fase 1) sem detalhe de histórico de lançamentos por local. Implementar depois como uma tela `EstablishmentDetailScreen` reaproveitando o filtro por `establishmentId` já disponível nos repositórios.
- **Teto de "consumo fora de faixa plausível"**: não implementado. As checagens já existentes (tanque cheio confirmado, capacidade informada, odômetro crescente, posto/combustível uniforme no intervalo) já filtram a maior parte dos dados ruins; um limite numérico fixo de km/L arriscava excluir veículos fora do perfil médio (motos, elétricos) sem validação de produto sobre os limites certos por tipo de veículo.
- **Card "Preço médio" da Home agora tem duplo papel** (mostra preço médio do mês E funciona como atalho): rótulo mudou para "Preço médio · ver por posto" para deixar isso explícito ao usuário, já que reaproveitar o mesmo tile evitou adicionar um quinto card ao grid 2x2 do dashboard.

---

### FASE 3 — Relatórios Premium completos — AGENTE-RELATORIOS — 🟡 PARCIAL (2026-09-22)

Depende de: Fases 1 e 2.

> **Decisão de escopo tomada nesta fase:** a arquitetura multi-aba completa (6 abas + cache dedicado) é a maior peça de risco desta fase — envolve reestruturar a navegação inteira de `reports_screen.dart` sem poder testar em dispositivo real nesta sessão. Em vez disso, priorizei os itens de maior valor por esforço indicados pelo próprio guia (seção 1.5: *"Se for para entregar poucos: consumo por posto, custo total por km e evolução do consumo"*) mantendo a estrutura atual de cards expansíveis. A reestruturação em abas fica como trabalho restante, não descartado.

- [ ] Transformar `reports_screen.dart` na arquitetura multi-aba da seção 1.5 (`Visão geral · Combustível · Por posto · Oficinas · Despesas · Veículos`) com filtro global de período e veículo fixo no topo. **Não feito** — mantida a estrutura atual de cards/`ExpandableReportCard` em lista única; cada novo relatório entrou como mais um card.
- [ ] Mover cálculos para camada de serviço dedicada (`lib/services/reports/`). **Não feito** — os cálculos dos relatórios novos continuam como métodos dentro dos próprios widgets em `reports_screen.dart`, seguindo o padrão que já existia no arquivo antes desta fase (ex.: `_calculate`, `_StationAggregate`). Vale revisitar se/quando a extração de serviço acontecer, para não ter duas convenções coexistindo.
- [ ] Cache dos agregados. **Não feito** — mesmo motivo acima; hoje todo card recalcula ao reconstruir, como já era o comportamento anterior a esta fase.
- [ ] Estado vazio orientado a ação ("faltam 2 abastecimentos..."). **Não feito** de forma dedicada; os cards novos mostram uma mensagem genérica quando não há dados suficientes (ex.: "São necessários ao menos dois abastecimentos com quilometragem no período"), mas sem o contador exato "faltam N".
- [x] **Relatório "Por oficina" implementado por completo** (`_WorkshopReportCard` em `reports_screen.dart`): gasto total e ticket médio por oficina, composição por tipo de serviço (barra proporcional nativa), alerta de possível retrabalho (duas visitas da mesma categoria em até 30 dias na mesma oficina), comparação de preço médio da mesma categoria entre oficinas diferentes (quando há histórico em 2+ oficinas), custo de manutenção por 1.000 km rodados, filtro de período (3/6/12/tudo). **Gate: 100% Premium**, sem exceção — não há carve-out equivalente à Regra 2 para oficinas.
- [x] **"Custo total por km" implementado** (`_CostPerKmCard`), somando combustível + manutenção + despesas ativas do veículo dividido pela distância rodada no período, com projeção anual simples (média mensal × 12) — os dois relatórios que a própria seção 1.5 do guia aponta como prioridade, ao lado de "por posto" (Fase 2). **Gate: Premium.**
- [ ] Demais relatórios da seção 1.4 (evolução do consumo isolada, gasto mensal comparado com delta, preço do combustível no tempo, custo por veículo, manutenções previstas, documentos a vencer, custo por percurso, ranking de categorias, relatório anual retrospectivo). **Não implementados nesta fase** — nota: "evolução do consumo" e "gasto mensal comparado" já são parcialmente cobertos pelos cards existentes (`_ConsumptionReport` mostra a diferença abastecimento a abastecimento; `_FuelExpenseReport`/`_MaintenanceExpenseReport` já mostram o detalhamento mês a mês), então a lacuna real é menor do que a lista sugere. "Custo por percurso" depende do módulo de Percursos, que ainda não existe no app (ver `GUIA_IMPLANTACAO_WEB_ASSINATURAS.md` seção 10.4) — **bloqueado a montante**, não é uma tarefa desta fase.
- [ ] Exportação PDF e CSV dos relatórios agregados. **Não implementado** — decisão registrada abaixo.

**Critério de saída:** parcialmente atingido — os dois relatórios prioritários do guia (por posto + custo por km) e o relatório de oficinas estão completos, testados via `flutter analyze`/`flutter test` (sem dispositivo). A arquitetura em abas, cache, export e os relatórios secundários da seção 1.4 continuam em aberto para uma próxima rodada desta fase.

**Decisões tomadas durante a implementação (registrar para não redecidir):**
- **Export PDF/CSV adiado**: exigiria adicionar `pdf`/`printing` (ou similar) ao `pubspec.yaml`, dependência nova não validada nesta sessão (sem `flutter pub get`/build real rodado). Ficou de fora para não introduzir risco não testado. Reavaliar junto com a Fase 6 (Backup Premium), que já vai precisar de export PDF de qualquer forma — dá para fazer as duas coisas juntas e evitar reabrir esse pacote duas vezes.
- **Distância no período** (usada tanto em "Custo por km" quanto em "Por oficina"): estimada pela diferença entre a menor e a maior quilometragem informada nos abastecimentos do período (`_distanceInPeriod`), não pelo hodômetro do veículo. É uma aproximação consistente com o que o resto do relatório de consumo já fazia; pode subestimar levemente se o usuário não abastecer perto do início/fim exato do período.
- **Comparação de preço "mesmo serviço, oficinas diferentes"** foi implementada por **categoria** (`category`, lista fixa do formulário de manutenção: Óleo e filtros, Motor, Freios etc.), não pelo texto livre de `service`. Categoria é estruturada e comparável entre oficinas; o nome do serviço digitado livremente não é.

---

### FASE 4 — Link institucional (gilessoftwares.com.br) — AGENTE-MARCA — ✅ CONCLUÍDA (2026-09-22)

Depende de: nada. Rodou em paralelo, sem conflito com as Fases 1–3.

- [x] Pacote `url_launcher: ^6.3.1` adicionado ao `pubspec.yaml` e resolvido com `flutter pub get` nesta sessão (confirmado que o ambiente tem acesso de rede para buscar pacotes — isso também destrava as dependências que as Fases 3/5/6 tinham deixado em aberto por precaução).
- [x] Widget reutilizável `lib/widgets/institutional_footer.dart` criado: "Desenvolvido por Giles Desenvolvimento de Softwares" + `gilessoftwares.com.br` tocável, fonte 11px, baixo contraste, área de toque ≥48dp (`BoxConstraints(minHeight: 48)`).
- [x] Abre com `launchUrl(uri, mode: LaunchMode.externalApplication)`, nunca WebView.
- [x] Adicionado `<queries>` com `android.intent.action.VIEW` + `scheme="https"` em `android/app/src/main/AndroidManifest.xml` — obrigatório no Android 11+ para `canLaunchUrl` enxergar o navegador (sem isso o link falharia silenciosamente em aparelhos novos).
- [x] Adicionado ao rodapé da tela de login (`login_screen.dart`).
- [x] Adicionado como `bottomNavigationBar` de `account_screen.dart` (a tela de conta já existente faz o papel de "Ajustes/Sobre" no app hoje — não foi criada uma tela "Sobre" separada). Aparece mesmo com o usuário deslogado, pois virou `bottomNavigationBar` do Scaffold, fora do `ListView` condicional por login.
- [x] Evento de analytics `institutional_site_tap` (`FirebaseAnalytics.instance.logEvent`) disparado no toque — **primeiro uso de `firebase_analytics` no código** (o pacote já estava no `pubspec.yaml` mas nunca tinha sido chamado).
- [ ] Links de Termos de Uso e Política de Privacidade — **não implementados**: não existem hoje nem telas nem URLs publicadas para esses documentos no app. Isso é pré-requisito do `GUIA_IMPLANTACAO_WEB_ASSINATURAS.md` (seção 15) antes de qualquer cobrança entrar em produção, não apenas desta atualização — ficou fora do escopo aqui por não ser uma decisão de UI, e sim depender de o documento legal existir primeiro.

**Critério de saída:** atingido no código (`flutter analyze`/`flutter test` limpos); falta apenas testar em Android real que o navegador abre corretamente com o `<queries>` novo — mesma pendência de teste manual das fases anteriores.

**Decisões tomadas durante a implementação (registrar para não redecidir):**
- **URL usada**: `https://gilessoftwares.com.br` (raiz do domínio), definida como constante `institutionalSiteUrl` em `institutional_footer.dart`. **Ainda não confirmado** se a home tem botão de assinatura — se tiver, troque só essa constante por uma página institucional sem oferta antes de publicar (pergunta 1 da seção 5 continua em aberto).
- Não existe uma tela "Sobre" dedicada no app — reaproveitei `AccountScreen`, que já cumpre esse papel de tela de configurações/conta.

---

### FASE 5 — Redução de RAM e tamanho das fotos — AGENTE-PERFORMANCE — 🟡 REVISADA, SEM PENDÊNCIA CONHECIDA (2026-09-22)

Depende de: nada. Pode rodar em paralelo.

> **Checagem feita nesta sessão**: o usuário reportou fotos "renderizadas maiores do que o necessário". Auditei todo `Image.*` (`lib/` inteiro) e todo `ImagePicker().pickImage(...)`: os 4 pontos de renderização (`home_screen.dart` `_ActiveVehicleImage`, `vehicles_screen.dart` `_VehicleImage`, `vehicle_registration_screen.dart` miniatura + visualizador em tela cheia, `app_logo.dart`) já usam `cacheWidth`/`cacheHeight` calculados por `tamanho do widget × devicePixelRatio`; os 3 pontos de captura (`fueling_form_screen.dart`, `vehicle_registration_screen.dart`, `receipt_attachments_field.dart`) já limitam `maxWidth`/`maxHeight` (1920–2048px) e `imageQuality` (82–86) na câmera/galeria. **Não encontrei o bug relatado no código atual** — pode ser um problema de layout (tamanho visual, não decodificação) em vez de RAM, ou algo específico de uma tela que não foi identificada ainda. Pendente: usuário indicar a tela exata onde viu o problema para eu confirmar e corrigir.
> O restante da fase (diagnóstico com DevTools/Profiler, pipeline de compressão/WebP na captura, auditoria de `dispose()`, paginação de listas) segue bloqueado por falta de dispositivo/emulador neste ambiente — não avançado nesta sessão por decisão do usuário.

- [ ] Rodar diagnóstico antes de codar: Flutter DevTools (aba Memory) nas telas com mais fotos/listas, Android Studio Profiler, teste em aparelho 2–3GB de RAM real, analisador de tamanho de build. Documentar os 3 maiores ofensores encontrados antes de decidir por onde começar.
- [ ] Adicionar pacote de compressão/redimensionamento (`flutter_image_compress` sugerido) ao `pubspec.yaml`.
- [ ] Implementar pipeline de 3 estágios na captura (não no upload): miniatura ~200px, exibição ~1280px, documento opcional ~1920px alta qualidade. Local do código: `lib/services/attachment_storage_service.dart` (hoje sem nenhum processamento — grava o arquivo bruto).
- [ ] Converter para WebP; remover EXIF (principalmente GPS); corrigir orientação antes de salvar.
- [ ] Oferecer escolha "foto normal" x "documento" no momento da captura (afeta `document_storage_service.dart` também).
- [ ] Garantir que listas usam a miniatura e só carregam a versão de exibição ao abrir a foto (maior impacto isolado em RAM).
- [ ] Definir teto de fotos por registro (ex.: 5 em manutenções, 10 no veículo) com aviso antes de atingir.
- [ ] Auditar `dispose()` de controllers/streams/timers nas telas mais navegadas; cancelar tudo ao sair.
- [ ] Revisar listas longas (histórico de abastecimento/manutenção) para construção preguiçosa com paginação sob demanda.
- [ ] Publicar como Android App Bundle (conferir se já é o padrão de build); auditar dependências não usadas; revisar assets e pesos de fonte embarcados.
- [ ] Criar seção "Armazenamento" em Ajustes (`account_screen.dart`): quanto o app ocupa, quanto é foto, botão "Limpar cache".

**Critério de saída:** medição antes/depois no DevTools mostra queda de pico de memória ao navegar na galeria do veículo; fotos novas pesam a faixa da tabela do guia (10–30KB miniatura, 150–400KB exibição).

---

### FASE 6 — Backup Premium em nuvem — AGENTE-BACKUP-NUVEM — 🟡 PARCIAL, CÓDIGO CLIENTE COMPLETO (2026-09-22)

Depende de: Fase 1 (para incluir estabelecimentos no backup). **Aplicação mais direta da Regra 1** — é a fase mais claramente "nuvem = Premium" do documento inteiro.

> **Mudança de arquitetura em relação ao rascunho original desta fase**: em vez de uma Cloud Function `createBackupSnapshot` lendo dados do Firestore, o app **ainda não tem nenhum dado do usuário no Firestore** (confirmado ao investigar: só `entitlements`/`users`/`referrals` existem lá — vehicles/fuelings/etc. seguem 100% locais, exatamente o que `GUIA_IMPLANTACAO_WEB_ASSINATURAS.md` já apontava). Uma Cloud Function não teria o que ler. A solução implementada foi **upload direto do cliente para o Storage**, com o gate de Premium garantido nas *regras* de segurança (Storage + Firestore), não em uma function — mesmo princípio de "o cliente nunca concede acesso a si mesmo" do guia Web, só que aplicado via regras em vez de via function.

- [x] Pacote `firebase_storage: ^13.0.5` adicionado e resolvido com `flutter pub get`.
- [x] `storage.rules` criado: caminho `users/{uid}/backups/{fileName}` — leitura/exclusão só do dono; **escrita exige** dono **e** Premium (`entitlements/{uid}.active == true` OU janela beta global `appConfig/public.premiumFreeUntil`, via `firestore.get()`/`firestore.exists()` cross-service), limite de 20MB por arquivo, `contentType` obrigatoriamente `application/json`.
- [x] `firestore.rules` ganhou o bloco `users/{uid}/backups/{backupId}` (metadados: contagem por módulo, tamanho, data) com o mesmo gate de Premium espelhado — comentado em ambos os arquivos para não desalinhar se o critério mudar.
- [x] `firebase.json` ganhou a seção `"storage"` e a porta do emulador de Storage (9199).
- [x] `lib/services/cloud_backup_service.dart`: `createBackup()` (lê os 5 storages locais, monta um JSON, sobe pro Storage, grava metadado no Firestore, poda backups antigos), `listBackups()`/`listBackupsSafely()`, `previewRestore()` (conta quantos registros seriam adicionados/atualizados, sem alterar nada) e `restoreMerge()` (mescla por id, nunca apaga, sempre cria uma cópia de segurança do estado atual antes de aplicar).
- [x] `lib/screens/backup_screen.dart`: botão "Fazer backup agora", lista de cópias com data/tamanho/contagem, restaurar com diálogo de confirmação mostrando o impacto real (N novos, M atualizados).
- [x] Restauração sempre cria backup de segurança do estado atual antes de aplicar (chama `createBackup()` no início de `restoreMerge()`).
- [x] Item "Backup e restauração" em `account_screen.dart`: card com estado (verde se backup < 7 dias, laranja se mais velho/inexistente) para Premium; card de upsell para gratuito. Sem CTA separado na Home nesta rodada — só em Ajustes, que já é a rota de 2 toques pedida.
- [ ] Retenção 7 diárias/4 semanais/3 mensais. **Simplificado**: mantém as 10 cópias mais recentes (`_keepCount = 10`), sem classificar por idade — decisão registrada abaixo.
- [ ] Backup de fotos/anexos. **Não incluído nesta versão** — decisão registrada abaixo.
- [ ] Opção "substituir tudo" ao restaurar. **Não implementada** — só existe "mesclar" (o padrão recomendado pelo próprio guia) — decisão registrada abaixo.
- [ ] Exportação manual CSV/JSON/PDF (seção 4.3 do guia). **Não implementada nesta fase** — mesma pendência já registrada na Fase 3, ainda mais reforçada: exportação PDF fica para quando as duas frentes (relatórios + backup) puderem reaproveitar o mesmo pacote de PDF de uma vez.
- [ ] Exclusão de conta apagar backups. **Não verificado** — não existe hoje um fluxo de "excluir conta" identificado no app; se existir, precisa ser atualizado para também limpar `users/{uid}/backups/*` no Storage e Firestore.
- [ ] Teto de armazenamento por usuário. Aplicado um limite técnico de 20MB **por arquivo** nas regras (evita upload de algo absurdamente grande), mas não há teto de **conta** (soma de todos os backups) — decisão de produto ainda em aberto (seção 5).

**Validação feita nesta sessão:**
- `flutter analyze` e `flutter test` limpos para todo o código Dart novo.
- `firestore.rules` **validado via emulador local** (`firebase emulators:start --only firestore --project myappcar-cd4ec`): subiu limpo, sem erro de sintaxe/compilação das regras (incluindo o novo bloco `backups`).
- `storage.rules` **NÃO foi validado no emulador** — o download do runtime de regras do Storage (`cloud-storage-rules-runtime-v1.1.3.jar`) travou/ficou muito lento neste ambiente (tentei por ~4 minutos, inclusive em segundo plano, sem sucesso). O arquivo foi escrito seguindo à risca a sintaxe documentada do Firebase (`firestore.get`/`firestore.exists` com o prefixo `firestore.`, diferente da sintaxe usada dentro do próprio `firestore.rules`), e a mesma lógica já validada em `firestore.rules` foi espelhada nele — mas **isso não substitui rodar o emulador**. Antes de publicar: `firebase emulators:start --only firestore,storage` localmente (deve ser rápido depois da primeira vez, já que o Firestore emulator já está em cache) e testar upload como usuário Premium e como usuário gratuito.
- **Nenhum deploy foi feito** (`firebase deploy` não foi executado) — os arquivos estão prontos localmente, mas o projeto real (`myappcar-cd4ec`, identificado em `.firebaserc` como o projeto de produção) não foi tocado. Também não sei se o Cloud Storage já está habilitado nesse projeto (pode exigir o plano Blaze) — isso é uma ação de console fora do alcance desta sessão.

**Critério de saída:** código cliente completo e testável estaticamente; falta (1) validar `storage.rules` no emulador, (2) confirmar que o Storage está habilitado no projeto Firebase, (3) `firebase deploy --only firestore:rules,storage` e (4) teste manual ponta a ponta em dispositivo (mesma pendência de todas as fases anteriores).

**Decisões tomadas durante a implementação (registrar para não redecidir):**
- **Sem Cloud Function**: upload feito diretamente do cliente autenticado; a segurança vem 100% das regras do Storage/Firestore, não de lógica de servidor. Isso é mais simples de manter, mas significa que qualquer mudança no critério de "é Premium?" precisa ser replicada nos **três lugares**: `access_service.dart` (cliente), `storage.rules` e `firestore.rules`. Deixei comentários cruzados nos três apontando isso.
- **Sem backup de fotos/documentos**: cobre só dados estruturados (veículos sem fotos, abastecimentos/manutenções sem anexos, despesas, locais). Fotos/documentos são arquivos binários, não registros JSON — incluí-los exigiria também subir/baixar os binários pro Storage, escopo maior que uma sessão. `Vehicle.photos`, `FuelingRecord.attachments` e `MaintenanceRecord.attachments` são zerados (`copyWith(photos: [])`/`copyWith(attachments: [])`) antes de entrar no JSON do backup.
- **Sem restauração "substituir tudo"**: só existe merge (upsert por id, nunca apaga). É a opção segura que o próprio guia recomenda como padrão; a opção destrutiva foi deliberadamente deixada de fora para não arriscar apagar dados do usuário sem poder testar em dispositivo real nesta sessão.
- **Retenção simplificada** para as 10 cópias mais recentes, não a janela 7 diárias/4 semanais/3 mensais do guia — essa classificação por idade é mais natural num job agendado no servidor (Cloud Scheduler) do que recalculada no cliente a cada backup nesta primeira versão.
- **Teto de 20MB por arquivo** aplicado nas regras como salvaguarda técnica; não é o teto de armazenamento por conta que o guia pede definir antes do lançamento (pergunta em aberto, seção 5).

---

### FASE 7 — Banner de recomendação e indicação — AGENTE-CRESCIMENTO

Depende de: nada tecnicamente, mas reaproveita o sistema de indicação já existente (ver seção 1 "Descobertas").

- [ ] Criar `lib/widgets/recommendation_banner.dart`: componente único e reaproveitável, 3 variantes de conteúdo (avaliação / indicação / upgrade Premium), mesmo padrão reativo de `free_user_banner_ad.dart`.
- [ ] Implementar regras de exibição obrigatórias: nunca para usuário novo (mínimo 3 lançamentos ou 7 dias de uso); nunca no meio de tarefa (só após ação concluída); sempre dispensável, dispensa respeitada por 30+ dias; máx. 1 banner por sessão, nunca 2 tipos na mesma sessão; some definitivamente se já avaliou/já é Premium; após 3 dispensas do mesmo banner, parar de exibir para sempre.
- [ ] Persistir estado de dispensa localmente (ex.: `SharedPreferences` ou arquivo local, mesmo padrão de `access_service.dart` para estado local simples).
- [ ] Fluxo de avaliação: usar API nativa de review do Google Play (`in_app_review` ou equivalente), **sem perguntar antes se o usuário gostou** — política do Google Play proíbe triagem prévia.
- [ ] Fluxo de indicação: **decisão de produto necessária antes de codar** — usar o sistema de desconto já existente (`applyReferralCode`, 50%/3 meses) como a mecânica real, ajustando apenas o texto do banner para refletir o benefício correto, em vez de implementar "Premium grátis por 3 indicações" como um sistema paralelo. Ver seção 5 "dúvidas" para confirmar.
- [ ] Se confirmado manter dois sistemas seria necessário, **isolar completamente** os registros do código de indicação e do código Fundador Beta no backend — nunca reaproveitar a mesma coleção/lógica.
- [ ] Adicionar caminho permanente em Ajustes: "Convidar um amigo" e "Avaliar o app" (2 toques cada, `account_screen.dart`).

**Critério de saída:** banner aparece só após os gatilhos corretos, some ao dispensar, e não reaparece antes de 30 dias; compartilhar indicação usa o link/código já emitido pelo backend existente.

---

### FASE 8 — Monetização, ASO e tráfego (conteúdo/operação, não é código Flutter)

Depende de: produto estável (não iniciar antes das Fases 1–5 estarem em uso real, conforme a própria sequência sugerida no guia, seção 6.4).

- [ ] Otimizar ficha da loja: título, descrição curta com benefício (não lista de recursos), palavras-chave ("controle de gastos do carro", "consumo de combustível", "manutenção do veículo", "km/l", "gasto com carro").
- [ ] Produzir capturas de tela com legenda por benefício; vídeo curto de demonstração.
- [ ] Responder todas as avaliações na loja.
- [ ] Avaliar blog no site (`gilessoftwares.com.br`) com conteúdo de busca, alimentando o link institucional da Fase 4.
- [ ] Só considerar tráfego pago depois de medir retenção D7/D30 saudável — não é tarefa de engenharia, é decisão de produto/marketing a revisitar depois.

**Critério de saída:** não aplicável a código; esta fase é acompanhada fora deste repositório (ficha da loja, redes, site).

---

## 5. Perguntas em aberto (confirmar antes de travar a fase correspondente)

Estas não bloqueiam o início da implementação — só precisam de resposta antes do item específico ser fechado:

1. **Fase 4**: qual URL exata do site deve receber o link institucional (home vs. página institucional dedicada sem oferta)? O guia original recomenda uma página institucional específica, sem oferta, para não violar a política de pagamentos do Google Play.
2. **Fase 6**: teto de armazenamento de backup por usuário (MB/GB) e política exata de retenção de fotos (só Wi-Fi, limite de volume).
3. **Fase 7**: confirmar se a mecânica de indicação final é a already-existente (desconto 50%/3 meses) ou se o produto quer mesmo um segundo benefício (Premium grátis por indicações) rodando em paralelo.

Quando qualquer uma dessas for respondida, atualizar esta seção e a fase correspondente, e seguir.
