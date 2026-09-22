import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/vehicle.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  static const otherBrand = 'Outra marca';
  static const otherModel = 'Outro modelo';
  static const carModels = <String, List<String>>{
    'Audi': ['A3', 'A4', 'A5', 'Q3', 'Q5', 'Q7'],
    'BMW': ['Série 1', 'Série 3', 'Série 5', 'X1', 'X3', 'X5'],
    'BYD': [
      'Dolphin',
      'Dolphin Mini',
      'King',
      'Seal',
      'Song Plus',
      'Yuan Plus',
    ],
    'Caoa Chery': ['Arrizo 5', 'Arrizo 6', 'Tiggo 5X', 'Tiggo 7', 'Tiggo 8'],
    'Chevrolet': [
      'Agile',
      'Astra',
      'Blazer',
      'Celta',
      'Classic',
      'Cobalt',
      'Corsa',
      'Cruze',
      'Equinox',
      'Meriva',
      'Montana',
      'Onix',
      'Prisma',
      'S10',
      'Spin',
      'Tracker',
      'Trailblazer',
      'Vectra',
      'Zafira',
    ],
    'Citroën': [
      'Aircross',
      'Basalt',
      'C3',
      'C4 Cactus',
      'C4 Lounge',
      'C5 Aircross',
    ],
    'Fiat': [
      '147',
      'Argo',
      'Bravo',
      'Cronos',
      'Doblo',
      'Ducato',
      'Fastback',
      'Fiorino',
      'Freemont',
      'Grand Siena',
      'Idea',
      'Linea',
      'Marea',
      'Mobi',
      'Palio',
      'Pulse',
      'Punto',
      'Siena',
      'Stilo',
      'Strada',
      'Tempra',
      'Toro',
      'Uno',
      'Weekend',
    ],
    'Ford': [
      'Belina',
      'Bronco Sport',
      'Corcel',
      'Courier',
      'EcoSport',
      'Edge',
      'Escort',
      'F-1000',
      'Fiesta',
      'Focus',
      'Fusion',
      'Ka',
      'Maverick',
      'Mustang',
      'Ranger',
      'Territory',
      'Verona',
    ],
    'GWM': ['Haval H6', 'Ora 03', 'Tank 300'],
    'Honda': ['Accord', 'City', 'Civic', 'CR-V', 'Fit', 'HR-V', 'WR-V', 'ZR-V'],
    'Hyundai': [
      'Azera',
      'Creta',
      'Elantra',
      'HB20',
      'HB20S',
      'i30',
      'Santa Fe',
      'Tucson',
      'ix35',
    ],
    'Jeep': [
      'Cherokee',
      'Commander',
      'Compass',
      'Grand Cherokee',
      'Renegade',
      'Wrangler',
    ],
    'Kia': [
      'Bongo',
      'Carnival',
      'Cerato',
      'Picanto',
      'Sorento',
      'Soul',
      'Sportage',
    ],
    'Mercedes-Benz': ['Classe A', 'Classe C', 'Classe E', 'GLA', 'GLC', 'GLE'],
    'Mitsubishi': [
      'ASX',
      'Eclipse Cross',
      'L200',
      'Lancer',
      'Outlander',
      'Pajero',
    ],
    'Nissan': [
      'Frontier',
      'Kicks',
      'Livina',
      'March',
      'Sentra',
      'Tiida',
      'Versa',
      'X-Trail',
    ],
    'Peugeot': [
      '2008',
      '206',
      '207',
      '208',
      '3008',
      '307',
      '308',
      '408',
      'Partner',
    ],
    'Ram': ['1500', '2500', '3500', 'Rampage'],
    'Renault': [
      'Captur',
      'Clio',
      'Duster',
      'Fluence',
      'Kangoo',
      'Kardian',
      'Kwid',
      'Logan',
      'Master',
      'Megane',
      'Oroch',
      'Sandero',
      'Scenic',
      'Symbol',
    ],
    'Subaru': ['Forester', 'Impreza', 'Legacy', 'Outback', 'XV'],
    'Suzuki': ['Grand Vitara', 'Jimny', 'S-Cross', 'Swift', 'Vitara'],
    'Toyota': [
      'Bandeirante',
      'Camry',
      'Corolla',
      'Corolla Cross',
      'Etios',
      'Hilux',
      'Prius',
      'RAV4',
      'SW4',
      'Yaris',
    ],
    'Volkswagen': [
      'Amarok',
      'Bora',
      'Brasília',
      'CrossFox',
      'Fox',
      'Fusca',
      'Gol',
      'Golf',
      'Jetta',
      'Kombi',
      'Nivus',
      'Parati',
      'Passat',
      'Polo',
      'Saveiro',
      'Santana',
      'SpaceFox',
      'T-Cross',
      'Taos',
      'Tiguan',
      'Up!',
      'Virtus',
      'Voyage',
    ],
    'Volvo': ['C40', 'EX30', 'S60', 'XC40', 'XC60', 'XC90'],
  };
  static const motorcycleModels = <String, List<String>>{
    'Avelloz': ['AZ1', 'AZ125', 'AZ160'],
    'Bajaj': [
      'Dominar 160',
      'Dominar 200',
      'Dominar 250',
      'Dominar 400',
      'Pulsar N150',
    ],
    'BMW': [
      'G 310 GS',
      'G 310 R',
      'F 750 GS',
      'F 800 GS',
      'F 850 GS',
      'F 900 R',
      'R 1200 GS',
      'R 1250 GS',
      'R 1300 GS',
      'S 1000 RR',
    ],
    'Dafra': [
      'Apache RTR 200',
      'Citycom 300',
      'Cruisym 150',
      'Cruisym 300',
      'Horizon 150',
      'NH 190',
      'Next 250',
    ],
    'Haojue': [
      'Chopper Road 150',
      'DK 150',
      'DR 160',
      'Lindy 125',
      'Master Ride 150',
      'NK 150',
    ],
    'Harley-Davidson': [
      'Fat Bob',
      'Fat Boy',
      'Iron 883',
      'Nightster',
      'Pan America',
      'Road Glide',
      'Sportster S',
      'Street Bob',
    ],
    'Honda': [
      'ADV 150',
      'Biz 110i',
      'Biz 125',
      'Bros 150',
      'Bros 160',
      'CB 250F Twister',
      'CB 300F',
      'CB 500F',
      'CB 500X',
      'CB 600F Hornet',
      'CB 650R',
      'CB 1000R',
      'CG 125',
      'CG 150',
      'CG 160',
      'Elite 125',
      'Lead 110',
      'NC 750X',
      'PCX 150',
      'PCX 160',
      'Pop 100',
      'Pop 110i',
      'Sahara 300',
      'Titan 150',
      'XRE 190',
      'XRE 300',
      'XRE 300 Sahara',
    ],
    'Kawasaki': [
      'Ninja 300',
      'Ninja 400',
      'Ninja 500',
      'Ninja 650',
      'Versys 300',
      'Versys 650',
      'Vulcan S',
      'Z300',
      'Z400',
      'Z500',
      'Z650',
      'Z900',
    ],
    'KTM': ['Duke 200', 'Duke 390', 'RC 390', 'Adventure 390'],
    'Royal Enfield': [
      'Classic 350',
      'Continental GT 650',
      'Himalayan',
      'Hunter 350',
      'Interceptor 650',
      'Meteor 350',
      'Super Meteor 650',
    ],
    'Shineray': [
      'Free 150',
      'Jet 125',
      'Jet 50',
      'Phoenix 50',
      'SHI 175',
      'Worker 125',
    ],
    'Suzuki': [
      'Bandit 650',
      'Boulevard M800',
      'Burgman 125',
      'Burgman 400',
      'GSX-R1000',
      'GSX-S750',
      'Hayabusa',
      'Intruder 125',
      'V-Strom 650',
      'V-Strom 800',
    ],
    'Triumph': [
      'Bonneville T100',
      'Scrambler 400 X',
      'Tiger 900',
      'Trident 660',
    ],
    'Yamaha': [
      'Crosser 150',
      'Crypton 115',
      'Factor 125',
      'Factor 150',
      'Fazer 150',
      'Fazer 250',
      'Fazer FZ15',
      'Fazer FZ25',
      'Fluo 125',
      'Lander 250',
      'MT-03',
      'MT-07',
      'MT-09',
      'NMax 160',
      'Neo 125',
      'R3',
      'Ténéré 250',
      'Ténéré 700',
      'Tracer 900',
      'XJ6',
      'XT 660R',
      'YBR 125',
      'YS 250 Fazer',
    ],
  };
  static const carPhotoTypes = [
    'Frente do veículo',
    'Traseira do veículo',
    'Lateral esquerda',
    'Lateral direita',
    'Painel',
    'Volante',
    'Pneu dianteiro esquerdo',
    'Pneu dianteiro direito',
    'Pneu traseiro esquerdo',
    'Pneu traseiro direito',
    'Motor',
    'Outro',
  ];
  static const motorcyclePhotoTypes = [
    'Frente da moto',
    'Traseira da moto',
    'Lateral esquerda',
    'Lateral direita',
    'Painel',
    'Guidão',
    'Pneu dianteiro',
    'Pneu traseiro',
    'Motor',
    'Escapamento',
    'Outro',
  ];

  final formKey = GlobalKey<FormState>();
  final nickname = TextEditingController();
  final mileage = TextEditingController();
  final customBrand = TextEditingController();
  final customModel = TextEditingController();
  final documents = <DocumentYear>[];
  final photos = <VehiclePhoto>[];
  final storage = VehicleStorageService();
  String? brand, model, fuel;
  int? year;
  String vehicleType = 'car';
  String transmission = 'Automático';
  String photoType = carPhotoTypes.first;
  bool isSaving = false;

  List<int> get years => List.generate(
    DateTime.now().year - 1978,
    (i) => DateTime.now().year + 1 - i,
  );
  Map<String, List<String>> get models =>
      vehicleType == 'motorcycle' ? motorcycleModels : carModels;
  List<String> get photoTypes =>
      vehicleType == 'motorcycle' ? motorcyclePhotoTypes : carPhotoTypes;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle == null) {
      documents.add(DocumentYear(DateTime.now().year));
      return;
    }
    nickname.text = vehicle.nickname;
    vehicleType = vehicle.vehicleType;
    mileage.text = vehicle.mileage.toString();
    if (models.containsKey(vehicle.brand)) {
      brand = vehicle.brand;
      if (models[brand]!.contains(vehicle.model)) {
        model = vehicle.model;
      } else {
        model = otherModel;
        customModel.text = vehicle.model;
      }
    } else {
      brand = otherBrand;
      model = otherModel;
      customBrand.text = vehicle.brand;
      customModel.text = vehicle.model;
    }
    year = vehicle.year;
    fuel = vehicle.fuel;
    transmission = vehicle.transmission;
    if (!photoTypes.contains(photoType)) photoType = photoTypes.first;
    documents.addAll(
      vehicle.documents.map(
        (item) => DocumentYear(
          item.year,
          ipvaPaid: item.ipvaPaid,
          licensingPaid: item.licensingPaid,
        ),
      ),
    );
    photos.addAll(vehicle.photos);
  }

  @override
  void dispose() {
    nickname.dispose();
    mileage.dispose();
    customBrand.dispose();
    customModel.dispose();
    super.dispose();
  }

  String? requiredField(Object? value) =>
      value == null || value.toString().trim().isEmpty
      ? 'Campo obrigatório'
      : null;

  void addDocument() {
    final used = documents.map((e) => e.year).toSet();
    final available = years.where((e) => !used.contains(e));
    if (available.isNotEmpty)
      setState(() => documents.add(DocumentYear(available.first)));
  }

  Future<void> addPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file != null && mounted) {
      setState(
        () => photos.add(VehiclePhoto(file.path, photoType, DateTime.now())),
      );
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    final now = DateTime.now();
    final existing = widget.vehicle;
    final vehicle = Vehicle(
      id: existing?.id ?? '${now.microsecondsSinceEpoch}',
      nickname: nickname.text.trim(),
      brand: brand == otherBrand ? customBrand.text.trim() : brand!,
      model: model == otherModel ? customModel.text.trim() : model!,
      year: year!,
      fuel: fuel!,
      transmission: transmission,
      mileage: int.parse(mileage.text),
      createdAt: existing?.createdAt ?? now,
      documents: documents,
      photos: photos,
      vehicleType: vehicleType,
    );

    try {
      await storage.saveVehicle(vehicle);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FileSystemException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar: ${error.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o veículo. Tente novamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(
        widget.vehicle == null ? 'Cadastrar veículo' : 'Editar veículo',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            icon: Icons.badge_outlined,
            title: 'Identificação',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'car',
                        icon: Icon(Icons.directions_car_rounded),
                        label: Text('Carro'),
                      ),
                      ButtonSegment(
                        value: 'motorcycle',
                        icon: Icon(Icons.two_wheeler_rounded),
                        label: Text('Moto'),
                      ),
                    ],
                    selected: {vehicleType},
                    onSelectionChanged: (selection) => setState(() {
                      vehicleType = selection.first;
                      brand = null;
                      model = null;
                      customBrand.clear();
                      customModel.clear();
                      transmission = vehicleType == 'motorcycle'
                          ? 'Manual'
                          : 'Automático';
                      photoType = photoTypes.first;
                    }),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nickname,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Apelido do veículo',
                    hintText: vehicleType == 'motorcycle'
                        ? 'Ex.: Minha moto'
                        : 'Ex.: Meu carro',
                  ),
                  validator: requiredField,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: brand,
                  decoration: const InputDecoration(labelText: 'Marca'),
                  items: [...models.keys, otherBrand]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    brand = value;
                    model = null;
                    customModel.clear();
                  }),
                  validator: requiredField,
                ),
                if (brand == otherBrand) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: customBrand,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome da marca',
                      hintText: 'Digite a marca do veículo',
                    ),
                    validator: requiredField,
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(brand),
                  initialValue: model,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                  items:
                      [
                            ...(models[brand] ?? const <String>[]),
                            if (brand != null) otherModel,
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: brand == null
                      ? null
                      : (value) => setState(() => model = value),
                  validator: requiredField,
                ),
                if (model == otherModel) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: customModel,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome do modelo',
                      hintText: 'Digite o modelo do veículo',
                    ),
                    validator: requiredField,
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: year,
                  decoration: const InputDecoration(
                    labelText: 'Ano do veículo',
                  ),
                  items: years
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (value) => setState(() => year = value),
                  validator: (value) =>
                      value == null ? 'Selecione o ano' : null,
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.tune_rounded,
            title: 'Características',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: fuel,
                  decoration: const InputDecoration(labelText: 'Combustível'),
                  items: ['Gasolina', 'Flex', 'Híbrido', 'Elétrico']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => fuel = value),
                  validator: requiredField,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Câmbio',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: vehicleType == 'motorcycle'
                        ? const [
                            ButtonSegment(
                              value: 'Manual',
                              label: Text('Manual'),
                            ),
                            ButtonSegment(
                              value: 'Automático',
                              label: Text('Automático'),
                            ),
                          ]
                        : const [
                            ButtonSegment(
                              value: 'Automático',
                              label: Text('Automático'),
                            ),
                            ButtonSegment(
                              value: 'Convencional',
                              label: Text('Convencional'),
                            ),
                          ],
                    selected: {transmission},
                    onSelectionChanged: (value) =>
                        setState(() => transmission = value.first),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: mileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem atual',
                    suffixText: 'km',
                  ),
                  validator: requiredField,
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.description_outlined,
            title: 'Documentação por ano',
            trailing: IconButton(
              onPressed: addDocument,
              icon: const Icon(Icons.add_circle_outline, color: AppColors.blue),
            ),
            child: Column(
              children: List.generate(documents.length, documentRow),
            ),
          ),
          SectionCard(
            icon: Icons.photo_camera_outlined,
            title: 'Fotos do veículo',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: photoType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'O que aparece na foto?',
                  ),
                  items: photoTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => photoType = value!),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: addPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('SELECIONAR FOTO'),
                  ),
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...photoHistory(),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: isSaving ? null : save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isSaving ? 'SALVANDO...' : 'SALVAR VEÍCULO',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );

  Widget documentRow(int index) {
    final item = documents[index];
    final used = documents.map((e) => e.year).toSet();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 115,
                child: DropdownButtonFormField<int>(
                  initialValue: item.year,
                  decoration: const InputDecoration(labelText: 'Ano'),
                  items: years
                      .where((e) => e == item.year || !used.contains(e))
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (value) => setState(() => item.year = value!),
                ),
              ),
              const Spacer(),
              if (documents.length > 1)
                IconButton(
                  onPressed: () => setState(() => documents.removeAt(index)),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('IPVA pago'),
            value: item.ipvaPaid,
            activeColor: AppColors.blue,
            onChanged: (value) => setState(() => item.ipvaPaid = value!),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Licenciamento pago'),
            value: item.licensingPaid,
            activeColor: AppColors.blue,
            onChanged: (value) => setState(() => item.licensingPaid = value!),
          ),
        ],
      ),
    );
  }

  Widget photoRow(int index) {
    final item = photos[index];
    final decodedSize = (58 * MediaQuery.devicePixelRatioOf(context)).ceil();
    final date =
        '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => showPhoto(item),
              child: Image.file(
                File(item.path),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                cacheWidth: decodedSize,
                cacheHeight: decodedSize,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 58,
                  height: 58,
                  child: ColoredBox(
                    color: AppColors.background,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  date,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => photos.removeAt(index)),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  List<Widget> photoHistory() {
    final indexed = photos.indexed.toList()
      ..sort((a, b) => b.$2.date.compareTo(a.$2.date));
    final groups = <String, List<(int, VehiclePhoto)>>{};
    for (final entry in indexed) {
      final key = '${entry.$2.date.year}-${entry.$2.date.month}';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    return [
      for (final group in groups.values) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 9),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 17,
                color: AppColors.blue,
              ),
              const SizedBox(width: 7),
              Text(
                _photoMonth(group.first.$2.date),
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${group.length} ${group.length == 1 ? 'foto' : 'fotos'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        ...group.map((entry) => photoRow(entry.$1)),
      ],
    ];
  }

  Future<void> showPhoto(VehiclePhoto photo) => showDialog<void>(
    context: context,
    builder: (context) {
      final screen = MediaQuery.sizeOf(context);
      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      final decodedWidth = (screen.width * pixelRatio * 2).ceil().clamp(
        1,
        2048,
      );

      return Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: Text(photo.type),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .62,
              child: InteractiveViewer(
                child: Image.file(
                  File(photo.path),
                  fit: BoxFit.contain,
                  cacheWidth: decodedWidth,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Icon(Icons.broken_image_outlined, size: 64),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _photoMonth(DateTime date) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[date.month - 1]} de ${date.year}';
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE5EAF0)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}
