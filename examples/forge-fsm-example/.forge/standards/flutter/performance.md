# Flutter Performance Standard

## Targets

| Metric | Target |
|---|---|
| Frame rate | 60 fps steady-state, no jank |
| First meaningful paint | < 2s on mid-range device |
| Build method duration | < 16ms |
| `build()` method lines | <= 80 lines |
| Heavy operation threshold | > 1ms → move off UI thread |

---

## Build Optimization

### Use `const` Everywhere Possible

```dart
// Bad
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(16.0),
    child: Text('Hello'),
  );
}

// Good
Widget build(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: Text('Hello'),
  );
}
```

Rule: if a widget's constructor arguments are all compile-time constants, prefix with `const`.

### RepaintBoundary for Isolated Animations

```dart
// Wrap animated widgets to isolate their repaint subtree
RepaintBoundary(
  child: AnimatedProgressRing(value: progress),
)

// Also useful for frequently-updated widgets in mostly-static screens
RepaintBoundary(
  child: StreamBuilder<int>(
    stream: tickerStream,
    builder: (context, snapshot) => Text('${snapshot.data}'),
  ),
)
```

### ListView.builder for Long Lists

```dart
// Bad: materializes all children eagerly
ListView(children: items.map((i) => ItemTile(item: i)).toList())

// Good: lazy, only builds visible items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(item: items[index]),
)

// For mixed-height items with sections:
CustomScrollView(
  slivers: [
    SliverList.separated(
      itemCount: items.length,
      itemBuilder: (context, index) => ItemTile(item: items[index]),
      separatorBuilder: (_, __) => const Divider(),
    ),
  ],
)
```

### BlocSelector to Minimize Rebuilds

```dart
// Bad: entire widget rebuilds on any state change
BlocBuilder<CartBloc, CartState>(
  builder: (context, state) => Text('${state.itemCount} items'),
)

// Good: only rebuilds when itemCount changes
BlocSelector<CartBloc, CartState, int>(
  selector: (state) => state.itemCount,
  builder: (context, count) => Text('$count items'),
)
```

### buildWhen to Filter Unnecessary Rebuilds

```dart
BlocBuilder<FormBloc, FormState>(
  buildWhen: (previous, current) => previous.isSubmitting != current.isSubmitting,
  builder: (context, state) => SubmitButton(loading: state.isSubmitting),
)
```

---

## Image Performance

### CachedNetworkImage with Explicit Dimensions

```dart
// Bad: no size constraints, forces layout recalculation
Image.network(url)

// Good
CachedNetworkImage(
  imageUrl: url,
  width: 80,
  height: 80,
  fit: BoxFit.cover,
  memCacheWidth: 160, // 2x for HDPI
  memCacheHeight: 160,
  placeholder: (context, url) => const ShimmerBox(width: 80, height: 80),
  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
)
```

### WebP Format

Serve WebP instead of PNG/JPEG. WebP is 25-34% smaller for lossy and 26% smaller for lossless. Configure your CDN or use Flutter's `image` package for conversion at build time.

### Precaching Critical Images

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(const AssetImage('assets/images/onboarding_hero.webp'), context);
}
```

### Resize in Memory

```dart
// Decode at display size, not at original size
ResizeImage(
  NetworkImage(url),
  width: 160,
  height: 160,
)
```

---

## Async & Heavy Operations

### compute() for CPU-Intensive Work

```dart
// Bad: blocks UI thread
final parsed = jsonDecode(largeJsonString);

// Good: runs in a separate isolate
final parsed = await compute(jsonDecode, largeJsonString);

// For custom parsing functions:
Future<List<Product>> parseProducts(String json) async {
  return compute(_parseProductsInIsolate, json);
}

List<Product> _parseProductsInIsolate(String json) {
  final data = jsonDecode(json) as List;
  return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
}
```

### Debounce Search / Input

```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._searchUseCase) : super(SearchState.initial()) {
    on<QueryChanged>(_onQueryChanged, transformer: debounce(const Duration(milliseconds: 300)));
  }

  EventTransformer<E> debounce<E>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }
}
```

### Cancel Subscriptions on Dispose

```dart
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription<Event>? _subscription;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _subscription = eventBus.on<UserEvent>().listen(_handleEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}
```

---

## Measurement with DevTools

1. **Profile mode only**: run `flutter run --profile` or `flutter build apk --profile`. Never measure in debug mode.
2. **Timeline events**: wrap suspect sections with `Timeline.startSync` / `Timeline.finishSync` to see them in DevTools.
3. **Performance overlay**: enable via `MaterialApp(showPerformanceOverlay: true)` temporarily.
4. **CPU profiler**: record a session in DevTools → CPU Profiler, identify heavy `build()` calls.
5. **Memory profiler**: detect widget tree leaks by checking the object count over time.

```dart
// Temporary instrumentation — remove before merging
Timeline.startSync('ExpensiveWidget.build');
final result = _buildExpensiveTree();
Timeline.finishSync();
return result;
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Heavy logic in `initState` | Blocks first frame, can throw if async | Use `WidgetsBinding.instance.addPostFrameCallback` or a BLoC event |
| `setState` inside `setState` | Causes double build, potential infinite loop | Flatten state updates, use a single `setState` call |
| Uncached `FutureBuilder` | Re-fetches on every rebuild | Store Future in a field or use BLoC; never create `Future` inline |
| `build()` > 80 lines | Hard to read, sign of too much logic in UI | Extract to private widgets or methods |
| Heavy operations in `build()` | Runs on every frame | Pre-compute in state initialization or use `cached_value` |
| `Opacity` widget for show/hide | Forces repaint of child subtree | Use `Visibility` with `maintainState` or `AnimatedOpacity` |
| `ClipRRect` without `RepaintBoundary` | Expensive clip on every repaint | Wrap clipped widget in `RepaintBoundary` |
| `MediaQuery.of(context)` deep in tree | Rebuilds entire subtree on size change | Cache in nearest `StatefulWidget` or use `MediaQuery.sizeOf(context)` |
| Synchronous image loading | Blocks UI thread | Always use async loading with placeholder |
| Unbounded `Column` inside `ListView` | Layout overflow | Use `shrinkWrap: true` sparingly, prefer `SliverList` |
