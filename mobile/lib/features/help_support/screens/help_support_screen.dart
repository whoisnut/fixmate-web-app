import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int _selectedIndex = 0;

  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I book a service?',
      'answer':
          'To book a service, go to the Services tab, select the service you need, choose your preferred date and time, and confirm your booking. You\'ll receive a confirmation email shortly.',
    },
    {
      'question': 'How can I track my technician?',
      'answer':
          'Once your service has been assigned to a technician, you can track their location in real-time from the booking details page. You\'ll also receive updates about their arrival time.',
    },
    {
      'question': 'What payment methods do you accept?',
      'answer':
          'We accept credit/debit cards (Visa, MasterCard, American Express), PayPal, and bank transfers. You can save multiple payment methods for quick checkout.',
    },
    {
      'question': 'How do I cancel my booking?',
      'answer':
          'You can cancel your booking up to 24 hours before the scheduled time from the booking details. Cancellations made within 24 hours may incur a cancellation fee.',
    },
    {
      'question': 'What if I\'m not satisfied with the service?',
      'answer':
          'If you\'re not satisfied with the service, please contact our support team within 24 hours. We offer a satisfaction guarantee and will address any concerns promptly.',
    },
    {
      'question': 'How do I become a technician?',
      'answer':
          'To become a technician, sign up with your professional credentials, complete our verification process, and pass our background check. Visit our Careers page for more information.',
    },
  ];

  void _launchURL(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton('FAQs', 0),
                _buildTabButton('Contact', 1),
                _buildTabButton('Report Issue', 2),
              ],
            ),
          ),
          const Divider(height: 0),
          // Tab content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildFAQsTab(),
                _buildContactTab(),
                _buildReportIssueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    _selectedIndex == index ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight:
                  _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
              color: _selectedIndex == index ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              faqs[index]['question']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faqs[index]['answer']!,
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Get in Touch',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@fixmate.com',
            onTap: () => _launchURL('mailto:support@fixmate.com'),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            subtitle: '+1 (555) 123-4567',
            onTap: () => _launchURL('tel:+15551234567'),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.chat_outlined,
            title: 'Live Chat',
            subtitle: 'Available 24/7',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat coming soon!')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.location_on_outlined,
            title: 'Visit Us',
            subtitle: '123 Service Ave, Tech City, TC 12345',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            'Business Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Monday - Friday: 8:00 AM - 6:00 PM\nSaturday: 9:00 AM - 4:00 PM\nSunday: Closed',
            style: TextStyle(color: Colors.grey, height: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReportIssueTab() {
    final formKey = GlobalKey<FormState>();
    String? issueType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Report an Issue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Issue Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: issueType,
              hint: const Text('Select an issue type'),
              items: [
                'Technical Issue',
                'Booking Problem',
                'Payment Issue',
                'Service Quality',
                'Other',
              ]
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) => issueType = value,
              validator: (value) =>
                  value == null ? 'Please select an issue type' : null,
            ),
            const SizedBox(height: 24),
            const Text('Description'),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Please describe the issue in detail...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 5,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please describe the issue' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Thank you for reporting the issue. We\'ll look into it soon.'),
                    ),
                  );
                  formKey.currentState!.reset();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
