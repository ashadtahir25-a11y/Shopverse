# ShopVerse 🛍️

A full-featured, production-grade e-commerce mobile app built with **Flutter**, **Riverpod**, and **Firebase**. ShopVerse includes a complete customer shopping experience and a full-featured Admin Dashboard for managing the store — all from a single codebase.

---

## ✨ Featuressss

### Customer App
- **Onboarding & Auth** — Splash screen, onboarding flow, email/password login & registration, forgot password (Firebase Auth)
- **Home** — Live promo banner carousel, categories, featured products, best sellers, new arrivals
- **Browse & Search** — Category listings, product search, filters
- **Product Details** — Image gallery, variants, ratings, related products, reviews
- **Cart & Wishlist** — Real-time synced across devices
- **Checkout** — Saved addresses, delivery options, coupon codes, payment method selection, order placement
- **Orders** — Order history, live status tracking, cancellation, reorder
- **Reviews** — Customers can rate & review products with photos (moderated before going public)
- **Returns & Refunds** — Submit return requests with photos, track status
- **Notifications** — In-app notification center
- **Help & Support** — Submit support tickets and view replies from the support team
- **Profile & Settings** — Edit profile (with avatar upload), theme (light/dark), language (with RTL support for Urdu)

### Admin Dashboard
A responsive web/desktop-friendly dashboard (also usable on mobile) accessible to staff accounts:

| Module | Capabilities |
|---|---|
| **Dashboard** | Live stats — revenue, orders, customers, products, low stock, pending returns |
| **Products** | Full CRUD, image upload (Cloudinary), publish/draft/archive status |
| **Orders** | View all orders, update status, see full order details |
| **Categories** | Full CRUD, icon picker, subcategories, active/inactive toggle |
| **Customers** | View all accounts, assign roles (admin/manager/support/etc.), block/unblock |
| **Coupons** | Create percentage/fixed discount codes with expiry & usage rules |
| **Banners** | Manage the home screen promo carousel — presets or custom uploaded images |
| **Reviews** | Moderation queue — approve/reject/delete customer reviews |
| **Returns** | Process return requests through a full status lifecycle |
| **Support** | View and reply to customer support tickets |

Role-based access is enforced via Firestore Security Rules.

---

## 🛠️ Tech Stack

- **Framework:** Flutter 3.x / Dart 3.x
- **State Management:** [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- **Navigation:** [go_router](https://pub.dev/packages/go_router)
- **Backend:** [Firebase](https://firebase.google.com/) — Authentication, Cloud Firestore
- **Image Hosting:** [Cloudinary](https://cloudinary.com/) (unsigned upload)
- **UI:** google_fonts, flutter_animate, cached visuals via native `Image.network`, carousel_slider, flutter_rating_bar, shimmer, badges

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed ([install guide](https://docs.flutter.dev/get-started/install))
- A Firebase project (Firestore + Authentication enabled)
- A Cloudinary account (for image uploads)

### Setup

1. **Clone the repo**
   ```bash
   git clone <your-repo-url>
   cd shopverse
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Run `flutterfire configure` and select your Firebase project — this regenerates `lib/firebase_options.dart`.
   - See `firebase/FIREBASE_SETUP.md` for full setup details and `firebase/FIRESTORE_SCHEMA.md` for the data model.
   - Deploy the included security rules:
     ```bash
     firebase deploy --only firestore:rules
     ```

4. **Configure Cloudinary**
   - Update `lib/core/config/cloudinary_config.dart` with your cloud name and unsigned upload preset, **or** pass them at run time:
     ```bash
     flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Setting up the first Admin account
New accounts default to the `customer` role. To grant the first admin:
1. Register a normal account in the app.
2. In the Firebase Console → Firestore → `users/{uid}`, set `role` to `admin`.
3. Log back in — the Profile screen will now show **Admin Dashboard**.
4. From there, you can promote other users to admin/staff roles directly from **Admin → Customers**, without touching the Firebase Console again.

See `firebase/ADMIN_SETUP.md` for details.

---

## 📁 Project Structure

```
lib/
  core/              # Theme, routing, shared widgets, config, Firebase/Cloudinary services
  features/
    splash/          # Splash & app bootstrap
    onboarding/
    auth/            # Login, register, forgot password
    home/            # Home screen, banners, categories preview
    categories/
    product/         # Listing, details, search
    cart/
    wishlist/
    checkout/        # Address, coupons, payment, order confirmation
    orders/          # Order history & tracking
    returns/
    reviews/
    notifications/
    settings/
    support/         # Help center & support tickets
    profile/
    admin/           # Full admin dashboard — providers, screens, widgets per module
firebase/
  firestore.rules     # Security rules
  FIRESTORE_SCHEMA.md
  ADMIN_SETUP.md
  FIREBASE_SETUP.md
```

---

## 🗺️ Roadmap

- [ ] Payment gateway integration (currently supports Cash on Delivery / card selection without live payment processing)
- [ ] Backend order validation layer (server-side price/stock/coupon re-validation before order confirmation)
- [ ] Automated testing
- [ ] Store deployment (Google Play / App Store)

---

## 📄 License

This project is private/proprietary unless you choose to license it otherwise.
