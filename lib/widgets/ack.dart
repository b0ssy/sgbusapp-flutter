import 'package:flutter/material.dart';

class Ack extends StatelessWidget {
  final String title;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;
  final Function onPressed;

  const Ack({
    Key? key,
    required this.title,
    this.backgroundColor,
    this.contentPadding,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: ListTile(
        dense: true,
        contentPadding: contentPadding,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14.0,
          ),
        ),
        trailing: TextButton(
          child: const Text('GOT IT'),
          onPressed: () => onPressed(),
        ),
      ),
    );
  }
}
