import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'nota_servico.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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
  final TextEditingController _obsController = TextEditingController();

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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ordens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT,
            tipo TEXT,
            servicos TEXT,
            data TEXT,
            valor TEXT,
            telefone TEXT,
            status TEXT DEFAULT 'Pendente',
            obs TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE ordens ADD COLUMN status TEXT DEFAULT 'Pendente'");
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE ordens ADD COLUMN obs TEXT");
          } catch (_) {}
        }
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

  void _abrirJanelaObservacoes() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Observações do Equipamento'),
          content: TextField(
            controller: _obsController,
            maxLines: 4,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: 'Ex.: marcas na carcaça, sem carregador, ecrã com risco...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _obsController.clear();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Limpar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _gerarOrdem() async {
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();
    final data = _dataController.text.trim();
    final valor = _valorController.text.trim();
    final obs = _obsController.text.trim();
    final servicosTexto = servicosSelecionados.isNotEmpty
        ? servicosSelecionados.join(', ')
        : 'Não especificado';

    if (_db == null) {
      await _iniciarBanco();
    }

    int numeroOrdem = 5050;
    if (_db != null) {
      final idGerado = await _db!.insert('ordens', {
        'nome': nome.isEmpty ? 'Cliente sem nome' : nome,
        'tipo': tipoSelecionado,
        'servicos': servicosTexto,
        'data': data,
        'valor': valor,
        'telefone': telefone,
        'status': 'Pendente',
        'obs': obs,
      });
      numeroOrdem = 5049 + idGerado;
    }

    String numeroLimpo = telefone.replaceAll(RegExp(r'\D'), '');
    if (numeroLimpo.isNotEmpty && numeroLimpo.length <= 11) {
      numeroLimpo = '55$numeroLimpo';
    }

    String mensagem = 'Olá, *${nome.isEmpty ? "Cliente" : nome}*!\n\nAqui estão os detalhes:\n📋 *OS N°:* $numeroOrdem\n📌 *Tipo:* $tipoSelecionado\n🛠️ *Serviço(s):* $servicosTexto';

    if (obs.isNotEmpty) {
      mensagem += '\n📝 *Obs:* $obs';
    }

    mensagem += '\n📅 *Data:* $data\n💰 *Valor:* $valor\n\nA LFL - Informática agradece!';

    if (tipoSelecionado == 'Ordem de Serviço') {
      mensagem += '\n\n⭐ *Avalie o nosso atendimento:* Sua opinião é muito importante para nós!\ng.page/r/CUrzNhkZxEFAEAE/review';
    }

    final textoCodificado = Uri.encodeComponent(mensagem);

    if (numeroLimpo.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/$numeroLimpo?text=$textoCodificado');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _abrirJanelaBusca() async {
    if (_db == null) {
      await _iniciarBanco();
    }

    final TextEditingController buscaController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        List<Map<String, dynamic>> resultados = [];

        return StatefulBuilder(
          builder: (context, setModalState) {
            void buscar() async {
              if (_db == null) return;
              final termo = buscaController.text.trim();
              List<Map<String, dynamic>> dados;
              if (termo.isNotEmpty) {
                dados = await _db!.rawQuery(
                  'SELECT id, tipo, nome, data, valor, servicos, status, telefone, obs FROM ordens WHERE nome LIKE ? ORDER BY id DESC',
                  ['%$termo%'],
                );
              } else {
                dados = await _db!.rawQuery(
                  'SELECT id, tipo, nome, data, valor, servicos, status, telefone, obs FROM ordens ORDER BY id DESC LIMIT 20',
                );
              }
              setModalState(() {
                resultados = dados;
              });
            }

            if (resultados.isEmpty && buscaController.text.isEmpty) {
              buscar();
            }

            void alternarStatus(int id, String statusAtual, String nomeCliente) {
              final novoStatus = (statusAtual == 'Finalizada') ? 'Pendente' : 'Finalizada';

              showDialog(
                context: context,
                builder: (confirmCtx) => AlertDialog(
                  title: Text(novoStatus == 'Finalizada' ? 'Finalizar Serviço' : 'Reabrir Serviço'),
                  content: Text('Deseja marcar a ordem de "$nomeCliente" como $novoStatus?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(confirmCtx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: novoStatus == 'Finalizada' ? Colors.green : Colors.orange,
                      ),
                      onPressed: () async {
                        await _db!.update(
                          'ordens',
                          {'status': novoStatus},
                          where: 'id = ?',
                          whereArgs: [id],
                        );
                        Navigator.pop(confirmCtx);
                        buscar();
                      },
                      child: Text(novoStatus == 'Finalizada' ? 'Finalizar' : 'Reabrir'),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: const Text('Histórico de Clientes'),
              content: SizedBox(
                width: double.maxFinite,
                height: 430,
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
                            onSubmitted: (_) => buscar(),
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
                                final id = r['id'] as int? ?? 1;
                                final numExibicao = 5049 + id;
                                final status = r['status']?.toString() ?? 'Pendente';
                                final bool isFinalizada = status == 'Finalizada';
                                final obsDb = r['obs']?.toString() ?? '';

                                return Card(
                                  color: isFinalizada ? const Color(0xFF1B4D2E) : const Color(0xFF333333),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    title: Text(
                                      'OS N°: $numExibicao | ${r['nome']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${r['tipo']} | Data: ${r['data']}\nValor: ${r['valor']} | Serviços: ${r['servicos']}${obsDb.isNotEmpty ? "\nObs: $obsDb" : ""}\nEstado: $status',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    trailing: Icon(
                                      isFinalizada ? Icons.check_circle : Icons.pending_actions,
                                      color: isFinalizada ? Colors.greenAccent : Colors.orangeAccent,
                                      size: 28,
                                    ),
                                    onTap: () {
                                      alternarStatus(id, status, r['nome']?.toString() ?? '');
                                    },
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

  void _abrirTelaNotaServico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaNotaServico(
          nomeInicial: _nomeController.text.trim(),
          telefoneInicial: _telefoneController.text.trim(),
          servicosIniciais: servicosSelecionados.map((s) => {
            'quant': '1',
            'desc': s,
            'valor': (opcoesServicos[s] ?? 0.0).toStringAsFixed(2),
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _obsController.text.trim().isNotEmpty
                      ? const Color(0xFF455A64)
                      : const Color(0xFFE5E5E5),
                  foregroundColor: _obsController.text.trim().isNotEmpty
                      ? Colors.white
                      : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _abrirJanelaObservacoes,
                icon: const Icon(Icons.note_alt_outlined),
                label: Text(
                  _obsController.text.trim().isNotEmpty
                      ? 'Observações: "${_obsController.text.trim()}"'
                      : 'Adicionar Observações',
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _abrirTelaNotaServico,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  'Emitir Nota de Serviços (PDF)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 25),
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
