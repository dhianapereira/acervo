import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:acervo/src/youtube/domain/youtube_video.dart';

class PlaylistSyncResult {
  const PlaylistSyncResult({
    required this.playlistId,
    required this.created,
    required this.added,
    required this.alreadyPresent,
    required this.removed,
  });

  final String playlistId;
  final bool created;
  final int added;
  final int alreadyPresent;
  final int removed;
}

Future<PlaylistSyncResult> syncPrivatePlaylist({
  required YouTubeApiClient client,
  required Map<String, String> playlistsByTitle,
  required String title,
  required String description,
  required Iterable<YouTubeVideo> videos,
  bool removeMissing = false,
}) async {
  var playlistId = playlistsByTitle[title];
  final created = playlistId == null;
  playlistId ??= await client.createPrivatePlaylist(
    title: title,
    description: description,
  );
  playlistsByTitle[title] = playlistId;

  final desiredVideos = videos.toList();
  final desiredVideoIds = desiredVideos.map((video) => video.id).toSet();
  final existingItems = !created && removeMissing
      ? await client.fetchPlaylistItems(playlistId)
      : const <Never>[];
  final existingVideoIds = created
      ? <String>{}
      : removeMissing
      ? existingItems.map((item) => item.videoId).toSet()
      : await client.fetchPlaylistVideoIds(playlistId);
  var removed = 0;
  if (removeMissing) {
    for (final item in existingItems) {
      if (desiredVideoIds.contains(item.videoId)) continue;
      await client.deletePlaylistItem(item.id);
      existingVideoIds.remove(item.videoId);
      removed += 1;
    }
  }
  var added = 0;
  var alreadyPresent = 0;
  for (final video in desiredVideos) {
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
    removed: removed,
  );
}
