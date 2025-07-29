import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

class AnimationLoader extends StatefulWidget {
  final String text;
  final String animation;
  final String? infoImagePath;

  const AnimationLoader({
    Key? key,
    required this.text,
    required this.animation,
    this.infoImagePath,
  }) : super(key: key);

  @override
  State<AnimationLoader> createState() => _AnimationLoaderState();
}

class ShinyProgressBar extends StatefulWidget {
  const ShinyProgressBar({Key? key}) : super(key: key);

  @override
  State<ShinyProgressBar> createState() => _ShinyProgressBarState();
}

class _ShinyProgressBarState extends State<ShinyProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        height: 6,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.greenAccent.withOpacity(0.3),
                    Colors.blueAccent.withOpacity(0.9),
                    Colors.greenAccent.withOpacity(0.3),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  transform: _SlidingGradientTransform(slidePercent: _animation.value),
                ).createShader(bounds);
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              blendMode: BlendMode.srcATop,
            );
          },
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class _AnimationLoaderState extends State<AnimationLoader>
    with SingleTickerProviderStateMixin {
  bool _imageLoaded = false;
  int _currentImageIndex = 0;
  Timer? _imageChangeTimer;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final List<String> _factImages = List.generate(
    9,
        (index) => 'assets/images/loader_facts/fact_${index + 1}.png',
  )..shuffle();

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _imageChangeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      setState(() {
        _imageLoaded = false;
        _currentImageIndex = (_currentImageIndex + 1) % _factImages.length;
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _imageChangeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _factImages[_currentImageIndex];

    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔥 Animated fact image with zoom+fade
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _imageLoaded ? 1.0 : 0.0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          imagePath,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              Future.microtask(() {
                                if (mounted) {
                                  setState(() => _imageLoaded = true);
                                }
                              });
                            }
                            return child;
                          },
                        ),
                      ),
                    ),
                    if (!_imageLoaded)
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.2),

            Text(
              widget.text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            const ShinyProgressBar(),
          ],
        ),
      ),
    );
  }
}
