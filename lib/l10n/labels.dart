import 'l10n.dart';

/// Valores que o app grava em português (combustível, câmbio, categorias de
/// manutenção, tipos de foto) continuam gravados assim, para não quebrar
/// dados e backups existentes; só a exibição é traduzida aqui. Valores
/// desconhecidos (digitados pelo usuário) aparecem como estão.
String valueLabel(String value) => switch (value) {
  'Gasolina' => tr.fuelGasoline,
  'Etanol' => tr.fuelEthanol,
  'Diesel' => tr.fuelDiesel,
  'GNV' => tr.fuelNaturalGas,
  'Elétrico' => tr.fuelElectric,
  'Flex' => tr.fuelFlex,
  'Híbrido' => tr.fuelHybrid,
  'Outro' => tr.other,
  'Manual' => tr.transmissionManual,
  'Automático' => tr.transmissionAutomatic,
  'Convencional' => tr.transmissionManual,
  'Óleo e filtros' => tr.maintOilFilters,
  'Motor' => tr.maintEngine,
  'Freios' => tr.maintBrakes,
  'Suspensão' => tr.maintSuspension,
  'Pneus' => tr.maintTires,
  'Câmbio' => tr.maintTransmission,
  'Ar-condicionado' => tr.maintAirConditioning,
  'Elétrica' => tr.maintElectrical,
  'Direção' => tr.maintSteering,
  'Correias' => tr.maintBelts,
  'Revisão' => tr.maintService,
  'Outros' => tr.maintOthers,
  'Frente do veículo' => tr.photoCarFront,
  'Traseira do veículo' => tr.photoCarRear,
  'Lateral esquerda' => tr.photoLeftSide,
  'Lateral direita' => tr.photoRightSide,
  'Painel' => tr.photoDashboard,
  'Volante' => tr.photoSteeringWheel,
  'Pneu dianteiro esquerdo' => tr.photoFrontLeftTire,
  'Pneu dianteiro direito' => tr.photoFrontRightTire,
  'Pneu traseiro esquerdo' => tr.photoRearLeftTire,
  'Pneu traseiro direito' => tr.photoRearRightTire,
  'Frente da moto' => tr.photoMotoFront,
  'Traseira da moto' => tr.photoMotoRear,
  'Guidão' => tr.photoHandlebar,
  'Pneu dianteiro' => tr.photoFrontTire,
  'Pneu traseiro' => tr.photoRearTire,
  'Escapamento' => tr.photoExhaust,
  'Outra marca' => tr.otherBrand,
  'Outro modelo' => tr.otherModel,
  _ => value,
};

String? fuelLabel(String? value) => value == null ? null : valueLabel(value);

String maintenanceCategoryLabel(String value) => valueLabel(value);
