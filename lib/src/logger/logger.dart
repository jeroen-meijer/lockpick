import 'dart:async';

import 'package:cli_dialog/cli_dialog.dart';
import 'package:cli_util/cli_logging.dart' as cli_logging;
import 'package:meta/meta.dart';

@visibleForTesting
class Logger {
  @visibleForTesting
  const Logger();

  @visibleForTesting
  static Logger instance = const Logger();

  void log(String message) {
    CLI_Dialog(
      messages: <String>[message],
    ).ask();
  }

  String askString(String question) {
    return CLI_Dialog(
      questions: <List<String>>[
        [question, 'answer'],
      ],
    ).ask()['answer'] as String;
  }

  bool askBool(String question) {
    return CLI_Dialog(
      booleanQuestions: <List<String>>[
        [question, 'answer'],
      ],
    ).ask()['answer'] as bool;
  }

  T pickOption<T>({
    required String question,
    required List<T> options,
  }) {
    assert(options.isNotEmpty, 'options must not be empty');

    final optionStrings = options.map((e) => '$e').toList();
    assert(
      optionStrings.length == {...optionStrings}.length,
      'All `options` must be unique when converted to a String',
    );

    final rawAnswer = CLI_Dialog(
      listQuestions: <List<Object>>[
        [
          {
            'question': question,
            'options': options.map((e) => '$e'),
          },
          'answer',
        ],
      ],
    ).ask()['answer'] as String;

    return options.firstWhere((e) => '$e' == rawAnswer);
  }

  Future<void> showProgress(
    String message,
    FutureOr<void> Function() fn,
  ) async {
    final progress = cli_logging.Logger.standard().progress(message);
    await fn();
    progress.finish(showTiming: true);
  }
}

void log(String message) => Logger.instance.log(message);
String askString(String question) => Logger.instance.askString(question);
bool askBool(String question) => Logger.instance.askBool(question);
T pickOption<T>({
  required String question,
  required List<T> options,
}) =>
    Logger.instance.pickOption(
      question: question,
      options: options,
    );
Future<void> showProgress(
  String message,
  FutureOr<void> Function() fn,
) =>
    Logger.instance.showProgress(message, fn);
