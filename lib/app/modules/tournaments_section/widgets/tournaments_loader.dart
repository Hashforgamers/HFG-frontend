import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';

class TournamentsLoader extends StatelessWidget {
  final AppLinearLoader _delegate;

  const TournamentsLoader._({
    super.key,
    required AppLinearLoader delegate,
  }) : _delegate = delegate;

  const TournamentsLoader.screen({Key? key})
    : this._(
        key: key,
        delegate: const AppLinearLoader.screen(),
      );

  const TournamentsLoader.button({Key? key})
    : this._(
        key: key,
        delegate: const AppLinearLoader.button(),
      );

  @override
  Widget build(BuildContext context) {
    return _delegate;
  }
}
