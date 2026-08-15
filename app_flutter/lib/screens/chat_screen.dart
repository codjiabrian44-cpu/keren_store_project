import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int orderId; 

  const ChatScreen({super.key, required this.orderId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  IO.Socket? socket;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String _monNom = "Client";
  int _monId = 0; 
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _preparerChat();
  }

  Future<void> _preparerChat() async {
    final prefs = await SharedPreferences.getInstance();
    _monNom = prefs.getString('user_nom') ?? "Moi";
    _monId = prefs.getInt('user_id') ?? 0; 

    final historique = await ChatService.getMessages(widget.orderId);
    setState(() {
      _messages = historique;
      _isLoading = false;
    });
    _faireDefilerVersLeBas();

    _connecterSocket();
  }

  void _connecterSocket() {
    socket = IO.io('https://keren-store-api.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      socket!.emit('rejoindre_chat', {'order_id': widget.orderId});
    });

    socket!.on('nouveau_message', (data) {
      if (mounted) {
        setState(() {
          _messages.add(data);
        });
        _faireDefilerVersLeBas();
      }
    });
  }

  Future<void> _envoyerMessage() async {
    String texte = _messageController.text.trim();
    if (texte.isEmpty) return;

    _messageController.clear(); 
    
    await ChatService.sendMessage(widget.orderId, texte);
  }

  void _faireDefilerVersLeBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket?.emit('quitter_chat', {'order_id': widget.orderId});
    socket?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // LE FIX EST LÀ : L'écran est enveloppé dans un Scaffold avec un AppBar
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Suivi de Commande #${widget.orderId}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(15),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      
                      bool estSysteme = msg['contenu'].toString().startsWith('🛒');

                      if (estSysteme) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                            ),
                            child: Text(
                              msg['contenu'],
                              style: TextStyle(color: colorScheme.primary, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      bool vientDeMoi = false;
                      if (msg['expediteur_id'] != null && _monId != 0) {
                        vientDeMoi = msg['expediteur_id'] == _monId;
                      } else if (msg['expediteur_nom'] != null) {
                        vientDeMoi = msg['expediteur_nom'] == _monNom;
                      }

                      return Align(
                        alignment: vientDeMoi ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: vientDeMoi ? colorScheme.primary : colorScheme.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: Radius.circular(vientDeMoi ? 15 : 0),
                              bottomRight: Radius.circular(vientDeMoi ? 0 : 15),
                            ),
                          ),
                          child: Text(
                            msg['contenu'],
                            style: TextStyle(
                              color: vientDeMoi 
                                  ? Colors.black 
                                  : (isDarkMode ? Colors.white : Colors.black),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Écrire un message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black, size: 20),
                      onPressed: _envoyerMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}