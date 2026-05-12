import 'package:flutter/material.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/pages/infusion_list_controller.dart';
import 'package:ivgo/widgets/timer_card_base.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({
    super.key,
    required this.controller,
    required this.onComplete,
    required this.onSkip,
  });

  final InfusionListController controller;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _titleController = TextEditingController(text: 'IV Infusion #1');
  final TextEditingController _volumeController = TextEditingController(text: '500');
  final TextEditingController _dropFactorController = TextEditingController(text: '20');
  final TextEditingController _flowRateController = TextEditingController(text: '30');

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _volumeFocus = FocusNode();
  final FocusNode _dropFactorFocus = FocusNode();
  final FocusNode _flowRateFocus = FocusNode();

  bool _titleFieldAnimated = false;
  bool _volumeFieldAnimated = false;
  bool _dropFactorFieldAnimated = false;
  bool _flowRateFieldAnimated = false;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _volumeController.dispose();
    _dropFactorController.dispose();
    _flowRateController.dispose();
    _titleFocus.dispose();
    _volumeFocus.dispose();
    _dropFactorFocus.dispose();
    _flowRateFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          TextButton(
            onPressed: widget.onSkip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: <Widget>[
                  _buildWelcomePage(),
                  _buildNamePage(),
                  _buildVolumePage(),
                  _buildFlowRatePage(),
                  _buildCreatePage(),
                ],
              ),
            ),
            _buildPageIndicators(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animateFieldIfNeeded(page);
  }

  void _animateFieldIfNeeded(int page) {
    if (page == 1 && !_titleFieldAnimated) {
      _titleFieldAnimated = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _titleFocus.requestFocus();
      });
    } else if (page == 2 && !_volumeFieldAnimated) {
      _volumeFieldAnimated = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _volumeFocus.requestFocus();
      });
    } else if (page == 3 && !_dropFactorFieldAnimated) {
      _dropFactorFieldAnimated = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _dropFactorFocus.requestFocus();
      });
    } else if (page == 4 && !_flowRateFieldAnimated) {
      _flowRateFieldAnimated = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _flowRateFocus.requestFocus();
      });
    }
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.vaccines,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 48),
          Text(
            'Welcome to IV Go',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Let's set up your first infusion timer",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            'Track your IV infusions with precision and ease',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return _buildFormPage(
      title: 'Name Your Infusion',
      description: 'Give your infusion a descriptive name to easily identify it later.',
      icon: Icons.label_outline,
      child: Column(
        children: <Widget>[
          _AnimatedTextField(
            focusNode: _titleFocus,
            controller: _titleController,
            label: 'Infusion Name',
            hint: 'e.g., IV Infusion #1',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(
            'The title helps you identify this infusion among others.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumePage() {
    return _buildFormPage(
      title: 'Set Your Target',
      description: 'Enter the total volume of fluid to be infused.',
      icon: Icons.water_drop_outlined,
      child: Column(
        children: <Widget>[
          _AnimatedTextField(
            focusNode: _volumeFocus,
            controller: _volumeController,
            label: 'Target Volume (ml)',
            hint: 'e.g., 500',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Typical volumes range from 100ml to 1000ml depending on the treatment.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRatePage() {
    return _buildFormPage(
      title: 'Configure Flow Rate',
      description: 'Set the drop factor and flow rate for your infusion.',
      icon: Icons.speed_outlined,
      child: Column(
        children: <Widget>[
          _AnimatedTextField(
            focusNode: _dropFactorFocus,
            controller: _dropFactorController,
            label: 'Drop Factor (gtts/ml)',
            hint: 'e.g., 20',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _AnimatedTextField(
            focusNode: _flowRateFocus,
            controller: _flowRateController,
            label: 'Flow Rate (gtts/min)',
            hint: 'e.g., 30',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'gtts/min (drops per minute) determines how fast the fluid flows. Check your IV set for the drop factor.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Create It!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your timer is ready to go',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          TimerCardBase(
            previewData: _getPreviewData(),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _createTimer,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Create Timer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPage({
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(5, (int index) {
          final bool isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final bool canGoBack = _currentPage > 0;
    final bool isLastPage = _currentPage == 4;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          if (canGoBack)
            Expanded(
              child: OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                child: const Text('Back'),
              ),
            ),
          if (canGoBack) const SizedBox(width: 16),
          Expanded(
            flex: canGoBack ? 1 : 2,
            child: FilledButton(
              onPressed: isLastPage ? null : _goNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
              child: Text(isLastPage ? '' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goNext() {
    if (_currentPage < 4 && _validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 1:
        return _titleController.text.trim().isNotEmpty;
      case 2:
        final volume = double.tryParse(_volumeController.text);
        return volume != null && volume > 0;
      case 3:
        final dropFactor = double.tryParse(_dropFactorController.text);
        final flowRate = double.tryParse(_flowRateController.text);
        return dropFactor != null && dropFactor > 0 && flowRate != null && flowRate > 0;
      default:
        return true;
    }
  }

  TimerPreviewData _getPreviewData() {
    return TimerPreviewData(
      title: _titleController.text.trim().isEmpty ? 'IV Infusion #1' : _titleController.text.trim(),
      volume: double.tryParse(_volumeController.text) ?? 0,
      dropFactor: double.tryParse(_dropFactorController.text) ?? 20,
      flowRate: double.tryParse(_flowRateController.text) ?? 30,
    );
  }

  Future<void> _createTimer() async {
    final characteristics = InfusionCharacteristics(
      volume: double.tryParse(_volumeController.text) ?? 500,
      dropFactor: double.tryParse(_dropFactorController.text) ?? 20,
      flowRate: double.tryParse(_flowRateController.text) ?? 30,
    );

    final title = _titleController.text.trim().isEmpty ? 'IV Infusion #1' : _titleController.text.trim();

    await widget.controller.addTimer(title: title, characteristics: characteristics);
    widget.onComplete();
  }
}

class _AnimatedTextField extends StatefulWidget {
  const _AnimatedTextField({
    required this.focusNode,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode && widget.focusNode.hasFocus) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value.clamp(0.85, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _controller.isAnimating
                    ? <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          ),
        );
      },
      child: TextField(
        focusNode: widget.focusNode,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}