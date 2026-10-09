import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
        _adicionarItem(
          quant: s['quant'] ?? '1',
          desc: s['desc'] ?? '',
          valor: s['valor'] ?? '0.00',
        );
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _estadoController,
                    decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cepController,
                    decoration: const InputDecoration(labelText: 'CEP', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cnpjCpfController,
                    decoration: const InputDecoration(labelText: 'CNPJ / CPF', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _inscEstController,
                    decoration: const InputDecoration(labelText: 'Insc. Est.', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _foneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Fone', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _condPgtoController,
                    decoration: const InputDecoration(labelText: 'Cond. Pgto.', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tabela de Serviços', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _adicionarItem(),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Linha'),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              itemBuilder: (ctx, idx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: itens[idx]['quant'],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qtd', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: itens[idx]['desc'],
                          decoration: const InputDecoration(labelText: 'Descrição do Serviço', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 85,
                        child: TextField(
                          controller: itens[idx]['valor'],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Valor R\$', isDense: true, border: OutlineInputBorder()),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removerItem(idx),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerRight,
              child: Text(
                'TOTAL: R\$ ${_calcularTotal().toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _imprimirOuVisualizarPdf,
                    icon: const Icon(Icons.print),
                    label: const Text('Visualizar / Imprimir'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _compartilharPdf,
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
