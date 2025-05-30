part of '../../dash_chat_2.dart';

/// {@category Customization}
class MessageListOptions {
  const MessageListOptions({
    this.showDateSeparator = true,
    this.dateSeparatorFormat,
    this.dateSeparatorBuilder,
    this.separatorFrequency = SeparatorFrequency.days,
    this.scrollController,
    this.chatFooterBuilder,
    this.showFooterBeforeQuickReplies = false,
    this.loadEarlierBuilder,
    this.onLoadEarlier,
    this.listStartWidget,
    this.typingBuilder,
    this.scrollPhysics,
    this.preventScrollWithFirstMessageSizeChange = false,
  });

  /// If you want to who a date separator between messages of different dates
  final bool showDateSeparator;

  /// The formatting of the date in the date separator.
  /// By default it will adapt according to the difference with today
  final intl.DateFormat? dateSeparatorFormat;

  /// If you want to create you own separator widget
  /// You can use DefaultDateSeparator to only override some variables
  final Widget Function(DateTime date)? dateSeparatorBuilder;

  /// The frequency of the separator
  final SeparatorFrequency separatorFrequency;

  /// Scroll controller of the list of message
  final ScrollController? scrollController;

  /// A widget to show at the bottom of the chat
  /// (between the input and the chat content)
  final Widget? chatFooterBuilder;

  /// If you want to show [chatFooterBuilder] before or after the quick replies
  final bool showFooterBeforeQuickReplies;

  /// If you want to show a widget when the top of the list is reached
  final Widget? loadEarlierBuilder;

  /// Function to call when the top of the list is reached
  /// Useful to load more messages
  /// Returns false when we know that the next call will not load anything
  final Future<bool?> Function()? onLoadEarlier;

  /// If you want to show a widget at the very beginning of the list
  final Widget? listStartWidget;

  /// Builder to create your own typing widget
  final Widget Function(ChatUser user)? typingBuilder;

  /// Scroll physics of the ListView
  final ScrollPhysics? scrollPhysics;

  /// If you want to prevent the scroll when the first message size changes
  final bool preventScrollWithFirstMessageSizeChange;
}

enum SeparatorFrequency { days, hours }
