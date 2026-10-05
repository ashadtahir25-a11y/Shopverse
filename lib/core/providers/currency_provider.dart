import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every price in the store is stored and charged in PKR. The currency
/// chosen in Settings only changes how prices are DISPLAYED (converted
/// at the latest exchange rate); orders, the admin dashboard and PDF
/// receipts stay in PKR so the numbers always match what was charged.
class AppCurrency {
  final String code;
  final String symbol;
  final String name;

  /// Approximate PKR -> this currency rate, used only until the first
  /// live rate has been downloaded (or if it can never be downloaded).
  final double fallbackRate;
  final int decimals;

  const AppCurrency(this.code, this.symbol, this.name, this.fallbackRate, this.decimals);

  bool get _spaced => symbol.length > 1;
}

const kCurrencies = [
  AppCurrency('PKR', 'Rs.', 'Pakistani Rupee', 1, 0),
  AppCurrency('USD', r'$', 'US Dollar', 0.0036, 2),
  AppCurrency('EUR', '€', 'Euro', 0.0033, 2),
  AppCurrency('GBP', '£', 'British Pound', 0.0027, 2),
  AppCurrency('AED', 'AED', 'UAE Dirham', 0.013, 2),
  AppCurrency('SAR', 'SAR', 'Saudi Riyal', 0.0134, 2),
];

AppCurrency currencyByCode(String code) =>
    kCurrencies.firstWhere((c) => c.code == code, orElse: () => kCurrencies.first);

class CurrencyState {
  final AppCurrency selected;

  /// PKR -> X rates from the last successful download (empty if none yet).
  final Map<String, double> rates;
  final DateTime? updatedAt;

  const CurrencyState({required this.selected, this.rates = const {}, this.updatedAt});

  bool get hasLiveRates => rates.isNotEmpty;

  double rateFor(AppCurrency c) => c.code == 'PKR' ? 1 : (rates[c.code] ?? c.fallbackRate);

  /// Converts a PKR amount into the selected currency and formats it.
  /// [amountPkr] may be negative (discounts) — the sign is kept.
  String format(double amountPkr) {
    final c = selected;
    final value = amountPkr * rateFor(c);
    final text = value.abs().toStringAsFixed(c.decimals);
    final sign = value < 0 ? '-' : '';
    return '$sign${c.symbol}${c._spaced ? ' ' : ''}$text';
  }

  /// One-line explanation shown under the Currency setting.
  String get note {
    if (selected.code == 'PKR') return 'Prices are shown in Pakistani Rupees';
    final perUnit = 1 / rateFor(selected);
    final base = '1 ${selected.code} ≈ Rs. ${perUnit.toStringAsFixed(0)}';
    if (!hasLiveRates || updatedAt == null) return '$base · approximate rate';
    final mins = DateTime.now().difference(updatedAt!).inMinutes;
    final ago = mins < 60 ? '${mins < 1 ? 1 : mins} min ago' : '${mins ~/ 60} h ago';
    return '$base · live rate, updated $ago';
  }

  CurrencyState copyWith({AppCurrency? selected, Map<String, double>? rates, DateTime? updatedAt}) => CurrencyState(
        selected: selected ?? this.selected,
        rates: rates ?? this.rates,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  CurrencyNotifier() : super(CurrencyState(selected: kCurrencies.first)) {
    _init();
  }

  static const _kCode = 'currency_code';
  static const _kRates = 'currency_rates';
  static const _kTime = 'currency_rates_time';

  /// Free endpoint, no API key. It refreshes its own figures about once a
  /// day, so "live" here means "as fresh as the provider publishes", not
  /// second-by-second market ticks.
  static const _url = 'https://open.er-api.com/v6/latest/PKR';
  static const _staleAfter = Duration(hours: 6);

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    var rates = <String, double>{};
    DateTime? at;
    final raw = prefs.getString(_kRates);
    final ms = prefs.getInt(_kTime);
    if (raw != null && ms != null) {
      try {
        rates = (jsonDecode(raw) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
        at = DateTime.fromMillisecondsSinceEpoch(ms);
      } catch (_) {}
    }
    state = CurrencyState(
      selected: currencyByCode(prefs.getString(_kCode) ?? 'PKR'),
      rates: rates,
      updatedAt: at,
    );
    if (state.selected.code != 'PKR' && (at == null || DateTime.now().difference(at) > _staleAfter)) {
      refresh();
    }
  }

  /// Downloads fresh rates. Failures are silent: the app keeps using the
  /// cached rates, or the built-in approximate ones.
  Future<void> refresh() async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)));
      final res = await dio.get<dynamic>(_url);
      final body = res.data is String ? jsonDecode(res.data as String) : res.data;
      if (body is! Map || body['result'] != 'success' || body['rates'] is! Map) return;

      final all = body['rates'] as Map;
      final wanted = <String, double>{
        for (final c in kCurrencies)
          if (c.code != 'PKR' && all[c.code] is num) c.code: (all[c.code] as num).toDouble(),
      };
      if (wanted.isEmpty) return;

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRates, jsonEncode(wanted));
      await prefs.setInt(_kTime, now.millisecondsSinceEpoch);
      state = state.copyWith(rates: wanted, updatedAt: now);
    } catch (_) {}
  }

  Future<void> selectCode(String code) async {
    final c = currencyByCode(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCode, c.code);
    state = state.copyWith(selected: c);
    final at = state.updatedAt;
    if (c.code != 'PKR' && (at == null || DateTime.now().difference(at) > _staleAfter)) refresh();
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) => CurrencyNotifier());
