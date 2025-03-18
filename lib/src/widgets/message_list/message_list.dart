part of '../../../dash_chat_2.dart';

/// @nodoc
class MessageList extends StatefulWidget {
  const MessageList({
    required this.currentUser,
    required this.messages,
    this.readOnly = false,
    this.messageOptions = const MessageOptions(),
    this.messageListOptions = const MessageListOptions(),
    this.quickReplyOptions = const QuickReplyOptions(),
    this.scrollToBottomOptions = const ScrollToBottomOptions(),
    this.typingUsers,
    this.buttonAfterTyping,
    Key? key,
  }) : super(key: key);

  /// The current user of the chat
  final ChatUser currentUser;

  /// List of messages visible in the chat
  final List<ChatMessage> messages;

  /// Whether the chat is read only, used for safe area
  final bool readOnly;

  /// Options to customize the behaviour and design of the messages
  final MessageOptions messageOptions;

  /// Options to customize the behaviour and design of the overall list of message
  final MessageListOptions messageListOptions;

  /// Options to customize the behaviour and design of the quick replies
  final QuickReplyOptions quickReplyOptions;

  /// Options to customize the behaviour and design of the scroll-to-bottom button
  final ScrollToBottomOptions scrollToBottomOptions;

  /// List of users currently typing in the chat
  final List<ChatUser>? typingUsers;

  /// Custom widget to display after typing text
  final Widget? buttonAfterTyping;

  @override
  State<MessageList> createState() => MessageListState();
}

class MessageListState extends State<MessageList> {
  bool scrollToBottomIsVisible = false;
  bool isLoadingMore = false;
  late ScrollController scrollController;
  bool showListStart = false;

  // var onlyLastOneChanged = false;
  double? oldLastHeight;
  double? lastOneSizeIncrease;

  @override
  void initState() {
    super.initState();
    scrollController =
        widget.messageListOptions.scrollController ?? ScrollController();
    scrollController.addListener(() => _onScroll());
    if (widget.messageListOptions.onLoadEarlier == null) {
      showListStart = true;
      _scrollToBottomInitially();
    } else {
      // with very few messages list start would not show otherwise
      SchedulerBinding.instance.addPostFrameCallback((_) {
        setState(() {
          final canScroll = scrollController.position.maxScrollExtent > 0;
          showListStart = !canScroll;
        });
        _scrollToBottomInitially();
      });
    }
  }

  @override
  void dispose() {
    if (widget.messageListOptions.scrollController == null) {
      scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    var different = false;
    var onlyFirstOneChanged = false;
    final oldMessages = oldWidget.messages;
    final newMessages = widget.messages;

    if (oldMessages.length == newMessages.length) {
      if (oldMessages.isNotEmpty && newMessages.isNotEmpty) {
        final oldFirst = oldMessages.first;
        final newFirst = newMessages.first;
        if (oldFirst != newFirst) {
          different = true;
          if (oldMessages.length > 2 && newMessages.length > 2) {
            if (oldMessages[1] == newMessages[1]) {
              onlyFirstOneChanged = true;
            }
          }
        }
      }
    } else {
      different = true;
    }
    final scrollToEnd = different &&
        (!widget.messageListOptions.preventScrollWithFirstMessageSizeChange ||
            !onlyFirstOneChanged);

    if (scrollToEnd) {
      _scrollToBottomAfterFrame();
    }
  }

  void _scrollToBottomAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _scrollToBottomInitially() async {
    await WidgetsBinding.instance.endOfFrame;
    scrollController.jumpTo(
      scrollController.position.maxScrollExtent,
    );
    // somehow need this second one or it won't fully scroll to the bottom
    await WidgetsBinding.instance.endOfFrame;
    scrollController.jumpTo(
      scrollController.position.maxScrollExtent,
    );
  }

  double? oldMaxHeight;
  double? oldViewportDimension;

  @override
  Widget build(BuildContext context) {
    final listStartWidget =
        showListStart ? widget.messageListOptions.listStartWidget : null;

    int itemCount =
        1 + widget.messages.length + (listStartWidget == null ? 0 : 1);
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: LayoutBuilder(builder: (_, constraints) {
                  if (oldMaxHeight != null) {
                    if (oldMaxHeight != constraints.maxHeight) {
                      oldMaxHeight = constraints.maxHeight;
                      final oldViewportDimension =
                          scrollController.position.viewportDimension;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final newViewportDimension =
                            scrollController.position.viewportDimension;
                        final diff =
                            newViewportDimension - oldViewportDimension;
                        scrollController.jumpTo(scrollController.offset - diff);
                      });
                    }
                  } else {
                    oldMaxHeight = constraints.maxHeight;
                  }
                  return ListView.builder(
                    physics: widget.messageListOptions.scrollPhysics,
                    padding: widget.readOnly ? null : EdgeInsets.zero,
                    controller: scrollController,
                    itemCount: itemCount,
                    itemBuilder: (BuildContext context, int iii) {
                      if (iii == 0) {
                        return SizedBox(
                          height: constraints.maxHeight / 2,
                        );
                      }
                      int ii = iii - 1;
                      int i = itemCount - ii - 2;
                      if (listStartWidget != null &&
                          i == widget.messages.length) {
                        return listStartWidget;
                      }

                      final ChatMessage? previousMessage =
                          i < widget.messages.length - 1
                              ? widget.messages[i + 1]
                              : null;
                      final ChatMessage? nextMessage =
                          i > 0 ? widget.messages[i - 1] : null;
                      final ChatMessage message = widget.messages[i];
                      final bool isAfterDateSeparator =
                          _shouldShowDateSeparator(previousMessage, message,
                              widget.messageListOptions);
                      bool isBeforeDateSeparator = false;
                      if (nextMessage != null) {
                        isBeforeDateSeparator = _shouldShowDateSeparator(
                            message, nextMessage, widget.messageListOptions);
                      }
                      return Column(
                        children: <Widget>[
                          if (isAfterDateSeparator)
                            widget.messageListOptions.dateSeparatorBuilder !=
                                    null
                                ? widget.messageListOptions
                                    .dateSeparatorBuilder!(message.createdAt)
                                : DefaultDateSeparator(
                                    date: message.createdAt,
                                    messageListOptions:
                                        widget.messageListOptions,
                                  ),
                          if (widget.messageOptions.messageRowBuilder !=
                              null) ...<Widget>[
                            widget.messageOptions.messageRowBuilder!(
                              message,
                              previousMessage,
                              nextMessage,
                              isAfterDateSeparator,
                              isBeforeDateSeparator,
                            ),
                          ] else
                            MessageRow(
                              message: widget.messages[i],
                              nextMessage: nextMessage,
                              previousMessage: previousMessage,
                              currentUser: widget.currentUser,
                              isAfterDateSeparator: isAfterDateSeparator,
                              isBeforeDateSeparator: isBeforeDateSeparator,
                              messageOptions: widget.messageOptions,
                            ),
                        ],
                      );
                    },
                  );
                }),
              ),
              if (widget.typingUsers != null && widget.typingUsers!.isNotEmpty)
                ...widget.typingUsers!.map((ChatUser user) {
                  if (widget.messageListOptions.typingBuilder != null) {
                    return widget.messageListOptions.typingBuilder!(user);
                  }
                  return DefaultTypingBuilder(
                      user: user, buttonAfterTyping: widget.buttonAfterTyping);
                }),
              if (widget.messageListOptions.showFooterBeforeQuickReplies &&
                  widget.messageListOptions.chatFooterBuilder != null)
                widget.messageListOptions.chatFooterBuilder!,
              if (widget.messages.isNotEmpty &&
                  widget.messages.first.quickReplies != null &&
                  widget.messages.first.quickReplies!.isNotEmpty &&
                  widget.messages.first.user.id != widget.currentUser.id)
                QuickReplies(
                  quickReplies: widget.messages.first.quickReplies!,
                  quickReplyOptions: widget.quickReplyOptions,
                ),
              if (!widget.messageListOptions.showFooterBeforeQuickReplies &&
                  widget.messageListOptions.chatFooterBuilder != null)
                widget.messageListOptions.chatFooterBuilder!,
            ],
          ),
          if (isLoadingMore)
            Positioned(
              top: 8.0,
              right: 0,
              left: 0,
              child: widget.messageListOptions.loadEarlierBuilder ??
                  const Center(
                    child: SizedBox(
                      child: CircularProgressIndicator(),
                    ),
                  ),
            ),
          if (!widget.scrollToBottomOptions.disabled && scrollToBottomIsVisible)
            widget.scrollToBottomOptions.scrollToBottomBuilder != null
                ? widget.scrollToBottomOptions
                    .scrollToBottomBuilder!(scrollController)
                : DefaultScrollToBottom(
                    scrollController: scrollController,
                    readOnly: widget.readOnly,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    textColor: Theme.of(context).primaryColor,
                  ),
        ],
      ),
    );
  }

  /// Check if a date separator needs to be shown
  bool _shouldShowDateSeparator(ChatMessage? previousMessage,
      ChatMessage message, MessageListOptions messageListOptions) {
    if (!messageListOptions.showDateSeparator) {
      return false;
    }
    if (previousMessage == null) {
      // Means this is the first message
      return true;
    }
    switch (messageListOptions.separatorFrequency) {
      case SeparatorFrequency.days:
        final DateTime previousDate = DateTime(
          previousMessage.createdAt.year,
          previousMessage.createdAt.month,
          previousMessage.createdAt.day,
        );
        final DateTime messageDate = DateTime(
          message.createdAt.year,
          message.createdAt.month,
          message.createdAt.day,
        );
        return previousDate.difference(messageDate).inDays.abs() > 0;
      case SeparatorFrequency.hours:
        final DateTime previousDate = DateTime(
          previousMessage.createdAt.year,
          previousMessage.createdAt.month,
          previousMessage.createdAt.day,
          previousMessage.createdAt.hour,
        );
        final DateTime messageDate = DateTime(
          message.createdAt.year,
          message.createdAt.month,
          message.createdAt.day,
          message.createdAt.hour,
        );
        return previousDate.difference(messageDate).inHours.abs() > 0;
      default:
        return false;
    }
  }

  /// Scroll listener to trigger different actions:
  /// show scroll-to-bottom btn and LoadEarlier behaviour
  Future<void> _onScroll() async {
    bool topReached =
        scrollController.offset <= scrollController.position.minScrollExtent &&
            !scrollController.position.outOfRange;
    if (topReached &&
        widget.messageListOptions.onLoadEarlier != null &&
        !isLoadingMore) {
      setState(() {
        isLoadingMore = true;
      });
      showScrollToBottom();
      final noMoreOnTop = await widget.messageListOptions.onLoadEarlier!();
      setState(() {
        isLoadingMore = false;
        showListStart = noMoreOnTop != null && !noMoreOnTop;
      });
    } else if (scrollController.offset <
        scrollController.position.maxScrollExtent - 200) {
      showScrollToBottom();
    } else {
      hideScrollToBottom();
    }
  }

  void showScrollToBottom() {
    if (!scrollToBottomIsVisible) {
      setState(() {
        scrollToBottomIsVisible = true;
      });
    }
  }

  void hideScrollToBottom() {
    if (scrollToBottomIsVisible) {
      setState(() {
        scrollToBottomIsVisible = false;
      });
    }
  }
}
