import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/project_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../feed/widgets/post_card.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _userRepository = UserRepository();
  final _postRepository = PostRepository();
  final _projectRepository = ProjectRepository();
  late final TextEditingController _controller;
  Timer? _debounce;

  String _query = '';
  int _selectedTab = 0;
  bool _loading = false;
  List<dynamic> _users = const [];
  List<dynamic> _posts = const [];
  List<dynamic> _projects = const [];
  List<String> _recent = const ['flutter', 'nestjs auth', 'docker'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
    _loadRecentSearches();
    if (_query.isNotEmpty) {
      _search(_query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    final saved = AppPreferences.instance.recentSearches;
    if (saved.isEmpty) return;
    _recent = saved;
  }

  void _handleQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _loading = false;
        _users = const [];
        _posts = const [];
        _projects = const [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _search(value);
      }
    });
  }

  Future<void> _search(String value) async {
    setState(() {
      _query = value.trim();
      _loading = true;
    });

    if (_query.isEmpty) {
      setState(() {
        _loading = false;
        _users = const [];
        _posts = const [];
        _projects = const [];
      });
      return;
    }

    try {
      final results = await Future.wait([
        _userRepository.searchUsers(_query),
        _postRepository.searchPosts(_query),
        _projectRepository.getProjects(limit: 12),
      ]);

      setState(() {
        _users = results[0] as List;
        _posts = results[1] as List;
        _projects =
            (results[2] as List).where((p) {
              final q = _query.toLowerCase();
              return p.title.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q) ||
                  (p.techStack as List).any((t) => t.toLowerCase().contains(q));
            }).toList();
        _loading = false;
      });
      await AppPreferences.instance.saveRecentSearch(_query);
      if (!mounted) return;
      setState(() => _recent = AppPreferences.instance.recentSearches);
    } catch (_) {
      setState(() {
        _users = const [];
        _posts = const [];
        _projects = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        titleSpacing: 6,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _controller,
            onSubmitted: (value) {
              _debounce?.cancel();
              _search(value);
            },
            onChanged: _handleQueryChanged,
            decoration: InputDecoration(
              hintText: AppStrings.of(context).t('search.hint'),
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.textSecondary,
              ),
              suffixIcon:
                  _controller.text.isNotEmpty
                      ? IconButton(
                        onPressed: () {
                          _debounce?.cancel();
                          _controller.clear();
                          _handleQueryChanged('');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(4, (index) {
                final labels = [
                  AppStrings.of(context).t('search.all'),
                  AppStrings.of(context).t('search.posts'),
                  AppStrings.of(context).t('search.people'),
                  AppStrings.of(context).t('search.projects'),
                ];
                final selected = index == _selectedTab;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              selected
                                  ? const Color(0xFF4F46E5)
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(height: 1, color: const Color(0xFFE9EDF4)),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      children: [
                        if (_selectedTab == 0)
                          ..._buildAllSections(context)
                        else
                          ..._buildSingleSection(context),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllSections(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      // Recent searches section
      Row(
        children: [
          const Icon(Icons.history, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            strings.t('search.recentSearches'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              await AppPreferences.instance.clearRecentSearches();
              if (!mounted) return;
              setState(() => _recent = const []);
            },
            child: Text(
              strings.t('search.clear'),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
      if (_recent.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            strings.t('search.noRecent'),
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _recent
                  .map(
                    (item) => GestureDetector(
                      onTap: () {
                        _controller.text = item;
                        _search(item);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE8EBF2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 5),
                            Text(item, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      const SizedBox(height: 16),
      // Trending topics
      Row(
        children: [
          const Icon(Icons.trending_up, size: 14, color: Color(0xFF5B53F6)),
          const SizedBox(width: 6),
          Text(
            strings.t('search.trending'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            ['Flutter', 'NestJS', 'Docker', 'React', 'AI'].map((topic) {
              return GestureDetector(
                onTap: () {
                  _controller.text = topic;
                  _search(topic);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$topic',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B53F6),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
      const SizedBox(height: 20),
      _SectionTitle(
        title: AppStrings.of(context).t('search.posts'),
        trailing:
            '${_posts.length} ${AppStrings.of(context).t('search.results')}',
      ),
      const SizedBox(height: 10),
      ..._posts
          .take(2)
          .map<Widget>(
            (post) => PostCard(
              post: post,
              onTap: () => context.push('${AppRoutes.postBase}/${post.id}'),
            ),
          ),
      const SizedBox(height: 10),
      _SectionTitle(
        title: AppStrings.of(context).t('search.people'),
        trailing: AppStrings.of(context).t('explore.seeAll'),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 138,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _users.length.clamp(0, 4),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, index) {
            final user = _users[index];
            return Container(
              width: 106,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7EAF2)),
              ),
              child: Column(
                children: [
                  UserAvatar(name: user.displayName, size: 46),
                  const SizedBox(height: 8),
                  _highlightedText(
                    user.displayName.split(' ').first,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _highlightedText(
                    user.skills.isNotEmpty
                        ? user.skills.first
                        : AppStrings.of(context).t('search.developer'),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 24,
                    child: ElevatedButton(
                      onPressed:
                          () =>
                              context.push('${AppRoutes.userBase}/${user.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.of(context).t('search.view'),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 14),
      _SectionTitle(
        title: AppStrings.of(context).t('search.projects'),
        trailing: AppStrings.of(context).t('explore.title'),
      ),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _projects.length.clamp(0, 2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (_, index) {
          final project = _projects[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    index.isEven
                        ? [const Color(0xFF6D63FF), const Color(0xFF8D84FF)]
                        : [const Color(0xFF21C7D8), const Color(0xFF68E5D2)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                _highlightedText(
                  project.title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  highlightStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x66FFFFFF),
                        blurRadius: 10,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children:
                      (project.techStack as List).take(2).map<Widget>((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tech,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildSingleSection(BuildContext context) {
    if (_selectedTab == 1) {
      return _posts
          .map<Widget>(
            (post) => PostCard(
              post: post,
              onTap: () => context.push('${AppRoutes.postBase}/${post.id}'),
            ),
          )
          .toList();
    }
    if (_selectedTab == 2) {
      return _users.map<Widget>((user) {
        return ListTile(
          leading: UserAvatar(name: user.displayName, size: 42),
          title: _highlightedText(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: _highlightedText(
            '@${user.username}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: OutlinedButton(
            onPressed: () => context.push('${AppRoutes.userBase}/${user.id}'),
            child: Text(AppStrings.of(context).t('search.view')),
          ),
        );
      }).toList();
    }
    return _projects.map<Widget>((project) {
      return ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: _highlightedText(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _highlightedText(
          project.description,
          maxLines: 1,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        onTap: () => context.push(AppRoutes.projects),
      );
    }).toList();
  }

  Widget _highlightedText(
    String text, {
    TextStyle? style,
    TextStyle? highlightStyle,
    int maxLines = 1,
  }) {
    final query = _query.trim();
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final regex = RegExp(RegExp.escape(query), caseSensitive: false);
    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style:
              highlightStyle ??
              (style ?? const TextStyle()).copyWith(
                color: const Color(0xFF4F46E5),
                fontWeight: FontWeight.w800,
                shadows: const [
                  Shadow(
                    color: Color(0x334F46E5),
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(
          trailing,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
