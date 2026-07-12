import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryBlue),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class AppShimmerLoading extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const AppShimmerLoading({
    super.key,
    this.itemCount = 4,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(index),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }
}
