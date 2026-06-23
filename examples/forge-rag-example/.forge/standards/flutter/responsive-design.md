# Flutter Responsive Design Standard

## Breakpoints

| Name | Width range | Target devices |
|---|---|---|
| Mobile | < 600 dp | Phones |
| Tablet | 600 – 900 dp | Tablets, large phones, small laptops |
| Desktop | > 900 dp | Laptops, desktops, web |

```dart
// lib/core/responsive/breakpoints.dart
abstract class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static ScreenSize screenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobile) return ScreenSize.mobile;
    if (width < tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }
}

enum ScreenSize { mobile, tablet, desktop }
```

---

## LayoutBuilder vs MediaQuery

- Use **`LayoutBuilder`** when you need to respond to the constraints of a specific parent widget (e.g., a card that behaves differently inside a narrow column vs. a wide grid).
- Use **`MediaQuery.sizeOf(context)`** when you need the overall screen size (e.g., deciding which navigation pattern to use at the app level).

```dart
// LayoutBuilder: responds to parent constraints, not screen size
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 300) {
      return const CompactProductCard();
    }
    return const ExpandedProductCard();
  },
)

// MediaQuery: top-level layout decision
Widget build(BuildContext context) {
  return Breakpoints.isDesktop(context)
      ? const DesktopLayout()
      : const MobileLayout();
}
```

---

## Adaptive Navigation

The navigation pattern changes based on screen width.

```dart
// lib/core/responsive/adaptive_scaffold.dart
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.body,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  final List<AdaptiveDestination> destinations;
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    final size = Breakpoints.screenSize(context);

    return switch (size) {
      ScreenSize.mobile => _buildMobileScaffold(),
      ScreenSize.tablet => _buildTabletScaffold(),
      ScreenSize.desktop => _buildDesktopScaffold(),
    };
  }

  // Mobile: BottomNavigationBar
  Widget _buildMobileScaffold() {
    return Scaffold(
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: widget.destinations.map((d) => NavigationDestination(
          icon: d.icon,
          selectedIcon: d.selectedIcon,
          label: d.label,
        )).toList(),
      ),
    );
  }

  // Tablet: NavigationRail (collapsed)
  Widget _buildTabletScaffold() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected ?? (_) {},
            extended: false,
            destinations: widget.destinations.map((d) => NavigationRailDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: Text(d.label),
            )).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  // Desktop: NavigationDrawer (always open)
  Widget _buildDesktopScaffold() {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected ?? (_) {},
            children: [
              const DrawerHeader(child: AppLogo()),
              ...widget.destinations.map((d) => NavigationDrawerDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              )),
            ],
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}
```

---

## Grid and Column Layouts

```dart
// Adaptive grid: 1 column on mobile, 2 on tablet, 3+ on desktop
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          < 600 => 1,
          < 900 => 2,
          < 1200 => 3,
          _ => 4,
        };

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}
```

---

## Content Width Constraints

On wide screens, constrain content width to remain readable.

```dart
// lib/core/responsive/constrained_content.dart
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
```

---

## Adaptive Spacing

```dart
// lib/core/responsive/adaptive_spacing.dart
extension AdaptiveSpacingX on BuildContext {
  double get horizontalPadding => switch (Breakpoints.screenSize(this)) {
    ScreenSize.mobile => 16.0,
    ScreenSize.tablet => 24.0,
    ScreenSize.desktop => 32.0,
  };

  double get verticalSpacing => switch (Breakpoints.screenSize(this)) {
    ScreenSize.mobile => 12.0,
    ScreenSize.tablet => 16.0,
    ScreenSize.desktop => 24.0,
  };
}

// Usage
Padding(
  padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
  child: content,
)
```

---

## Orientation Changes

State must survive orientation changes. Never use `orientation` to store data.

```dart
// Bad: data lost on rotation if widget is rebuilt from scratch
class _MyState extends State<MyPage> {
  List<Item> loadedItems = []; // lost on rotation if widget is replaced

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    return isLandscape ? LandscapeLayout(items: loadedItems) : PortraitLayout(items: loadedItems);
  }
}

// Good: BLoC or state management holds data; widget only chooses layout
BlocBuilder<ItemsBloc, ItemsState>(
  builder: (context, state) {
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    return isLandscape
        ? LandscapeLayout(items: state.items)
        : PortraitLayout(items: state.items);
  },
)
```

---

## Touch Targets

```dart
// Minimum 48x48 dp for all interactive elements on mobile
// Minimum 36x36 dp on desktop (pointer-based input)

// Use SizedBox to enforce minimum touch target
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: const Icon(Icons.close, size: 24),
    onPressed: _close,
    padding: EdgeInsets.zero,
  ),
)

// Or MaterialTapTargetSize globally in theme
ThemeData(
  materialTapTargetSize: MaterialTapTargetSize.padded, // enforces 48dp
)
```

---

## Testing Three Breakpoints

```dart
// test/responsive/adaptive_scaffold_test.dart
const mobileSize = Size(375, 812);    // iPhone SE
const tabletSize = Size(768, 1024);   // iPad
const desktopSize = Size(1440, 900);  // MacBook

void main() {
  for (final (size, expectedNav) in [
    (mobileSize, find.byType(NavigationBar)),
    (tabletSize, find.byType(NavigationRail)),
    (desktopSize, find.byType(NavigationDrawer)),
  ]) {
    testWidgets('shows correct navigation at ${size.width}w', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const AppShell());
      expect(expectedNav, findsOneWidget);
    });
  }
}
```

---

## Rules

- **Never hardcode pixel sizes**: use `Breakpoints`, `LayoutBuilder`, or theme spacing tokens
- **Text scales with system settings**: never fix `textScaleFactor`; test at 150% and 200% scale
- **Touch targets minimum 48 dp on mobile, 36 dp on desktop**
- **Test all three breakpoints for every screen**: use the three size constants above
- **Orientation change must not lose state**: keep data in BLoC/state management
- **Use `MediaQuery.sizeOf(context)` not `MediaQuery.of(context).size`**: avoids full rebuilds on unrelated changes
- **Use `EdgeInsetsDirectional` and `AlignmentDirectional`**: ensures correct RTL behavior at all widths
- **Constrain maximum content width on desktop**: use `ConstrainedContent` wrapper for text-heavy layouts
