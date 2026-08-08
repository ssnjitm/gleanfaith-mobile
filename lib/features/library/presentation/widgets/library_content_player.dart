import 'dart:async';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

class LibraryContentPlayer extends StatefulWidget {
  final String type;
  final String? videoUrl;
  final String? audioUrl;
  final String? pdfUrl;
  final String? thumbnailUrl;
  final String body;

  const LibraryContentPlayer({
    super.key,
    required this.type,
    this.videoUrl,
    this.audioUrl,
    this.pdfUrl,
    this.thumbnailUrl,
    this.body = '',
  });

  @override
  State<LibraryContentPlayer> createState() => _LibraryContentPlayerState();
}

class _LibraryContentPlayerState extends State<LibraryContentPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  AudioPlayer? _audioPlayer;
  bool _audioInitializing = true;
  bool _audioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  PdfController? _pdfController;
  bool _pdfReady = false;
  String? _pdfError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    switch (widget.type) {
      case 'video':
        await _initVideo();
      case 'audio':
        await _initAudio();
      case 'pdf':
        await _initPdf();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) return;
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;
      await controller.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryBlue,
          handleColor: AppColors.primaryBlue,
          bufferedColor: AppColors.primaryBlue.withValues(alpha: 0.3),
          backgroundColor: Colors.grey.shade300,
        ),
        placeholder:
            widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
                ? Image.network(widget.thumbnailUrl!, fit: BoxFit.cover)
                : null,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  Future<void> _initAudio() async {
    final url = widget.audioUrl;
    if (url == null || url.isEmpty) return;
    try {
      final player = AudioPlayer();
      _audioPlayer = player;
      final duration = await player.setUrl(url);
      if (!mounted) return;
      setState(() {
        _audioDuration = duration ?? Duration.zero;
        _audioInitializing = false;
      });
      _positionSub = player.positionStream.listen((pos) {
        if (mounted) setState(() => _audioPosition = pos);
      });
      _playerStateSub = player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => _audioPlaying = state.playing);
      });
    } catch (e) {
      debugPrint('Audio init error: $e');
      if (mounted) setState(() => _audioInitializing = false);
    }
  }

  Future<void> _initPdf() async {
    final url = widget.pdfUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _pdfReady = false;
          _pdfError = 'No PDF attached';
        });
      }
      return;
    }
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) throw Exception('Empty PDF response');
      final data = Uint8List.fromList(bytes);
      final controller = PdfController(document: PdfDocument.openData(data));
      if (!mounted) return;
      setState(() {
        _pdfController = controller;
        _pdfReady = true;
        _pdfError = null;
      });
    } catch (e) {
      debugPrint('PDF init error: $e');
      if (mounted) {
        setState(() {
          _pdfReady = false;
          _pdfError = 'Could not load PDF';
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    final player = _audioPlayer;
    if (player == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _chewieController?.dispose();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (widget.type) {
      case 'video':
        return _buildVideo(isDark);
      case 'audio':
        return _buildAudio(isDark);
      case 'pdf':
        return _buildPdf(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVideo(bool isDark) {
    final chewie = _chewieController;
    if (chewie == null) {
      return _buildUnavailable(
        isDark,
        Icons.videocam_off_outlined,
        'Video unavailable',
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: chewie),
      ),
    );
  }

  Widget _buildAudio(bool isDark) {
    if (_audioInitializing) {
      return _buildLoading(isDark, 'Loading audio...');
    }

    final player = _audioPlayer;
    if (player == null) {
      return _buildUnavailable(
        isDark,
        Icons.headphones_outlined,
        'Audio unavailable',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
            child: const Icon(
              Icons.headphones_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Slider(
            value: _audioDuration.inMilliseconds > 0
                ? _audioPosition.inMilliseconds
                    .clamp(0, _audioDuration.inMilliseconds)
                    .toDouble()
                : 0,
            max: _audioDuration.inMilliseconds > 0
                ? _audioDuration.inMilliseconds.toDouble()
                : 1,
            activeColor: AppColors.primaryBlue,
            inactiveColor:
                isDark ? const Color(0xFF334155) : AppColors.borderLight,
            onChanged: (value) {
              player.seek(Duration(milliseconds: value.round()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(_audioPosition),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _format(_audioDuration),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => player.seek(
                  _audioPosition - const Duration(seconds: 10),
                ),
                icon: const Icon(Icons.replay_10_rounded),
                iconSize: 30,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: AppDimensions.paddingMd),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(
                    _audioPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMd),
              IconButton(
                onPressed: () => player.seek(
                  _audioPosition + const Duration(seconds: 10),
                ),
                icon: const Icon(Icons.forward_10_rounded),
                iconSize: 30,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdf(bool isDark) {
    if (!_pdfReady) {
      if (_pdfError != null) {
        return _buildUnavailable(
          isDark,
          Icons.picture_as_pdf_outlined,
          _pdfError!,
        );
      }
      return _buildLoading(isDark, 'Loading PDF...');
    }
    final controller = _pdfController;
    if (controller == null) {
      return _buildUnavailable(
        isDark,
        Icons.picture_as_pdf_outlined,
        'PDF unavailable',
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        height: 560,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMd,
                vertical: AppDimensions.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    'PDF Document',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  PdfPageNumber(
                    controller: controller,
                    builder: (context, loadingState, page, pagesCount) {
                      return Text(
                        '$page / ${pagesCount ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PdfView(
                controller: controller,
                scrollDirection: Axis.vertical,
                builders: PdfViewBuilders(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  pageLoaderBuilder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (context, error) => Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark, String message) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable(bool isDark, IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textLight),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }
}
