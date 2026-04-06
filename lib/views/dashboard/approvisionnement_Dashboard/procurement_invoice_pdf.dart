import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:invera_mobile/models/facture_model.dart';
import 'package:invera_mobile/models/procurement_models.dart';

// Valeurs globales partagees utilisees par l'interface.
const Color _primary = Color(0xFF2D47C8);
const double _pdfVatRate = 0.19;
const String _pdfCompanyAddress = '123 Rue de la Republique, 1000 Tunis';
const String _pdfCompanyPhone = '+216 00 000 000';
const String _pdfCompanyEmail = 'contact@invera.tn';
const String _pdfCompanyTaxId = 'MF: 0000000/A/M/000';

/// Exporte le PDF de la facture d'approvisionnement.
Future<void> exportProcurementInvoicePdf(
  ProcurementOrder order,
  FactureModel facture,
) {
  final invoiceReference = _factureReference(facture, order);
  return Printing.layoutPdf(
    onLayout: (_) => buildProcurementInvoicePdfBytes(order, facture),
    name: '${_sanitizeFileName(invoiceReference)}.pdf',
  );
}

/// Construit les octets du PDF de la facture d'approvisionnement.
Future<Uint8List> buildProcurementInvoicePdfBytes(
  ProcurementOrder order,
  FactureModel facture,
) async {
  final baseFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/roboto-regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/roboto-bold.ttf'),
  );
  final pdfTheme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
  final document = pw.Document();
  final supplier = order.fournisseur;
  final logoBytes = await rootBundle.load('assets/images/logo.png');
  final logoImage = pw.MemoryImage(
    logoBytes.buffer.asUint8List(
      logoBytes.offsetInBytes,
      logoBytes.lengthInBytes,
    ),
  );
  final generatedAt = _formatPdfDate(facture.dateFactureDisplay);
  final lines = _buildInvoiceLines(order);
  final subtotal = lines.isNotEmpty
      ? lines.fold<double>(0, (sum, line) => sum + line.sousTotal)
      : order.totalHT;
  final vatRate = _effectiveVatRate(order);
  final vatAmount = order.totalTVA > 0 ? order.totalTVA : subtotal * vatRate;
  final invoiceHeadlineAmount = facture.montantTotal > 0
      ? facture.montantTotal
      : order.total;
  final totalTtc = invoiceHeadlineAmount > 0
      ? invoiceHeadlineAmount
      : subtotal + vatAmount;

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pdfTheme,
      margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
      build: (context) => [
        _buildPdfHeader(
          logoImage: logoImage,
          reference: _factureReference(facture, order),
          status: _factureStatusLabel(facture, order),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildPdfInfoCard(
                title: 'FOURNISSEUR',
                marker: 'F',
                markerBackground: PdfColor.fromInt(0xFFF1E8FF),
                markerColor: PdfColor.fromInt(0xFF6B3FA0),
                children: [
                  _buildPdfInfoRow('Nom', supplier?.displayName ?? '-'),
                  _buildPdfInfoRow('Email', supplier?.email ?? '-'),
                  _buildPdfInfoRow('Tel', supplier?.telephone ?? '-'),
                  _buildPdfInfoRow(
                    'Adresse',
                    supplier?.adresse.trim().isNotEmpty == true
                        ? supplier!.adresse
                        : order.adresseLivraison,
                  ),
                  _buildPdfInfoRow('Ville', _composeSupplierLocation(supplier)),
                ],
              ),
            ),
            pw.SizedBox(width: 18),
            pw.Expanded(
              child: _buildPdfInfoCard(
                title: 'FACTURE',
                marker: 'F',
                markerBackground: PdfColor.fromInt(0xFFF3EBFF),
                markerColor: PdfColor.fromInt(0xFFA06BFF),
                children: [
                  _buildPdfInfoRow('Date', generatedAt),
                  _buildPdfInfoRow('No', _factureReference(facture, order)),
                  _buildPdfInfoRow('Commande', order.referenceCommande),
                  _buildPdfInfoRow(
                    'Reception',
                    order.dateLivraisonReelleFormatted,
                  ),
                  pw.SizedBox(height: 14),
                  pw.Container(height: 1, color: PdfColor.fromInt(0xFFE8ECF4)),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total TTC',
                        style: pw.TextStyle(
                          fontSize: 12.5,
                          color: PdfColor.fromInt(0xFF4B5A6A),
                        ),
                      ),
                      pw.Text(
                        _formatPdfAmount(invoiceHeadlineAmount),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(_primary.toARGB32()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 26),
        _buildPdfSectionTitle('ARTICLES'),
        pw.SizedBox(height: 12),
        _buildPdfArticlesTable(lines),
        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: _buildPdfTotalsCard(
            subtotal: subtotal,
            vatAmount: vatAmount,
            totalTtc: totalTtc,
            vatRate: vatRate,
          ),
        ),
        pw.SizedBox(height: 30),
        _buildPdfFooter(),
      ],
    ),
  );

  return document.save();
}

FactureModel buildProcurementFactureModelFromOrder(
  ProcurementOrder order, {
  DateTime? billedAt,
}) {
  final generatedAt =
      billedAt ??
      order.dateLivraisonReelle ??
      order.dateCommande ??
      DateTime.now();

  return FactureModel(
    idFactureClient: order.idCommandeFournisseur,
    referenceFactureClient: procurementInvoiceReference(order),
    commandeId: order.idCommandeFournisseur,
    clientId: null,
    statut: order.statut.toUpperCase() == 'FACTUREE'
        ? 'FACTUREE'
        : order.statutDisplay.toUpperCase(),
    montantTotal: order.total,
    dateFactureDisplay: _formatDateTime(generatedAt),
  );
}

/// Methode utilitaire pour la reference de facture d'approvisionnement.
String procurementInvoiceReference(ProcurementOrder order) {
  final number = order.referenceCommande.trim();
  if (number.isEmpty) {
    return 'FAC-ACH-${order.idCommandeFournisseur}';
  }

  final normalized = number.replaceAll(RegExp(r'\s+'), '-');
  return 'FAC-$normalized';
}

List<_ProcurementInvoiceLine> _buildInvoiceLines(ProcurementOrder order) {
  return order.produits.map(_ProcurementInvoiceLine.fromOrderLine).toList();
}

/// Methode utilitaire pour effective vat rate.
double _effectiveVatRate(ProcurementOrder order) {
  final rawRate = order.tauxTVA > 0 ? order.tauxTVA / 100 : _pdfVatRate;
  return rawRate <= 0 ? _pdfVatRate : rawRate;
}

/// Methode utilitaire pour la reference de facture.
String _factureReference(FactureModel facture, ProcurementOrder order) {
  final reference = facture.referenceFactureClient.trim();
  return reference.isEmpty || reference == '-'
      ? procurementInvoiceReference(order)
      : reference;
}

/// Methode utilitaire pour le libelle du statut de facture.
String _factureStatusLabel(FactureModel facture, ProcurementOrder order) {
  final status = facture.statut.trim();
  if (status.isEmpty || status == 'INCONNU') {
    return order.statutDisplay;
  }
  return _displayStatus(status);
}

/// Methode utilitaire pour la localisation du fournisseur.
String _composeSupplierLocation(ProcurementSupplier? supplier) {
  if (supplier == null) return '-';
  final parts = <String>[
    if (supplier.ville.trim().isNotEmpty) supplier.ville.trim(),
    if (supplier.pays.trim().isNotEmpty) supplier.pays.trim(),
  ];
  if (parts.isEmpty) return '-';
  return parts.join(', ');
}

pw.Widget _buildPdfHeader({
  required pw.MemoryImage logoImage,
  required String reference,
  required String status,
}) {
  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 78,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 14),
                pw.Container(
                  width: 1,
                  height: 84,
                  color: PdfColor.fromInt(0xFFE6EAF2),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfContactLine(
                        marker: 'P',
                        value: _pdfCompanyAddress,
                        markerBackground: PdfColor.fromInt(0xFFFFE8F2),
                        markerColor: PdfColor.fromInt(0xFFE25793),
                      ),
                      pw.SizedBox(height: 10),
                      _buildPdfContactLine(
                        marker: 'T',
                        value: _pdfCompanyPhone,
                        markerBackground: PdfColor.fromInt(0xFFFFE7F1),
                        markerColor: PdfColor.fromInt(0xFFD44A86),
                      ),
                      pw.SizedBox(height: 10),
                      _buildPdfContactLine(
                        marker: '@',
                        value: _pdfCompanyEmail,
                        markerBackground: PdfColor.fromInt(0xFFF4EDFF),
                        markerColor: PdfColor.fromInt(0xFF8C73E6),
                      ),
                      pw.SizedBox(height: 10),
                      _buildPdfContactLine(
                        marker: 'ID',
                        value: _pdfCompanyTaxId,
                        markerBackground: PdfColor.fromInt(0xFFF2E9FF),
                        markerColor: PdfColor.fromInt(0xFF9A63E6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'FACTURE',
                  style: pw.TextStyle(
                    fontSize: 29,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF16223C),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  reference.trim().isEmpty ? '-' : reference,
                  style: pw.TextStyle(
                    fontSize: 12.5,
                    color: PdfColor.fromInt(0xFF6E7C8F),
                  ),
                ),
                pw.SizedBox(height: 18),
                _buildPdfStatusPill(status),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 18),
      pw.Container(height: 1, color: PdfColor.fromInt(0xFFF0F2F6)),
    ],
  );
}

pw.Widget _buildPdfContactLine({
  required String marker,
  required String value,
  required PdfColor markerBackground,
  required PdfColor markerColor,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 16,
        height: 16,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: markerBackground,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          marker,
          style: pw.TextStyle(
            fontSize: marker.length > 1 ? 6.5 : 8.5,
            fontWeight: pw.FontWeight.bold,
            color: markerColor,
          ),
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColor.fromInt(0xFF556273),
          ),
        ),
      ),
    ],
  );
}

pw.Widget _buildPdfStatusPill(String rawStatus) {
  final statusLabel = _displayStatus(rawStatus);
  final statusUpper = rawStatus.trim().toUpperCase();
  var borderColor = PdfColor.fromInt(0xFFF5D978);
  var fillColor = PdfColor.fromInt(0xFFFFFBEC);
  var textColor = PdfColor.fromInt(0xFFB27A1D);

  if (statusUpper == 'PAYEE' ||
      statusUpper == 'PAID' ||
      statusUpper == 'FACTUREE') {
    borderColor = PdfColor.fromInt(0xFF93D7AB);
    fillColor = PdfColor.fromInt(0xFFEFFAF3);
    textColor = PdfColor.fromInt(0xFF24734A);
  } else if (statusUpper == 'ANNULEE' || statusUpper == 'REJETEE') {
    borderColor = PdfColor.fromInt(0xFFF0A5A5);
    fillColor = PdfColor.fromInt(0xFFFFF1F1);
    textColor = PdfColor.fromInt(0xFFC25353);
  }

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: pw.BoxDecoration(
      color: fillColor,
      border: pw.Border.all(color: borderColor),
      borderRadius: pw.BorderRadius.circular(18),
    ),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 7,
          height: 7,
          decoration: pw.BoxDecoration(
            color: textColor,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          statusLabel,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildPdfInfoCard({
  required String title,
  required String marker,
  required PdfColor markerBackground,
  required PdfColor markerColor,
  required List<pw.Widget> children,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(18),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFFBFCFF),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE9EEF5)),
      borderRadius: pw.BorderRadius.circular(18),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfCardTitle(
          title: title,
          marker: marker,
          markerBackground: markerBackground,
          markerColor: markerColor,
        ),
        pw.SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

pw.Widget _buildPdfCardTitle({
  required String title,
  required String marker,
  required PdfColor markerBackground,
  required PdfColor markerColor,
}) {
  return pw.Row(
    children: [
      pw.Container(
        width: 18,
        height: 18,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: markerBackground,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text(
          marker,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: markerColor,
          ),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF6B7788),
          letterSpacing: 0.5,
        ),
      ),
    ],
  );
}

pw.Widget _buildPdfInfoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 54,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11.5,
              color: PdfColor.fromInt(0xFF8A96A7),
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            value.trim().isEmpty ? '-' : value,
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1C263A),
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildPdfSectionTitle(String title) {
  return pw.Row(
    children: [
      pw.Container(
        width: 16,
        height: 16,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF3EBFF),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          title.substring(0, 1),
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFFB58CFF),
          ),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF6A7788),
          letterSpacing: 0.4,
        ),
      ),
    ],
  );
}

pw.Widget _buildPdfArticlesTable(List<_ProcurementInvoiceLine> lines) {
  final rows = lines.isEmpty ? <_ProcurementInvoiceLine>[] : lines;

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE9EEF5)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(
      children: [
        _buildPdfArticleRow(
          description: 'DESCRIPTION',
          quantity: 'QTE',
          unitPrice: 'PRIX UNITAIRE',
          total: 'TOTAL',
          isHeader: true,
        ),
        if (rows.isEmpty)
          _buildPdfArticleRow(
            description: 'Aucun article',
            quantity: '-',
            unitPrice: '-',
            total: '-',
          )
        else
          for (final line in rows)
            _buildPdfArticleRow(
              description: line.description,
              quantity: '${line.quantity}',
              unitPrice: _formatPdfAmount(line.prixUnitaire),
              total: _formatPdfAmount(line.sousTotal),
            ),
      ],
    ),
  );
}

pw.Widget _buildPdfArticleRow({
  required String description,
  required String quantity,
  required String unitPrice,
  required String total,
  bool isHeader = false,
}) {
  final textColor = isHeader
      ? PdfColor.fromInt(0xFF7A8696)
      : PdfColor.fromInt(0xFF1E273A);
  final borderSide = pw.BorderSide(color: PdfColor.fromInt(0xFFEFF3F8));

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: pw.BoxDecoration(
      color: isHeader ? PdfColor.fromInt(0xFFFBFCFF) : PdfColors.white,
      border: isHeader ? null : pw.Border(top: borderSide),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfArticleCell(
          text: description,
          flex: 4,
          alignment: pw.Alignment.centerLeft,
          isHeader: isHeader,
          color: textColor,
        ),
        _buildPdfArticleCell(
          text: quantity,
          flex: 1,
          alignment: pw.Alignment.center,
          isHeader: isHeader,
          color: textColor,
        ),
        _buildPdfArticleCell(
          text: unitPrice,
          flex: 2,
          alignment: pw.Alignment.centerRight,
          isHeader: isHeader,
          color: textColor,
        ),
        _buildPdfArticleCell(
          text: total,
          flex: 2,
          alignment: pw.Alignment.centerRight,
          isHeader: isHeader,
          color: textColor,
        ),
      ],
    ),
  );
}

pw.Widget _buildPdfArticleCell({
  required String text,
  required int flex,
  required pw.Alignment alignment,
  required bool isHeader,
  required PdfColor color,
}) {
  return pw.Expanded(
    flex: flex,
    child: pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignment == pw.Alignment.centerRight
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isHeader ? 10.5 : 11.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
          letterSpacing: isHeader ? 0.25 : 0,
        ),
      ),
    ),
  );
}

pw.Widget _buildPdfTotalsCard({
  required double subtotal,
  required double vatAmount,
  required double totalTtc,
  required double vatRate,
}) {
  return pw.Container(
    width: 258,
    padding: const pw.EdgeInsets.all(18),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE9EEF5)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildPdfSummaryLine('Sous-total', _formatPdfAmount(subtotal)),
        pw.SizedBox(height: 12),
        _buildPdfSummaryLine(
          'TVA ${(100 * vatRate).toStringAsFixed(0)}%',
          _formatPdfAmount(vatAmount),
        ),
        pw.SizedBox(height: 12),
        pw.Container(height: 1, color: PdfColor.fromInt(0xFFE9EEF5)),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Total TTC',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF20293B),
              ),
            ),
            pw.Text(
              _formatPdfAmount(totalTtc),
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(_primary.toARGB32()),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildPdfSummaryLine(String label, String value) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 12.5,
          color: PdfColor.fromInt(0xFF667383),
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 12.5,
          color: PdfColor.fromInt(0xFF303A49),
        ),
      ),
    ],
  );
}

pw.Widget _buildPdfFooter() {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF7F9FD),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Center(
      child: pw.Text(
        'Merci de votre confiance - Facture generee par InVera',
        style: pw.TextStyle(
          fontSize: 10.5,
          color: PdfColor.fromInt(0xFF8A96A6),
        ),
      ),
    ),
  );
}

/// Retourne un libelle d'affichage pour le statut.
String _displayStatus(String raw) {
  final norm = raw.trim().toUpperCase();
  if (norm == 'EN_ATTENTE') return 'En attente';
  if (norm == 'CONFIRMEE' || norm == 'VALIDEE') return 'Confirmee';
  if (norm == 'ANNULEE' || norm == 'REJETEE') return 'Annulee';
  if (norm == 'FACTUREE') return 'Facturee';
  if (norm == 'RECUE') return 'Recue';
  if (norm == 'ENVOYEE') return 'Envoyee';
  if (norm == 'BROUILLON') return 'Brouillon';
  return raw.trim().isEmpty ? '-' : raw;
}

/// Formate pdf amount pour l'affichage.
String _formatPdfAmount(double value) {
  final absolute = value.abs().toStringAsFixed(3);
  final parts = absolute.split('.');
  final integerPart = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  final formatted = '$integerPart,${parts.last} DT';
  return value < 0 ? '-$formatted' : formatted;
}

/// Formate pdf date pour l'affichage.
String _formatPdfDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '-';
  final parsed = _parseFlexibleDate(trimmed);
  if (parsed == null) return trimmed;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

DateTime? _parseFlexibleDate(String raw) {
  final parsedRaw = DateTime.tryParse(raw);
  if (parsedRaw != null) return parsedRaw;

  final normalized = raw.replaceFirst(' ', 'T');
  final parsedNormalized = DateTime.tryParse(normalized);
  if (parsedNormalized != null) return parsedNormalized;

  final match = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
  ).firstMatch(raw);
  if (match == null) return null;

  final day = int.tryParse(match.group(1) ?? '');
  final month = int.tryParse(match.group(2) ?? '');
  final year = int.tryParse(match.group(3) ?? '');
  final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
  final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
  final second = int.tryParse(match.group(6) ?? '0') ?? 0;
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day, hour, minute, second);
}

/// Formate la date et l'heure pour l'affichage.
String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString().padLeft(4, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

/// Methode utilitaire pour le nettoyage du nom de fichier.
String _sanitizeFileName(String value) {
  final sanitized = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return sanitized.isEmpty ? 'facture-achat' : sanitized;
}

/// Petit modele utilitaire qui stocke les donnees de la ligne de facture d'approvisionnement.
class _ProcurementInvoiceLine {
  // Configuration, dependances et etat local de l'interface.
  final String description;
  final int quantity;
  final double prixUnitaire;
  final double sousTotal;

  const _ProcurementInvoiceLine({
    required this.description,
    required this.quantity,
    required this.prixUnitaire,
    required this.sousTotal,
  });

  factory _ProcurementInvoiceLine.fromOrderLine(ProcurementOrderLine line) {
    final quantity = line.quantiteRecue > 0
        ? line.quantiteRecue
        : line.quantite;
    final descriptionParts = <String>[
      line.displayName,
      if (line.produitReference.trim().isNotEmpty &&
          line.produitReference.trim() != '-')
        line.produitReference.trim(),
    ];
    final sousTotal = quantity * line.prixUnitaire;

    return _ProcurementInvoiceLine(
      description: descriptionParts.join(' - '),
      quantity: quantity,
      prixUnitaire: line.prixUnitaire,
      sousTotal: sousTotal,
    );
  }
}
