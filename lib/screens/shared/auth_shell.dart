import 'package:flutter/material.dart';

import '../../theme/app_ui.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showSplit = true,
    this.rightTitle,
    this.rightIcon = Icons.security,
    this.compact = false,
  });

  final Widget child;
  final bool showSplit;
  final String? rightTitle;
  final IconData rightIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;
    final shouldSplit = showSplit && isDesktop;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: shouldSplit
            ? Row(
                children: [
                  Expanded(child: _leftPanel()),
                  Expanded(child: _rightPanel()),
                ],
              )
            : _leftPanel(singlePanel: true),
      ),
    );
  }

  Widget _leftPanel({bool singlePanel = false}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 32,
          vertical: compact ? 18 : 28,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 520 : 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandHeader(),
              SizedBox(height: compact ? 26 : 38),
              child,
              SizedBox(height: compact ? 48 : 90),
              const Text(
                'Copyrights © 2026 - FalconIT',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF707784), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rightPanel() {
    return Container(
      color: const Color(0xFFF9DEC2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 420,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7D1),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(rightIcon, size: 170, color: const Color(0xFF273C59)),
            ),
            if (rightTitle != null) ...[
              const SizedBox(height: 24),
              Text(
                rightTitle!,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF444B57),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5D8E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class AuthStyles {
  static const heading = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: Color(0xFF252C38),
  );

  static const subHeading = TextStyle(
    fontSize: 17,
    color: Color(0xFF6A717E),
    height: 1.35,
  );

  static const fieldLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF282D36),
  );

  static const smallHeading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: Color(0xFF252C38),
  );

  static InputDecoration input({required String hint, required Widget suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFABB0BA)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9DCE3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9DCE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF8A03D), width: 1.4),
      ),
    );
  }

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF8A03D),
    foregroundColor: Colors.white,
    elevation: 0,
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  );
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AuthStyles.fieldLabel);
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/images/logo.gif',
            height: 70,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2C5E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Isovent Bau ',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 34,
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: 'Inventory',
                    style: TextStyle(
                      color: Color(0xFFF9A03F),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
