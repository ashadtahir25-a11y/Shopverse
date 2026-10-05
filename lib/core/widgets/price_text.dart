import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/currency_provider.dart';

/// Shows a PKR amount in whichever currency the customer picked in
/// Settings, and rebuilds by itself when that choice (or the live rate)
/// changes. [prefix]/[suffix] cover mixed strings like "Qty: 2 · Rs. 500".
class PriceText extends ConsumerWidget {
  final double amountPkr;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const PriceText(
    this.amountPkr, {
    super.key,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(currencyProvider).format(amountPkr);
    return Text('$prefix$text$suffix', style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
  }
}
