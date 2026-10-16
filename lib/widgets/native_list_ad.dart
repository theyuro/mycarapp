import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/access_service.dart';
import '../services/ads_config.dart';
import '../services/ads_service.dart';
import '../theme/app_colors.dart';

/// Entrada de uma lista com anúncios nativos intercalados: ou um item real
/// ([NativeListItem]) ou a vaga de um anúncio ([NativeListAdSlot]).
///
/// Montar a lista de entradas evita mexer na aritmética de índices das
/// telas: cada item continua sabendo a própria posição original.
sealed class NativeListEntry<T> {
  const NativeListEntry();
}

class NativeListItem<T> extends NativeListEntry<T> {
  const NativeListItem(this.item, this.index);

  final T item;

  /// Posição do item na lista original (sem contar anúncios).
  final int index;
}

class NativeListAdSlot<T> extends NativeListEntry<T> {
  const NativeListAdSlot(this.slot);

  /// Número da vaga na tela (0, 1, 2...), usado como chave do widget.
  final int slot;
}

/// Intercala vagas de anúncio nativo em [items]: uma depois de cada
/// `native_every_n_items` itens, sem limite de vagas por tela. [firstSlot]
/// numera as vagas sem repetir chaves entre listas da mesma tela.
///
/// Se os nativos estiverem desligados no Remote Config, devolve só os itens.
/// A decisão de exibir (Premium, consentimento) fica com o [NativeListAd].
List<NativeListEntry<T>> withNativeAds<T>(List<T> items, {int firstSlot = 0}) {
  final config = AdsConfig.instance;
  final insertAds = config.nativeEnabled;
  final every = config.nativeEveryNItems;
  final entries = <NativeListEntry<T>>[];
  var ads = 0;
  for (var index = 0; index < items.length; index++) {
    entries.add(NativeListItem(items[index], index));
    if (insertAds && (index + 1) % every == 0) {
      entries.add(NativeListAdSlot(firstSlot + ads));
      ads++;
    }
  }
  return entries;
}

/// Quantas vagas de anúncio há em [entries].
int nativeAdCount<T>(List<NativeListEntry<T>> entries) =>
    entries.whereType<NativeListAdSlot<T>>().length;

/// Anúncio nativo (template pequeno) exibido entre os itens de uma lista.
///
/// Cada instância carrega o próprio anúncio e não ocupa espaço enquanto não
/// carregar ou se falhar. Respeita Premium, consentimento e o
/// `native_enabled`; não é afetado pelo período sem anúncios em tela cheia.
class NativeListAd extends StatelessWidget {
  const NativeListAd({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.borderRadius = 17,
  });

  /// Mesma margem dos cards da lista onde o anúncio aparece.
  final EdgeInsetsGeometry margin;

  /// Mesmo raio dos cards da lista onde o anúncio aparece.
  final double borderRadius;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AdsService.instance,
    builder: (context, _) => AnimatedBuilder(
      animation: AccessService.instance,
      builder: (context, _) {
        if (!AccessService.instance.showsAds ||
            !AdsService.instance.canRequestAds ||
            !AdsConfig.instance.nativeEnabled) {
          return const SizedBox.shrink();
        }
        return _LoadedNativeAd(margin: margin, borderRadius: borderRadius);
      },
    ),
  );
}

class _LoadedNativeAd extends StatefulWidget {
  const _LoadedNativeAd({required this.margin, required this.borderRadius});

  final EdgeInsetsGeometry margin;
  final double borderRadius;

  @override
  State<_LoadedNativeAd> createState() => _LoadedNativeAdState();
}

class _LoadedNativeAdState extends State<_LoadedNativeAd>
    with AutomaticKeepAliveClientMixin {
  // Altura fixa do template pequeno, para a lista não "pular" ao carregar.
  static const _height = 110.0;

  NativeAd? _ad;
  bool _loaded = false;

  // Mantém o anúncio carregado ao rolar a lista, em vez de descartar e pedir
  // outro sempre que ele sai da tela.
  @override
  bool get wantKeepAlive => _loaded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _ad = NativeAd(
      adUnitId: AdsService.instance.nativeAdUnitId,
      request: const AdRequest(),
      // Template pronto do SDK: dispensa factory nativa em Kotlin.
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.text,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.muted,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.muted,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
          updateKeepAlive();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (identical(ad, _ad)) _ad = null;
          AdsService.instance.reportAdIssue(
            'native_load',
            'code=${error.code} domain=${error.domain} ${error.message}',
          );
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Container(
      margin: widget.margin,
      height: _height,
      // Folga de 1 dp para a borda do card não ficar sob o anúncio.
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: const Color(0xFFE1E7EE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: ad),
    );
  }
}
