import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String projectId;
  final String otherUserId;
  final bool isClient;

  const ChatScreen({
    super.key,
    required this.projectId,
    required this.otherUserId,
    required this.isClient,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final _scrollController = ScrollController();
  late Future<DocumentSnapshot> _otherUserFuture;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _otherUserFuture = _getOtherUser();
    _initializeChat();
  }

  Future<DocumentSnapshot> _getOtherUser() async {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();
  }

  Future<void> _initializeChat() async {
    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.projectId);
      await chatRef.set({
        'projectId': widget.projectId,
        'participants': {
          'client': widget.isClient ? user!.uid : widget.otherUserId,
          'freelancer': widget.isClient ? widget.otherUserId : user!.uid,
        },
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _initialized = true);
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_initialized) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.projectId)
          .collection('messages')
          .add({
        'senderId': user!.uid,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.projectId)
          .update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: _otherUserFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            }
            if (snapshot.hasError) {
              return const Text('Usuario');
            }
            return Text(snapshot.data?['name'] ?? 'Usuario');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: !_initialized
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.projectId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No hay mensajes aún. ¡Envía el primero!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == user!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF0D47A1)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}