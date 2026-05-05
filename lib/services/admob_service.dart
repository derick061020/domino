import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // IDs de anuncios reales proporcionados por el usuario
  static String get _bannerAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-4159428003190645/6649118101';  // Web banner
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-4159428003190645/6649118101';  // Android banner
    } else {
      return 'ca-app-pub-4159428003190645/6649118101';  // iOS banner
    }
  }

  static String get _interstitialAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-4159428003190645/6649118101';  // Web interstitial
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-4159428003190645/6649118101';  // Android interstitial
    } else {
      return 'ca-app-pub-4159428003190645/6649118101';  // iOS interstitial
    }
  }

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // Inicializar AdMob
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      
      // Configurar el modo de prueba para desarrollo
      if (kDebugMode) {
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: ['YOUR_DEVICE_ID_HERE']),
        );
      }
    } catch (e) {
      debugPrint('Error inicializando AdMob: $e');
    }
  }

  // Crear anuncio banner
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Anuncio banner cargado');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Error al cargar anuncio banner: $error');
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('Anuncio banner abierto'),
        onAdClosed: (ad) => debugPrint('Anuncio banner cerrado'),
      ),
    );
  }

  // Cargar anuncio banner
  void loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = createBannerAd();
    _bannerAd?.load();
  }

  // Obtener widget del banner
  Widget? getBannerAdWidget() {
    return _bannerAd != null ? AdWidget(ad: _bannerAd!) : null;
  }

  // Cargar anuncio intersticial
  Future<void> loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            debugPrint('Anuncio intersticial cargado');
          },
          onAdFailedToLoad: (error) {
            debugPrint('Error al cargar anuncio intersticial: $error');
            _isInterstitialAdReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error cargando anuncio intersticial: $e');
      _isInterstitialAdReady = false;
    }
  }

  // Mostrar anuncio intersticial
  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      try {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) => debugPrint('Anuncio intersticial mostrado'),
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('Anuncio intersticial cerrado');
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdReady = false;
            // Pre-cargar el siguiente anuncio
            loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('Error al mostrar anuncio intersticial: $error');
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdReady = false;
          },
        );

        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('Error mostrando anuncio intersticial: $e');
      }
    } else {
      debugPrint('Anuncio intersticial no está listo');
      // Intentar cargar uno nuevo
      loadInterstitialAd();
    }
  }

  // Liberar recursos
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }

  // Verificar si el anuncio intersticial está listo
  bool get isInterstitialAdReady => _isInterstitialAdReady;
}
