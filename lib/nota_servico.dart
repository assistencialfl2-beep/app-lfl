import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

    // Carrega a imagem do logo dos assets de forma segura
    pw.MemoryImage? imageLogo;
    try {
      final ByteData logoBytes = await rootBundle.load('assets/logo.png');
      final Uint8List logoData = logoBytes.buffer.asUint8List();
      imageLogo = pw.MemoryImage(logoData);
    } catch (_) {}

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
                // CABEÇALHO COM LOGO
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (imageLogo != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(imageLogo, fit: pw.BoxFit.contain),
                        )
                      else
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
                              fontSize: 14,
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
                      pw.
