import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
                                      'OS N°: $numExibicao |${r['nome']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${r['tipo']} | Data: ${r['data']}\nValor:${r['valor']} | Serviços: ${r['servicos']}${obsDb.isNotEmpty ? "\nObs: $obsDb" : ""}\nEstado: $status',
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
          servicosIniciais: servicosSelecionados.map((s) => {'quant': '1', 'desc': s, 'valor': (opcoesServicos[s] ?? 0.0).toStringAsFixed(2)}).toList(),
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

// -------------------------------------------------------------
// TELA DE EMISSÃO DA NOTA DE SERVIÇO (PDF IDÊNTICO AO TALÃO)
// -------------------------------------------------------------
class TelaNotaServico extends StatefulWidget {
  final String nomeInicial;
  final String telefoneInicial;
  final List<Map<String, String>> servicosIniciais;

  const TelaNotaServico({
    super.key,
    this.nomeInicial = '',
    this.telefoneInicial = '',
    this.servicosIniciais = const [],
  });

  @override
  State<TelaNotaServico> createState() => _TelaNotaServicoState();
}

class _TelaNotaServicoState extends State<TelaNotaServico> {
  final _numeroNotaController = TextEditingController(text: '3141');
  final _dataController = TextEditingController();
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroEnderecoController = TextEditingController();
  final _cidadeController = TextEditingController(text: 'Curitiba');
  final _estadoController = TextEditingController(text: 'PR');
  final _cepController = TextEditingController();
  final _cnpjCpfController = TextEditingController();
  final _inscEstController = TextEditingController();
  final _foneController = TextEditingController();
  final _condPgtoController = TextEditingController(text: 'À vista / Pix');

  List<Map<String, TextEditingController>> itens = [];

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _nomeController.text = widget.nomeInicial;
    _foneController.text = widget.telefoneInicial;

    if (widget.servicosIniciais.isNotEmpty) {
      for (var s in widget.servicosIniciais) {
        _adicionarItem(quant: s['quant'] ?? '1', desc: s['desc'] ?? '', valor: s['valor'] ?? '0.00');
      }
    } else {
      _adicionarItem();
    }
  }

  void _adicionarItem({String quant = '1', String desc = '', String valor = ''}) {
    setState(() {
      itens.add({
        'quant': TextEditingController(text: quant),
        'desc': TextEditingController(text: desc),
        'valor': TextEditingController(text: valor),
      });
    });
  }

  void _removerItem(int index) {
    if (itens.length > 1) {
      setState(() {
        itens.removeAt(index);
      });
    }
  }

  double _calcularTotal() {
    double total = 0.0;
    for (var item in itens) {
      final v = double.tryParse(item['valor']!.text.replaceAll(',', '.')) ?? 0.0;
      total += v;
    }
    return total;
  }

  Future<Uint8List> _gerarDocumentoPdf() async {
    final pdf = pw.Document();

    final numeroNota = _numeroNotaController.text.trim();
    final data = _dataController.text.trim();
    final nome = _nomeController.text.trim();
    final endereco = _enderecoController.text.trim();
    final numeroEnd = _numeroEnderecoController.text.trim();
    final cidade = _cidadeController.text.trim();
    final estado = _estadoController.text.trim();
    final cep = _cepController.text.trim();
    final cnpjCpf = _cnpjCpfController.text.trim();
    final inscEst = _inscEstController.text.trim();
    final fone = _foneController.text.trim();
    final condPgto = _condPgtoController.text.trim();

    final listaItensPdf = itens.map((item) {
      return {
        'quant': item['quant']!.text.trim(),
        'desc': item['desc']!.text.trim(),
        'valor': item['valor']!.text.trim().replaceAll('.', ','),
      };
    }).toList();

    final totalFormatado = _calcularTotal().toStringAsFixed(2).replaceAll('.', ',');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // CABEÇALHO
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#6E6E6E'),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          'Suporte Técnico',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 14),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('LFL INFORMÁTICA LTDA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text('(41) 98499-6521', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('assistencialfl@gmail.com', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('CNPJ: 31.246.852/0001-97', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rua David Geronasso, 820 - Boa Vista - CEP 82.540-150 - Curitiba - PR', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // TÍTULO E NÚMERO
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'NOTA DE PRESTAÇÃO DE SERVIÇOS',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                      ),
                      pw.Text(
                        numeroNota,
                        style: pw.TextStyle(color: PdfColors.red900, fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // DADOS DO CLIENTE
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Data da Emissão: $data', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Nome: $nome', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('Endereço: $endereco', style: const pw.TextStyle(fontSize: 10))),
                          pw.Text('Nº: $numeroEnd', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(flex: 2, child: pw.Text('Cidade: $cidade', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(flex: 1, child: pw.Text('Estado: $estado', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(flex: 1, child: pw.Text('CEP: $cep', style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('CNPJ/CPF: $cnpjCpf', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(child: pw.Text('Insc. Est.: $inscEst', style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('Fone: $fone', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(child: pw.Text('Cond. pgto.: $condPgto', style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                    ],
                  ),
                ),

                // TABELA (CABEÇALHO)
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 55,
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.center,
                        decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1))),
                        child: pw.Text('Quant.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          alignment: pw.Alignment.center,
                          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1))),
                          child: pw.Text('Descrição dos Serviços', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      pw.Container(
                        width: 90,
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.center,
                        child: pw.Text('VALOR R\$', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // LINHAS DA TABELA (12 linhas fixas)
                pw.Expanded(
                  child: pw.Column(
                    children: List.generate(12, (index) {
                      final item = index < listaItensPdf.length ? listaItensPdf[index] : null;
                      return pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 55,
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                                alignment: pw.Alignment.center,
                                decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1))),
                                child: pw.Text(item?['quant'] ?? '', style: const pw.TextStyle(fontSize: 9)),
                              ),
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                                  alignment: pw.Alignment.centerLeft,
                                  decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1))),
                                  child: pw.Text(item?['desc'] ?? '', style: const pw.TextStyle(fontSize: 9)),
                                ),
                              ),
                              pw.Container(
                                width: 90,
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(item != null && item['valor']!.isNotEmpty ? 'R\$ ${item['valor']}' : '', style: const pw.TextStyle(fontSize: 9)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // TOTAL
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 10),
                      pw.Container(
                        width: 100,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 1),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('R\$ $totalFormatado', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _compartilharPdf() async {
    final pdfBytes = await _gerarDocumentoPdf();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Nota_Servico_${_numeroNotaController.text}.pdf',
    );
  }

  Future<void> _imprimirOuVisualizarPdf() async {
    final pdfBytes = await _gerarDocumentoPdf();
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota de Prestação de Serviços'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numeroNotaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nº da Nota', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dataController,
                    decoration: const InputDecoration(labelText: 'Data da Emissão', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Cliente', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _enderecoController,
                    decoration: const InputDecoration(labelText: 'Endereço', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _numeroEnderecoController,
                    decoration: const InputDecoration(labelText: 'Nº', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cidadeController,
                    decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                  ),
