import '../categories/category_model.dart';
import '../product/models/product_model.dart';

/// Mock/seed data layer. Used as: (1) the source for the one-time
/// Firestore seeder (see lib/core/data/seed_service.dart), and (2) an
/// automatic fallback in productsProvider/categoriesProvider whenever
/// Firebase isn't configured yet or Firestore is still empty — so the app
/// is always demonstrable, never a blank screen.

const List<ProductCategory> mockCategories = [
  ProductCategory(
    id: 'electronics',
    name: 'Electronics',
    iconKey: 'electronics',
    subcategories: ['Mobile Phones', 'Laptops', 'Headphones', 'Smart Watches'],
  ),
  ProductCategory(
    id: 'fashion',
    name: 'Fashion',
    iconKey: 'fashion',
    subcategories: ['Men', 'Women', 'Kids', 'Accessories'],
  ),
  ProductCategory(
    id: 'shoes',
    name: 'Shoes',
    iconKey: 'shoes',
    subcategories: ['Sneakers', 'Formal', 'Sports', 'Sandals'],
  ),
  ProductCategory(
    id: 'beauty',
    name: 'Beauty',
    iconKey: 'beauty',
    subcategories: ['Skincare', 'Makeup', 'Fragrance', 'Hair Care'],
  ),
  ProductCategory(
    id: 'home',
    name: 'Home',
    iconKey: 'home',
    subcategories: ['Furniture', 'Decor', 'Kitchen', 'Lighting'],
  ),
  ProductCategory(
    id: 'accessories',
    name: 'Accessories',
    iconKey: 'accessories',
    subcategories: ['Bags', 'Jewelry', 'Belts', 'Sunglasses'],
  ),
];

final List<Product> mockProducts = [
  Product(
    id: 'p1',
    name: 'AeroFit Wireless Headphones',
    brand: 'SoundWave',
    sku: 'SW-AERO-BLK',
    category: 'electronics',
    images: const ['headphones_1', 'headphones_2'],
    price: 8999,
    originalPrice: 12999,
    rating: 4.6,
    reviewCount: 342,
    stock: 24,
    isFeatured: true,
    isBestSeller: true,
    description:
        'Immersive sound with active noise cancellation and 30-hour battery life. Designed for all-day comfort with plush memory-foam ear cushions.',
    variants: const [
      VariantAttribute(
        name: 'Color',
        options: [
          VariantOption(id: 'blk', label: 'Black', colorHex: '#1A1A2E'),
          VariantOption(id: 'wht', label: 'White', colorHex: '#FFFFFF'),
          VariantOption(id: 'blu', label: 'Blue', colorHex: '#3E9DFF'),
        ],
      ),
    ],
  ),
  Product(
    id: 'p2',
    name: 'Nova X1 Smartphone 128GB',
    brand: 'Nova',
    sku: 'NOVA-X1-128',
    category: 'electronics',
    images: const ['phone_1', 'phone_2'],
    price: 64999,
    originalPrice: 71999,
    rating: 4.8,
    reviewCount: 891,
    stock: 12,
    isFeatured: true,
    isNewArrival: true,
    description:
        'A flagship-grade smartphone with a 6.7" AMOLED display, triple camera system, and all-day battery life.',
    variants: const [
      VariantAttribute(
        name: 'Color',
        options: [
          VariantOption(
            id: 'blk',
            label: 'Midnight Black',
            colorHex: '#1A1A2E',
          ),
          VariantOption(id: 'slv', label: 'Silver', colorHex: '#C9C9D6'),
        ],
      ),
      VariantAttribute(
        name: 'Storage',
        options: [
          VariantOption(id: '128', label: '128GB'),
          VariantOption(id: '256', label: '256GB'),
        ],
      ),
    ],
  ),
  Product(
    id: 'p3',
    name: 'Classic Leather Sneakers',
    brand: 'Urbanix',
    sku: 'URB-SNK-WHT',
    category: 'shoes',
    images: const ['shoes_1', 'shoes_2'],
    price: 5499,
    rating: 4.4,
    reviewCount: 156,
    stock: 40,
    isBestSeller: true,
    description:
        'Handcrafted leather sneakers with a cushioned sole for everyday comfort and timeless style.',
    variants: const [
      VariantAttribute(
        name: 'Size',
        options: [
          VariantOption(id: '40', label: '40'),
          VariantOption(id: '41', label: '41'),
          VariantOption(id: '42', label: '42'),
          VariantOption(id: '43', label: '43'),
        ],
      ),
    ],
  ),
  Product(
    id: 'p4',
    name: 'Minimalist Chronograph Watch',
    brand: 'Chronotime',
    sku: 'CT-CHR-GLD',
    category: 'accessories',
    images: const ['watch_1'],
    price: 15999,
    originalPrice: 19999,
    rating: 4.7,
    reviewCount: 210,
    stock: 8,
    isFeatured: true,
    description:
        'A refined chronograph watch with a sapphire-coated dial and genuine leather strap.',
    variants: const [
      VariantAttribute(
        name: 'Color',
        options: [
          VariantOption(id: 'gld', label: 'Gold', colorHex: '#D4AF37'),
          VariantOption(id: 'slv', label: 'Silver', colorHex: '#C9C9D6'),
        ],
      ),
    ],
  ),
  Product(
    id: 'p5',
    name: 'Radiance Vitamin C Serum',
    brand: 'GlowLab',
    sku: 'GL-VITC-30',
    category: 'beauty',
    images: const ['serum_1'],
    price: 2499,
    rating: 4.5,
    reviewCount: 528,
    stock: 60,
    isNewArrival: true,
    isBestSeller: true,
    description:
        'A lightweight, fast-absorbing serum that brightens skin tone and reduces the look of dark spots.',
  ),
  Product(
    id: 'p6',
    name: 'Everyday Canvas Tote Bag',
    brand: 'FieldNote',
    sku: 'FN-TOTE-BEI',
    category: 'accessories',
    images: const ['bag_1'],
    price: 3299,
    originalPrice: 3999,
    rating: 4.3,
    reviewCount: 87,
    stock: 35,
    isNewArrival: true,
    description:
        'A durable, spacious canvas tote built for daily errands and weekend trips alike.',
    variants: const [
      VariantAttribute(
        name: 'Color',
        options: [
          VariantOption(id: 'bei', label: 'Beige', colorHex: '#D8CBB8'),
          VariantOption(id: 'blk', label: 'Black', colorHex: '#1A1A2E'),
        ],
      ),
    ],
  ),
  Product(
    id: 'p7',
    name: 'AirFlow Running Jacket',
    brand: 'Urbanix',
    sku: 'URB-JKT-NVY',
    category: 'fashion',
    images: const ['jacket_1'],
    price: 6799,
    rating: 4.2,
    reviewCount: 64,
    stock: 22,
    isBestSeller: true,
    description:
        'Lightweight, water-resistant running jacket with breathable mesh lining.',
    variants: const [
      VariantAttribute(
        name: 'Size',
        options: [
          VariantOption(id: 's', label: 'S'),
          VariantOption(id: 'm', label: 'M'),
          VariantOption(id: 'l', label: 'L'),
          VariantOption(id: 'xl', label: 'XL'),
        ],
      ),
    ],
  ),
  Product(
    id: 'p8',
    name: 'Ceramic Table Lamp',
    brand: 'Homestead',
    sku: 'HS-LAMP-WHT',
    category: 'home',
    images: const ['lamp_1'],
    price: 4499,
    originalPrice: 5299,
    rating: 4.6,
    reviewCount: 41,
    stock: 15,
    isNewArrival: true,
    description:
        'A handcrafted ceramic table lamp that adds warmth and texture to any room.',
  ),
];
