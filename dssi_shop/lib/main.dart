import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Gemini Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  String message = "";
  bool _isSending = false;
  String _mode = "gemini"; 
  
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
        _messages.add(ChatMessage(text: text, isUser: true));
        _isSending = true;
        _controller.clear();
    });

    try {
        final response = await http.post(
        Uri.parse('http://192.168.1.155:3001/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text, 'mode': _mode}), 
        );

        if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? 'No reply';
        setState(() {
            _messages.add(ChatMessage(text: reply, isUser: false));
        });
        } else {
        setState(() {
            _messages.add(ChatMessage(
                text: 'Error: ${response.statusCode}', isUser: false));
        });
        }
    } catch (e) {
        setState(() {
        _messages.add(ChatMessage(text: 'Exception: $e', isUser: false));
        });
    } finally {
        setState(() => _isSending = false);
    }
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Gemini Demo'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _mode = value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: "gemini", child: Text("Gemini")),
              const PopupMenuItem(value: "gpt", child: Text("OpenAI GPT")),
              const PopupMenuItem(value: "demo", child: Text("Demo Mode")),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: Text(_mode.toUpperCase())),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
