# Flutter Accessibility Standard

## Principles

1. Every interactive element has a semantic label
2. Color is never the sole conveyor of information
3. Text scales with system font size
4. Focus order is logical and predictable
5. All features are operable without a pointer device

---

## Semantic Labels

### Interactive Elements

```dart
// Bad: screen reader announces "button"
IconButton(
  icon: const Icon(Icons.favorite),
  onPressed: _toggleFavorite,
)

// Good
IconButton(
  icon: const Icon(Icons.favorite),
  tooltip: 'Add to favorites', // used as semantic label automatically
  onPressed: _toggleFavorite,
)

// Or explicitly
Semantics(
  label: 'Add to favorites',
  button: true,
  child: GestureDetector(
    onTap: _toggleFavorite,
    child: const Icon(Icons.favorite),
  ),
)
```

### Images

```dart
// Decorative image — exclude from semantics
Semantics(
  excludeSemantics: true,
  child: Image.asset('assets/decorative_pattern.png'),
)

// Informative image
Semantics(
  label: 'User profile photo of Alice Johnson',
  image: true,
  child: CircleAvatar(backgroundImage: NetworkImage(photoUrl)),
)
```

### Icons

```dart
// Icon with adjacent text — merge semantics, exclude icon
Row(
  children: [
    ExcludeSemantics(child: const Icon(Icons.star)),
    const Text('4.8 rating'),
  ],
)

// Standalone icon
Semantics(
  label: 'Verified account',
  child: const Icon(Icons.verified, color: Colors.blue),
)
```

### Custom Widgets

```dart
class RatingBar extends StatelessWidget {
  const RatingBar({super.key, required this.value, required this.max});

  final double value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${value.toStringAsFixed(1)} out of $max stars',
      value: '${(value / max * 100).toInt()}%',
      child: _buildStars(),
    );
  }
}
```

---

## Navigation and Focus

### Sort Key for Logical Reading Order

```dart
// When visual order differs from logical order
Column(
  children: [
    Semantics(
      sortKey: const OrdinalSortKey(2.0),
      child: const Text('Secondary info'),
    ),
    Semantics(
      sortKey: const OrdinalSortKey(1.0),
      child: const Text('Primary info (reads first)'),
    ),
  ],
)
```

### FocusNode Management

```dart
class SignInForm extends StatefulWidget { ... }

class _SignInFormState extends State<SignInForm> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _submitFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          focusNode: _emailFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        TextField(
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        ElevatedButton(
          focusNode: _submitFocus,
          onPressed: _submit,
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
```

### ExcludeSemantics and MergeSemantics

```dart
// Merge a card's interactive elements into a single semantic node
MergeSemantics(
  child: Card(
    child: ListTile(
      leading: const Icon(Icons.article),
      title: const Text('Article title'),
      subtitle: const Text('5 min read'),
      trailing: IconButton(
        icon: const Icon(Icons.bookmark_border),
        onPressed: _bookmark,
      ),
    ),
  ),
)

// Exclude decorative sub-elements
Semantics(
  label: 'Profile card for Alice Johnson, Admin',
  child: Card(
    child: Row(
      children: [
        ExcludeSemantics(child: CircleAvatar(...)),
        const Column(
          children: [
            ExcludeSemantics(child: Text('Alice Johnson')),
            ExcludeSemantics(child: Text('Admin')),
          ],
        ),
      ],
    ),
  ),
)
```

---

## Color Contrast

### WCAG AA Requirements

| Element | Minimum Ratio |
|---|---|
| Normal text (< 18pt) | 4.5:1 |
| Large text (>= 18pt or 14pt bold) | 3:1 |
| Interactive element boundaries | 3:1 |
| Focus indicators | 3:1 against adjacent colors |

### Checking Contrast

Use the [WCAG Contrast Checker](https://webaim.org/resources/contrastchecker/) or the `flutter_contrast_checker` package.

```dart
// Never rely solely on color to convey state
// Bad: red = error, green = success (invisible to color-blind users)
Container(color: isError ? Colors.red : Colors.green)

// Good: add icon or pattern in addition to color
Row(
  children: [
    Icon(isError ? Icons.error : Icons.check_circle,
         color: isError ? Colors.red : Colors.green),
    const SizedBox(width: 8),
    Text(message),
  ],
)
```

### Theme Color Setup

```dart
// Ensure your MaterialTheme passes contrast checks
final theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1565C0),
    // Verify generated colors meet WCAG AA
  ),
);

// Override specific colors when generated ones fail contrast
final correctedScheme = theme.colorScheme.copyWith(
  onPrimary: Colors.white, // verified 4.6:1 against primary
);
```

---

## Text Scaling

```dart
// Never hard-code font sizes without considering scaling
Text(
  'Important message',
  style: Theme.of(context).textTheme.bodyLarge,
  // Do NOT add: textScaleFactor: 1.0 — this breaks accessibility
)

// Clamp scaling only when layout truly cannot accommodate larger text
Text(
  label,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  // Acceptable when the label has a tooltip or full text elsewhere
)

// Test with large text scales:
// Settings → Accessibility → Display & Text Size → Larger Text
```

---

## Testing Accessibility

### Semantic Finder in Widget Tests

```dart
testWidgets('submit button has correct semantics', (tester) async {
  await tester.pumpApp(const SignInPage());

  final semantics = tester.getSemantics(find.byKey(const Key('submit_button')));

  expect(semantics.label, 'Sign in');
  expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
  expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
});

testWidgets('error field announces error message', (tester) async {
  await tester.pumpApp(const SignInPage());
  // Trigger error state
  await tester.tap(find.byKey(const Key('submit_button')));
  await tester.pumpAndSettle();

  final semantics = tester.getSemantics(find.byKey(const Key('email_field')));
  expect(semantics.hasFlag(SemanticsFlag.isTextField), isTrue);
  // Error should be in the label or value
  expect(semantics.label, contains('required'));
});
```

### Screen Reader Manual Testing Checklist

- [ ] VoiceOver (iOS): every element has a label; swipe-right traversal makes sense; double-tap activates buttons
- [ ] TalkBack (Android): swipe-right traversal; actions announced; form fields have hints
- [ ] Keyboard navigation (web/desktop): Tab moves logically; Enter/Space activates buttons; Escape closes dialogs
- [ ] Switch control (iOS): group navigation works; no orphaned focus traps

---

## Platform-Specific Notes

### VoiceOver (iOS)

```dart
// Ensure custom gestures don't conflict with VoiceOver gestures
GestureDetector(
  onPanStart: _onPanStart,
  // VoiceOver users use swipe gestures — ensure your pan handler
  // only activates when accessibility is disabled
  excludeFromSemantics: true, // if it's decorative
)
```

### TalkBack (Android)

```dart
// Live regions announce dynamic updates automatically
Semantics(
  liveRegion: true,
  child: Text(statusMessage),
)
```

### Web

```dart
// Wrap complex widgets with ARIA roles via HtmlElementView or semantics
Semantics(
  label: 'Navigation menu',
  child: NavigationRail(...),
)
```

### Desktop

```dart
// Tooltips are essential for icon-only toolbars
IconButton(
  icon: const Icon(Icons.save),
  tooltip: 'Save (Ctrl+S)', // shows on hover and in screen readers
  onPressed: _save,
)
```

---

## Rules

- **Every `Icon` used alone must have a `tooltip` or `Semantics(label: ...)`**
- **Every `GestureDetector` with a tap handler must have a semantic label and `onTapHint`**
- **Never set `textScaleFactor` to a fixed value** (except in golden tests)
- **Minimum touch target: 48x48 dp** for all interactive elements
- **Never use color alone to convey information**: pair with icon, pattern, or text
- **Run `flutter test` with `SemanticsHandle` open** to catch semantic regressions
- **Accessibility audit every sprint**: use a screen reader on a real device, not only the emulator
