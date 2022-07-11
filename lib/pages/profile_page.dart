import 'package:flutter/material.dart';

import '../../widgets/error_text.dart';
import '../widgets/ui/spinner.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final bool _fetching = false;
  final String? _fetchError = null;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      if (_fetching) {
        return const Center(
          child: Spinner(
            size: SpinnerSize.large,
            showLabel: true,
          ),
        );
      }
      if (_fetchError != null) {
        return ErrorText(_fetchError!);
      }
      return const Center(
        child: Text('Not Implemented Yet.'),
      );
    });
  }
}
