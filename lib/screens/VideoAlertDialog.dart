import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.

class VideoAlertDialog extends StatefulWidget {
  final String videoUrl;

  const VideoAlertDialog(this.videoUrl, {super.key});

  @override
  VideoAlertDialogState createState() => VideoAlertDialogState();
}

class VideoAlertDialogState extends State<VideoAlertDialog> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    player.open(Media(widget.videoUrl));
    return AlertDialog(
      insetPadding: const EdgeInsets.only(),
      contentPadding: EdgeInsets.zero,
      content: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            AspectRatio(
              aspectRatio: 4 / 2,
              child:
                  //
                  SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                child: Video(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
