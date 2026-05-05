# 🚨 Diagnóstico de Anuncios AdMob

## 🔍 **Problema: Los anuncios no se muestran**

### **Posibles Causas Identificadas:**

#### 1. **⚠️ IDs de Anuncio Incorrectos**
Estás usando el mismo ID (`ca-app-pub-4159428003190645/6649118101`) para:
- Banner
- Intersticial  
- Web
- Android
- iOS

**❌ ESTO ES INCORRECTO**

Cada tipo de anuncio necesita su propio ID único.

#### 2. **🔧 Configuración Actual (Temporal)**
He revertido a IDs de prueba para que funcione:
- **Banner**: `ca-app-pub-3940256099942544/6300978111`
- **Intersticial**: `ca-app-pub-3940256099942544/8691691433`

## 📋 **Pasos para Solucionar:**

### **Paso 1: Crear IDs Correctos en AdMob**
1. Ve a [AdMob Console](https://apps.admob.com)
2. Selecciona tu app: `Domino Apunte Score`
3. Crea **dos unidades de anuncio**:

#### **Para Banner:**
- Nombre: "Banner Principal"
- Formato: Banner
- Obtendrás un ID como: `ca-app-pub-4159428003190645/XXXXXXXXXX`

#### **Para Intersticial:**
- Nombre: "Intersticial Fin Juego"  
- Formato: Intersticial
- Obtendrás un ID como: `ca-app-pub-4159428003190645/YYYYYYYYYY`

### **Paso 2: Actualizar los IDs**
Edita `lib/services/admob_service.dart`:

```dart
static String get _bannerAdUnitId {
  if (kIsWeb) {
    return 'TU_BANNER_WEB_ID';
  } else if (Platform.isAndroid) {
    return 'TU_BANNER_ANDROID_ID';
  } else {
    return 'TU_BANNER_IOS_ID';
  }
}

static String get _interstitialAdUnitId {
  if (kIsWeb) {
    return 'TU_INTERSTITIAL_WEB_ID';
  } else if (Platform.isAndroid) {
    return 'TU_INTERSTITIAL_ANDROID_ID';
  } else {
    return 'TU_INTERSTITIAL_IOS_ID';
  }
}
```

## 🧪 **Pruebas Inmediatas:**

### **Para Ver si Funciona:**
```bash
flutter run
```

Luego revisa la consola/debug para ver:
- `Iniciando AdMob...`
- `AdMob inicializado correctamente`
- `Cargando anuncio banner con ID: ca-app-pub-3940256099942544/6300978111`
- `✅ Anuncio banner cargado` o `❌ Error...`

### **Para Web Específicamente:**
1. Abre las herramientas de desarrollador del navegador (F12)
2. Ve a la pestaña Console
3. Busca errores relacionados con anuncios
4. Verifica que no haya bloqueadores de anuncios activos

## 🔍 **Verificación Rápida:**

### **Revisa estos puntos:**

#### ✅ **¿Se inicializa AdMob?**
- Busca: "Iniciando AdMob..." en los logs

#### ✅ **¿Se cargan los anuncios?**
- Busca: "Anuncio banner cargado" 
- Busca: "Anuncio intersticial cargado"

#### ✅ **¿Hay errores en consola?**
- Busca: "Error al cargar anuncio"

#### ✅ **¿El banner aparece en UI?**
- Deberías ver un espacio de 50px en la parte inferior
- Si está vacío, el anuncio no cargó

## 🚨 **Si aún no funciona:**

### **Opción A: Mantener Pruebas**
Usa los IDs de prueba actuales para desarrollo:
- ✅ Funcionan inmediatamente
- ✅ Sin riesgo de suspensión
- ✅ Ideales para testing

### **Opción B: Debug Avanzado**
Agrega más logging en `game_screen.dart`:

```dart
@override
void initState() {
  super.initState();
  _currentGame = widget.game;
  _loadBackground();
  
  // Debug AdMob
  debugPrint('🔍 Iniciando carga de anuncios...');
  _adMobService.loadBannerAd();
  _adMobService.loadInterstitialAd();
  
  // Verificar después de 2 segundos
  Future.delayed(Duration(seconds: 2), () {
    debugPrint('🔍 Banner widget: ${_adMobService.getBannerAdWidget() != null ? "CARGADO" : "NULL"}');
    debugPrint('🔍 Intersticial listo: ${_adMobService.isInterstitialAdReady}');
  });
}
```

## 📱 **Recordatorio Importante:**

- **Cada tipo de anuncio = ID único**
- **Cada plataforma = ID específico** (opcional pero recomendado)
- **Usa IDs de prueba en desarrollo**
- **Verifica consola para errores**

---

## 🎯 **Próxima Acción:**

1. **Prueba con IDs actuales** (deben funcionar)
2. **Si funcionan**, crea tus IDs reales en AdMob Console
3. **Reemplaza los IDs** en el código
4. **Prueba nuevamente**

Los IDs de prueba deberían mostrar anuncios inmediatamente. Si no aparecen, el problema está en otro lado.
