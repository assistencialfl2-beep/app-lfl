import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrdemServicoApp());
}

class OrdemServicoApp extends StatelessWidget {
  const OrdemServicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LFL - INFORMÁTICA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: const TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  Database? _db;

  String tipoSelecionado = 'Ordem de Serviço';
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  Map<String, double> opcoesServicos = {
    "Formatação": 100.00,
    "Backup de Dados": 80.00,
    "Limpeza Preventiva": 90.00,
    "Troca de Peça": 50.00,
    "Instalação de Programas": 60.00,
  };
  List<String> servicosSelecionados = [];

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _iniciarBanco();
  }

  Future<void> _iniciarBanco() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = p.join(dir.path, 'ordens_lfl.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ordens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT,
            tipo TEXT,
            servicos TEXT,
            data TEXT,
            valor TEXT,
            telefone TEXT
          )
        ''');
      },
    );
  }

  void _abrirJanelaServicos() {
    final TextEditingController novoServicoController = TextEditingController();
    final TextEditingController novoPrecoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Marque os Serviços e Valores'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView(
                        children: opcoesServicos.entries.map((entry) {
                          final isSelected = servicosSelecionados.contains(entry.key);
                          final precoFormatado = entry.value.toStringAsFixed(2).replaceAll('.', ',');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[300],
                                foregroundColor: isSelected ? Colors.white : Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  if (isSelected) {
                                    servicosSelecionados.remove(entry.key);
                                  } else {
                                    servicosSelecionados.add(entry.key);
                                  }
                                });
                              },
                              child: Text(
                                '${entry.key} - R\$ $precoFormatado',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: novoServicoController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Nome do serviço...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: novoPrecoController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Valor',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onPressed: () {
                            final nome = novoServicoController.text.trim();
                            final valorTexto = novoPrecoController.text.trim().replaceAll(',', '.');
                            final preco = double.tryParse(valorTexto) ?? 0.0;
                            if (nome.isNotEmpty && !opcoesServicos.containsKey(nome)) {
                              setModalState(() {
                                opcoesServicos[nome] = preco;
                                servicosSelecionados.add(nome);
                                novoServicoController.clear();
                                novoPrecoController.clear();
                              });
                            }
                          },
                          child: const Text('+', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CB01C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      double total = 0.0;
                      for (var s in servicosSelecionados) {
                        total += (opcoesServicos[s] ?? 0.0);
                      }
                      setState(() {
                        if (servicosSelecionados.isNotEmpty) {
                          _valorController.text = 'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';
                        } else {
                          _valorController.text = '';
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Confirmar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _gerarOrdem() async {
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();
    final data = _dataController.text.trim();
    final valor = _valorController.text.trim();
    final servicosTexto = servicosSelecionados.isNotEmpty
        ? servicosSelecionados.join(', ')
        : 'Não especificado';

    if (_db != null) {
      await _db!.insert('ordens', {
        'nome': nome,
        'tipo': tipoSelecionado,
        'servicos': servicosTexto,
        'data': data,
        'valor': valor,
        'telefone': telefone,
      });
    }

    String numeroLimpo = telefone.replaceAll(RegExp(r'\D'), '');
    if (numeroLimpo.isNotEmpty && numeroLimpo.length <= 11) {
      numeroLimpo = '55$numeroLimpo';
    }

    final mensagem = 'Olá, *$nome*!\n\nAqui estão os detalhes:\n📌 *Tipo:* $tipoSelecionado\n🛠️ *Serviço(s):* $servicosTexto\n📅 *Data:* $data\n💰 *Valor:* $valor\n\nA LFL - Informática agradece!';
    final textoCodificado = Uri.encodeComponent(mensagem);

    if (numeroLimpo.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/$numeroLimpo?text=$textoCodificado');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _abrirJanelaBusca() {
    final TextEditingController buscaController = TextEditingController();
    List<Map<String, dynamic>> resultados = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void buscar() async {
              if (_db == null) return;
              final termo = buscaController.text.trim();
              List<Map<String, dynamic>> dados;
              if (termo.isNotEmpty) {
                dados = await _db!.rawQuery(
                  'SELECT tipo, nome, data, valor, servicos FROM ordens WHERE nome LIKE ? ORDER BY id DESC',
                  ['%$termo%'],
                );
              } else {
                dados = await _db!.rawQuery(
                  'SELECT tipo, nome, data, valor, servicos FROM ordens ORDER BY id DESC LIMIT 15',
                );
              }
              setModalState(() {
                resultados = dados;
              });
            }

            return AlertDialog(
              title: const Text('Histórico de Clientes'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: buscaController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Pesquisar por nome...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                          ),
                          onPressed: buscar,
                          child: const Text('Procurar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: resultados.isEmpty
                          ? const Center(child: Text('Nenhum registo encontrado.'))
                          : ListView.builder(
                              itemCount: resultados.length,
                              itemBuilder: (context, index) {
                                final r = resultados[index];
                                return Card(
                                  color: const Color(0xFF333333),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      'Cliente: ${r['nome']}\n${r['tipo']} | Data: ${r['data']}\nValor: ${r['valor']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'LFL - INFORMÁTICA (v0.3.0)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tipoSelecionado,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    items: const [
                      DropdownMenuItem(
                        value: 'Ordem de Serviço',
                        child: Text('Ordem de Serviço'),
                      ),
                      DropdownMenuItem(
                        value: 'Orçamento',
                        child: Text('Orçamento'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          tipoSelecionado = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Nome do Cliente',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E5E5),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _abrirJanelaServicos,
                child: Text(
                  servicosSelecionados.isNotEmpty
                      ? '${servicosSelecionados.length} serviço(s) selecionado(s)'
                      : 'Selecionar Serviços',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dataController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valorController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Valor Total (R\$)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Telefone (com DDD, sem +)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _gerarOrdem,
                child: const Text(
                  'Gerar Ordem e Enviar WhatsApp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB0B0B0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _abrirJanelaBusca,
                child: const Text(
                  'Buscar Ordem/Orçamento',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'Desenvolvido por Lysandro Luiz',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
