# Rust FFI Patterns Standard

## Technology Stack

| Crate / Tool | Role |
|---|---|
| `flutter_rust_bridge` | Safe, high-level FFI between Rust and Flutter/Dart |
| `flutter_rust_bridge_codegen` | Code generation CLI |
| `cbindgen` | Generate C headers for raw FFI (if needed) |

---

## Project Structure

```
my_app/
├── flutter_app/          # Flutter project
│   ├── lib/
│   │   └── src/
│   │       └── rust/     # Generated Dart bindings
│   │           └── frb_generated.dart
│   └── pubspec.yaml
└── rust_lib/             # Rust FFI crate (separate from core logic)
    ├── Cargo.toml
    └── src/
        ├── lib.rs         # Public FFI API
        ├── api/           # flutter_rust_bridge annotated functions
        │   ├── mod.rs
        │   ├── crypto.rs
        │   └── image_processing.rs
        └── core/          # Internal implementation (no FFI annotations)
            ├── mod.rs
            └── ...
```

---

## flutter_rust_bridge Setup

```toml
# rust_lib/Cargo.toml
[package]
name = "rust_lib"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "staticlib"]

[dependencies]
flutter_rust_bridge = "2"
tokio = { version = "1", features = ["rt-multi-thread"] }
anyhow = "1"

[build-dependencies]
flutter_rust_bridge_codegen = "2"
```

```rust
// rust_lib/src/lib.rs
// Re-export generated bridge code
mod frb_generated;
pub use frb_generated::*;

// Initialize the async runtime used by flutter_rust_bridge
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
```

---

## API Functions

```rust
// rust_lib/src/api/crypto.rs
use flutter_rust_bridge::frb;

/// Hash data using BLAKE3. Runs on a background thread automatically.
#[frb(sync)]  // Use sync for fast operations (< 1ms)
pub fn hash_bytes(data: Vec<u8>) -> Vec<u8> {
    blake3::hash(&data).as_bytes().to_vec()
}

/// Encrypt data with AES-256-GCM.
/// Returns Err if key or nonce lengths are invalid.
#[frb]  // async by default for potentially slow operations
pub async fn encrypt(
    plaintext: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
) -> Result<Vec<u8>, String> {
    encrypt_internal(&plaintext, &key, &nonce)
        .map_err(|e| e.to_string())
}

/// Decrypt data with AES-256-GCM.
#[frb]
pub async fn decrypt(
    ciphertext: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
) -> Result<Vec<u8>, String> {
    decrypt_internal(&ciphertext, &key, &nonce)
        .map_err(|e| e.to_string())
}

// Internal implementation — not exposed to FFI
fn encrypt_internal(plaintext: &[u8], key: &[u8], nonce: &[u8]) -> anyhow::Result<Vec<u8>> {
    // ... AES-256-GCM implementation
    Ok(vec![])
}
```

```rust
// rust_lib/src/api/image_processing.rs
use flutter_rust_bridge::frb;

/// Resize an image to the given dimensions.
/// Runs on a Tokio thread pool — never blocks the Flutter UI thread.
#[frb]
pub async fn resize_image(
    input: Vec<u8>,
    target_width: u32,
    target_height: u32,
) -> Result<Vec<u8>, String> {
    tokio::task::spawn_blocking(move || {
        let img = image::load_from_memory(&input)
            .map_err(|e| e.to_string())?;
        let resized = img.resize(target_width, target_height, image::imageops::FilterType::Lanczos3);
        let mut output = Vec::new();
        resized
            .write_to(&mut std::io::Cursor::new(&mut output), image::ImageFormat::Webp)
            .map_err(|e| e.to_string())?;
        Ok::<Vec<u8>, String>(output)
    })
    .await
    .map_err(|e| e.to_string())?
}

/// Typed struct returned to Dart — flutter_rust_bridge generates a Dart class
#[frb(dart_metadata=("freezed"))]
pub struct ImageInfo {
    pub width: u32,
    pub height: u32,
    pub format: String,
    pub size_bytes: u64,
}

#[frb]
pub async fn get_image_info(data: Vec<u8>) -> Result<ImageInfo, String> {
    let img = image::load_from_memory(&data).map_err(|e| e.to_string())?;
    Ok(ImageInfo {
        width: img.width(),
        height: img.height(),
        format: "webp".to_string(),
        size_bytes: data.len() as u64,
    })
}
```

---

## Code Generation

```bash
# Install the codegen tool
cargo install flutter_rust_bridge_codegen

# Generate Dart bindings from Rust source
flutter_rust_bridge_codegen generate \
    --rust-input rust_lib/src/api \
    --dart-output flutter_app/lib/src/rust \
    --dart-root flutter_app

# Run as part of CI
flutter_rust_bridge_codegen generate --watch  # during development
```

---

## Build Integration

```yaml
# flutter_app/pubspec.yaml
dependencies:
  flutter_rust_bridge: ^2.0.0

dev_dependencies:
  ffigen: ^9.0.0
```

```makefile
# Makefile
.PHONY: build-ios build-android build-web

build-ios:
	cd rust_lib && cargo build --release --target aarch64-apple-ios
	cd rust_lib && cargo build --release --target x86_64-apple-ios
	lipo -create \
		rust_lib/target/aarch64-apple-ios/release/librust_lib.a \
		rust_lib/target/x86_64-apple-ios/release/librust_lib.a \
		-output flutter_app/ios/Frameworks/librust_lib.a

build-android:
	cd rust_lib && cargo ndk \
		--target aarch64-linux-android \
		--target armv7-linux-androideabi \
		--target i686-linux-android \
		--target x86_64-linux-android \
		build --release

build-macos:
	cd rust_lib && cargo build --release
	cp rust_lib/target/release/librust_lib.dylib flutter_app/macos/Frameworks/
```

---

## Safety Rules

```rust
// NEVER expose raw pointers in the public FFI API
// Bad
pub extern "C" fn bad_api() -> *mut MyStruct { ... }

// Good — flutter_rust_bridge handles memory automatically
#[frb]
pub async fn good_api() -> MyStruct { ... }

// NEVER use CStr/CString unless bypassing flutter_rust_bridge
// flutter_rust_bridge handles String ↔ Dart String conversion automatically

// NEVER share mutable state across FFI boundary without synchronization
// Bad
static mut GLOBAL_STATE: Option<MyState> = None;

// Good — use Arc<Mutex<T>> if shared state is needed
// Better — make functions stateless, pass data explicitly
```

---

## CI Testing

```yaml
# .github/workflows/ffi-tests.yml
jobs:
  test-rust:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Rust tests
        run: cargo test --manifest-path rust_lib/Cargo.toml

  test-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - name: Build Rust library
        run: make build-linux
      - name: Run Flutter tests
        run: cd flutter_app && flutter test

  validate-bindings:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Generate bindings
        run: flutter_rust_bridge_codegen generate
      - name: Check no diff
        run: git diff --exit-code flutter_app/lib/src/rust/
```

---

## Rules

- **Use `flutter_rust_bridge` for all Flutter↔Rust FFI**: never write raw `extern "C"` functions exposed to Dart
- **No raw pointers in the public API**: `flutter_rust_bridge` manages memory ownership automatically
- **No `unsafe` blocks in the `api/` module**: unsafe code is allowed only in `core/` behind a safe wrapper
- **Typed wrappers for all data structures**: define named structs and enums; no opaque `Vec<u8>` for structured data
- **CPU-intensive work uses `tokio::task::spawn_blocking`**: prevents blocking the tokio runtime thread pool
- **`#[frb(sync)]` only for operations < 1ms**: longer operations must be async to avoid blocking Dart isolate
- **Separate FFI crate from business logic**: `rust_lib` contains only the FFI surface; `core` contains the implementation
- **Generated bindings are committed and checked in CI**: the `validate-bindings` job ensures they are up-to-date
- **Both Rust and Flutter tests run in CI**: Rust unit tests + Flutter integration tests exercising the FFI boundary
