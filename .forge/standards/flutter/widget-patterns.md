# Widget Patterns

## Composition Over Inheritance

Flutter's widget system is built for composition. Prefer combining small, focused widgets to building large widgets that do everything. Never extend application widgets via class inheritance — compose them.

```dart
// WRONG — inheritance to add behavior
class RoundedCard extends Card {
  // Never do this — Flutter's widget API is not designed for inheritance
}

// CORRECT — composition
class RoundedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const RoundedCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? context.theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
```

---

## The Three Widget Categories

Every widget in the application belongs to exactly one of three categories. This categorization determines what the widget is allowed to do.

### Category 1: Presentational Widgets

**What they are:** Pure display. They receive all their data through constructor parameters and report user interactions via callbacks. They know nothing about BLoC, repositories, or state management.

**Rules:**
- No BLoC access. No `context.read<>()`. No `BlocBuilder`.
- All data comes in as parameters.
- User interactions go out as callbacks (`onTap`, `onChanged`, etc.).
- Always `const`-constructible where possible.
- Golden tests are mandatory for all presentational widgets.

```dart
// lib/features/products/presentation/widgets/product_tile.dart

class ProductTile extends StatelessWidget {
  final Product product;
  final bool isInCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductTile({
    super.key,
    required this.product,
    required this.isInCart,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('productTile_${product.id.value}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(imageUrl: product.imageUrl),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: context.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price.formatted,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AddToCartButton(
                    isInCart: isInCart,
                    onTap: onAddToCart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _ImagePlaceholder(),
                errorWidget: (_, __, ___) => const _ImageError(),
              )
            : const _ImagePlaceholder(),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final bool isInCart;
  final VoidCallback onTap;

  const _AddToCartButton({required this.isInCart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: isInCart ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isInCart ? Icons.check : Icons.add_shopping_cart, size: 18),
          const SizedBox(width: 4),
          Text(isInCart ? 'In Cart' : 'Add to Cart'),
        ],
      ),
    );
  }
}
```

**Golden Test for Presentational Widget:**

```dart
// test/features/products/presentation/widgets/product_tile_test.dart

import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('ProductTile golden tests', () {
    final product = Product(
      id: ProductId('test-1'),
      name: 'Test Product',
      price: Price.fromCents(2999),
      imageUrl: null,
    );

    testGoldens('renders default state', (tester) async {
      await tester.pumpWidgetBuilder(
        ProductTile(
          product: product,
          isInCart: false,
          onTap: () {},
          onAddToCart: () {},
        ),
        wrapper: materialAppWrapper(),
      );
      await screenMatchesGolden(tester, 'product_tile_default');
    });

    testGoldens('renders in-cart state', (tester) async {
      await tester.pumpWidgetBuilder(
        ProductTile(
          product: product,
          isInCart: true,
          onTap: () {},
          onAddToCart: () {},
        ),
        wrapper: materialAppWrapper(),
      );
      await screenMatchesGolden(tester, 'product_tile_in_cart');
    });

    testGoldens('renders across device sizes', (tester) async {
      await tester.pumpWidgetBuilder(
        ProductTile(
          product: product,
          isInCart: false,
          onTap: () {},
          onAddToCart: () {},
        ),
        wrapper: materialAppWrapper(),
      );
      await multiScreenGolden(tester, 'product_tile_responsive');
    });
  });
}
```

---

### Category 2: Container Widgets

**What they are:** The bridge between the state layer and the display layer. Container widgets connect to BLoC, transform state into presentational data, and route user events back to BLoC. They contain no layout code.

**Rules:**
- Connected to exactly one BLoC (or read from multiple via `BlocSelector`).
- No visual layout code — delegates all display to presentational widgets.
- Translates BLoC state → widget parameters.
- Translates user callbacks → BLoC events.
- May contain `BlocListener` for side effects (navigation, snackbars).

```dart
// lib/features/products/presentation/widgets/product_list_container.dart

class ProductListContainer extends StatelessWidget {
  const ProductListContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      listenWhen: (_, current) => current is ProductStateError,
      listener: (context, state) {
        if (state case ProductStateError(:final failure)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.userMessage)),
          );
        }
      },
      builder: (context, state) => switch (state) {
        ProductStateLoading() => const ProductListSkeleton(),
        ProductStateLoaded(:final products, :final isLoadingMore) =>
            ProductListView(
              products: products,
              isLoadingMore: isLoadingMore,
              onProductTap: (product) =>
                  context.go('/products/${product.id.value}'),
              onAddToCart: (product) => context
                  .read<CartBloc>()
                  .add(CartItemAdded(productId: product.id)),
              onLoadMore: () =>
                  context.read<ProductBloc>().add(const NextPageRequested()),
            ),
        ProductStateEmpty(:final currentQuery) =>
            EmptyStateView(
              message: currentQuery != null
                  ? 'No products found for "$currentQuery"'
                  : 'No products available',
            ),
        ProductStateError(:final failure) =>
            ErrorView(
              failure: failure,
              onRetry: () =>
                  context.read<ProductBloc>().add(const ProductsRequested()),
            ),
        ProductStateInitial() => const SizedBox.shrink(),
      },
    );
  }
}
```

---

### Category 3: Page Widgets

**What they are:** The entry point for a route. Pages set up the BLoC scope for the feature, trigger initial data loading, and compose the scaffold structure. They are routed to directly by the router.

**Rules:**
- One per route.
- Creates and provides the BLoC for the feature (via `BlocProvider`).
- Triggers initial events in the BLoC (e.g., `ProductsRequested`).
- Composes the page layout (AppBar, body, FAB, etc.) using container and presentational widgets.
- Does not contain complex display logic — delegates to containers.

```dart
// lib/features/products/presentation/pages/products_page.dart

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductBloc>()..add(const ProductsRequested()),
      child: const _ProductsPageView(),
    );
  }
}

class _ProductsPageView extends StatelessWidget {
  const _ProductsPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: const [
          _CartIconButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SearchField(),
          ),
        ),
      ),
      body: const ProductListContainer(),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartBloc, CartState, int>(
      selector: (state) => state.maybeWhen(
        loaded: (cart) => cart.itemCount,
        orElse: () => 0,
      ),
      builder: (context, itemCount) => Badge(
        count: itemCount,
        isLabelVisible: itemCount > 0,
        child: IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: 'Search products...',
      onChanged: (query) =>
          context.read<ProductBloc>().add(SearchQueryChanged(query)),
    );
  }
}
```

---

## Keys

Keys tell Flutter when to preserve vs replace widget state across rebuilds. Use them correctly.

### When to Use Keys

```dart
// ValueKey — when the identity of an item is a simple value
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) => ProductTile(
    key: ValueKey(products[index].id.value), // Correct: stable, unique identity
    product: products[index],
    // ...
  ),
)

// ObjectKey — when the identity is an object
// Useful when the object's == is already correct
ListView.builder(
  itemBuilder: (context, index) => OrderCard(
    key: ObjectKey(orders[index]), // Uses Order's == (which is id-based)
    order: orders[index],
    // ...
  ),
)

// GlobalKey — for accessing state across widget tree (use sparingly)
// Valid uses: form key, scaffold key, animation key
final _formKey = GlobalKey<FormState>();
Form(key: _formKey, child: ...)
```

### Never Use Index as Key

```dart
// WRONG — index as key causes incorrect animations and state retention
ListView.builder(
  itemBuilder: (context, index) => DismissibleItem(
    key: Key('item-$index'),  // When item is deleted, wrong state is retained
    item: items[index],
  ),
)

// CORRECT — use the item's stable identity
ListView.builder(
  itemBuilder: (context, index) => DismissibleItem(
    key: ValueKey(items[index].id),  // State is correctly tied to this specific item
    item: items[index],
  ),
)
```

---

## Const Everything

`const` widgets are never rebuilt unless their parameters change. Use `const` aggressively.

```dart
// Every constructor call that can be const, must be const
@override
Widget build(BuildContext context) {
  return const Scaffold(        // const — Scaffold is always the same
    body: Center(               // const — never changes
      child: Column(            // const — never changes
        children: [
          Text('Hello'),        // const — static string
          SizedBox(height: 16), // const — never changes
          CircularProgressIndicator(), // const
        ],
      ),
    ),
  );
}

// Class-level const
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});  // const constructor

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// Usage is const too
child: const LoadingIndicator()  // Zero rebuild cost
```

---

## Golden Tests — Mandatory for Presentational Widgets

Every presentational widget must have golden tests. No exceptions. Golden tests catch accidental visual regressions that unit tests cannot detect.

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  golden_toolkit: ^0.15.0
```

```dart
// flutter_test_config.dart (in test/ directory)
import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    testMain,
    config: GoldenToolkitConfiguration(
      enableRealShadows: true,
      defaultDevices: [
        Device.phone,
        Device.iphone11,
        Device.tabletLandscape,
      ],
    ),
  );
}
```

### Pattern

```dart
// Always test:
// 1. Default/initial state
// 2. All significant visual states
// 3. Multiple device sizes (for responsive widgets)
// 4. Dark mode (if the app supports it)

testGoldens('SignInForm golden tests', (tester) async {
  await loadAppFonts(); // Load real fonts for accurate golden

  // Default state
  await tester.pumpWidgetBuilder(
    const SignInForm(isLoading: false, onSubmit: null),
    wrapper: materialAppWrapper(theme: AppTheme.light),
    surfaceSize: Device.phone.size,
  );
  await screenMatchesGolden(tester, 'sign_in_form/default');

  // Loading state
  await tester.pumpWidgetBuilder(
    const SignInForm(isLoading: true, onSubmit: null),
    wrapper: materialAppWrapper(theme: AppTheme.light),
    surfaceSize: Device.phone.size,
  );
  await screenMatchesGolden(tester, 'sign_in_form/loading');

  // Dark mode
  await tester.pumpWidgetBuilder(
    const SignInForm(isLoading: false, onSubmit: null),
    wrapper: materialAppWrapper(theme: AppTheme.dark),
    surfaceSize: Device.phone.size,
  );
  await screenMatchesGolden(tester, 'sign_in_form/dark');
});
```

### Updating Goldens

```bash
# Update goldens when UI intentionally changes
flutter test --update-goldens

# Review changed goldens in git diff before committing
git diff test/goldens/
```
