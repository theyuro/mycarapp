<p align="center">
  <img src="Publicidade/branding/mycarapp-icon-180x180.png" alt="MyCarApp" width="120">
</p>

<h1 align="center">MyCarApp</h1>

<p align="center"><strong>Seu veículo. Tudo sob controle.</strong></p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.gilesdesenvolvimento.mycarapp">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/pt-br_badge_web_generic.png" alt="Disponível no Google Play" height="80">
  </a>
</p>

<p align="center">
  <a href="https://gilessoftwares.com.br">gilessoftwares.com.br</a>
</p>

---

O **MyCarApp** é um aplicativo de gestão veicular que reúne em um só lugar tudo o que envolve o seu carro: abastecimentos, manutenções, despesas, documentos e relatórios de custo.

## Funcionalidades

- **Abastecimentos**: registro de litros, valor e posto, cálculo de consumo médio (km/L), preço médio por litro e comparação entre postos.
- **Leitura de comprovantes**: fotografe o cupom fiscal e o app reconhece os dados automaticamente (OCR).
- **Manutenções**: histórico de serviços com peças, mão de obra, oficina e lembrete da próxima manutenção.
- **Despesas**: seguro, financiamento, consórcio, impostos e outros gastos, incluindo despesas recorrentes.
- **Documentos**: armazenamento de documentos do veículo com alerta de vencimento.
- **Relatórios**: custo por km, gasto mensal, projeção anual e exportação para planilha (Excel).
- **Vários veículos**: controle de mais de um carro na mesma conta.
- **Backup na nuvem**: login com Google e sincronização dos dados entre dispositivos.
- **Notificações e agenda**: lembretes de manutenção e vencimentos, com opção de adicionar à agenda do celular.

## Tecnologias

- [Flutter](https://flutter.dev) (Android e iOS)
- Firebase: Authentication, Cloud Firestore, Cloud Storage, Cloud Functions, Analytics, Crashlytics e App Check
- Google ML Kit (reconhecimento de texto)
- Google Mobile Ads e compras no app (Google Play Billing)

## Estrutura

```
lib/
  models/     modelos de dados (veículo, abastecimento, manutenção, despesa...)
  screens/    telas do aplicativo
  services/   persistência, Firebase, OCR, anúncios, notificações
  theme/      cores e tema visual
  widgets/    componentes reutilizáveis
functions/    Cloud Functions (Node.js)
ios/          projeto iOS (build via Codemagic, ver codemagic.yaml)
android/      projeto Android
```

## Desenvolvimento

```bash
flutter pub get
flutter run
```

Os arquivos de configuração do Firebase (`google-services.json` e `GoogleService-Info.plist`) e as chaves de assinatura **não** são versionados. Eles precisam ser obtidos no Firebase Console ou, no caso do iOS, são injetados pelo Codemagic durante o build.

---

<p align="center">
  Desenvolvido por <strong>Giles Desenvolvimento de Softwares</strong><br>
  CNPJ 69.190.330/0001-93<br>
  <a href="https://gilessoftwares.com.br">gilessoftwares.com.br</a>
</p>

<p align="center">© 2026 Giles Desenvolvimento de Softwares. Todos os direitos reservados.</p>
