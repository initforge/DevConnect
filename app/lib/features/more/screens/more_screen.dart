import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/feature_destination.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/decorative_widgets.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items =
        FeatureDestinations.moreItems.where((item) {
          if (_query.isEmpty) return true;
          return item.label.toLowerCase().contains(_query.toLowerCase());
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'More',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: DecorativeBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            const ScreenGradientHeader(
              title: 'More Features',
              subtitle:
                  'Explore all tools and features available in DevConnect',
              icon: Icons.apps_outlined,
              gradientColors: [Color(0xFF5B53F6), Color(0xFF21B5FF)],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Find a feature',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _queryController.clear();
                            setState(() => _query = '');
                          },
                        ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...FeatureDestinationGroup.values
                .where((group) => group != FeatureDestinationGroup.primary)
                .map((group) {
                  final groupItems =
                      items.where((item) => item.group == group).toList();
                  if (groupItems.isEmpty) return const SizedBox.shrink();
                  return _FeatureGroup(
                    title: FeatureDestinations.groupLabel(group),
                    items: groupItems,
                  );
                }),
          ],
        ),
      ),
    );
  }
}

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({required this.title, required this.items});

  final String title;
  final List<FeatureDestination> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns =
                  width >= 960
                      ? 4
                      : width >= 640
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 102,
                ),
                itemBuilder: (context, index) {
                  return _FeatureTile(destination: items[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.destination});

  final FeatureDestination destination;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go(destination.route),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F0FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  destination.icon,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (destination.status == FeatureDestinationStatus.preview)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Text(
                          'Preview',
                          style: TextStyle(
                            color: Color(0xFFC2410C),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
