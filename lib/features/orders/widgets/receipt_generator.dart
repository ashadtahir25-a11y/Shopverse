import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

/// Brand purple, matching AppColors.primary — kept as a literal here
/// since the `pdf` package's widget tree is a separate render pipeline
/// from Flutter's own and doesn't read the app's ThemeData/AppColors.
const _brandColor = PdfColor.fromInt(0xFF5B4FF0);
const _mutedColor = PdfColor.fromInt(0xFF6B7280);

/// Builds a one-page PDF receipt for [order] — used by both "Share" and
/// "Print" actions on Order Details, so the exact same document is what
/// gets shared and what gets printed.
Future<pw.Document> buildReceiptPdf(AppOrder order) async {
  final doc = pw.Document();
  final dateStr = '${order.date.day}/${order.date.month}/${order.date.year}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ShopVerse', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _brandColor)),
                    pw.SizedBox(height: 2),
                    pw.Text('Order Receipt', style: const pw.TextStyle(fontSize: 12, color: _mutedColor)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(order.orderNumber, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.Text(dateStr, style: const pw.TextStyle(fontSize: 11, color: _mutedColor)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 14),

            // Bill to / delivery
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO', style: const pw.TextStyle(fontSize: 9, color: _mutedColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(order.customerName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.customerEmail, style: const pw.TextStyle(fontSize: 10, color: _mutedColor)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DELIVERY ADDRESS', style: const pw.TextStyle(fontSize: 9, color: _mutedColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(order.addressSummary, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PAYMENT', style: const pw.TextStyle(fontSize: 9, color: _mutedColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(order.paymentMethodLabel, style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text(order.status.label, style: pw.TextStyle(fontSize: 10, color: _brandColor, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 22),

            // Items table
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.grey300),
                horizontalInside: pw.BorderSide(color: PdfColors.grey200),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F2FF)),
                  children: [
                    _cell('Item', bold: true, pad: true),
                    _cell('Qty', bold: true, pad: true, align: pw.TextAlign.center),
                    _cell('Price', bold: true, pad: true, align: pw.TextAlign.right),
                    _cell('Subtotal', bold: true, pad: true, align: pw.TextAlign.right),
                  ],
                ),
                for (final item in order.items)
                  pw.TableRow(
                    children: [
                      _cell(
                        item.variantLabel.isNotEmpty ? '${item.name} (${item.variantLabel})' : item.name,
                        pad: true,
                      ),
                      _cell('${item.quantity}', pad: true, align: pw.TextAlign.center),
                      _cell('Rs. ${item.price.toStringAsFixed(0)}', pad: true, align: pw.TextAlign.right),
                      _cell('Rs. ${item.subtotal.toStringAsFixed(0)}', pad: true, align: pw.TextAlign.right),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _totalRow('Subtotal', order.subtotal),
                    if (order.discount > 0) _totalRow('Discount', -order.discount),
                    _totalRow('Delivery Fee', order.deliveryFee),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Divider(color: PdfColors.grey300)),
                    _totalRow('Total', order.total, bold: true),
                  ],
                ),
              ),
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for shopping with ShopVerse',
                style: const pw.TextStyle(fontSize: 10, color: _mutedColor),
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc;
}

pw.Widget _cell(String text, {bool bold = false, bool pad = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: pad ? const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4) : pw.EdgeInsets.zero,
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
    ),
  );
}

pw.Widget _totalRow(String label, double value, {bool bold = false}) {
  final style = pw.TextStyle(fontSize: bold ? 13 : 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
  final sign = value < 0 ? '-' : '';
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style.copyWith(color: bold ? PdfColors.black : _mutedColor)),
        pw.Text('$sign Rs. ${value.abs().toStringAsFixed(0)}', style: style),
      ],
    ),
  );
}

/// Opens the system share sheet with the receipt as a PDF attachment.
Future<void> shareOrderReceipt(AppOrder order) async {
  final doc = await buildReceiptPdf(order);
  await Printing.sharePdf(bytes: await doc.save(), filename: '${order.orderNumber}_receipt.pdf');
}

/// Opens the system print/save dialog for the receipt — on most
/// platforms this also offers "Save as PDF" alongside actual printers.
Future<void> printOrderReceipt(AppOrder order) async {
  final doc = await buildReceiptPdf(order);
  await Printing.layoutPdf(onLayout: (format) async => doc.save());
}