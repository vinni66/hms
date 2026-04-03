import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _api = ApiService();
  final _msgC = TextEditingController();
  final _scrollC = ScrollController();
  final _picker = ImagePicker();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final history = await _api.getChatHistory("patient_convo_1");
      if (history.isEmpty) {
        _messages.add({
          'is_user': false,
          'text': "Hello! I'm Rakshak 🩺. I have access to your basic profile and past appointment history. How can I assist you today? You can detail your symptoms or upload an image of a medical report/issue.",
          'risk_level': 'normal'
        });
      } else {
        for (var m in history) {
          _messages.add({
            'is_user': m['is_user'] == 1 || m['is_user'] == true,
            'text': m['text'] ?? '',
            'risk_level': m['risk_level'] ?? 'normal',
          });
        }
      }
    } catch (e) {
      _messages.add({
        'is_user': false,
        'text': "Hello! I'm Rakshak 🩺. (Could not load past history)",
        'risk_level': 'normal'
      });
    }
    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollC.hasClients) _scrollC.animateTo(_scrollC.position.maxScrollExtent, duration: 300.ms, curve: Curves.easeOut);
    });
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() => _selectedImage = img);
    }
  }

  Future<void> _send() async {
    final text = _msgC.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final imgToProcess = _selectedImage;
    setState(() {
      _messages.add({
        'is_user': true,
        'text': text,
        'image': imgToProcess != null, 
      });
      _msgC.clear();
      _selectedImage = null;
      _loading = true;
    });
    _scrollToBottom();

    try {
      String? base64Str;
      if (imgToProcess != null) {
        final bytes = await imgToProcess.readAsBytes();
        base64Str = base64Encode(bytes);
      }

      // Format history accurately for the API
      final history = _messages.map((m) => {
        'role': m['is_user'] == true ? 'user' : 'assistant',
        'content': m['text'] ?? '',
      }).toList();

      final res = await _api.sendMessage(text, "patient_convo_1", history, imageBase64: base64Str);
      
      setState(() {
        _loading = false;
        _messages.add({
          'is_user': false,
          'text': res['ai_response']?['text'] ?? "I couldn't process that.",
          'risk_level': res['ai_response']?['risk_level'] ?? 'normal',
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        _messages.add({'is_user': false, 'text': '⚠️ Connection error. Please try again.', 'risk_level': 'normal'});
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.bot, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Rakshak Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: isDark ? AppColors.bgDarkSecondary : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.trash2, color: AppColors.error.withAlpha(200)),
            onPressed: () async {
              await _api.clearChat("patient_convo_1");
              setState(() {
                _messages.clear();
                _messages.add({
                  'is_user': false,
                  'text': "Hello! I'm Rakshak 🩺. I have access to your basic profile and past appointment history. How can I assist you today? You can detail your symptoms or upload an image of a medical report/issue.",
                  'risk_level': 'normal'
                });
              });
            },
          )
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollC,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final m = _messages[i];
              final bool isUser = m['is_user'] == true;
              final rLevel = m['risk_level'] ?? 'normal';

              Color bubbleColor;
              if (isUser) {
                bubbleColor = AppColors.primary;
              } else {
                bubbleColor = rLevel == 'urgent' ? AppColors.error.withAlpha(isDark? 80: 40)
                            : rLevel == 'caution' ? AppColors.warning.withAlpha(isDark? 80: 40)
                            : (isDark ? AppColors.cardDark : Colors.white);
              }

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                      bottomLeft: !isUser ? Radius.zero : const Radius.circular(20),
                    ),
                    boxShadow: [if (!isUser) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (!isUser && rLevel != 'normal')
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rLevel == 'urgent' ? AppColors.error : AppColors.warning,
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Text(rLevel.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    
                    if (m['image'] == true)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.image, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Image Attached', style: TextStyle(color: Colors.white, fontSize: 12))
                        ]),
                      ),
                      
                    Text(m['text'], style: TextStyle(
                      color: isUser ? Colors.white : (isDark ? AppColors.textDark : AppColors.textLight),
                      height: 1.5,
                    )),
                  ]),
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0);
            },
          ),
        ),
        
        if (_loading)
          const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: AppColors.primary)),

        // Input Area
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkSecondary : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(LucideIcons.fileImage, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_selectedImage!.name, style: const TextStyle(fontSize: 12, color: AppColors.primary), maxLines: 1)),
                    IconButton(icon: const Icon(LucideIcons.x, size: 18, color: AppColors.primary), onPressed: () => setState(()=> _selectedImage = null))
                  ]),
                ),
              Row(children: [
                IconButton(
                  icon: const Icon(LucideIcons.paperclip, color: AppColors.primary),
                  onPressed: _loading ? null : _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgC,
                    decoration: InputDecoration(
                      hintText: _selectedImage != null ? 'Add a message about this image...' : 'Ask Rakshak...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _send(),
                    enabled: !_loading,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _loading ? null : _send,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
