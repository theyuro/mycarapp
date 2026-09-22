import 'package:flutter/material.dart';

import '../models/support_ticket.dart';
import '../services/account_cloud_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

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
      message('Não foi possível carregar os chamados.');
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
      title: Text(isAdmin ? 'Central de chamados · Admin' : 'Ajuda e feedback'),
    ),
    floatingActionButton: cloud.currentUser == null
        ? null
        : FloatingActionButton.extended(
            onPressed: openNewTicket,
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('NOVO CHAMADO'),
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
                    children: const [
                      SizedBox(height: 160),
                      Icon(
                        Icons.forum_outlined,
                        size: 68,
                        color: AppColors.blue,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Nenhum chamado aberto ainda.',
                        textAlign: TextAlign.center,
                      ),
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
      ).showSnackBar(SnackBar(content: Text('Chamado #$number enviado.')));
      Navigator.pop(context, true);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar o chamado.')),
      );
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
          const Text(
            'Novo chamado',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'feedback',
                icon: Icon(Icons.lightbulb_outline),
                label: Text('Feedback'),
              ),
              ButtonSegment(
                value: 'bug',
                icon: Icon(Icons.bug_report_outlined),
                label: Text('Bug'),
              ),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: subject,
            decoration: const InputDecoration(labelText: 'Assunto'),
            validator: (value) =>
                (value?.trim().length ?? 0) < 3 ? 'Informe o assunto' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: description,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Conte o que aconteceu',
              hintText: 'Se for um bug, descreva os passos até o problema.',
            ),
            validator: (value) => (value?.trim().length ?? 0) < 10
                ? 'Descreva com mais detalhes'
                : null,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: sending ? null : send,
            icon: const Icon(Icons.send_outlined),
            label: Text(sending ? 'ENVIANDO...' : 'ENVIAR CHAMADO'),
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
          const Text(
            'Resposta do suporte',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(widget.ticket.adminResponse!),
        ],
        if (widget.isAdmin) ...[
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Aberto')),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('Em andamento'),
              ),
              DropdownMenuItem(value: 'resolved', child: Text('Resolvido')),
            ],
            onChanged: (value) => setState(() => status = value!),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: response,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Resposta ao usuário'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'SALVANDO...' : 'SALVAR RESPOSTA'),
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
          const Text(
            'Entre na sua conta para enviar e acompanhar chamados.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onTap,
            child: const Text('ENTRAR COM GOOGLE'),
          ),
        ],
      ),
    ),
  );
}

String _status(String value) => switch (value) {
  'in_progress' => 'Em andamento',
  'resolved' => 'Resolvido',
  _ => 'Aberto',
};
