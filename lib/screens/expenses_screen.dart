import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vehicle.dart';
import '../models/vehicle_expense.dart';
import '../services/ads_service.dart';
import '../services/expense_storage_service.dart';
import '../services/premium_upsell_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/free_user_banner_ad.dart';
import '../widgets/native_list_ad.dart';
import '../widgets/premium_upsell_banner.dart';
import '../l10n/l10n.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, this.initialCategory});

  final VehicleExpenseCategory? initialCategory;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final storage = ExpenseStorageService();
  final vehicleStorage = VehicleStorageService();
  Vehicle? vehicle;
  List<VehicleExpense> expenses = const [];
  bool loading = true;
  bool openedInitialForm = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final active = await vehicleStorage.loadActiveVehicle();
      final all = await storage.loadExpenses();
      if (!mounted) return;
      setState(() {
        vehicle = active;
        expenses =
            active == null
                  ? const []
                  : all.where((item) => item.vehicleId == active.id).toList()
              ..sort((a, b) => a.firstDueDate.compareTo(b.firstDueDate));
        loading = false;
      });
      if (!openedInitialForm &&
          active != null &&
          widget.initialCategory != null) {
        openedInitialForm = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => openForm(category: widget.initialCategory),
        );
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openForm({
    VehicleExpense? expense,
    VehicleExpenseCategory? category,
  }) async {
    final active = vehicle;
    if (active == null) {
      message(tr.expenseNeedVehicle);
      return;
    }
    final saved = await showModalBottomSheet<VehicleExpense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExpenseFormSheet(
        vehicle: active,
        expense: expense,
        initialCategory: category,
      ),
    );
    if (saved == null) return;
    await storage.saveExpense(saved);
    await load();
    if (mounted) message(tr.expenseSaved);
    if (expense == null) AdsService.instance.registerMainActivity();
  }

  Future<void> delete(VehicleExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.expenseDeleteTitle),
        content: Text(tr.expenseDeleteText(expense.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(tr.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await storage.deleteExpense(expense.id);
    await load();
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final month = DateTime(DateTime.now().year, DateTime.now().month);
    final current = expenses.where((item) => item.occursIn(month)).toList();
    final total = current.fold<double>(0, (sum, item) => sum + item.amount);
    final next = current.isEmpty
        ? null
        : current.reduce(
            (a, b) => a.firstDueDate.day <= b.firstDueDate.day ? a : b,
          );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(tr.expensesTitle),
      ),
      // Anúncio no rodapé; o FAB flutua acima dele, com folga.
      bottomNavigationBar: const SafeArea(
        top: false,
        child: FreeUserBannerAd(placement: BannerPlacement.expenses),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vehicle == null ? null : openForm,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
        icon: const Icon(Icons.add),
        label: Text(tr.expenseAdd),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : vehicle == null
          ? _EmptyExpenseMessage(
              icon: Icons.garage_outlined,
              text: tr.expenseNeedVehicleFirst,
            )
          : expenses.isEmpty
          ? _EmptyExpenseMessage(
              icon: Icons.account_balance_wallet_outlined,
              text: tr.expensesEmpty,
              onAdd: openForm,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ExpenseSummary(
                        label: tr.expensesMonthlyRecurring,
                        value: _money(total),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExpenseSummary(
                        label: tr.expensesNextDue,
                        value: next == null
                            ? '--'
                            : tr.expensesDueDay(next.firstDueDate.day),
                      ),
                    ),
                  ],
                ),
                const PremiumUpsellBanner(
                  placement: UpsellPlacement.expenses,
                  margin: EdgeInsets.only(top: 12),
                ),
                const SizedBox(height: 18),
                Text(
                  vehicle!.nickname,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // Despesas com anúncios nativos intercalados.
                ...withNativeAds(expenses).map(
                  (entry) => switch (entry) {
                    NativeListAdSlot(:final slot) => NativeListAd(
                      key: ValueKey('native-expenses-$slot'),
                      margin: const EdgeInsets.all(4),
                      borderRadius: 12,
                    ),
                    NativeListItem(item: final expense) => _ExpenseTile(
                      expense: expense,
                      month: month,
                      onEdit: () => openForm(expense: expense),
                      onDelete: () => delete(expense),
                    ),
                  },
                ),
              ],
            ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  const _ExpenseFormSheet({
    required this.vehicle,
    this.expense,
    this.initialCategory,
  });

  final Vehicle vehicle;
  final VehicleExpense? expense;
  final VehicleExpenseCategory? initialCategory;

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController amount;
  late final TextEditingController installments;
  late final TextEditingController notes;
  late VehicleExpenseCategory category;
  late ExpenseFrequency frequency;
  late DateTime firstDueDate;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    category =
        expense?.category ??
        widget.initialCategory ??
        VehicleExpenseCategory.insurance;
    frequency = expense?.frequency ?? ExpenseFrequency.monthly;
    firstDueDate = expense?.firstDueDate ?? DateTime.now();
    title = TextEditingController(text: expense?.title ?? category.label);
    amount = TextEditingController(
      text: expense == null ? '' : _plainNumber(expense.amount),
    );
    installments = TextEditingController(
      text: expense?.totalInstallments?.toString() ?? '',
    );
    notes = TextEditingController(text: expense?.notes ?? '');
  }

  Future<void> selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: firstDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => firstDueDate = selected);
  }

  void save() {
    if (!formKey.currentState!.validate()) return;
    final parsed = double.parse(amount.text.replaceAll(',', '.'));
    final total = installments.text.trim().isEmpty
        ? null
        : int.parse(installments.text);
    Navigator.pop(
      context,
      VehicleExpense(
        id:
            widget.expense?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        vehicleId: widget.vehicle.id,
        title: title.text.trim(),
        category: category,
        amount: parsed,
        firstDueDate: firstDueDate,
        frequency: frequency,
        totalInstallments: frequency == ExpenseFrequency.monthly ? total : null,
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    installments.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 18,
      right: 18,
      top: 10,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DCE3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.expense == null ? tr.expenseNew : tr.expenseEdit,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          Text(
            widget.vehicle.nickname,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<VehicleExpenseCategory>(
            initialValue: category,
            decoration: InputDecoration(labelText: tr.category),
            items: VehicleExpenseCategory.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                final oldDefault = title.text == category.label;
                category = value;
                if (oldDefault) title.text = value.label;
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: title,
            decoration: InputDecoration(labelText: tr.description),
            validator: (value) => value == null || value.trim().isEmpty
                ? tr.descriptionRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: InputDecoration(
              labelText: tr.amount,
              prefixText: '$currencySymbol ',
            ),
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').replaceAll(',', '.'),
              );
              return parsed == null || parsed <= 0 ? tr.invalidValue : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseFrequency>(
            initialValue: frequency,
            decoration: InputDecoration(labelText: tr.frequency),
            items: ExpenseFrequency.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => frequency = value!),
          ),
          if (frequency == ExpenseFrequency.monthly) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: installments,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: tr.expenseInstallments,
                helperText: tr.expenseInstallmentsHint,
              ),
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: tr.expenseFirstDue,
                suffixIcon: const Icon(Icons.calendar_month_outlined),
              ),
              child: Text(_date(firstDueDate)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notes,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: tr.notes),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_outlined),
              label: Text(tr.expenseSave),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExpenseSummary extends StatelessWidget {
  const _ExpenseSummary({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE1E7EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.month,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleExpense expense;
  final DateTime month;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final installment = expense.installmentIn(month);
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.blue.withValues(alpha: .09),
          foregroundColor: AppColors.blue,
          child: Icon(_categoryIcon(expense.category)),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            expense.category.label,
            expense.frequency.label,
            if (installment != null && expense.totalInstallments != null)
              tr.installmentOf(installment, expense.totalInstallments!),
          ].join(' • '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr.edit)),
            PopupMenuItem(value: 'delete', child: Text(tr.delete)),
          ],
          icon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _money(expense.amount),
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const Icon(Icons.more_vert, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExpenseMessage extends StatelessWidget {
  const _EmptyExpenseMessage({
    required this.icon,
    required this.text,
    this.onAdd,
  });
  final IconData icon;
  final String text;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: AppColors.blue),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          if (onAdd != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(tr.expenseAdd),
            ),
          ],
        ],
      ),
    ),
  );
}

IconData _categoryIcon(VehicleExpenseCategory category) => switch (category) {
  VehicleExpenseCategory.insurance ||
  VehicleExpenseCategory.cooperative => Icons.shield_outlined,
  VehicleExpenseCategory.financing ||
  VehicleExpenseCategory.consortium => Icons.account_balance_outlined,
  VehicleExpenseCategory.other => Icons.receipt_long_outlined,
};

String _date(DateTime value) => formatDate(value);
String _money(double value) => formatMoney(value);
String _plainNumber(double value) => formatInput(value);
