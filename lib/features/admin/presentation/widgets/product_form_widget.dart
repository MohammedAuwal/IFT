import 'package:flutter/material.dart';

class ProductFormWidget extends StatelessWidget {
  final Widget child;

  const ProductFormWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
