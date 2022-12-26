import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final Map<String, TextStyle> highlights;
  final TextStyle? style;
  final bool softWrap;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightText({
    Key? key,
    required this.text,
    required this.highlights,
    this.style,
    this.softWrap = false,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<dynamic> parts = [
      [text, null],
    ];
    var stop = false;
    while (!stop) {
      var recheck = false;
      for (var i = 0; i < parts.length; i++) {
        for (var key in highlights.keys) {
          String text = parts[i][0];
          TextStyle? style = parts[i][1];
          var pos = text.indexOf(RegExp(key, caseSensitive: false));
          if (pos >= 0 && (text.length != key.length || style == null)) {
            if (text.substring(pos + key.length).isNotEmpty) {
              parts.insert(i + 1, [text.substring(pos + key.length), style]);
            }
            parts.insert(i + 1,
                [text.substring(pos, pos + key.length), highlights[key]]);
            if (text.substring(0, pos).isNotEmpty) {
              parts.insert(i + 1, [text.substring(0, pos), style]);
            }
            parts.removeAt(i);
            recheck = true;
          }
        }
        if (recheck) {
          break;
        }
        if (i == parts.length - 1) {
          stop = true;
        }
      }
    }
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          for (var part in parts)
            TextSpan(
              text: part[0],
              style: part[1] ?? style,
            ),
        ],
      ),
      softWrap: softWrap,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
