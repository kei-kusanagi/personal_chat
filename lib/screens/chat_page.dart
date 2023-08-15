import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// ignore: library_prefixes
import 'package:provider/provider.dart' as Prov;

import 'package:personal_messenger/models/message.dart';
import 'package:personal_messenger/models/profile.dart';
import 'package:personal_messenger/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

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
      themeModel.setIsDark(themeModel.isDark);
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
      themeModel.setColorTheme(color);
    }

    return Scaffold(
      // appBar: AppBar(title: const Text('Chat')),
      appBar: AppBar(
        backgroundColor: pickerColor,
        title: const Text('Chat'),
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
                        onPressed: () {
                          setState(() {
                            themeModel.colorTheme = pickerColor;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pickerColor,
                        ),
                        child: const Text('Got it'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.color_lens),
          ),
          IconButton(
            icon: themeModel.isDark
                ? const Icon(Icons.sunny)
                : const Icon(Icons.nights_stay),
            onPressed: toggleDarkMode,
          ),
          IconButton(
              onPressed: () {
                logout(context);
              },
              icon: const Icon(Icons.logout))
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
                  _submitCamera();
                },
                icon: const Icon(Icons.camera_alt),
              ),
              IconButton(
                onPressed: () {
                  _submitFile();
                },
                icon: const Icon(Icons.cloud_upload_outlined),
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
    final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
    Color pickerColor = themeModel.colorTheme;
    final text = _textController.text;
    final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      context.showSnackBar(
        message: 'Escribe un mensaje',
        messageColor: pickerColor,
        // context: context,
      );
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
        'file_path': '',
      });
    } on PostgrestException catch (Error) {
      context.showErrorSnackBar(message: Error.message);
    } catch (_) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }

  void _submitFile() async {
    String supabaseFilePath = '';
    String thumbnailFilePath = '';
    String _pickedFileName = '';
    final myUserId = supabase.auth.currentUser!.id;
    final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseKey);
    var pickedFile = await FilePicker.platform.pickFiles(allowMultiple: false);
    final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
    Color pickerColor = themeModel.colorTheme;

    if (pickedFile != null) {
      final file = File(pickedFile.files.first.path!);
      await client.storage
          .from('Files')
          .upload(pickedFile.files.first.name, file)
          .then((response) {
        supabaseFilePath = response;
      });

      bool _isVideo(String url) {
        final videoExtensions = [
          '.mp4',
          '.avi',
          '.mov',
          '.mkv',
          '.flv',
          '.wmv'
        ];
        final fileExtension = url.toLowerCase();

        return videoExtensions
            .any((extension) => fileExtension.endsWith(extension));
      }

      bool isVideoLink = _isVideo(supabaseFilePath);
      if (isVideoLink) {
        try {
          String? thumbnailPath = await videoThumbnail(
              'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$supabaseFilePath');
          final miniatura = File(thumbnailPath!);
          _pickedFileName = pickedFile.files.first.name;

          _pickedFileName =
              _pickedFileName.substring(0, _pickedFileName.lastIndexOf('.'));

          await client.storage
              .from('Files')
              .upload('$_pickedFileName.png', miniatura)
              .then((response) {
            thumbnailFilePath =
                'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$response';
          });
        } catch (e) {
          print(e);
        }
      } else {
        thumbnailFilePath = '';
      }

      try {
        await supabase.from('messages').insert({
          'profile_id': myUserId,
          'content':
              'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$supabaseFilePath',
          'file_path': thumbnailFilePath,
        });

        context.showSnackBar(
          message: "📎 Archivo subido 📂",
          messageColor: pickerColor,
          // context: context,
        );
      } on StorageException catch (error) {
        context.showErrorSnackBar(
          message: error.message,
        );
      } catch (e) {
        context.showErrorSnackBar(
          message: unexpectedErrorMessage,
        );
      }
    }
  }

  void _submitCamera() async {
    final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
    Color pickerColor = themeModel.colorTheme;
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    String filePath = '';
    final myUserId = supabase.auth.currentUser!.id;
    final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseKey);

    if (photo != null) {
      final File imageFile = File(photo.path);

      await client.storage
          .from('Files')
          .upload(photo.name, imageFile)
          .then((response) {
        filePath = response;
        // print(filePath);
      });

      try {
        await supabase.from('messages').insert({
          'profile_id': myUserId,
          'content':
              'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$filePath',
          'file_path': '',
        });
        context.showSnackBar(
          message: "📷 Foto subida correctamente 🖼",
          messageColor: pickerColor,
          // context: context,
        );
      } on StorageException catch (error) {
        context.showErrorSnackBar(
          message: error.message,
        );
      } catch (e) {
        context.showErrorSnackBar(
          message: unexpectedErrorMessage,
        );
      }
    }
  }
}

class _ChatBubble extends StatefulWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool isPlay = true;

  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.message.content)) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.message.content))
            ..initialize().then((_) {
              setState(() {});
            });
    } else {
      _controller = VideoPlayerController.asset('');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isVideo(String url) {
    final videoExtensions = ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv'];
    final fileExtension = url.toLowerCase();
    return videoExtensions
        .any((extension) => fileExtension.endsWith(extension));
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double containerWidth = screenSize.width * 0.95;
    double containerHeight = screenSize.height * 0.95;
    bool isImageUrl = Uri.tryParse(widget.message.content)?.isAbsolute ?? false;
    final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
    final Uri _url = Uri.parse(widget.message.content);

    List<Widget> chatContents = [
      if (!widget.message.isMine)
        CircleAvatar(
          child: widget.profile == null
              ? preloader
              : Text(widget.profile!.username.substring(0, 2)),
        ),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: widget.message.isMine
                ? themeModel.colorTheme
                : Theme.of(context).focusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: isImageUrl
              ? GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SingleChildScrollView(
                        child: AlertDialog(
                          insetPadding: const EdgeInsets.only(),
                          contentPadding: EdgeInsets.zero,
                          content: FractionallySizedBox(
                            widthFactor: 0.90,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back_ios),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        widget.message.filePath.isNotEmpty
                                            ? setState(() {
                                                _controller.pause();
                                                _controller
                                                    .seekTo(Duration.zero);
                                              })
                                            : null;
                                      },
                                    ),
                                  ),
                                  widget.message.filePath.isEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: widget.message.content,
                                          fit: BoxFit.cover,
                                          width: containerWidth, // alto
                                          height:
                                              containerHeight / 1.2, // ancho
                                        )
                                      : Builder(
                                          builder: (context) {
                                            _controller = VideoPlayerController
                                                .networkUrl(Uri.parse(
                                                    widget.message.content))
                                              ..initialize().then((_) {
                                                _controller.play();
                                              });

                                            return VideoAlertDialog(
                                                _controller);
                                          },
                                        ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.open_in_browser),
                                        tooltip: 'Abrir',
                                        onPressed: () {
                                          launchUrl(_url);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy),
                                        onPressed: () {
                                          if (isImageUrl) {
                                            copyImageUrlToClipboard(
                                                context, _url.toString());
                                            Navigator.of(context).pop();
                                          } else {
                                            context.showErrorSnackBar(
                                                message:
                                                    "No se puede copiar el archivo ❌");
                                            Navigator.of(context).pop();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () async {
                                          if (Platform.isAndroid ||
                                              Platform.isIOS) {
                                            Navigator.of(context).pop();

                                            _downloadFile(context,
                                                widget.message.content);
                                            context.showSnackBar(
                                              message:
                                                  'Archivo guardado en la galeria 📂',
                                              messageColor: Theme.of(context)
                                                  .primaryColor,
                                              // context: context,
                                            );
                                          } else {
                                            await launchUrl(_url);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: widget.message.filePath.isEmpty
                        ? CachedNetworkImage(
                            fit: BoxFit.cover,
                            width: containerWidth / 3,
                            height: containerHeight / 5,
                            imageUrl: widget.message.content,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        await launchUrl(_url);
                                      },
                                      iconSize: 80,
                                      icon: const Icon(
                                          Icons.file_present_rounded),
                                    ),
                                    const Text('Abrir archivo'),
                                  ],
                                ))
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: widget.message.filePath,
                                fit: BoxFit.cover,
                                width: containerWidth / 3,
                                height: containerHeight / 5,
                              ),
                              const Icon(
                                Icons.play_circle_filled,
                                color: Colors.white70,
                                size: 50,
                              ),
                            ],
                          ),
                  ),
                )
              : Text(widget.message.content),
        ),
      ),
      const SizedBox(width: 12),
      Text(format(widget.message.createdAt, locale: 'en_short')),
      const SizedBox(width: 60),
    ];
    if (widget.message.isMine) {
      chatContents = chatContents.reversed.toList();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment: widget.message.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}

void _downloadFile(BuildContext context, String url) async {
  bool dounloadError = false;
  var errorMessage;
  await FileDownloader.downloadFile(
    url: url,
    onDownloadCompleted: (String path) {
      dounloadError = false;
    },
    onDownloadError: (String error) {
      dounloadError = true;

      errorMessage = error;
    },
  );
  if (dounloadError) {
    context.showErrorSnackBar(
        message: '❌ Error al descargar el archivo: $errorMessage');
  }
}

void copyImageUrlToClipboard(BuildContext context, imageUrl) {
  final themeModel = Prov.Provider.of<ThemeModel>(context, listen: false);
  Color pickerColor = themeModel.colorTheme;
  Clipboard.setData(ClipboardData(text: imageUrl));

  context.showSnackBar(
    message: "Copiado al 📋",
    messageColor: pickerColor,
    // context: context,
  );
}

Future<String?> videoThumbnail(path) async {
  final fileName = await VideoThumbnail.thumbnailFile(
    video: path,
    thumbnailPath: (await getTemporaryDirectory()).path,
    imageFormat: ImageFormat.PNG,
    maxHeight: 500,
    maxWidth: 500,
    quality: 100,
  );

  return fileName;
}

class VideoAlertDialog extends StatefulWidget {
  final VideoPlayerController controller;

  VideoAlertDialog(this.controller);

  @override
  _VideoAlertDialogState createState() => _VideoAlertDialogState();
}

class _VideoAlertDialogState extends State<VideoAlertDialog> {
  bool isPlaying = true;

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        widget.controller.play();
      } else {
        widget.controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double containerWidth = screenSize.width * 0.95;
    double containerHeight = screenSize.height * 0.95;
    return AlertDialog(
      insetPadding: const EdgeInsets.only(),
      contentPadding: EdgeInsets.zero,
      content: FractionallySizedBox(
        widthFactor: 0.90,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                // aspectRatio: screenSize.height / screenSize.width,
                aspectRatio: 4 / 2,
                child: VideoPlayer(widget.controller),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          if (widget.controller.value.isPlaying) {
                            widget.controller.pause();
                          } else {
                            widget.controller.play();
                          }
                          togglePlayPause();
                        });
                      },
                      icon: isPlaying
                          ? const Icon(Icons.pause)
                          : const Icon(Icons.play_arrow)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        widget.controller.pause();
                        widget.controller.seekTo(Duration.zero);
                        isPlaying = false;
                      });
                    },
                    icon: const Icon(Icons.stop),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
