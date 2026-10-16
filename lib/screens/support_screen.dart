import 'package:flutter/material.dart';

import '../models/support_ticket.dart';
import '../services/account_cloud_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import '../l10n/l10n.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final cloud = AccountCloudService();
  List<SupportTicket> tickets = const [];
  bool isAdmin = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (cloud.currentUser == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final result = await cloud.listSupportTickets();
      if (!mounted) return;
      setState(() {
        tickets = result.tickets;
        isAdmin = result.isAdmin;
        loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      message(tr.supportLoadError);
      debugPrint('Erro ao carregar chamados: $error');
    }
  }

  Future<void> openNewTicket() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _NewTicketSheet(),
    );
    if (created == true) await load();
  }

  Future<void> openTicket(SupportTicket ticket) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _TicketDetailScreen(ticket: ticket, isAdmin: isAdmin),
      ),
    );
    if (changed == true) await load();
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(isAdmin ? tr.supportAdminTitle : tr.supportScreenTitle),
    ),
    floatingActionButton: cloud.currentUser == null
        ? null
        : FloatingActionButton.extended(
            onPressed: openNewTicket,
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
            icon: const Icon(Icons.add_comment_outlined),
            label: Text(tr.supportNew),
          ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : cloud.currentUser == null
        ? _SignInRequired(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
          )
        : RefreshIndicator(
            onRefresh: load,
            child: tickets.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 160),
                      const Icon(
                        Icons.forum_outlined,
                        size: 68,
                        color: AppColors.blue,
                      ),
                      const SizedBox(height: 14),
                      Text(tr.supportEmpty, textAlign: TextAlign.center),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final ticket = tickets[index];
                      return Card(
                        elevation: 0,
                        child: ListTile(
                          onTap: () => openTicket(ticket),
                          leading: Icon(
                            ticket.type == 'bug'
                                ? Icons.bug_report_outlined
                                : Icons.lightbulb_outline,
                            color: AppColors.blue,
                          ),
                          title: Text(
                            ticket.subject,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '#${ticket.ticketNumber} · ${_status(ticket.status)}${isAdmin && ticket.email != null ? '\n${ticket.email}' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      );
                    },
                  ),
          ),
  );
}

class _NewTicketSheet extends StatefulWidget {
  const _NewTicketSheet();
  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  final formKey = GlobalKey<FormState>();
  final subject = TextEditingController();
  final description = TextEditingController();
  String type = 'feedback';
  bool sending = false;

  Future<void> send() async {
    if (!formKey.currentState!.validate() || sending) return;
    setState(() => sending = true);
    try {
      final number = await AccountCloudService().createSupportTicket(
        type: type,
        subject: subject.text.trim(),
        message: description.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.supportSent(number))));
      Navigator.pop(context, true);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.supportSendError)));
      debugPrint('Erro ao enviar chamado: $error');
      setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    subject.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            tr.supportNewTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'feedback',
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(tr.supportFeedback),
              ),
              ButtonSegment(
                value: 'bug',
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(tr.supportBug),
              ),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: subject,
            decoration: InputDecoration(labelText: tr.supportSubject),
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? tr.supportSubjectRequired
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: description,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: tr.supportDetails,
              hintText: tr.supportDetailsHint,
            ),
            validator: (value) => (value?.trim().length ?? 0) < 10
                ? tr.supportDetailsRequired
                : null,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: sending ? null : send,
            icon: const Icon(Icons.send_outlined),
            label: Text(sending ? tr.backupUploadingSend : tr.supportSend),
          ),
        ],
      ),
    ),
  );
}

class _TicketDetailScreen extends StatefulWidget {
  const _TicketDetailScreen({required this.ticket, required this.isAdmin});
  final SupportTicket ticket;
  final bool isAdmin;
  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  late String status = widget.ticket.status;
  late final response = TextEditingController(
    text: widget.ticket.adminResponse ?? '',
  );
  bool saving = false;
  @override
  void dispose() {
    response.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await AccountCloudService().updateSupportTicket(
        id: widget.ticket.id,
        status: status,
        response: response.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text('#${widget.ticket.ticketNumber}'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.ticket.subject,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(widget.ticket.message, style: const TextStyle(height: 1.45)),
        if (widget.ticket.adminResponse != null && !widget.isAdmin) ...[
          const SizedBox(height: 22),
          Text(
            tr.supportReply,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(widget.ticket.adminResponse!),
        ],
        if (widget.isAdmin) ...[
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: InputDecoration(labelText: tr.status),
            items: [
              DropdownMenuItem(value: 'open', child: Text(tr.statusOpen)),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text(tr.statusInProgress),
              ),
              DropdownMenuItem(
                value: 'resolved',
                child: Text(tr.statusResolved),
              ),
            ],
            onChanged: (value) => setState(() => status = value!),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: response,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(labelText: tr.supportReplyToUser),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? tr.saving : tr.supportSaveReply),
          ),
        ],
      ],
    ),
  );
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 64,
            color: AppColors.blue,
          ),
          const SizedBox(height: 14),
          Text(tr.supportSignIn, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton(onPressed: onTap, child: Text(tr.loginWithGoogle)),
        ],
      ),
    ),
  );
}

String _status(String value) => switch (value) {
  'in_progress' => tr.statusInProgress,
  'resolved' => tr.statusResolved,
  _ => tr.statusOpen,
};
