import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:genkit/genkit.dart';
// ignore: implementation_imports
import 'package:genkit/src/ai/generate.dart' show GenerateResponse;
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/translator/data/datasources/ai_datasource.dart';
import 'package:kudlit_ph/features/translator/domain/entities/baybayin_challenge.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';

/// The model used for all cloud Baybayin inference. (using Gemma)
const String _kModel = 'gemma-4-26b-a4b-it';

/// Name of the Supabase Edge Function that proxies Gemini calls. The function
/// owns the upstream `GEMINI_API_KEY`; the client never sees it.
const String _kProxyFunction = 'gemini-proxy';

/// System prompt that scopes Butty to Baybayin / Filipino culture only.
const String _kChatSystemPrompt = '''
You are Butty, a friendly Baybayin learning companion inside the Kudlit app.
You ONLY discuss topics related to Baybayin script, the Filipino language,
Philippine history, and Filipino culture. Politely decline anything else.
Keep answers concise and encouraging. Use simple Tagalog/English mixed responses.
''';

/// System prompt for the challenge generator.
const String _kChallengeSystemPrompt = '''
You are a Baybayin quiz engine. Respond ONLY with valid JSON matching the
schema below and nothing else — no markdown fences, no extra keys.

Schema:
{
  "type": "writeCharacter" | "identifyCharacter" | "translateWord",
  "prompt": "<instruction for the learner>",
  "answer": "<correct answer>",
  "targetGlyph": "<Baybayin glyph, if applicable, else null>",
  "hint": "<one-sentence hint, or null>"
}
''';

/// Live cloud inference datasource.
///
/// Production builds use the Supabase Edge Function `gemini-proxy` so the
/// Google AI Studio key never ships to clients. Tests inject a fake [Genkit]
/// via [CloudGemmaDatasource.withAi] to avoid touching the network.
///
/// One instance is kept alive for the lifetime of the app via the
/// `cloudGemmaDatasourceProvider`.
class CloudGemmaDatasource implements AiDatasource {
  /// Production constructor — routes through the Supabase Edge Function.
  CloudGemmaDatasource({required SupabaseClient supabase})
    : _supabase = supabase,
      _ai = null;

  /// Test constructor — accepts an injected [Genkit] instance.
  CloudGemmaDatasource.withAi(Genkit ai) : _ai = ai, _supabase = null;

  final Genkit? _ai;
  final SupabaseClient? _supabase;

  ModelRef<GeminiOptions>? get _model =>
      _ai == null ? null : googleAI.gemini(_kModel);

  // ─── 1. Scoped chat ────────────────────────────────────────────────────────

  /// Streams response tokens for a Baybayin-scoped conversation.
  ///
  /// [history] is the full message history (user + model turns).
  /// A hard-coded [systemInstruction] keeps Butty on topic unless
  /// the caller overrides it.
  @override
  Stream<String> generate(
    List<ChatMessage> history, {
    String? systemInstruction,
  }) {
    final String prompt = systemInstruction ?? _kChatSystemPrompt;
    if (_ai != null) {
      return _generateViaGenkit(history, systemInstruction: prompt);
    }
    return _generateViaProxy(history, systemInstruction: prompt);
  }

  Stream<String> _generateViaGenkit(
    List<ChatMessage> history, {
    required String systemInstruction,
  }) {
    final StreamController<String> controller = StreamController<String>();
    final List<Message> messages = _buildGenkitMessages(
      history,
      systemInstruction: systemInstruction,
    );

    _ai!
        .generate(
          model: _model!,
          messages: messages,
          onChunk: (GenerateResponseChunk chunk) {
            final String token = chunk.content
                .whereType<TextPart>()
                .map((TextPart p) => p.text)
                .join();
            if (token.isNotEmpty && !controller.isClosed) {
              controller.add(token);
            }
          },
        )
        .then((_) => controller.close())
        .catchError((Object e, StackTrace s) {
          if (!controller.isClosed) {
            controller.addError(e, s);
            controller.close();
          }
        });

    return controller.stream;
  }

  Stream<String> _generateViaProxy(
    List<ChatMessage> history, {
    required String systemInstruction,
  }) async* {
    final Map<String, dynamic> payload = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': systemInstruction},
        ],
      },
      'contents': <Map<String, dynamic>>[
        for (final ChatMessage msg in history)
          <String, dynamic>{
            'role': msg.isUser ? 'user' : 'model',
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': msg.text},
            ],
          },
      ],
    };

    final String text = await _invokeProxy(payload);
    if (text.isNotEmpty) yield text;
  }

  // ─── 2. Image analysis ────────────────────────────────────────────────────

  /// Streams a description / translation of drawn or photographed
  /// Baybayin characters supplied as raw image bytes.
  ///
  /// [mimeType] defaults to `'image/png'`. Pass `'image/jpeg'` for photos.
  @override
  Stream<String> analyzeImage(
    Uint8List imageBytes, {
    String mimeType = 'image/png',
    String? prompt,
  }) {
    final String systemInstruction =
        prompt ??
        'Identify the Baybayin character(s) in this image. '
            'Give the romanized equivalent and a short explanation of each.';
    if (_ai != null) {
      return _analyzeImageViaGenkit(
        imageBytes,
        mimeType: mimeType,
        systemInstruction: systemInstruction,
      );
    }
    return _analyzeImageViaProxy(
      imageBytes,
      mimeType: mimeType,
      systemInstruction: systemInstruction,
    );
  }

  Stream<String> _analyzeImageViaGenkit(
    Uint8List imageBytes, {
    required String mimeType,
    required String systemInstruction,
  }) {
    final StreamController<String> controller = StreamController<String>();
    final String base64Image = base64Encode(imageBytes);
    final String dataUrl = 'data:$mimeType;base64,$base64Image';

    final List<Message> messages = <Message>[
      Message.from(
        role: Role.system,
        content: <Part>[TextPart.from(text: systemInstruction)],
      ),
      Message.from(
        role: Role.user,
        content: <Part>[
          MediaPart.from(
            media: Media.from(contentType: mimeType, url: dataUrl),
          ),
          TextPart.from(text: 'Evaluate this drawing.'),
        ],
      ),
    ];

    _ai!
        .generate(
          model: _model!,
          messages: messages,
          onChunk: (GenerateResponseChunk chunk) {
            final String token = chunk.content
                .whereType<TextPart>()
                .map((TextPart p) => p.text)
                .join();
            if (token.isNotEmpty && !controller.isClosed) {
              controller.add(token);
            }
          },
        )
        .then((_) => controller.close())
        .catchError((Object e, StackTrace s) {
          if (!controller.isClosed) {
            controller.addError(e, s);
            controller.close();
          }
        });

    return controller.stream;
  }

  Stream<String> _analyzeImageViaProxy(
    Uint8List imageBytes, {
    required String mimeType,
    required String systemInstruction,
  }) async* {
    final String base64Image = base64Encode(imageBytes);
    final Map<String, dynamic> payload = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': systemInstruction},
        ],
      },
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{
              'inlineData': <String, dynamic>{
                'mimeType': mimeType,
                'data': base64Image,
              },
            },
            <String, dynamic>{'text': 'Evaluate this drawing.'},
          ],
        },
      ],
    };

    final String text = await _invokeProxy(payload);
    if (text.isNotEmpty) yield text;
  }

  // ─── 3. Challenge generation ──────────────────────────────────────────────

  /// Asks Gemini to produce one Baybayin challenge, returned as a typed
  /// [BaybayinChallenge].
  ///
  /// Optionally narrow the challenge to a subset of Baybayin [characters]
  /// (e.g. vowel kudlit only).
  @override
  Future<BaybayinChallenge> generateChallenge({
    List<String>? characters,
  }) async {
    final StringBuffer userPrompt = StringBuffer(
      'Generate one Baybayin learning challenge.',
    );
    if (characters != null && characters.isNotEmpty) {
      userPrompt.write(' Focus on these characters: ${characters.join(', ')}.');
    }

    if (_ai != null) {
      return _generateChallengeViaGenkit(userPrompt.toString());
    }
    return _generateChallengeViaProxy(userPrompt.toString());
  }

  Future<BaybayinChallenge> _generateChallengeViaGenkit(
    String userPrompt,
  ) async {
    final List<Message> messages = <Message>[
      Message.from(
        role: Role.system,
        content: <Part>[TextPart.from(text: _kChallengeSystemPrompt)],
      ),
      Message.from(
        role: Role.user,
        content: <Part>[TextPart.from(text: userPrompt)],
      ),
    ];

    final StringBuffer raw = StringBuffer();
    final GenerateResponse response = await _ai!.generate(
      model: _model!,
      messages: messages,
      onChunk: (GenerateResponseChunk chunk) {
        final String token = chunk.content
            .whereType<TextPart>()
            .map((TextPart p) => p.text)
            .join();
        if (token.isNotEmpty) raw.write(token);
      },
    );

    // Prefer the complete response text; fall back to streamed buffer.
    final String json = response.text.isNotEmpty
        ? response.text
        : raw.toString();
    return _parseChallenge(json);
  }

  Future<BaybayinChallenge> _generateChallengeViaProxy(
    String userPrompt,
  ) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': _kChallengeSystemPrompt},
        ],
      },
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': userPrompt},
          ],
        },
      ],
    };

    final String text = await _invokeProxy(payload);
    return _parseChallenge(text);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Invokes the Supabase `gemini-proxy` Edge Function with [payload] (a raw
  /// Gemini REST request body) and returns the first candidate's text.
  ///
  /// The Supabase client automatically forwards the signed-in user's JWT in
  /// the `Authorization` header, which the Edge Function verifies before
  /// calling Gemini with the server-held API key.
  Future<String> _invokeProxy(Map<String, dynamic> payload) async {
    final FunctionResponse response = await _supabase!.functions.invoke(
      _kProxyFunction,
      body: <String, dynamic>{
        'model': _kModel,
        'stream': false,
        'payload': payload,
      },
    );

    final int status = response.status;
    if (status < 200 || status >= 300) {
      throw Exception(
        'gemini-proxy returned $status: ${response.data}',
      );
    }

    return _extractTextFromGeminiResponse(response.data);
  }

  /// Extracts the concatenated text of the first candidate from a Gemini
  /// `generateContent` response. Returns an empty string if the response is
  /// shaped unexpectedly.
  String _extractTextFromGeminiResponse(Object? data) {
    Map<String, dynamic>? json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is String && data.isNotEmpty) {
      try {
        json = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return '';
      }
    }
    if (json == null) return '';

    final List<dynamic>? candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';

    final Map<String, dynamic>? first =
        candidates.first as Map<String, dynamic>?;
    final Map<String, dynamic>? content =
        first?['content'] as Map<String, dynamic>?;
    final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
    if (parts == null) return '';

    final StringBuffer buf = StringBuffer();
    for (final dynamic part in parts) {
      if (part is Map<String, dynamic>) {
        final Object? text = part['text'];
        if (text is String) buf.write(text);
      }
    }
    return buf.toString();
  }

  /// Converts domain [ChatMessage] list → Genkit [Message] list,
  /// prepending a system instruction message. Used only by the [withAi]
  /// (test) code path.
  List<Message> _buildGenkitMessages(
    List<ChatMessage> history, {
    required String systemInstruction,
  }) {
    final List<Message> result = <Message>[
      Message.from(
        role: Role.system,
        content: <Part>[TextPart.from(text: systemInstruction)],
      ),
    ];

    for (final ChatMessage msg in history) {
      result.add(
        Message.from(
          role: msg.isUser ? Role.user : Role.model,
          content: <Part>[TextPart.from(text: msg.text)],
        ),
      );
    }
    return result;
  }

  /// Parses raw JSON from the model into a [BaybayinChallenge].
  /// Falls back to a safe default if the JSON is malformed.
  BaybayinChallenge _parseChallenge(String raw) {
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      return BaybayinChallenge(
        type: _parseChallengeType(json['type'] as String? ?? ''),
        prompt: json['prompt'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        targetGlyph: json['targetGlyph'] as String?,
        hint: json['hint'] as String?,
      );
    } catch (_) {
      return const BaybayinChallenge(
        type: ChallengeType.identifyCharacter,
        prompt: 'What romanized syllable does the character ᜀ represent?',
        answer: 'a',
        targetGlyph: 'ᜀ',
        hint: 'It is the first vowel in the Baybayin alphabet.',
      );
    }
  }

  ChallengeType _parseChallengeType(String raw) => switch (raw) {
    'writeCharacter' => ChallengeType.writeCharacter,
    'translateWord' => ChallengeType.translateWord,
    _ => ChallengeType.identifyCharacter,
  };

  @override
  Future<void> dispose() async {}
}
