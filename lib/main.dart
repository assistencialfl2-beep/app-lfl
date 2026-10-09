import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const LFLApp());
}

class LFLApp extends StatelessWidget {
  const LFLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LFL Informática',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _servicoController = TextEditingController();
  final List<Map<String, String>> _ordens = [];

  void _adicionarOrdem() {
    if (_clienteController.text.isNotEmpty && _servicoController.text.isNotEmpty) {
      setState(() {
        _ordens.add({
          'cliente': _clienteController.text,
          'servico': _servicoController.text,
        });
        _clienteController.clear();
        _servicoController.clear();
      });
    }
  }

  Future<void> _abrirWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LFL Informática'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'WhatsApp',
            onPressed: _abrirWhatsApp,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(
                labelText: 'Nome do Cliente',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _servicoController,
              decoration: const InputDecoration(
                labelText: 'Descrição do Serviço',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _adicionarOrdem,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Ordem de Serviço'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: _ordens.isEmpty
                  ? const Center(child: Text('Nenhuma ordem cadastrada'))
                  : ListView.builder(
                      itemCount: _ordens.length,
                      itemBuilder: (context, index) {
                        final item = _ordens[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.build),
                            title: Text(item['cliente'] ?? ''),
                            subtitle: Text(item['servico'] ?? ''),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
