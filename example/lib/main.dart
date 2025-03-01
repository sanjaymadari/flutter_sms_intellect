import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_sms_intellect/flutter_sms_intellect.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    try {
      bool hasPermission = await SmsInbox.hasPermissions();

      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      print('Failed to check permissions: ${e.message}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool result = await SmsInbox.requestPermissions();
      setState(() {
        _hasPermission = result;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      print('Failed to request permissions: ${e.message}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SMS Intellect Example')),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasPermission
                ? const SmsInboxPage()
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SMS permissions required to read messages',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: requestPermissions,
                        child: const Text('Request Permissions'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class SmsInboxPage extends StatefulWidget {
  const SmsInboxPage({super.key});

  @override
  _SmsInboxPageState createState() => _SmsInboxPageState();
}

class _SmsInboxPageState extends State<SmsInboxPage> {
  List<SmsMessage> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await SmsInbox.getAllSms(count: 100);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading messages: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: loadMessages, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No messages found', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loadMessages,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadMessages,
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return ListTile(
            title: Text(message.address),
            subtitle: Text(message.body),
            trailing: Text(
              DateTime.fromMillisecondsSinceEpoch(
                message.date,
              ).toString().substring(0, 16),
            ),
          );
        },
      ),
    );
  }
}
