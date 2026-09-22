import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../services/establishment_migration_service.dart';
import '../services/establishment_storage_service.dart';
import '../theme/app_colors.dart';

class EstablishmentsScreen extends StatefulWidget {
  const EstablishmentsScreen({super.key});

  @override
  State<EstablishmentsScreen> createState() => _EstablishmentsScreenState();
}

class _EstablishmentsScreenState extends State<EstablishmentsScreen> {
  final storage = EstablishmentStorageService();
  final migration = EstablishmentMigrationService();
  List<Establishment> establishments = const [];
  bool loading = true;
  bool organizing = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final all = await storage.loadActiveEstablishments();
      all.sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        establishments = all;
        loading = false;
      });
    } on Object {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  Future<void> toggleFavorite(Establishment establishment) async {
    await storage.saveEstablishment(
      establishment.copyWith(
        favorite: !establishment.favorite,
        updatedAt: DateTime.now(),
      ),
    );
    await load();
  }

  Future<void> archive(Establishment establishment) async {
    await storage.saveEstablishment(
      establishment.copyWith(active: false, updatedAt: DateTime.now()),
    );
    if (mounted) _message('${establishment.name} arquivado.');
    await load();
  }

  Future<void> openEditor([Establishment? establishment]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EstablishmentEditorSheet(
        establishment: establishment,
        storage: storage,
      ),
    );
    if (saved == true) await load();
  }

  Future<void> openOrganize() async {
    setState(() => organizing = true);
    try {
      final suggestions = await migration.findSuggestions();
      if (!mounted) return;
      if (suggestions.isEmpty) {
        _message('Nenhum local pendente de organização.');
        return;
      }
      final applied = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) =>
            _OrganizeSheet(suggestions: suggestions, migration: migration),
      );
      if (applied != null && applied > 0) {
        _message('$applied local(is) organizado(s).');
        await load();
      }
    } finally {
      if (mounted) setState(() => organizing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: const Text('Meus locais'),
      actions: [
        IconButton(
          tooltip: 'Organizar meus locais',
          onPressed: organizing ? null : openOrganize,
          icon: organizing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_fix_high_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => openEditor(),
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.navy,
      child: const Icon(Icons.add_rounded),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : establishments.isEmpty
        ? _EmptyState(onOrganize: openOrganize)
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: establishments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final establishment = establishments[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE5EAF0)),
                ),
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      establishment.favorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: establishment.favorite
                          ? AppColors.gold
                          : AppColors.muted,
                    ),
                    onPressed: () => toggleFavorite(establishment),
                  ),
                  title: Text(
                    establishment.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(establishment.type.label),
                  onTap: () => openEditor(establishment),
                  trailing: IconButton(
                    tooltip: 'Arquivar',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () => archive(establishment),
                  ),
                ),
              );
            },
          ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOrganize});
  final VoidCallback onOrganize;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_outlined, size: 56, color: AppColors.muted),
          const SizedBox(height: 12),
          const Text(
            'Nenhum local cadastrado ainda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre postos e oficinas ao lançar um abastecimento ou '
            'manutenção, ou organize os locais já digitados como texto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onOrganize,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('ORGANIZAR MEUS LOCAIS'),
          ),
        ],
      ),
    ),
  );
}

class _EstablishmentEditorSheet extends StatefulWidget {
  const _EstablishmentEditorSheet({this.establishment, required this.storage});

  final Establishment? establishment;
  final EstablishmentStorageService storage;

  @override
  State<_EstablishmentEditorSheet> createState() =>
      _EstablishmentEditorSheetState();
}

class _EstablishmentEditorSheetState extends State<_EstablishmentEditorSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController brand;
  late final TextEditingController address;
  late final TextEditingController neighborhood;
  late EstablishmentType type;
  bool favorite = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final establishment = widget.establishment;
    name = TextEditingController(text: establishment?.name ?? '');
    brand = TextEditingController(text: establishment?.brand ?? '');
    address = TextEditingController(text: establishment?.address ?? '');
    neighborhood = TextEditingController(
      text: establishment?.neighborhood ?? '',
    );
    type = establishment?.type ?? EstablishmentType.posto;
    favorite = establishment?.favorite ?? false;
  }

  @override
  void dispose() {
    name.dispose();
    brand.dispose();
    address.dispose();
    neighborhood.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    final now = DateTime.now();
    final existing = widget.establishment;
    final establishment = Establishment(
      id: existing?.id ?? '${now.microsecondsSinceEpoch}',
      name: name.text.trim(),
      type: type,
      brand: brand.text.trim().isEmpty ? null : brand.text.trim(),
      address: address.text.trim().isEmpty ? null : address.text.trim(),
      neighborhood: neighborhood.text.trim().isEmpty
          ? null
          : neighborhood.text.trim(),
      favorite: favorite,
      active: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await widget.storage.saveEstablishment(establishment);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.establishment == null ? 'Novo local' : 'Editar local',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Informe um nome'
                : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<EstablishmentType>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: EstablishmentType.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => type = value!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: brand,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Bandeira (opcional)'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: address,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Endereço (opcional)'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: neighborhood,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Bairro (opcional)'),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Favorito'),
            subtitle: const Text('Fica no topo das sugestões rápidas'),
            value: favorite,
            activeThumbColor: AppColors.blue,
            onChanged: (value) => setState(() => favorite = value),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: saving ? null : save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
              ),
              child: Text(saving ? 'SALVANDO...' : 'SALVAR'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrganizeSheet extends StatefulWidget {
  const _OrganizeSheet({required this.suggestions, required this.migration});

  final List<EstablishmentMigrationGroup> suggestions;
  final EstablishmentMigrationService migration;

  @override
  State<_OrganizeSheet> createState() => _OrganizeSheetState();
}

class _OrganizeSheetState extends State<_OrganizeSheet> {
  late final Set<int> selected = {
    for (var index = 0; index < widget.suggestions.length; index++) index,
  };
  bool applying = false;

  Future<void> apply() async {
    setState(() => applying = true);
    var count = 0;
    for (final index in selected) {
      await widget.migration.applySuggestion(widget.suggestions[index]);
      count++;
    }
    if (mounted) Navigator.of(context).pop(count);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organizar meus locais',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Encontramos estes nomes digitados em lançamentos antigos. '
          'Selecione os que devem virar um local estruturado.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.suggestions.length,
            itemBuilder: (context, index) {
              final group = widget.suggestions[index];
              return CheckboxListTile(
                value: selected.contains(index),
                title: Text(group.name),
                subtitle: Text(
                  '${group.type.label} · ${group.recordCount} lançamento(s)',
                ),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selected.add(index);
                  } else {
                    selected.remove(index);
                  }
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: applying || selected.isEmpty ? null : apply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            child: Text(
              applying
                  ? 'ORGANIZANDO...'
                  : 'UNIFICAR ${selected.length} SELECIONADO(S)',
            ),
          ),
        ),
      ],
    ),
  );
}
