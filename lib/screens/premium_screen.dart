import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../languages/app_localizations.dart';
import '../services/purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PurchaseService _purchases = PurchaseService();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          loc.get('premium_title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _purchases.isPremium,
        builder: (context, isPremium, _) {
          if (isPremium) return _buildActiveState(loc);
          return _buildPaywall(loc);
        },
      ),
    );
  }

  Widget _buildActiveState(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified, color: Color(0xFFE53935), size: 96),
          const SizedBox(height: 24),
          Text(
            loc.get('premium_active'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.get('premium_active_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywall(AppLocalizations loc) {
    return ValueListenableBuilder<bool>(
      valueListenable: _purchases.isAvailable,
      builder: (context, available, _) {
        return ValueListenableBuilder<List<ProductDetails>>(
          valueListenable: _purchases.products,
          builder: (context, products, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _purchases.isProcessing,
              builder: (context, processing, _) {
                final product = _purchases.premiumProduct;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Icon(Icons.star,
                          color: Color(0xFFE53935), size: 80),
                      const SizedBox(height: 16),
                      Text(
                        loc.get('unlock_premium'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBenefit(Icons.block, loc.get('benefit_no_ads')),
                      const SizedBox(height: 32),
                      if (!available)
                        _infoBox(loc.get('iap_unavailable'))
                      else if (product == null)
                        _infoBox(loc.get('loading_product'))
                      else
                        _buildBuyButton(loc, product, processing),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: processing
                            ? null
                            : () => _purchases.restorePurchases(),
                        child: Text(
                          loc.get('restore_purchases'),
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.get('subscription_terms'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE53935), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuyButton(
      AppLocalizations loc, ProductDetails product, bool processing) {
    return ElevatedButton(
      onPressed: processing ? null : () => _purchases.buyPremium(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE53935),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: processing
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.get('subscribe_for').replaceFirst('%s', product.price),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  loc.get('per_month'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF444466)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
