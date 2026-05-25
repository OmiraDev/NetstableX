import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/signal_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SignalService _signalService = SignalService();
  bool isStabilizing = false;
  String signalStrength = "Checking...";
  String networkType = "Searching...";
  Timer? _timer;

  String selectedProvider = "Dialog";
  List<String> providers = ["Dialog", "Mobitel", "Hutch"];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    await [Permission.location, Permission.phone].request();
    await Future.delayed(const Duration(milliseconds: 500));

    String rawCarrierName = await _signalService.getCarrierName();
    String formattedName = "Dialog";

    String rawLower = rawCarrierName.toLowerCase();

    if (rawLower.contains("dialog")) {
      formattedName = "Dialog";
    } else if (rawLower.contains("mobitel") || rawLower.contains("slt")) {
      formattedName = "Mobitel";
    } else if (rawLower.contains("hutch") || rawLower.contains("hutchison")) {
      formattedName = "Hutch";
    } else if (rawLower.contains("airtel")) {
      formattedName = "Airtel";
      if (!providers.contains("Airtel")) providers.add("Airtel");
    } else if (rawCarrierName != "Unknown" &&
        rawCarrierName.trim().isNotEmpty) {
      formattedName = rawCarrierName;
      if (!providers.contains(formattedName)) providers.add(formattedName);
    }

    setState(() {
      selectedProvider = formattedName;
    });

    _startSignalUpdates();
  }

  void _startSignalUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final data = await _signalService.getSignalData(selectedProvider);
      if (data != null && mounted) {
        setState(() {
          signalStrength = "${data['dbm']} dBm";
          networkType = data['networkType'];
        });
      }
    });
  }

  void toggleStabilizer() async {
    setState(() {
      isStabilizing = !isStabilizing;
    });

    if (isStabilizing) {
      await _signalService.startStabilizer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$selectedProvider Connection Stabilized!"),
            backgroundColor: Colors.greenAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      await _signalService.stopStabilizer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);
    const Color accentColor = Colors.greenAccent;
    const Color dangerColor = Colors.redAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "NetStable",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accentColor, Color(0xFF00BFA5)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "X",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 15.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedProvider,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: accentColor,
                      ),
                      dropdownColor: cardColor,
                      isExpanded: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      items: providers.map((String provider) {
                        return DropdownMenuItem<String>(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedProvider = newValue;
                          });
                          _startSignalUpdates();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: isStabilizing
                            ? accentColor.withOpacity(0.15)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: isStabilizing ? 5 : 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isStabilizing
                          ? accentColor.withOpacity(0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        signalStrength,
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          color: isStabilizing ? accentColor : Colors.white,
                          shadows: [
                            if (isStabilizing)
                              Shadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 15,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "LIVE SIGNAL STRENGTH",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          letterSpacing: 2,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cell_tower_rounded,
                              color: isStabilizing
                                  ? accentColor
                                  : Colors.amberAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              networkType,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                GestureDetector(
                  onTap: toggleStabilizer,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: isStabilizing
                              ? dangerColor.withOpacity(0.3)
                              : accentColor.withOpacity(0.2),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                        // Inner shadow effect simulation
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(4, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isStabilizing ? dangerColor : accentColor,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isStabilizing
                                ? Icons.power_settings_new_rounded
                                : Icons.rocket_launch_rounded,
                            color: isStabilizing ? dangerColor : accentColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isStabilizing ? "STOP" : "START",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: isStabilizing ? dangerColor : accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                InkWell(
                  onTap: () async {
                    await _signalService.openRadioSettings();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_ethernet_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Advanced Network Settings",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
