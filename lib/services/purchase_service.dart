import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // Mismo ID en Google Play Console y App Store Connect.
  static const String premiumMonthlyId = 'domino_apuntes_premium_monthly';
  static const Set<String> _productIds = {premiumMonthlyId};

  static const String _prefsKeyPremium = 'is_premium';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<List<ProductDetails>> products =
      ValueNotifier<List<ProductDetails>>(const []);
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);

  // Diagnóstico visible en pantalla para depurar la carga de productos.
  final ValueNotifier<String> debugLog = ValueNotifier<String>('');

  void _log(String message) {
    debugPrint(message);
    debugLog.value =
        '${debugLog.value}${debugLog.value.isEmpty ? '' : '\n'}$message';
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium.value = prefs.getBool(_prefsKeyPremium) ?? false;

    _log('IDs solicitados: $_productIds');
    final available = await _iap.isAvailable();
    isAvailable.value = available;
    _log('IAP disponible: $available');
    if (!available) {
      _log('IAP no disponible en este dispositivo');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (Object e) => debugPrint('Error en purchaseStream: $e'),
    );

    await _loadProducts();
    // Restaura compras pasadas al iniciar (importante para iOS).
    await _iap.restorePurchases();
  }

  Future<void> _loadProducts() async {
    _log('Consultando productos...');
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      _log('Error consultando productos: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      _log('Productos NO encontrados: ${response.notFoundIDs}');
    }
    if (response.productDetails.isNotEmpty) {
      for (final p in response.productDetails) {
        _log('Producto OK: ${p.id} -> ${p.price}');
      }
    }
    products.value = response.productDetails;
  }

  Future<bool> buyPremium() async {
    if (!isAvailable.value) return false;
    final product = _findProduct(premiumMonthlyId);
    if (product == null) {
      debugPrint('Producto $premiumMonthlyId no disponible');
      return false;
    }
    isProcessing.value = true;
    final param = PurchaseParam(productDetails: product);
    try {
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('Error iniciando compra: $e');
      isProcessing.value = false;
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!isAvailable.value) return;
    isProcessing.value = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error restaurando compras: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  ProductDetails? _findProduct(String id) {
    for (final p in products.value) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isProcessing.value = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == premiumMonthlyId) {
            await _setPremium(true);
          }
          isProcessing.value = false;
          break;
        case PurchaseStatus.error:
          debugPrint('Error en compra: ${purchase.error}');
          isProcessing.value = false;
          break;
        case PurchaseStatus.canceled:
          isProcessing.value = false;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _setPremium(bool value) async {
    isPremium.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyPremium, value);
  }

  ProductDetails? get premiumProduct => _findProduct(premiumMonthlyId);

  void dispose() {
    _subscription?.cancel();
  }
}
