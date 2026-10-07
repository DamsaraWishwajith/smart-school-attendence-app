import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../widgets/app_colors.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (!_isScanning) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() => _isScanning = false);
                  _handleScanResult(code);
                }
              }
            },
          ),
          _buildOverlay(),
          _buildHeader(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 48,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 44), // Spacer for centering title
          Text(
            'Scan Attendance',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 44), // Spacer
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Scanner animation could go here
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Positioned(
      bottom: 48,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Align the QR code within the frame to mark your attendance automatically.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _handleScanResult(String code) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final response = await context.read<AttendanceProvider>().getUserDetails(code);
    
    if (!mounted) return;
    Navigator.pop(context); // Remove loading indicator

    if (response != null && response['success'] == true) {
      final userData = response['user'];
      final userName = userData['name'] ?? 'Unknown User';
      final studentId = userData['student']?['student_id'] ?? 'N/A';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Confirm Attendance',
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Details Found:',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                'Name: $userName',
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'ID: $studentId',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Text(
                'Do you want to mark attendance for this user?',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isScanning = true); // Resume scanning
              },
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close confirm dialog
                _markAttendance(code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('OK', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      _showErrorDialog('User not found or API error.');
    }
  }

  void _markAttendance(String code) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    // Fetch last status to decide next action
    final lastStatus = await context.read<AttendanceProvider>().getLastAttendanceStatus(code);
    
    // Logic: if last is 'in', next is 'out'. If last is 'out' (or no history), next is 'in'.
    final nextStatus = (lastStatus == 'in') ? 'out' : 'in';

    final now = DateTime.now();
    final date = DateFormat('yyyy/MM/dd').format(now);
    final time = DateFormat('HH.mm').format(now);

    final success = await context.read<AttendanceProvider>().markAttendance(
      userId: code,
      status: nextStatus,
      time: time,
      date: date,
    );
    
    if (!mounted) return;
    Navigator.pop(context); // Remove loading indicator

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (success ? AppColors.success : AppColors.error).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                success ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
                color: success ? AppColors.success : AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              success ? 'Success!' : 'Failed!',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              success 
                ? 'Attendance has been marked successfully.' 
                : 'Unable to process the request. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  setState(() => _isScanning = true); // Resume scanning
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(FontAwesomeIcons.circleExclamation, color: AppColors.error, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isScanning = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Try Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
