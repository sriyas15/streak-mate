import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  const CustomAvatar({
    super.key,
    required this.url,
    required this.name,
    required this.size,
  });

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Check if the user has a valid web URL (e.g., they uploaded a photo)
    final bool hasUploadedPhoto = url != null && url!.startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent, 
      ),
      child: ClipOval(
        child: hasUploadedPhoto
            // If they uploaded a photo, show it from the network
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                // If the network image fails to load, show the local default
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              )
            // If the DB says null, show the local default instantly
            : _buildDefaultAvatar(),
      ),
    );
  }

  // A helper method to keep the code clean
  Widget _buildDefaultAvatar() {
    return Image.asset(
      'assets/images/defaultAvatar.png', // <--- YOUR DEFAULT LOCAL IMAGE
      fit: BoxFit.cover,
    );
  }
}