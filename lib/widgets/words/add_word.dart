import 'package:flutter/material.dart';

class AddWord extends StatefulWidget {
  const AddWord({Key? key}) : super(key: key);

  @override
  State<AddWord> createState() => _AddWordState();
}

class _AddWordState extends State<AddWord> {
  final List<String> _translations =
      List.generate(5, (index) => 'Translation $index');

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return AlertDialog(
      scrollable: true,
      content: Container(
        height: height,
        width: 500,
        constraints: BoxConstraints(
          minHeight: 200,
          maxHeight: height,
          maxWidth: 340,
        ),
        child: Column(
          children: [
            Text('Add Word'),
            TextField(
              decoration: InputDecoration(labelText: 'Enter a word'),
            ),
            Text('Translations'),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _translations.length,
                itemBuilder: (context, index) {
                  return TextField();
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
