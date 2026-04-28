import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class TechnicianVerificationScreen extends ConsumerStatefulWidget {
  const TechnicianVerificationScreen({super.key});

  @override
  ConsumerState<TechnicianVerificationScreen> createState() =>
      _TechnicianVerificationScreenState();
}

class _TechnicianVerificationScreenState
    extends ConsumerState<TechnicianVerificationScreen> {
  final List<String> _uploadedDocuments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await ref
          .read(authStateProvider.notifier)
          .getTechnicianVerificationStatus();

      // If already verified, navigate to home
      if (status['is_verified'] == true) {
        Navigator.of(context).pushReplacementNamed('/technician-home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocuments() async {
    if (_uploadedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one document')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .uploadTechnicianDocuments(_uploadedDocuments);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh status
      await _checkVerificationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          size: 48,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pending Verification',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please upload your documents to complete verification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Required Documents
                  const Text(
                    'Required Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentRequirement(
                    'National ID',
                    'Valid government-issued ID',
                    Icons.credit_card,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentRequirement(
                    'Professional License',
                    'Trade certificate or license',
                    Icons.card_membership,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentRequirement(
                    'Insurance Certificate',
                    'Professional liability insurance',
                    Icons.security,
                  ),
                  const SizedBox(height: 32),
                  // Upload Section
                  const Text(
                    'Upload Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUploadButton(
                    'Choose Files',
                    Icons.cloud_upload_outlined,
                    () {
                      // TODO: Implement file picker
                      // For now, simulate adding documents
                      setState(() {
                        _uploadedDocuments
                            .add('document_${_uploadedDocuments.length}.pdf');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document added (simulated)'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Uploaded Documents List
                  if (_uploadedDocuments.isNotEmpty) ...[
                    const Text(
                      'Uploaded Files',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._uploadedDocuments.asMap().entries.map((entry) {
                      return _buildDocumentTile(
                        entry.value,
                        () {
                          setState(() {
                            _uploadedDocuments.removeAt(entry.key);
                          });
                        },
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                  // Submit Button
                  ElevatedButton(
                    onPressed:
                        _uploadedDocuments.isEmpty ? null : _uploadDocuments,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit for Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outlined, color: Colors.blue),
                            SizedBox(width: 12),
                            Text(
                              'Verification Timeline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTimeline(
                          'Submit Documents',
                          'Step 1',
                          true,
                        ),
                        _buildTimeline(
                          'Verification Review',
                          'Step 2 (1-2 days)',
                          false,
                        ),
                        _buildTimeline(
                          'Account Approved',
                          'Step 3',
                          false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Contact Support
                  TextButton(
                    onPressed: () {
                      // TODO: Implement contact support
                    },
                    child: const Text('Need help? Contact Support'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentRequirement(
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildUploadButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: Colors.blue, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String fileName, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onDelete,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String title, String subtitle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: isActive ? Colors.blue : Colors.grey[300],
                ),
                if (title != 'Account Approved')
                  Container(
                    width: 2,
                    height: 30,
                    color: isActive ? Colors.blue : Colors.grey[300],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
