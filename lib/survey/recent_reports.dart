import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class RecentReportsPage extends StatelessWidget {
  final String userId; // Pass the user ID

  RecentReportsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Reports'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Surveys')
            .where('userId', isEqualTo: userId) // Filtering based on userId
            .orderBy('createdAt', descending: true) // Order by createdAt to get the most recent tests first
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show a loader
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // Iterate through the test results and display each one in a card
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final testResult = snapshot.data!.docs[index];
                final DateTime createdAt = (testResult['createdAt'] as Timestamp).toDate();
                final int questionScore = testResult['questionScore'];
                final String severityStatus = getSeverityStatus(questionScore); // Determine severity status based on score

                // Formatting the date and time
                final String formattedDateTime = DateFormat.yMMMMd().add_jm().format(createdAt);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Date & Time: $formattedDateTime',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Score: $questionScore/52',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Severity Status: $severityStatus',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: getSeverityColor(severityStatus), // Change text color based on severity
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No recent reports found.'));
          }
        },
      ),
    );
  }

  // A function to determine severity status based on score
  String getSeverityStatus(int score) {
    if (score <= 20) {
      return 'Low';
    } else if (score >= 21 && score <= 35) {
      return 'Moderate';
    } else if (score >= 36 && score <= 39) {
      return 'High';
    } else {
      return 'Very High';
    }
  }

  // A function to return the color for severity status
  Color getSeverityColor(String status) {
    switch (status) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.amber;
      case 'High':
        return Colors.orange;
      case 'Very High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
