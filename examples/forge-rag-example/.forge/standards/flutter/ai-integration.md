# Flutter AI Integration Standard

## Voice Pipeline

### Technology Stack

| Component | Package |
|---|---|
| WebRTC audio capture | `flutter_webrtc` |
| Audio session management | `audio_session` |
| Streaming transcription | WebSocket to STT backend |
| TTS playback | `just_audio` or platform TTS |

### State Machine

```
idle → listening → processing → speaking → idle
         ↓              ↓
      cancelled      error → idle
```

```dart
// lib/features/voice/domain/voice_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'voice_state.freezed.dart';

@freezed
class VoiceState with _$VoiceState {
  const factory VoiceState.idle() = _Idle;
  const factory VoiceState.listening({required double audioLevel}) = _Listening;
  const factory VoiceState.processing({required String partialTranscript}) = _Processing;
  const factory VoiceState.speaking({required String text, required double progress}) = _Speaking;
  const factory VoiceState.error({required String message}) = _Error;
}
```

```dart
// lib/features/voice/application/voice_bloc.dart
@injectable
class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc(this._audioCapture, this._sttService, this._aiService, this._ttsService)
      : super(const VoiceState.idle()) {
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<AudioLevelChanged>(_onAudioLevel);
    on<TranscriptReceived>(_onTranscript);
    on<ResponseReceived>(_onResponse);
    on<SpeakingCompleted>(_onSpeakingCompleted);
    on<Cancel>(_onCancel);
  }

  final AudioCapture _audioCapture;
  final SttService _sttService;
  final AiService _aiService;
  final TtsService _ttsService;

  StreamSubscription? _audioSubscription;
  StreamSubscription? _transcriptSubscription;

  Future<void> _onStartListening(StartListening event, Emitter<VoiceState> emit) async {
    if (state is! _Idle) return;

    await _configureAudioSession();
    await _audioCapture.start();

    emit(const VoiceState.listening(audioLevel: 0));

    final audioStream = _audioCapture.pcmStream(sampleRate: 16000, channels: 1);
    _transcriptSubscription = _sttService.stream(audioStream).listen(
      (transcript) => add(TranscriptReceived(transcript)),
    );
  }

  Future<void> _onStopListening(StopListening event, Emitter<VoiceState> emit) async {
    if (state is! _Listening) return;

    final partialTranscript = (state as _Listening).audioLevel.toString(); // simplified
    await _audioCapture.stop();
    await _transcriptSubscription?.cancel();

    emit(VoiceState.processing(partialTranscript: ''));
  }

  Future<void> _onTranscript(TranscriptReceived event, Emitter<VoiceState> emit) async {
    if (!event.isFinal) {
      emit(VoiceState.processing(partialTranscript: event.text));
      return;
    }

    final response = await _aiService.generate(event.text);
    add(ResponseReceived(response));
  }

  Future<void> _onResponse(ResponseReceived event, Emitter<VoiceState> emit) async {
    emit(VoiceState.speaking(text: event.text, progress: 0));
    await _ttsService.speak(event.text);
    add(SpeakingCompleted());
  }

  Future<void> _onSpeakingCompleted(SpeakingCompleted event, Emitter<VoiceState> emit) async {
    emit(const VoiceState.idle());
  }

  Future<void> _onCancel(Cancel event, Emitter<VoiceState> emit) async {
    await _audioCapture.stop();
    await _transcriptSubscription?.cancel();
    await _ttsService.stop();
    emit(const VoiceState.idle());
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidWillPauseWhenDucked: true,
    ));
  }

  @override
  Future<void> close() async {
    await _audioSubscription?.cancel();
    await _transcriptSubscription?.cancel();
    return super.close();
  }
}
```

---

## GenUI without Firebase (JSON Schema → Widgets)

```dart
// lib/features/genui/domain/ui_schema.dart
@freezed
class UiSchema with _$UiSchema {
  const factory UiSchema({
    required String type,
    Map<String, dynamic>? props,
    List<UiSchema>? children,
  }) = _UiSchema;

  factory UiSchema.fromJson(Map<String, dynamic> json) => _$UiSchemaFromJson(json);
}
```

```dart
// lib/features/genui/presentation/dynamic_widget_builder.dart
class DynamicWidgetBuilder extends StatelessWidget {
  const DynamicWidgetBuilder({super.key, required this.schema});

  final UiSchema schema;

  @override
  Widget build(BuildContext context) {
    return _buildWidget(schema) ?? _buildFallback(schema);
  }

  Widget? _buildWidget(UiSchema schema) {
    return switch (schema.type) {
      'text' => Text(
          schema.props?['content'] as String? ?? '',
          style: _parseTextStyle(schema.props?['style']),
        ),
      'button' => ElevatedButton(
          onPressed: () => _handleAction(schema.props?['action']),
          child: Text(schema.props?['label'] as String? ?? 'Button'),
        ),
      'image' => CachedNetworkImage(
          imageUrl: schema.props?['url'] as String? ?? '',
          width: (schema.props?['width'] as num?)?.toDouble(),
          height: (schema.props?['height'] as num?)?.toDouble(),
        ),
      'column' => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: schema.children?.map((c) => DynamicWidgetBuilder(schema: c)).toList() ?? [],
        ),
      'row' => Row(
          children: schema.children?.map((c) => DynamicWidgetBuilder(schema: c)).toList() ?? [],
        ),
      _ => null,
    };
  }

  Widget _buildFallback(UiSchema schema) {
    // Always render something — never crash on unknown type
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        '[Unsupported component: ${schema.type}]',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  void _handleAction(dynamic action) {
    if (action == null) return;
    // Route action to event bus or router
  }

  TextStyle? _parseTextStyle(dynamic style) {
    if (style is! Map<String, dynamic>) return null;
    return TextStyle(
      fontSize: (style['fontSize'] as num?)?.toDouble(),
      fontWeight: style['bold'] == true ? FontWeight.bold : null,
      color: style['color'] != null ? Color(int.parse(style['color'])) : null,
    );
  }
}
```

---

## GenUI with Firebase Vertex AI

```dart
// lib/features/genui/adapters/vertex_genui_service.dart
@lazySingleton
class VertexGenUiService {
  VertexGenUiService()
      : _model = FirebaseVertexAI.instance.generativeModel(
          model: 'gemini-1.5-pro',
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
          tools: [_uiGenerationTool],
        );

  final GenerativeModel _model;

  static final _uiGenerationTool = Tool(
    functionDeclarations: [
      FunctionDeclaration(
        'generate_ui',
        'Generate a UI schema from a natural language description',
        Schema(
          SchemaType.object,
          properties: {
            'schema': Schema(SchemaType.object, description: 'The UI component tree'),
          },
        ),
      ),
    ],
  );

  Future<UiSchema> generateUi(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    final functionCall = response.candidates.first.content.parts
        .whereType<FunctionCallPart>()
        .firstOrNull;

    if (functionCall == null) {
      throw const GenUiException('Model did not return a function call');
    }

    return UiSchema.fromJson(functionCall.args['schema'] as Map<String, dynamic>);
  }
}
```

---

## Frontend Agents

### Event Bus

```dart
// lib/core/agents/agent_event_bus.dart
@lazySingleton
class AgentEventBus {
  final _controller = StreamController<AgentEvent>.broadcast();

  Stream<AgentEvent> get events => _controller.stream;

  void emit(AgentEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}
```

### Agent with Tool Boundaries

```dart
// lib/features/agent/application/task_agent.dart
@injectable
class TaskAgent {
  TaskAgent(this._llmService, this._eventBus, this._memory, this._tools);

  final LlmService _llmService;
  final AgentEventBus _eventBus;
  final AgentMemory _memory;
  final List<AgentTool> _tools;

  Future<void> run(String userMessage) async {
    // Load relevant memory
    final context = await _memory.recall(userMessage, limit: 10);

    // Stream response from LLM
    final stream = _llmService.streamWithTools(
      systemPrompt: _buildSystemPrompt(),
      memory: context,
      userMessage: userMessage,
      tools: _tools,
    );

    await for (final chunk in stream) {
      switch (chunk) {
        case TextChunk(:final text):
          _eventBus.emit(AgentTextEvent(text));

        case ToolCallChunk(:final name, :final arguments):
          _eventBus.emit(AgentToolCallEvent(name, arguments));
          final tool = _tools.firstWhere((t) => t.name == name);
          final result = await tool.execute(arguments);
          _eventBus.emit(AgentToolResultEvent(name, result));

        case FinalChunk(:final fullText):
          await _memory.store(userMessage, fullText);
          _eventBus.emit(AgentCompleteEvent(fullText));
      }
    }
  }

  String _buildSystemPrompt() => '''
You are a helpful assistant. You have access to the following tools:
${_tools.map((t) => '- ${t.name}: ${t.description}').join('\n')}

Use tools only when necessary. Never perform actions outside tool boundaries.
''';
}
```

### Hive Memory

```dart
// lib/features/agent/adapters/hive_agent_memory.dart
@LazySingleton(as: AgentMemory)
class HiveAgentMemory implements AgentMemory {
  HiveAgentMemory(this._box);

  final Box<MemoryEntry> _box;

  @override
  Future<List<MemoryEntry>> recall(String query, {int limit = 10}) async {
    // Simple recency-based recall; swap for vector search in production
    final entries = _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }

  @override
  Future<void> store(String input, String output) async {
    await _box.add(MemoryEntry(
      input: input,
      output: output,
      timestamp: DateTime.now(),
    ));
    // Keep last 100 entries
    if (_box.length > 100) {
      await _box.deleteAt(0);
    }
  }
}
```

---

## Rules

- **Never block the UI thread**: all AI calls are async; show loading states with the voice state machine
- **Fallback is mandatory**: every GenUI component type must have a fallback renderer
- **PII consent before voice**: request microphone permission and display a privacy notice before starting any voice session
- **Token budget management**: set a max token limit on all LLM requests; implement `maxOutputTokens` and monitor usage
- **Cancel on navigate away**: voice and agent streams must be cancelled when the user navigates away from the screen
- **Tool boundaries are strict**: agents may only call tools from their registered tool list; no arbitrary code execution
- **Memory is scoped per user**: never share memory entries across different authenticated users
- **Streaming responses update UI incrementally**: use `StreamBuilder` or BLoC emit per chunk for low-latency text display
- **Audio is PCM 16kHz mono**: standardize audio format across all STT backends
- **iOS audio session must be configured before capture starts**: use `AudioSession` with `.voiceChat` mode
