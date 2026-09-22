import '../models/establishment.dart';
import 'establishment_storage_service.dart';
import 'fueling_storage_service.dart';
import 'maintenance_storage_service.dart';

/// Um grupo de lançamentos antigos que compartilham o mesmo texto livre de
/// posto/oficina e ainda não têm um [Establishment] estruturado vinculado.
class EstablishmentMigrationGroup {
  const EstablishmentMigrationGroup({
    required this.name,
    required this.type,
    required this.fuelingIds,
    required this.maintenanceIds,
  });

  final String name;
  final EstablishmentType type;
  final List<String> fuelingIds;
  final List<String> maintenanceIds;

  int get recordCount => fuelingIds.length + maintenanceIds.length;
}

/// Agrupa os textos livres de posto/oficina já lançados (campos `station`
/// e `workshop`) que ainda não têm um [Establishment] vinculado, para a
/// tela "Organizar meus locais" (Seção 1.1 do guia de planejamento).
///
/// O agrupamento usa igualdade por texto normalizado (aparado e em
/// minúsculas). Variações mais distantes, como abreviações diferentes,
/// continuam aparecendo como grupos separados e podem ser unificadas
/// manualmente depois, editando o estabelecimento.
class EstablishmentMigrationService {
  final _fuelingStorage = FuelingStorageService();
  final _maintenanceStorage = MaintenanceStorageService();
  final _establishmentStorage = EstablishmentStorageService();

  Future<List<EstablishmentMigrationGroup>> findSuggestions() async {
    final fuelings = await _fuelingStorage.loadFuelings();
    final maintenances = await _maintenanceStorage.loadMaintenances();

    final stationGroups = <String, _RawGroup>{};
    for (final record in fuelings) {
      final text = record.station?.trim() ?? '';
      if (text.isEmpty || record.establishmentId != null) continue;
      final group = stationGroups.putIfAbsent(
        text.toLowerCase(),
        () => _RawGroup(text),
      );
      group.fuelingIds.add(record.id);
    }

    final workshopGroups = <String, _RawGroup>{};
    for (final record in maintenances) {
      final text = record.workshop?.trim() ?? '';
      if (text.isEmpty || record.establishmentId != null) continue;
      final group = workshopGroups.putIfAbsent(
        text.toLowerCase(),
        () => _RawGroup(text),
      );
      group.maintenanceIds.add(record.id);
    }

    return [
      for (final group in stationGroups.values)
        EstablishmentMigrationGroup(
          name: group.name,
          type: EstablishmentType.posto,
          fuelingIds: group.fuelingIds,
          maintenanceIds: const [],
        ),
      for (final group in workshopGroups.values)
        EstablishmentMigrationGroup(
          name: group.name,
          type: EstablishmentType.oficina,
          fuelingIds: const [],
          maintenanceIds: group.maintenanceIds,
        ),
    ];
  }

  /// Cria o estabelecimento do grupo e faz o backfill de `establishmentId`
  /// em todos os lançamentos que usavam aquele texto livre.
  Future<Establishment> applySuggestion(
    EstablishmentMigrationGroup group,
  ) async {
    final establishment = await _establishmentStorage.createQuick(
      name: group.name,
      type: group.type,
    );

    if (group.fuelingIds.isNotEmpty) {
      final fuelings = await _fuelingStorage.loadFuelings();
      for (final record in fuelings) {
        if (!group.fuelingIds.contains(record.id)) continue;
        await _fuelingStorage.saveFueling(
          record.copyWith(establishmentId: establishment.id),
        );
      }
    }
    if (group.maintenanceIds.isNotEmpty) {
      final maintenances = await _maintenanceStorage.loadMaintenances();
      for (final record in maintenances) {
        if (!group.maintenanceIds.contains(record.id)) continue;
        await _maintenanceStorage.saveMaintenance(
          record.copyWith(establishmentId: establishment.id),
        );
      }
    }
    return establishment;
  }
}

class _RawGroup {
  _RawGroup(this.name);
  final String name;
  final List<String> fuelingIds = [];
  final List<String> maintenanceIds = [];
}
