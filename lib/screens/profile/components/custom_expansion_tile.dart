import 'package:flutter/material.dart';

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String content;

  const CustomExpansionTile({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) => Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Titillium Web',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        trailing: Icon(
          _isExpanded ? Icons.remove : Icons.add,
          color: _isExpanded ? Colors.blue : Colors.white,
        ),
        children: <Widget>[
          ListTile(
            title: Text(
              widget.content,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Titillium Web',
                color: Colors.white,
              ),
            ),
          ),
        ],
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
      ),
    );
}
