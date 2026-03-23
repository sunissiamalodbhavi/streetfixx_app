import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/issue_card.dart';
import 'issue_detail_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  final int userId;

  const MyIssuesScreen({super.key, required this.userId});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _issuesFuture;

  @override
  void initState() {
    super.initState();
    _issuesFuture = _apiService.getCitizenIssues(widget.userId);
  }

  Future<void> _refreshIssues() async {
    setState(() {
      _issuesFuture = _apiService.getCitizenIssues(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Issues'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Assigned'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _issuesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.error_outline, size: 60, color: Colors.red),
                     const SizedBox(height: 10),
                     Text('Error loading issues: ${snapshot.error}'),
                     const SizedBox(height: 20),
                     ElevatedButton(
                       onPressed: _refreshIssues, 
                       child: const Text('Retry')
                     ),
                   ],
                 ),
               );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return TabBarView(
                children: [
                  _buildEmptyState('No pending issues.'),
                  _buildEmptyState('No assigned issues.'),
                  _buildEmptyState('No resolved issues.'),
                ],
              );
            }

            final allIssues = snapshot.data!;
            
            // Filter issues based on status mapping
            final pendingIssues = allIssues.where((issue) {
              final status = (issue['status'] as String?)?.toLowerCase() ?? '';
              return status == 'pending';
            }).toList();

            final assignedIssues = allIssues.where((issue) {
              final status = (issue['status'] as String?)?.toLowerCase() ?? '';
              return ['assigned', 'in progress'].contains(status);
            }).toList();

            final resolvedIssues = allIssues.where((issue) {
              final status = (issue['status'] as String?)?.toLowerCase() ?? '';
              return ['resolved', 'completed', 'verified'].contains(status);
            }).toList();

            return TabBarView(
              children: [
                _buildIssueList(pendingIssues, 'No pending issues.'),
                _buildIssueList(assignedIssues, 'No assigned issues.'),
                _buildIssueList(resolvedIssues, 'No resolved issues.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return RefreshIndicator(
      onRefresh: _refreshIssues,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          Center(
            child: Text(
              message,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueList(List<dynamic> issues, String emptyMessage) {
    if (issues.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }
    
    return RefreshIndicator(
      onRefresh: _refreshIssues,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return IssueCard(
            issue: issue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IssueDetailScreen(issue: issue as Map<String, dynamic>),
                ),
              ).then((_) {
                // Refresh list when coming back from detail screen
                _refreshIssues();
              });
            },
          );
        },
      ),
    );
  }
}
