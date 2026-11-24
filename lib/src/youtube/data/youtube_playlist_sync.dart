import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:acervo/src/youtube/domain/youtube_video.dart';

class PlaylistSyncResult {
  const PlaylistSyncResult({
    required this.playlistId,
    required this.created,
    required this.added,
    required this.alreadyPresent,
  });

  final String playlistId;
  final bool created;
  final int added;
  final int alreadyPresent;
}

Future<PlaylistSyncResult> syncPrivatePlaylist({
  required YouTubeApiClient client,
  required Map<String, String> playlistsByTitle,
  required String title,
  required String description,
  required Iterable<YouTubeVideo> videos,
}) async {
  var playlistId = playlistsByTitle[title];
  final created = playlistId == null;
  playlistId ??= await client.createPrivatePlaylist(
    title: title,
    description: description,
  );
  playlistsByTitle[title] = playlistId;

  final existingVideoIds = created
      ? <String>{}
      : await client.fetchPlaylistVideoIds(playlistId);
  var added = 0;
  var alreadyPresent = 0;
  for (final video in videos) {
    if (!existingVideoIds.add(video.id)) {
      alreadyPresent += 1;
      continue;
    }
    try {
      await client.addVideoToPlaylist(
        playlistId: playlistId,
        videoId: video.id,
      );
      added += 1;
    } on YouTubeApiException catch (error) {
      // The list and insert requests are not atomic. Another sync may insert
      // the video between them, in which case the desired state was reached.
      if (!error.isPlaylistItemDuplicate) rethrow;
      alreadyPresent += 1;
    }
  }

  return PlaylistSyncResult(
    playlistId: playlistId,
    created: created,
    added: added,
    alreadyPresent: alreadyPresent,
  );
}
