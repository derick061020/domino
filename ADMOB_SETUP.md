# Configuración de AdMob para Domino Score

## 📱 Anuncios Implementados

### 1. **Banner (No Intrusivo)**
- **Ubicación**: Parte inferior de la pantalla principal
- **Tamaño**: 320x50px (Banner estándar)
- **Comportamiento**: Siempre visible pero discreto

### 2. **Intersticial**
- **Ubicación**: Se muestra cuando termina una partida
- **Comportamiento**: Solo aparece después de que un juego alcanza el límite de puntos
- **Frecuencia**: Máximo 1 por partida completada

## 🔧 Configuración Actual

### IDs de Anuncios (Configurados)
```dart
// ID de Aplicación
ca-app-pub-4159428003190645~6649118101

// Banner
ca-app-pub-4159428003190645/3678394311

// Intersticial  
ca-app-pub-4159428003190645/2365312640
```

## ✅ Configuración Completada

### **Plataformas Configuradas:**

#### ✅ **Android**
- ID de aplicación configurado en `AndroidManifest.xml`
- IDs de anuncios configurados en `admob_service.dart`

#### ✅ **iOS**
- ID de aplicación configurado en `Info.plist`
- IDs de anuncios configurados en `admob_service.dart`

#### ✅ **Web**
- Script de AdMob configurado en `index.html`
- IDs de anuncios configurados en `admob_service.dart`

#### ✅ **Flutter**
- Servicio AdMob implementado
- Banner e intersticial integrados
- Manejo de errores y lifecycle

### 4. **Probar en Dispositivo Real**
```bash
flutter run
```

## 📋 Mejores Prácticas

### ✅ **Lo que está bien implementado:**
- Anuncios no intrusivos
- Banner pequeño y discreto
- Intersticial solo al finalizar partidas
- Manejo de errores
- Limpieza de recursos

### 🎯 **Recomendaciones:**
1. **Usa IDs de prueba** durante desarrollo
2. **Prueba en dispositivos reales** antes de publicar
3. **Monitorea el rendimiento** en AdMob Console
4. **Considera anuncios rewarded** para características premium

## 🔍 Solución de Problemas

### "No se cargan los anuncios"
- Verifica conexión a internet
- Confirma que los IDs son correctos
- Revisa que AdMob esté aprobado para tu app

### "Error en Web"
- Asegúrate que el script cargue correctamente
- Verifica la consola del navegador
- Confirma que no haya bloqueadores de anuncios

## 📊 Monetización

### Estrategia Implementada:
- **Banner**: Ingresos pasivos constantes
- **Intersticial**: Ingresos adicionales por partidas completadas
- **Balance**: No afecta negativamente la experiencia del usuario

### Próximos Mejoras (Opcional):
- Anuncios rewarded para desbloquear fondos premium
- Anuncios nativos para integración más fluida
- Segmentación por región para mejores eCPM

---

## 🚨 Importante

- **NO uses IDs de producción en desarrollo**
- **SÍGUETE las políticas de AdMob**
- **TESTEA exhaustivamente antes de publicar**
- **MONITOREA el rendimiento regularmente**

Para soporte adicional, consulta la [documentación oficial de AdMob](https://developers.google.com/admob/flutter/overview).
