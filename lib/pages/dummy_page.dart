import 'package:flutter/material.dart';

import '../widgets/ui/icon_button_square.dart';
import '../widgets/ui/spinner.dart';

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
        title: const Text('dummy page'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Wrap(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/unknown-route-here');
                },
                icon: const Icon(Icons.reddit),
              ),
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Ink(
                  decoration: const ShapeDecoration(
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
              IconButtonSquare(
                icon: const Icon(
                  Icons.reddit,
                ),
                onTap: () {},
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
                label: const SizedBox(),
              ),
              const SizedBox(height: 20, width: 20),
              Container(
                  // color: AppColors.reject,
                  padding: const EdgeInsets.all(20),
                  child: const Spinner(
                    showLabel: true,
                    size: SpinnerSize.small,
                  )),
              Container(
                  // color: AppColors.reject,
                  padding: const EdgeInsets.all(20),
                  child: const Spinner(
                    showLabel: true,
                  )),
              Container(
                  // color: AppColors.reject,
                  padding: const EdgeInsets.all(20),
                  child: const Spinner(
                    showLabel: true,
                    size: SpinnerSize.large,
                  )),
              Container(
                  // color: AppColors.reject,
                  padding: const EdgeInsets.all(20),
                  child: const Spinner(
                    size: SpinnerSize.small,
                  )),
              Container(
                  // color: AppColors.reject,
                  padding: const EdgeInsets.all(20),
                  child: const Spinner()),
              Container(
                  // color: AppColors.reject,
                  padding: const EdgeInsets.all(20),
                  child: const Spinner(
                    size: SpinnerSize.large,
                  )),
              const SizedBox(height: 20, width: 20),
            ],
          ),
        ],
      ),
    );
  }
}
