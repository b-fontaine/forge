# Rust TUI Design Standard (ratatui)

## Technology Stack

| Crate | Role |
|---|---|
| `ratatui` | TUI rendering library |
| `crossterm` | Cross-platform terminal backend |
| `tokio` | Async event loop |

---

## Elm Architecture

The TUI follows a strict unidirectional data flow:

```
User Input → Event → update(App, Event) → new App → render(App) → Terminal
```

```rust
// src/app.rs
pub struct App {
    pub mode: AppMode,
    pub screen: Screen,
    pub status_bar: StatusBarState,
    pub command_palette: CommandPaletteState,
    pub error: Option<String>,
    pub should_quit: bool,
}

#[derive(Debug, Clone, PartialEq)]
pub enum AppMode {
    Normal,
    Insert,
    Command,
    Help,
}

#[derive(Debug)]
pub enum AppEvent {
    // Terminal events
    Key(KeyEvent),
    Mouse(MouseEvent),
    Resize(u16, u16),
    // Application events
    DataLoaded(Vec<Item>),
    Error(String),
    Tick,
}
```

---

## Render Function

```rust
// src/ui/mod.rs
use ratatui::{Frame, layout::{Constraint, Direction, Layout, Rect}};

pub fn render(app: &App, frame: &mut Frame) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),  // title bar
            Constraint::Min(0),     // main content
            Constraint::Length(1),  // status bar
        ])
        .split(frame.area());

    render_title_bar(app, frame, chunks[0]);
    render_main(app, frame, chunks[1]);
    render_status_bar(app, frame, chunks[2]);

    if app.command_palette.is_open {
        render_command_palette(app, frame, centered_rect(60, 40, frame.area()));
    }

    if let Some(ref error) = app.error {
        render_error_popup(error, frame, centered_rect(50, 20, frame.area()));
    }
}

fn render_main(app: &App, frame: &mut Frame, area: Rect) {
    match &app.screen {
        Screen::ItemList(state) => render_item_list(state, frame, area),
        Screen::ItemDetail(state) => render_item_detail(state, frame, area),
        Screen::Help => render_help(frame, area),
    }
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}
```

---

## Event Loop

```rust
// src/main.rs
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let mut terminal = setup_terminal()?;
    let result = run_app(&mut terminal).await;
    restore_terminal(&mut terminal)?;
    result
}

fn setup_terminal() -> anyhow::Result<Terminal<CrosstermBackend<Stdout>>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    Terminal::new(backend).context("Creating terminal")
}

fn restore_terminal(terminal: &mut Terminal<CrosstermBackend<Stdout>>) -> anyhow::Result<()> {
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    terminal.show_cursor()?;
    Ok(())
}

async fn run_app(terminal: &mut Terminal<CrosstermBackend<Stdout>>) -> anyhow::Result<()> {
    let mut app = App::default();
    let mut event_rx = spawn_event_reader();

    loop {
        // Render at target framerate (30fps = 33ms interval)
        terminal.draw(|frame| render(&app, frame))?;

        // Handle events with timeout matching frame interval
        if let Ok(event) = tokio::time::timeout(
            Duration::from_millis(33),
            event_rx.recv(),
        ).await {
            if let Some(event) = event {
                app = handle_event(app, event).await?;
            }
        }

        if app.should_quit {
            break;
        }
    }

    Ok(())
}
```

---

## Graceful Restore on Panic

```rust
// src/main.rs — set up panic hook before running
fn setup_panic_hook() {
    let original_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        // Restore terminal before printing panic
        let _ = disable_raw_mode();
        let _ = execute!(io::stdout(), LeaveAlternateScreen, DisableMouseCapture);
        original_hook(panic_info);
    }));
}

fn main() -> anyhow::Result<()> {
    setup_panic_hook();
    // ... rest of main
}
```

---

## Built-in Widgets

```rust
use ratatui::widgets::{Block, Borders, List, ListItem, Paragraph, Table, Row, Cell, Chart, Dataset};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};

fn render_item_list(state: &ItemListState, frame: &mut Frame, area: Rect) {
    let items: Vec<ListItem> = state
        .items
        .iter()
        .enumerate()
        .map(|(i, item)| {
            let style = if i == state.selected {
                Style::default().fg(Color::Black).bg(Color::Cyan)
            } else {
                Style::default()
            };
            ListItem::new(Line::from(vec![
                Span::styled(&item.name, style),
                Span::raw("  "),
                Span::styled(&item.status, Style::default().fg(Color::DarkGray)),
            ]))
        })
        .collect();

    let list = List::new(items)
        .block(Block::default().title("Items").borders(Borders::ALL))
        .highlight_style(Style::default().add_modifier(Modifier::BOLD));

    frame.render_widget(list, area);
}

fn render_table(state: &TableState, frame: &mut Frame, area: Rect) {
    let rows: Vec<Row> = state.rows.iter().map(|r| {
        Row::new(vec![
            Cell::from(r.id.to_string()),
            Cell::from(r.name.as_str()),
            Cell::from(r.value.to_string()),
        ])
    }).collect();

    let table = Table::new(rows, [
        Constraint::Length(10),
        Constraint::Min(20),
        Constraint::Length(12),
    ])
    .header(Row::new(["ID", "Name", "Value"]).style(Style::default().add_modifier(Modifier::BOLD)))
    .block(Block::default().title("Data").borders(Borders::ALL));

    frame.render_widget(table, area);
}
```

---

## Custom StatefulWidget

```rust
use ratatui::widgets::StatefulWidget;

pub struct ProgressRing {
    pub color: Color,
}

pub struct ProgressRingState {
    pub progress: f64, // 0.0–1.0
}

impl StatefulWidget for ProgressRing {
    type State = ProgressRingState;

    fn render(self, area: Rect, buf: &mut ratatui::buffer::Buffer, state: &mut Self::State) {
        let filled = (state.progress * area.width as f64) as u16;
        for x in area.left()..area.right() {
            let style = if x < area.left() + filled {
                Style::default().bg(self.color)
            } else {
                Style::default().bg(Color::DarkGray)
            };
            buf.set_style(Rect { x, y: area.y, width: 1, height: 1 }, style);
        }
    }
}

// Usage
let mut ring_state = ProgressRingState { progress: 0.65 };
frame.render_stateful_widget(ProgressRing { color: Color::Green }, area, &mut ring_state);
```

---

## Key Bindings (Vim-Style)

```rust
// src/event_handler.rs
async fn handle_event(mut app: App, event: AppEvent) -> anyhow::Result<App> {
    if let AppEvent::Key(key) = event {
        match app.mode {
            AppMode::Normal => handle_normal_mode(&mut app, key),
            AppMode::Command => handle_command_mode(&mut app, key),
            AppMode::Insert => handle_insert_mode(&mut app, key),
            AppMode::Help => handle_help_mode(&mut app, key),
        }
    }
    Ok(app)
}

fn handle_normal_mode(app: &mut App, key: KeyEvent) {
    match (key.code, key.modifiers) {
        (KeyCode::Char('q'), _) | (KeyCode::Char('c'), KeyModifiers::CONTROL) => {
            app.should_quit = true;
        }
        (KeyCode::Char(':'), _) => {
            app.mode = AppMode::Command;
            app.command_palette.open();
        }
        (KeyCode::Char('?'), _) => app.screen = Screen::Help,
        (KeyCode::Char('j'), _) | (KeyCode::Down, _) => app.screen.select_next(),
        (KeyCode::Char('k'), _) | (KeyCode::Up, _) => app.screen.select_previous(),
        (KeyCode::Char('g'), _) => app.screen.select_first(),
        (KeyCode::Char('G'), _) => app.screen.select_last(),
        (KeyCode::Enter, _) => app.open_selected(),
        (KeyCode::Esc, _) => app.go_back(),
        _ => {}
    }
}
```

---

## Status Bar

```rust
fn render_status_bar(app: &App, frame: &mut Frame, area: Rect) {
    let mode_str = match app.mode {
        AppMode::Normal => "NORMAL",
        AppMode::Insert => "INSERT",
        AppMode::Command => "COMMAND",
        AppMode::Help => "HELP",
    };

    let mode_style = match app.mode {
        AppMode::Normal => Style::default().fg(Color::Black).bg(Color::Blue),
        AppMode::Insert => Style::default().fg(Color::Black).bg(Color::Green),
        AppMode::Command => Style::default().fg(Color::Black).bg(Color::Yellow),
        AppMode::Help => Style::default().fg(Color::Black).bg(Color::Cyan),
    };

    let line = Line::from(vec![
        Span::styled(format!(" {mode_str} "), mode_style),
        Span::raw(" "),
        Span::raw(&app.status_bar.message),
        Span::raw("  "),
        Span::styled("? Help  q Quit", Style::default().fg(Color::DarkGray)),
    ]);

    frame.render_widget(Paragraph::new(line), area);
}
```

---

## Rules

- **Graceful restore on panic**: set `std::panic::set_hook` to call `restore_terminal` before the original hook
- **30 fps target**: render loop uses a 33ms timeout; never render on every event without rate limiting
- **Minimum 80x24 terminal**: check `frame.area()` at startup and display an error if too small
- **256-color and truecolor**: use `Color::Rgb(r, g, b)` for branding; fall back to named colors for compatibility
- **All key bindings are documented in the help screen**: pressing `?` shows a complete binding reference
- **Mouse support is opt-in**: enable `EnableMouseCapture` and handle `MouseEvent::ScrollDown/Up` for lists
- **Clipboard via `arboard`**: copy selected text to system clipboard on `y` in normal mode
- **Never block the render loop**: spawn long operations with `tokio::spawn` and send results via channel
- **`StatefulWidget` for any widget with mutable selection or scroll state**
- **Layout constraints use `Min(0)` for the main content area**: ensures it grows to fill available space
