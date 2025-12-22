import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  // Mapping from media ID to local file ID or path
  // We use MediaItem.id as the song ISAR ID or Path.

  AudioPlayerHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToSequenceState();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      debugPrint('Error loading audio source: $e');
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
    super.setRepeatMode(repeatMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.setShuffleModeEnabled(true);
    }
    super.setShuffleMode(shuffleMode);
  }

  // Queue Management
  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSources = mediaItems.map(_createAudioSource).toList();
    await _playlist.addAll(audioSources);

    // Update queue in audio_service
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    await _playlist.clear();
    final audioSources = queue.map(_createAudioSource).toList();
    await _playlist.addAll(audioSources);
    this.queue.add(queue);
  }

  // Custom action to clear queue and play a new list
  Future<void> playSongList(List<MediaItem> items, int initialIndex) async {
    await _playlist.clear();
    queue.add(items);
    final audioSources = items.map(_createAudioSource).toList();
    await _playlist.addAll(audioSources);
    await _player.seek(Duration.zero, index: initialIndex);
    await _player.play();
  }

  UriAudioSource _createAudioSource(MediaItem item) {
    return AudioSource.uri(
      Uri.parse(item.id), // ID is path
      tag: item, // Store MediaItem as tag
    );
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  void _listenToPlaybackState() {
    // We do NOT listen to positionStream here because sending continuous position updates
    // without updating updateTime causes the audio_service clients (and our UI) to
    // double-count the elapsed time.
    // _notifyAudioHandlerAboutPlaybackEvents handles the necessary state updates for
    // play/pause/seek/completion.
  }

  void _listenToCurrentPosition() {
    // Listen to shuffle mode
    _player.shuffleModeEnabledStream.listen((enabled) {
      final oldState = playbackState.value;
      playbackState.add(
        oldState.copyWith(
          shuffleMode: enabled
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
        ),
      );
    });

    // Listen to loop mode
    _player.loopModeStream.listen((loopMode) {
      final oldState = playbackState.value;
      playbackState.add(
        oldState.copyWith(
          repeatMode: const {
            LoopMode.off: AudioServiceRepeatMode.none,
            LoopMode.one: AudioServiceRepeatMode.one,
            LoopMode.all: AudioServiceRepeatMode.all,
          }[loopMode]!,
        ),
      );
    });
  }

  void _listenToSequenceState() {
    _player.sequenceStateStream.listen((state) {
      final sequence = state?.sequence;
      if (sequence == null || sequence.isEmpty) return;

      final source = state?.currentSource;
      if (source is UriAudioSource && source.tag is MediaItem) {
        final item = source.tag as MediaItem;
        mediaItem.add(item);
      }
    });
  }

  void _listenToBufferedPosition() {}
  void _listenToTotalDuration() {}
  // Sleep Timer
  Timer? _sleepTimer;

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'setSleepTimer') {
      final minutes = extras?['minutes'] as int?;
      _sleepTimer?.cancel();
      if (minutes != null && minutes > 0) {
        _sleepTimer = Timer(Duration(minutes: minutes), () {
          pause();
          _sleepTimer = null;
        });
      }
    } else if (name == 'setVolume') {
      final volume = extras?['volume'] as double?;
      if (volume != null) {
        await _player.setVolume(volume);
      }
    } else if (name == 'getVolume') {
      return _player.volume;
    }
  }
}
