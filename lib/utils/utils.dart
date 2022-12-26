import 'dart:async';

import 'package:flutter/material.dart';

class Cache<T> {
  final int? defaultExpiryMs;
  final Map<String, T> _cache = {};

  Cache({this.defaultExpiryMs});

  void put(String key, T value, {int? expiryMs}) {
    expiryMs = expiryMs ?? defaultExpiryMs;
    _cache[key] = value;
    if (expiryMs != null) {
      Timer(Duration(milliseconds: expiryMs), () {
        _cache.remove(key);
      });
    }
  }

  T? get(String key) {
    T? value;
    if (_cache.containsKey(key)) {
      value = _cache[key];
    }
    return value;
  }

  Iterable<String> keys() {
    return _cache.keys;
  }

  void clear() {
    _cache.clear();
  }
}

class Wait {
  final Duration duration;
  final DateTime start = DateTime.now();

  Wait({required this.duration});

  Future<void> wait() async {
    var diff = DateTime.now().difference(start);
    if (diff < duration) {
      await Future.delayed(duration - diff);
    }
  }
}

Future<void> executeForAtLeast(int milliseconds, Function callback) async {
  var start = DateTime.now();
  await callback();
  var diffMs = DateTime.now().difference(start).inMilliseconds;
  if (diffMs < milliseconds) {
    await Future.delayed(Duration(milliseconds: milliseconds - diffMs));
  }
}

String capitalizeFirst(String text) {
  return text.isNotEmpty
      ? '${text.substring(0, 1).toUpperCase()}${text.substring(1)}'
      : '';
}

bool? parseBool(dynamic input) {
  bool? value;
  if (input != null && input.runtimeType == bool) {
    value = input;
  }
  return value;
}

int? parseInt(dynamic input) {
  int? value;
  if (input != null) {
    if (input.runtimeType == int) {
      value = input;
    } else if (input.runtimeType == String) {
      value = int.tryParse(input);
    }
  }
  return value;
}

double? parseDouble(dynamic input) {
  double? value;
  if (input != null) {
    if (input.runtimeType == double) {
      value = input;
    } else if (input.runtimeType == int) {
      value = input.toDouble();
    } else if (input.runtimeType == String) {
      value = double.tryParse(input);
    }
  }
  return value;
}

String? parseString(dynamic input) {
  String? value;
  if (input != null && input.runtimeType == String) {
    value = input;
  }
  return value;
}

List<int>? parseIntList(dynamic input) {
  List<int>? value;
  if (input != null && input.runtimeType == List) {
    value = [];
    for (var i in input) {
      var tmp = parseInt(i);
      if (tmp != null) {
        value.add(tmp);
      }
    }
  }
  return value;
}

List<String>? parseStringList(dynamic input) {
  List<String>? value;
  if (input != null && input.runtimeType == List) {
    value = [];
    for (var i in input) {
      var tmp = parseString(i);
      if (tmp != null) {
        value.add(tmp);
      }
    }
  }
  return value;
}

void selectAllText(TextEditingController controller) {
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );
}

void showSnackBar(
  BuildContext context,
  String text, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      action: action,
    ));
}

void showSnackBarUndo(
  BuildContext context, {
  required String text,
  required Function onUndo,
  String? undoLabel,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
          label: undoLabel ?? 'UNDO',
          textColor: Theme.of(context).colorScheme.inversePrimary,
          onPressed: () => onUndo(),
        ),
      ),
    );
}

void hideSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}

Future<void> showMessageDialog({
  required BuildContext context,
  required String title,
  String? content,
}) async {
  await showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18.0),
        ),
        content: content != null
            ? Text(
                content,
                style: const TextStyle(fontSize: 14.0),
              )
            : null,
      );
    },
  );
}

Future<bool> showYesCancelDialog({
  required BuildContext context,
  required String title,
  String yesText = 'Yes',
  String? cancelText = 'Cancel',
}) async {
  return await showDialog<bool?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontSize: 18.0),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(yesText),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              if (cancelText != null)
                TextButton(
                  child: Text(cancelText),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
            ],
          );
        },
      ) ??
      false;
}

Future<String?> showTextDialog({
  required BuildContext context,
  required String title,
  String okText = 'OK',
  String? cancelText = 'Cancel',
  String? initialValue,
  String? hintText,
}) async {
  var controller = TextEditingController();
  controller.text = initialValue ?? '';
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );
  return await showDialog<String?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            label: Text(title),
            hintText: hintText,
          ),
          textCapitalization: TextCapitalization.sentences,
          controller: controller,
          onChanged: (value) {},
        ),
        actions: [
          ElevatedButton(
            child: Text(okText),
            onPressed: () {
              var text = controller.text.trim();
              Navigator.pop(context, text);
            },
          ),
          if (cancelText != null)
            TextButton(
              child: Text(cancelText),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
        ],
      );
    },
  );
}

// Size _computeTextSize(String text, TextStyle style) {
//   final TextPainter textPainter = TextPainter(
//       text: TextSpan(text: text, style: style),
//       maxLines: 1,
//       textDirection: TextDirection.ltr)
//     ..layout(minWidth: 0, maxWidth: double.infinity);
//   return textPainter.size;
// }
