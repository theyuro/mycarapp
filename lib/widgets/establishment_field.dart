import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../theme/app_colors.dart';

/// Campo de seleção de estabelecimento com busca, chips de sugestão rápida
/// (mais usados recentemente) e criação inline ("+ Novo"), conforme a
/// Seção 1.1 do guia de planejamento da próxima atualização.
///
/// Mantém compatibilidade com o texto livre existente: o texto digitado é
/// sempre reportado via [onTextChanged], mesmo quando o usuário não
/// seleciona (ou cria) um estabelecimento estruturado.
class EstablishmentField extends StatefulWidget {
  const EstablishmentField({
    super.key,
    required this.label,
    required this.type,
    required this.establishments,
    this.recentIds = const [],
    this.initialText,
    this.initialEstablishmentId,
    required this.onTextChanged,
    required this.onEstablishmentSelected,
    required this.onCreateEstablishment,
  });

  final String label;
  final EstablishmentType type;

  /// Estabelecimentos ativos do [type], já carregados pela tela.
  final List<Establishment> establishments;

  /// Até 3 ids mais usados recentemente, exibidos como chips acima do campo.
  final List<String> recentIds;

  final String? initialText;
  final String? initialEstablishmentId;

  final ValueChanged<String> onTextChanged;
  final ValueChanged<Establishment?> onEstablishmentSelected;
  final Future<Establishment> Function(String name) onCreateEstablishment;

  @override
  State<EstablishmentField> createState() => _EstablishmentFieldState();
}

class _EstablishmentFieldState extends State<EstablishmentField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String? _selectedId;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _selectedId = widget.initialEstablishmentId;
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Establishment? _byId(String id) {
    for (final item in widget.establishments) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<Establishment> get _recentEstablishments {
    final result = <Establishment>[];
    for (final id in widget.recentIds) {
      final match = _byId(id);
      if (match != null) result.add(match);
    }
    return result;
  }

  List<Establishment> get _suggestions {
    final query = _controller.text.trim().toLowerCase();
    final source = query.isEmpty
        ? widget.establishments
        : widget.establishments.where(
            (item) => item.name.toLowerCase().contains(query),
          );
    final list = source.toList()
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return list.take(6).toList();
  }

  bool get _hasExactMatch {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return widget.establishments.any(
      (item) => item.name.toLowerCase() == query,
    );
  }

  void _select(Establishment establishment) {
    setState(() {
      _controller.text = establishment.name;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _selectedId = establishment.id;
    });
    widget.onTextChanged(establishment.name);
    widget.onEstablishmentSelected(establishment);
    _focusNode.unfocus();
  }

  Future<void> _createFromQuery() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final created = await widget.onCreateEstablishment(name);
      if (!mounted) return;
      setState(() => _selectedId = created.id);
      widget.onEstablishmentSelected(created);
      _focusNode.unfocus();
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPanel = _focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentEstablishments.isNotEmpty) ...[
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentEstablishments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final establishment = _recentEstablishments[index];
                final selected = establishment.id == _selectedId;
                return ChoiceChip(
                  label: Text(establishment.name),
                  selected: selected,
                  onSelected: (_) => _select(establishment),
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.navy : AppColors.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _creating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _selectedId = null;
                            });
                            widget.onTextChanged('');
                            widget.onEstablishmentSelected(null);
                          },
                        )
                      : null),
          ),
          onChanged: (value) {
            setState(() => _selectedId = null);
            widget.onTextChanged(value);
            widget.onEstablishmentSelected(null);
          },
        ),
        if (showPanel && _controller.text.trim().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5EAF0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final establishment in _suggestions)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      establishment.favorite
                          ? Icons.star_rounded
                          : Icons.place_outlined,
                      color: establishment.favorite
                          ? AppColors.gold
                          : AppColors.muted,
                    ),
                    title: Text(establishment.name),
                    subtitle: establishment.brand == null
                        ? null
                        : Text(establishment.brand!),
                    onTap: () => _select(establishment),
                  ),
                if (!_hasExactMatch)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.blue,
                    ),
                    title: Text('Criar "${_controller.text.trim()}"'),
                    onTap: _createFromQuery,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
