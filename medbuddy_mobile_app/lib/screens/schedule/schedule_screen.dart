import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medbuddy_mobile_application/screens/dashboard/dashboard_screen.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _dbRef = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  
  String? deviceId;
  String? deviceName;
  List<Map<String, dynamic>> _schedules = [];

  User? _user;

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _pillADoseController = TextEditingController();
  final _pillBDoseController = TextEditingController();
  final _pillCDoseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserDevice();
  }

  void _fetchUserDevice() async {
    DatabaseEvent event = await _dbRef.child("devices").orderByChild("userId").equalTo(_user!.uid).once();

    if (event.snapshot.value != null) {
      Map<String, dynamic> devices = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (devices.isNotEmpty) {
        deviceId = devices.keys.first;
        deviceName = devices[deviceId]?["deviceName"];
        _fetchSchedules();
      }
    }
  }

  void _fetchSchedules() async {
    if (deviceId == null) return;

    DatabaseEvent event = await _dbRef.child("devices/$deviceId/schedules").once();
    if (event.snapshot.exists && event.snapshot.value != null) {
      Map<String, dynamic> schedules = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _schedules = schedules.values.map((schedule) => schedule as Map<String, dynamic>).toList();
      });
    }
  }

  void _saveSchedule() async {
    if (deviceId == null) return;

    String scheduleId = _dbRef.child("devices/$deviceId/schedules").push().key!;
    String date = _dateController.text;
    String time = _timeController.text;
    
    Map<String, dynamic> scheduleData = {
      "date": date,
      "time": time,
      "pillA_dose": _pillADoseController.text,
      "pillB_dose": _pillBDoseController.text,
      "pillC_dose": _pillCDoseController.text,
      "status": "pending"
    };

    await _dbRef.child("devices/$deviceId/schedules/$scheduleId").set(scheduleData);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Schedule added successfully!")));
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Manager")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //Text("Device: $deviceName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            //const SizedBox(height: 10),
            //Text("User ID: ${_user?.uid ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
            //const SizedBox(height: 10),
            _schedules.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = _schedules[index];
                        return Card(
                          child: ListTile(
                            title: Text("Date: ${schedule['date']}"),
                            subtitle: Text("Time: ${schedule['time']}, Status: ${schedule['status']}"),
                          ),
                        );
                      },
                    ),
                  )
                : const Text("No schedules found. Add a new one!"),
            const SizedBox(height: 20),
            const Text("Add New Schedule", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Select Date"),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _timeController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Select Time"),
              onTap: _pickTime,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _pillADoseController,
              decoration: const InputDecoration(labelText: "Panadol Dose"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _pillBDoseController,
              decoration: const InputDecoration(labelText: "Candesartan Dose"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _pillCDoseController,
              decoration: const InputDecoration(labelText: "Amoxcillin Dose"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSchedule,
              child: const Text("Save Schedule"),
            ),
          ],
        ),
      ),
    );
  }
}
