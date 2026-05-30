# Configuración de Compras In-App (Suscripción Premium)

Esta app integra la suscripción **Domino Score Premium** (mensual) que elimina
los anuncios de AdMob.

- **ID del producto (Google Play y App Store):** `domino_premium_monthly`
- **Tipo:** Suscripción auto-renovable (mensual)
- **Librería:** [`in_app_purchase`](https://pub.dev/packages/in_app_purchase) oficial

## 1. Instalar dependencias

```bash
flutter pub get
```

## 2. Google Play Console

1. Subí un **release build firmado** (mínimo a la pista **Internal testing**)
   para que Play registre el `applicationId` `com.ccdevllc.dominoapuntes`.
2. En **Monetize → Products → Subscriptions** creá una suscripción:
   - Product ID: `domino_premium_monthly`
   - Nombre: *Domino Score Premium*
   - Período de facturación: **1 mes** (P1M)
   - Precio: el que definas (Play lo localiza automáticamente)
   - Activala (estado **Active**)
3. En **Setup → License testing** agregá los emails de prueba para comprar sin
   cobro real. Usá una cuenta que **no** sea el dueño de la consola.
4. El plugin agrega automáticamente el permiso `com.android.vending.BILLING`
   al `AndroidManifest.xml` final. No hace falta editarlo a mano.

> Pruebas: instalá la app desde la pista de testing (URL de opt-in) con la
> cuenta agregada como License tester. Las compras de prueba aparecen como
> reales pero no se cobran.

## 3. App Store Connect

1. **Agreements, Tax, and Banking:** activá el contrato de **Paid Apps**
   antes que cualquier compra funcione.
2. En **App Store Connect → tu app → Subscriptions** creá un grupo de
   suscripción (por ejemplo `domino_premium`) y dentro:
   - Product ID: `domino_premium_monthly`
   - Reference name: *Domino Premium Monthly*
   - Duración: **1 mes**
   - Precio y localizaciones
   - Subí los textos legales y la descripción
3. Creá un **Sandbox Tester** en **Users and Access → Sandbox Testers** y
   usá ese email en el iPhone (Settings → App Store → Sandbox Account) para
   probar sin cobro.

> En iOS la app **debe** ofrecer botón de "Restaurar compras" (ya incluido en
> la pantalla Premium) y mostrar términos de renovación automática (incluido
> en el texto `subscription_terms`).

## 4. Cambiar el Product ID (opcional)

Si querés un ID distinto a `domino_premium_monthly`, editá la constante en:

```
lib/services/purchase_service.dart
  → static const String premiumMonthlyId = '...';
```

El mismo ID debe coincidir en Google Play y App Store Connect.

## 5. Validación

Estado actual: **validación local** (la app guarda `is_premium: true` en
`SharedPreferences` cuando el stream entrega `PurchaseStatus.purchased` o
`restored`).

> Esto es suficiente para empezar pero un usuario técnico podría editar
> los `SharedPreferences` en un dispositivo rooteado. Para validación
> antifraude robusta hay que validar los recibos en un backend
> (`purchase.verificationData.serverVerificationData` contra Google Play
> Developer API / Apple App Store Server API). No está implementado.

## 6. Probar en desarrollo

1. **Android:** subí un build a Internal testing, instalalo en un dispositivo
   con la cuenta License tester y abrí la pantalla Premium.
2. **iOS:** corré la app firmada con un perfil de provisioning real y la cuenta
   de Sandbox configurada en Ajustes.
3. **No funciona en emuladores sin Play Services / en el simulador iOS**.

## 7. Comportamiento en la app

- Botón "Premium" en el bottom bar → abre `PremiumScreen` (paywall).
- Compra exitosa → `PurchaseService.isPremium` pasa a `true`, se persiste y
  los banners + intersticiales dejan de cargarse.
- "Restaurar compras" → consulta a la tienda y re-aplica el estado premium si
  el usuario ya está suscrito (cambio de dispositivo, reinstalación).
- Al iniciar la app se llama a `restorePurchases()` automáticamente para
  recuperar el estado de iOS (donde las compras no quedan localmente tras
  reinstalar).
