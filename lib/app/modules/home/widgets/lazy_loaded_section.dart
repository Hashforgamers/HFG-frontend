import 'package:flutter/material.dart';

class LazyLoadedSection extends StatefulWidget {
  final Widget child;
  final String sectionKey;
  final bool initiallyVisible;
  final Duration animationDuration;
  final Curve animationCurve;

  const LazyLoadedSection({
    super.key,
    required this.child,
    required this.sectionKey,
    this.initiallyVisible = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<LazyLoadedSection> createState() => _LazyLoadedSectionState();
}

class _LazyLoadedSectionState extends State<LazyLoadedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isVisible = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    
    if (widget.initiallyVisible) {
      _showSection();
    }
  }

  void _showSection() {
    if (_isVisible) return;
    
    setState(() {
      _isVisible = true;
      _isLoaded = true;
    });
    
    _animationController.forward();
  }

  void _hideSection() {
    if (!_isVisible) return;
    
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Extension to easily show/hide sections
extension LazyLoadedSectionExtension on _LazyLoadedSectionState {
  void show() => _showSection();
  void hide() => _hideSection();
}
