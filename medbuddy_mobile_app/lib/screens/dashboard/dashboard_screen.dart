import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:medbuddy_mobile_application/screens/schedule/schedule_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  User? _user;
  String _userName = "User";
  String? existingDeviceId;
  String? existingDeviceName;
  List<Map<String, dynamic>> todaySchedules = [];
  List<Map<String, dynamic>> emergencyAlerts = [];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserName();
    _fetchDeviceDetails();
  }

  /// Fetch user's name from Firestore
  Future<void> _fetchUserName() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(_user!.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _userName = userDoc["userName"] ?? "User";
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  /// Fetch user's existing device details
  void _fetchDeviceDetails() async {
    if (_user == null) return;

    DatabaseEvent event = await _dbRef.child("devices").orderByChild("userId").equalTo(_user!.uid).once();

    if (event.snapshot.value != null) {
      Map<String, dynamic> devices = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (devices.isNotEmpty) {
        existingDeviceId = devices.keys.first;
        existingDeviceName = devices[existingDeviceId]?["deviceName"];
        _fetchSchedulesAndAlerts();
      }
    }
  }

  /// Fetch today's schedules & emergency alerts
  void _fetchSchedulesAndAlerts() async {
    if (existingDeviceId == null) return;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Fetch schedules
    DatabaseEvent scheduleEvent = await _dbRef.child("devices/$existingDeviceId/schedules").once();
    if (scheduleEvent.snapshot.value != null) {
      Map<String, dynamic> schedules = Map<String, dynamic>.from(scheduleEvent.snapshot.value as Map);
      todaySchedules = schedules.values
          .where((schedule) => schedule["date"] == today)
          .map((schedule) => schedule as Map<String, dynamic>)
          .toList();
    }
    print("Fetched schedules: $todaySchedules");

    // Fetch emergency alerts
    DatabaseEvent alertEvent = await _dbRef.child("devices/$existingDeviceId/emergencyAlerts").once();
    if (alertEvent.snapshot.value != null) {
      Map<String, dynamic> alerts = Map<String, dynamic>.from(alertEvent.snapshot.value as Map);
      emergencyAlerts = alerts.values
          .where((alert) => alert["date"] == today)
          .map((alert) => alert as Map<String, dynamic>)
          .toList();
    }
    print("Fetched emergency alerts: $emergencyAlerts");

    setState(() {}); // Update UI
  }

  /// Show Add/Update Device Dialog
  void _showAddDeviceDialog() {
    _deviceIdController.text = existingDeviceId ?? "";
    _deviceNameController.text = existingDeviceName ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingDeviceId != null ? "Update Device" : "Add Device"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _deviceNameController,
                decoration: InputDecoration(labelText: "Device Name"),
              ),
              const SizedBox(height: 10.0),
              TextField(
                controller: _deviceIdController,
                decoration: InputDecoration(labelText: "Device ID"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => _saveDevice(),
              child: Text(existingDeviceId != null ? "Update" : "Add"),
            ),
          ],
        );
      },
    );
  }

  /// Add or Update Device
  void _saveDevice() async {
    String userId = _user!.uid;
    String deviceId = _deviceIdController.text.trim();
    String deviceName = _deviceNameController.text.trim();

    if (deviceId.isEmpty || deviceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter all fields!")));
      return;
    }

    DatabaseReference deviceRef = _dbRef.child("devices/$deviceId");

    await deviceRef.set({
      "deviceId": deviceId,
      "deviceName": deviceName,
      "userId": userId,
    }).then((_) {
      setState(() {
        existingDeviceId = deviceId;
        existingDeviceName = deviceName;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(existingDeviceId != null ? "Device updated successfully!" : "Device added successfully!"),
      ));

      _deviceNameController.clear();
      _deviceIdController.clear();
      Navigator.pop(context);
      _fetchSchedulesAndAlerts(); // Refresh schedules & alerts
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BedBuddy")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40.0,
              backgroundImage: _user?.photoURL != null
                  ? NetworkImage(_user!.photoURL!)
                  : const AssetImage("assets/images/user.png") as ImageProvider,
            ),
            const SizedBox(height: 20.0),
            Text(
              "Welcome, $_userName",
              style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30.0),
            const Text("Schedule", style: TextStyle(fontSize: 18.0)),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ScheduleScreen()),
              ),
              child: const Text("Schedule"),
            ),
            const SizedBox(height: 20),

            /// Today's Schedules
            if (todaySchedules.isNotEmpty) ...[
              const Text("Today's Schedules", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...todaySchedules.map((schedule) => ListTile(
                    title: Text("Time: ${schedule['time']}"),
                    subtitle: Text("Pill A: ${schedule['pillA_dose']} | Pill B: ${schedule['pillB_dose']} | Pill C: ${schedule['pillC_dose']}"),
                    trailing: Text("Status: ${schedule['status']}"),
                  )),
              const SizedBox(height: 20),
            ] else ...[
              const Text("No schedules for today", style: TextStyle(fontSize: 18.0, color: Colors.green)),
              const SizedBox(height: 20),
            ],

            /// Emergency Alerts
            if (emergencyAlerts.isNotEmpty) ...[
              const Text("Emergency Alerts", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),
              ...emergencyAlerts.map((alert) => ListTile(
                    title: Text("Time: ${alert['time']}"),
                    subtitle: Text(alert['message']),
                  )),
              const SizedBox(height: 20),
            ] else ...[
              const Text("No emergency alerts for today", style: TextStyle(fontSize: 18.0, color: Colors.green)),
              const SizedBox(height: 20),
            ],

            const Spacer(),
            ElevatedButton(
              onPressed: _showAddDeviceDialog,
              child: Text(existingDeviceId != null ? "Update Device" : "Add Device"),
            ),
          ],
        ),
      ),
    );
  }
}
