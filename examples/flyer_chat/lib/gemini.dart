import 'dart:async';
import 'package:cross_cache/cross_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'connection_check.dart';
import 'gemini_stream_manager.dart';
import 'groq_client.dart';
import 'hive_chat_controller.dart';
import 'supabase_messages.dart';
import 'widgets/composer_action_bar.dart';

// Define the shared animation duration
const Duration _kChunkAnimationDuration = Duration(milliseconds: 350);

class Gemini extends StatefulWidget {
  final String groqApiKey;

  const Gemini({super.key, required this.groqApiKey});

  @override
  GeminiState createState() => GeminiState();
}

class GeminiState extends State<Gemini> {
  final _uuid = const Uuid();
  final _crossCache = CrossCache();
  final _scrollController = ScrollController();
  final _chatController = HiveChatController();

  final _currentUser = const User(id: 'me');
  final _agent = const User(id: 'agent');

  late final GeminiStreamManager _streamManager;

  final Map<String, double> _initialScrollExtents = {};
  final Map<String, bool> _reachedTargetScroll = {};

  bool _isStreaming = false;
  StreamSubscription? _currentStreamSubscription;
  String? _currentStreamId;

  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _streamManager = GeminiStreamManager(
      chatController: _chatController,
      chunkAnimationDuration: _kChunkAnimationDuration,
    );
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    try {
      final messages = await fetchMessages();
      await _chatController.setMessages(messages);
    } catch (e) {
      debugPrint('Supabase load error: $e');
    }
    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _currentStreamSubscription?.cancel();
    _streamManager.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    _crossCache.dispose();
    super.dispose();
  }

  void _stopCurrentStream() {
    if (_currentStreamSubscription != null && _currentStreamId != null) {
      _currentStreamSubscription!.cancel();
      _currentStreamSubscription = null;

      setState(() {
        _isStreaming = false;
      });

      // Mark the current stream as stopped/errored
      if (_currentStreamId != null) {
        _streamManager.errorStream(_currentStreamId!, 'Stream stopped by user');
        _currentStreamId = null;
      }
    }
  }

  void _handleStreamError(
    String streamId,
    dynamic error,
    TextStreamMessage? streamMessage,
  ) async {
    debugPrint('Generation error for $streamId: $error');

    // Stream failed (only if message was created)
    if (streamMessage != null) {
      await _streamManager.errorStream(streamId, error);
    }

    // Reset streaming state
    if (mounted) {
      setState(() {
        _isStreaming = false;
      });
    }
    _currentStreamSubscription = null;
    _currentStreamId = null;

    // Clean up scroll state for this stream ID
    _initialScrollExtents.remove(streamId);
    _reachedTargetScroll.remove(streamId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Business Mentor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Check connection',
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Checking connection...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              final results = await checkConnections();
              if (!mounted) return;
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Connection Check'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supabase: ${results['Supabase'] == true ? "Connected" : "Failed"}',
                        style: TextStyle(
                          color: results['Supabase'] == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Groq: ${results['Groq'] == true ? "Connected" : "Failed"}',
                        style: TextStyle(
                          color: results['Groq'] == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _streamManager,
        child: Chat(
          builders: Builders(
            chatAnimatedListBuilder: (context, itemBuilder) {
              return ChatAnimatedList(
                scrollController: _scrollController,
                itemBuilder: itemBuilder,
                shouldScrollToEndWhenAtBottom: false,
              );
            },
            imageMessageBuilder:
                (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) => FlyerChatImageMessage(
                  message: message,
                  index: index,
                  showTime: false,
                  showStatus: false,
                ),
            composerBuilder: (context) => CustomComposer(
              isStreaming: _isStreaming,
              onStop: _stopCurrentStream,
              topWidget: ComposerActionBar(
                buttons: [
                  ComposerActionButton(
                    icon: Icons.delete_sweep,
                    title: 'Clear all',
                    onPressed: () async {
                      try {
                        await deleteAllMessages();
                      } catch (e) {
                        debugPrint('Supabase clear error: $e');
                      }
                      await _chatController.setMessages([]);
                    },
                    destructive: true,
                  ),
                ],
              ),
            ),
            textMessageBuilder:
                (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) => FlyerChatTextMessage(
                  message: message,
                  index: index,
                  showTime: false,
                  showStatus: false,
                  receivedBackgroundColor: Colors.transparent,
                  padding: message.authorId == _agent.id
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                ),
            textStreamMessageBuilder:
                (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  // Watch the manager for state updates
                  final streamState = context
                      .watch<GeminiStreamManager>()
                      .getState(message.streamId);
                  // Return the stream message widget, passing the state
                  return FlyerChatTextStreamMessage(
                    message: message,
                    index: index,
                    streamState: streamState,
                    chunkAnimationDuration: _kChunkAnimationDuration,
                    showTime: false,
                    showStatus: false,
                    receivedBackgroundColor: Colors.transparent,
                    padding: message.authorId == _agent.id
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                  );
                },
          ),
          chatController: _chatController,
          crossCache: _crossCache,
          currentUserId: _currentUser.id,
          onAttachmentTap: _handleAttachmentTap,
          onMessageSend: _handleMessageSend,
          resolveUser: (id) => Future.value(switch (id) {
            'me' => _currentUser,
            'agent' => _agent,
            _ => null,
          }),
          theme: ChatTheme.fromThemeData(theme),
        ),
      ),
    );
  }

  void _handleMessageSend(String text) async {
    final messageId = _uuid.v4();
    final createdAt = DateTime.now().toUtc();

    try {
      await insertMessage(
        id: messageId,
        text: text,
        isAi: false,
        authorId: _currentUser.id,
      );
    } catch (e) {
      debugPrint('Supabase insert user message error: $e');
    }

    await _chatController.insertMessage(
      TextMessage(
        id: messageId,
        authorId: _currentUser.id,
        createdAt: createdAt,
        text: text,
        metadata: isOnlyEmoji(text) ? {'isOnlyEmoji': true} : null,
      ),
    );

    _sendToGroq(text);
  }

  void _handleAttachmentTap() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _crossCache.downloadAndSave(image.path);
    await _chatController.insertMessage(
      ImageMessage(
        id: _uuid.v4(),
        authorId: _currentUser.id,
        createdAt: DateTime.now().toUtc(),
        source: image.path,
      ),
    );
  }

  void _sendToGroq(String userText) async {
    final streamId = _uuid.v4();
    _currentStreamId = streamId;
    TextStreamMessage? streamMessage;

    _reachedTargetScroll[streamId] = false;
    setState(() => _isStreaming = true);

    streamMessage = TextStreamMessage(
      id: streamId,
      authorId: _agent.id,
      createdAt: DateTime.now().toUtc(),
      streamId: streamId,
    );
    await _chatController.insertMessage(streamMessage);
      _streamManager.startStream(streamId, streamMessage);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients || !mounted) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.linearToEaseOut,
      );
    });

    final history = <Map<String, String>>[];
    for (final m in _chatController.messages) {
      if (m is TextMessage) {
        history.add({
          'role': m.authorId == _currentUser.id ? 'user' : 'assistant',
          'content': m.text,
        });
      }
    }
    final messages = buildMessages(history, userText);

    try {
      final stream = kIsWeb
          ? streamChatViaProxy(baseUrl: Uri.base.origin, messages: messages)
          : streamChat(apiKey: widget.groqApiKey, messages: messages);
      _currentStreamSubscription = stream.listen(
        (textChunk) async {
          if (textChunk.isEmpty || streamMessage == null) return;
          _streamManager.addChunk(streamId, textChunk);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients || !mounted) return;
            var initialExtent = _initialScrollExtents[streamId];
            final reachedTarget = _reachedTargetScroll[streamId] ?? false;
            if (reachedTarget) return;
            initialExtent ??= _initialScrollExtents[streamId] =
                _scrollController.position.maxScrollExtent;
            if (initialExtent > 0) {
              final targetScroll =
                  initialExtent +
                  _scrollController.position.viewportDimension -
                  MediaQuery.of(context).padding.bottom -
                  168;
              if (_scrollController.position.maxScrollExtent > targetScroll) {
                _scrollController.animateTo(
                  targetScroll,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.linearToEaseOut,
                );
                _reachedTargetScroll[streamId] = true;
              } else {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.linearToEaseOut,
                );
              }
            }
          });
        },
        onDone: () async {
          if (streamMessage != null) {
            final state = _streamManager.getState(streamId);
            if (state is StreamStateStreaming && state.accumulatedText.isNotEmpty) {
              try {
                await insertMessage(
                  id: streamId,
                  text: state.accumulatedText,
                  isAi: true,
                  authorId: _agent.id,
                );
              } catch (e) {
                debugPrint('Supabase insert AI message error: $e');
              }
            }
            await _streamManager.completeStream(streamId);
          }
          if (mounted) setState(() => _isStreaming = false);
          _currentStreamSubscription = null;
          _currentStreamId = null;
          _initialScrollExtents.remove(streamId);
          _reachedTargetScroll.remove(streamId);
        },
        onError: (error) async {
          _handleStreamError(streamId, error, streamMessage);
        },
      );
    } catch (error) {
      _handleStreamError(streamId, error, streamMessage);
    }
  }
}

class CustomComposer extends StatefulWidget {
  final Widget? topWidget;
  final bool isStreaming;
  final VoidCallback? onStop;

  const CustomComposer({
    super.key,
    this.topWidget,
    this.isStreaming = false,
    this.onStop,
  });

  @override
  State<CustomComposer> createState() => _CustomComposerState();
}

class _CustomComposerState extends State<CustomComposer> {
  final _key = GlobalKey();
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.onKeyEvent = _handleKeyEvent;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Check for Shift+Enter
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isShiftPressed) {
      _handleSubmitted(_textController.text);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant CustomComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final onAttachmentTap = context.read<OnAttachmentTapCallback?>();
    final theme = context.select(
      (ChatTheme t) => (
        bodyMedium: t.typography.bodyMedium,
        onSurface: t.colors.onSurface,
        surfaceContainerHigh: t.colors.surfaceContainerHigh,
        surfaceContainerLow: t.colors.surfaceContainerLow,
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: Container(
          key: _key,
          color: theme.surfaceContainerLow,
          child: Column(
            children: [
              if (widget.topWidget != null) widget.topWidget!,
              Padding(
                padding: EdgeInsets.only(
                  bottom: bottomSafeArea,
                ).add(const EdgeInsets.all(8.0)),
                child: Row(
                  children: [
                    onAttachmentTap != null
                        ? IconButton(
                            icon: const Icon(Icons.attachment),
                            color: theme.onSurface.withValues(alpha: 0.5),
                            onPressed: onAttachmentTap,
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: theme.bodyMedium.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.5),
                          ),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          filled: true,
                          fillColor: theme.surfaceContainerHigh.withValues(
                            alpha: 0.8,
                          ),
                          hoverColor: Colors.transparent,
                        ),
                        style: theme.bodyMedium.copyWith(
                          color: theme.onSurface,
                        ),
                        onSubmitted: _handleSubmitted,
                        textInputAction: TextInputAction.newline,
                        autocorrect: true,
                        autofocus: false,
                        textCapitalization: TextCapitalization.sentences,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: widget.isStreaming
                          ? const Icon(Icons.stop_circle)
                          : const Icon(Icons.send),
                      color: theme.onSurface.withValues(alpha: 0.5),
                      onPressed: widget.isStreaming
                          ? widget.onStop
                          : () => _handleSubmitted(_textController.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _measure() {
    if (!mounted) return;

    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final height = renderBox.size.height;
      final bottomSafeArea = MediaQuery.of(context).padding.bottom;

      context.read<ComposerHeightNotifier>().setHeight(height - bottomSafeArea);
    }
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      context.read<OnMessageSendCallback?>()?.call(text);
      _textController.clear();
    }
  }
}
