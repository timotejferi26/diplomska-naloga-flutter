import 'dart:developer';
import 'dart:io';

import 'package:diplomska_naloga/libraries/getx/advanced/getx_sub_app.dart';
import 'package:diplomska_naloga/libraries/provider/advanced/provider_sub_app.dart';
import 'package:diplomska_naloga/libraries/riverpod/advanced/riverpod_sub_app.dart';
import 'package:diplomska_naloga/libraries/watch_it/advanced/watchit_sub_app.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

void logMemoryUsage(String stage) {
  final usedMemory = ProcessInfo.currentRss; // Trenutna poraba pomnilnika
  log('Memory usage at $stage: ${usedMemory / (1024 * 1024)} MB');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class SMSelectionScreen extends StatelessWidget {
  final void Function(StateManagementLib) onSelected;

  const SMSelectionScreen({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Provider'),
          onTap: () => onSelected(StateManagementLib.provider),
        ),
        ListTile(
          title: const Text('Riverpod'),
          onTap: () => onSelected(StateManagementLib.riverpod),
        ),
        ListTile(
          title: const Text('GetX'),
          onTap: () => onSelected(StateManagementLib.getx),
        ),
        ListTile(
          title: const Text('Watch_It'),
          onTap: () => onSelected(StateManagementLib.watchit),
        ),
      ],
    );
  }
}

enum StateManagementLib { provider, riverpod, getx, watchit }

class _MyAppState extends State<MyApp> {
  StateManagementLib? selectedSM;

  @override
  Widget build(BuildContext context) {
    logMemoryUsage('build');
    // Če še ni izbrane knjižnice, pokažemo menu
    if (selectedSM == null) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Choose State Management')),
          body: SMSelectionScreen(
            onSelected: (lib) {
              setState(() {
                selectedSM = lib;
              });
              logMemoryUsage('Selected ${lib.name} - Initial Load');
            },
          ),
        ),
      );
    } else {
      // Ko imamo izbrano SM knjižnico, pokažemo ustrezno "sub-aplikacijo".
      return buildSubApp(selectedSM!);
    }
  }

  Widget buildSubApp(StateManagementLib lib) {
    switch (lib) {
      case StateManagementLib.provider:
        return ProviderSubApp(onReset: _goBackToMenu);
      case StateManagementLib.riverpod:
        return RiverpodSubApp(onReset: _goBackToMenu);
      case StateManagementLib.getx:
        return GetXSubApp(onReset: _goBackToMenu);
      case StateManagementLib.watchit:
        return WatchItSubApp(onReset: _goBackToMenu);
    }
  }

  void _goBackToMenu() {
    setState(() {
      selectedSM = null;
    });
  }
}
