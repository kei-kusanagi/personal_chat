import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart' as Prov;

import 'package:personal_messenger/models/message.dart';
import 'package:personal_messenger/models/profile.dart';
import 'package:personal_messenger/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Page to chat with someone.
///
/// Displays chat bubbles as a ListView and TextField to enter new chat.

String supabaseUrl = 'https://bdhwkukeejylmfoxyygb.supabase.co';
String supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaHdrdWtlZWp5bG1mb3h5eWdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTAyMzM1MjMsImV4cCI6MjAwNTgwOTUyM30.9civyOj1ITEsIAFcwc0nrQB6ihqEcsg2hp2emylRaRQ';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const ChatPage(),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};

  @override
  void initState() {
    final myUserId = supabase.auth.currentUser!.id;
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps
            .map((map) => Message.fromMap(map: map, myUserId: myUserId))
            .toList());
    super.initState();
  }

  void toggleDarkMode() {
    setState(() {
      final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
      themeModel.isDark = !themeModel.isDark;
    });
  }

  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data =
        await supabase.from('profiles').select().eq('id', profileId).single();
    final profile = Profile.fromMap(data);
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
    Color pickerColor = themeModel.colorTheme;

    void changeColor(Color color) {
      setState(() => pickerColor = color);
    }

    return Scaffold(
      // appBar: AppBar(title: const Text('Chat')),
      appBar: AppBar(
        backgroundColor: pickerColor,
        title: Text('Chat'),
        actions: [
          IconButton(
            iconSize: 20,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Pick a color!'),
                    content: SingleChildScrollView(
                      child: BlockPicker(
                        pickerColor: pickerColor,
                        onColorChanged: changeColor,
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('Got it'),
                        onPressed: () {
                          setState(() {
                            themeModel.colorTheme = pickerColor;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pickerColor,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.color_lens),
          ),
          IconButton(
            icon:
                themeModel.isDark ? Icon(Icons.sunny) : Icon(Icons.nights_stay),
            onPressed: toggleDarkMode,
          ),
          IconButton(
              onPressed: () {
                Logout(context);
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('Start your conversation now :)'),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];

                            /// I know it's not good to include code that is not related
                            /// to rendering the widget inside build method, but for
                            /// creating an app quick and dirty, it's fine 😂
                            _loadProfileCache(message.profileId);

                            return _ChatBubble(
                              message: message,
                              profile: _profileCache[message.profileId],
                            );
                          },
                        ),
                ),
                const _MessageBar(),
              ],
            );
          } else {
            return preloader;
          }
        },
      ),
    );
  }
}

/// Set of widget that contains TextField and Button to submit message
class _MessageBar extends StatefulWidget {
  const _MessageBar({
    Key? key,
  }) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).splashColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _submitFile();
                },
                icon: Icon(Icons.cloud_upload_outlined),
              ),
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  autofocus: true,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _submitMessage(),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
      });
    } on PostgrestException catch (Error) {
      context.showErrorSnackBar(
          message: Error.message, messageColor: Colors.red);
    } catch (_) {
      context.showErrorSnackBar(
          message: unexpectedErrorMessage, messageColor: Colors.red);
    }
  }

  void _submitFile() async {
    String file_path = '';
    final myUserId = supabase.auth.currentUser!.id;
    final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseKey);
    var pickedFile = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (pickedFile != null) {
      final file = File(pickedFile.files.first.path!);
      await client.storage
          .from('Files')
          .upload(pickedFile.files.first.name, file)
          .then((response) {
        file_path = response;
        print(file_path);
      });

      try {
        await supabase.from('messages').insert({
          'profile_id': myUserId,
          'content':
              'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$file_path',
        });
        context.showErrorSnackBar(
          message: "Archivo subido",
          messageColor: Colors.greenAccent,
        );
      } on StorageException catch (error) {
        context.showErrorSnackBar(
          message: error.message,
          messageColor: Colors.red,
        );
      } catch (e) {
        context.showErrorSnackBar(
          message: unexpectedErrorMessage,
          messageColor: Colors.red,
        );
      }
    }
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    bool isImageUrl = Uri.tryParse(message.content)?.isAbsolute ?? false;
    final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
    final Uri _url = Uri.parse(message.content);

    List<Widget> chatContents = [
      if (!message.isMine)
        CircleAvatar(
          child: profile == null
              ? preloader
              : Text(profile!.username.substring(0, 2)),
        ),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: message.isMine
                ? themeModel.colorTheme
                : Theme.of(context).focusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: isImageUrl
              ? GestureDetector(
                  onTap: () async {
                    if (Platform.isAndroid || Platform.isIOS) {
                      print('mensaje tapeado en Android');
                    } else {
                      await launch(message.content);
                      print('mensaje tapeado en Windows');
                    }
                  },
                  child: CachedNetworkImage(
                    imageUrl: message.content,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.download),
                  ),
                )
              : Text(message.content),
        ),
      ),
      const SizedBox(width: 12),
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 60),
    ];
    if (message.isMine) {
      chatContents = chatContents.reversed.toList();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment:
            message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}

// void _downloadFile(String url, String fileName) async {
//   final taskId = await FlutterDownloader.enqueue(
//     url: url,
//     savedDir:
//         'ruta/donde/guardar/el/archivo', // Puedes cambiar esto por el directorio deseado
//     fileName: fileName,
//     showNotification:
//         true, // Mostrar notificación en la barra de estado al descargar
//     openFileFromNotification:
//         true, // Abrir automáticamente el archivo descargado cuando se toca la notificación
//   );
// }
