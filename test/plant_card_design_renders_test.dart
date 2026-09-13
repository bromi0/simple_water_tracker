import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders plant card option A: photo with corner action well', (
    tester,
  ) async {
    await _pumpCard(tester, const _CornerWellCard());

    await expectLater(
      find.byKey(const ValueKey('design-card')),
      matchesGoldenFile('goldens/plant_card_option_a.png'),
    );
  });

  testWidgets('renders plant card option B: photo with integrated footer', (
    tester,
  ) async {
    await _pumpCard(tester, const _FooterCard());

    await expectLater(
      find.byKey(const ValueKey('design-card')),
      matchesGoldenFile('goldens/plant_card_option_b.png'),
    );
  });

  testWidgets('renders plant card option C: photo with clear action footer', (
    tester,
  ) async {
    await _pumpCard(tester, const _ActionFooterCard());

    await expectLater(
      find.byKey(const ValueKey('design-card')),
      matchesGoldenFile('goldens/plant_card_option_c.png'),
    );
  });
}

Future<void> _pumpCard(WidgetTester tester, Widget card) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF121016),
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('design-card'),
            child: SizedBox(width: 220, height: 310, child: card),
          ),
        ),
      ),
    ),
  );
}

class _PlantImage extends StatelessWidget {
  const _PlantImage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF739F70), Color(0xFF244E35)],
        ),
      ),
      child: Center(
        child: Image.asset('assets/images/vine.png', width: 116, height: 116),
      ),
    );
  }
}

class _StatusCopy extends StatelessWidget {
  const _StatusCopy({this.onDarkImage = false, this.compact = false});

  final bool onDarkImage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = onDarkImage ? Colors.green.shade200 : Colors.green.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Doing well',
          style:
              (compact
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(
                    color: onDarkImage ? Colors.white : null,
                    fontWeight: FontWeight.w700,
                  ),
        ),
        if (!compact) const SizedBox(height: 2),
        Text(
          'Water in ~2 days',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A: Photo-first card with a solid, rounded lower-right action well.
class _CornerWellCard extends StatelessWidget {
  const _CornerWellCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _PlantImage(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1],
                colors: [Colors.transparent, Color(0xD9000000)],
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 60,
            child: _PlantName(),
          ),
          Positioned(
            left: 16,
            right: 0,
            bottom: 0,
            height: 60,
            child: Row(
              children: [
                const Expanded(
                  child: _StatusCopy(onDarkImage: true, compact: true),
                ),
                Material(
                  color: Colors.green.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {},
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.water_drop, color: Colors.black),
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
}

class _PlantName extends StatelessWidget {
  const _PlantName();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Fern',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// B: One rounded card whose content lives in a tonal footer below the photo.
class _FooterCard extends StatelessWidget {
  const _FooterCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const Expanded(flex: 6, child: _PlantImage()),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Expanded(child: _StatusCopy()),
                  IconButton.filled(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade300,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.water_drop),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// C: Separates the action into a full-width footer for maximum clarity.
class _ActionFooterCard extends StatelessWidget {
  const _ActionFooterCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const Expanded(flex: 5, child: _PlantImage()),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(alignment: Alignment.centerLeft, child: _StatusCopy()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.water_drop),
                label: const Text('Water'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
