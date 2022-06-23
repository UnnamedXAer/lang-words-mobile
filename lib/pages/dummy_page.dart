import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

class DummyPage extends StatefulWidget {
  static const routeName = '/dummy-page';
  const DummyPage({Key? key}) : super(key: key);

  @override
  State<DummyPage> createState() => _DummyPageState();
}

class _DummyPageState extends State<DummyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dummy page'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Container(
            // color: AppColors.bgHeader,
            child: Wrap(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.reddit),
                ),
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Ink(
                    decoration: ShapeDecoration(
                      shape: BeveledRectangleBorder(
                          side: (BorderSide(
                        color: Colors.red,
                        width: 3,
                      ))),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.reddit,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  child: Container(
                    
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      // border: Border.all(
                      //   width: 1,
                      // ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 24,
                    ),
                  ),
                  onTap: () {},
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.refresh),
                  label: SizedBox(),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: MaterialButton(
                    onPressed: () {},
                    child: Icon(Icons.refresh),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
