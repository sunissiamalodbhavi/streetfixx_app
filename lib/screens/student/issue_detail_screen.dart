import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class IssueDetailScreen extends StatelessWidget {
  final Map<String, dynamic> issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issue Detail")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              issue['description'] ?? 'No Description',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text('Category: ${issue['category'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Status: ${issue['status'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Location: ${issue['location'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            if (issue['assigned_to'] != null)
              Text('Assigned To: Staff ID ${issue['assigned_to']}'),
          ],
        ),
      ),
    );
  }
}
