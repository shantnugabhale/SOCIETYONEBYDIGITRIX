import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../widgets/modern_empty_state.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: const ModernEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chat Feature',
        subtitle: 'Direct messaging between residents is coming soon!\nStay connected with your neighbors',
        iconColor: AppColors.primary,
      ),
    );
  }
}
