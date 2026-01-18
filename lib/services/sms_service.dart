import 'package:flutter_sms/flutter_sms.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

class SMSService {
  // Singleton pattern to manage SOS state app-wide
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  bool _isSOSActive = false;

  /// Sends an SOS SMS with location. 
  /// Optimized for speed: Fetches last known location first, then tries current location with a short timeout.
  Future<void> sendSOS() async {
    // Flag to prevent overlapping triggers while still keeping button responsive
    if (_isSOSActive) {
      developer.log('SOS already active. Ignoring additional triggers.');
      return;
    }
    _isSOSActive = true;

    try {
      // 1. Check Permissions (Non-blocking check if already granted)
      bool hasSms = await Permission.sms.isGranted;
      bool hasLoc = await Permission.location.isGranted;

      if (!hasSms || !hasLoc) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.sms,
          Permission.location,
        ].request();
        if (statuses[Permission.sms] != PermissionStatus.granted ||
            statuses[Permission.location] != PermissionStatus.granted) {
          developer.log('Permissions denied. Cannot send SOS.');
          _isSOSActive = false;
          return;
        }
      }

      // 2. FAST LOCATION FETCH (Primary goal: Don't delay the SMS)
      String locationLink = await _getFastLocationLink();

      // 3. Fetch Contacts (Offline-ready)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isSOSActive = false;
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trusted_contacts')
          .get(const GetOptions(source: Source.serverAndCache));

      List<String> recipients = snapshot.docs
          .map((doc) => doc.data()['phone']?.toString() ?? '')
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (recipients.isEmpty) {
        _isSOSActive = false;
        return;
      }

      // 4. Message Formatting
      final String message = "🚨 EMERGENCY SOS ALERT – SAAYA\n"
          "I am in danger. Please help immediately.\n\n"
          "📍 My location:\n"
          "$locationLink\n\n"
          "Sent automatically from SAAYA.";

      // 5. Immediate SMS Send
      await sendSMS(
        message: message,
        recipients: recipients,
      ).catchError((e) {
        developer.log('SMS Failed: $e');
        return "Error";
      });

    } catch (e) {
      developer.log('Error in SOS logic: $e');
      _isSOSActive = false;
    }
  }

  /// Fetches location link with a 3-second deadline. 
  /// Falls back to 'Last Known Location' if 'Current Location' is slow.
  Future<String> _getFastLocationLink() async {
    try {
      // Try fetching last known location first (Instant)
      Position? position = await Geolocator.getLastKnownPosition();
      
      // If no last known, or to get fresh data, try current location with a tight timeout
      // This ensures we don't wait 10-20 seconds for a GPS lock while in danger.
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Medium is faster than High
        timeLimit: const Duration(seconds: 3),
      ).catchError((_) async {
        // If current position fails/times out, we return the last known one (even if null)
        return position; 
      });

      if (position != null) {
        return "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
      }
    } catch (e) {
      developer.log('Location fetch error: $e');
    }
    return "[Location Unavailable]";
  }

  void resetSOSFlag() {
    _isSOSActive = false;
  }
}
