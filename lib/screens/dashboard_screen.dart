import 'package:flutter/material.dart';
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
  String networkType = "Hutch 4G";

  void toggleStabilizer() async {
    setState(() {
      isStabilizing = !isStabilizing;
    });

    if (isStabilizing) {
      await _signalService.startStabilizer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NetStable Stabilizer Activated!")),
        );
      }
    } else {
      await _signalService.stopStabilizer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NetStable X",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xff1e1e1e),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isStabilizing
                      ? Colors.greenAccent
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    signalStrength,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: isStabilizing ? Colors.greenAccent : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "SIGNAL STRENGTH (dBm)",
                    style: TextStyle(color: Colors.grey, letterSpacing: 1.5),
                  ),
                  const Divider(height: 30, color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.network_check,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        networkType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              isStabilizing
                  ? "Target Area: -70 to -90 dBm (Sweet Spot)"
                  : "Press Start to optimize connection",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            GestureDetector(
              onTap: toggleStabilizer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStabilizing
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.greenAccent.withOpacity(0.1),
                  border: Border.all(
                    color: isStabilizing
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isStabilizing
                          ? Colors.redAccent.withOpacity(0.3)
                          : Colors.greenAccent.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isStabilizing ? "STOP" : "START",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isStabilizing
                          ? Colors.redAccent
                          : Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
