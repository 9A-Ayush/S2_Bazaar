import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../providers/app_providers.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                children: [
                  S2IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: AppColors.text1),
                    onTap: () => context.go('/home'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Categories', style: AppTextStyles.h3()),
                  ),
                  S2IconButton(
                    bgColor: AppColors.primarySoft,
                    icon: const Icon(Icons.search,
                        size: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Search ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: S2SearchBar(
                controller: _searchCtrl,
                hint: 'Search groceries, clothes...',
              ),
            ),

            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: categoriesAsync.when(
                data: (allCategories) {
                  final filtered = _query.isEmpty
                      ? allCategories
                      : allCategories
                          .where((c) =>
                              c.name.toLowerCase().contains(_query.toLowerCase()) ||
                              c.subcategories.any((s) => s.name
                                  .toLowerCase()
                                  .contains(_query.toLowerCase())))
                          .toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      emoji: '🔍',
                      title: 'No results found',
                      subtitle: 'Try searching for something else',
                    );
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    itemBuilder: (_, i) => _CategorySection(
                      category: filtered[i],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Section ─────────────────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  final CategoryModel category;

  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(category.emoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(category.name, style: AppTextStyles.h4()),
              ],
            ),
            GestureDetector(
              onTap: () {},
              child: Text('See all',
                  style: AppTextStyles.captionBold(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Subcategory grid - 4 columns
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: category.subcategories.length,
          itemBuilder: (_, j) =>
              _SubCategoryCard(sub: category.subcategories[j]),
        ),
      ],
    );
  }
}

// ─── Sub Category Card ────────────────────────────────────────────────────────
class _SubCategoryCard extends ConsumerWidget {
  final SubCategoryModel sub;

  const _SubCategoryCard({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(sub.color),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Text(sub.emoji,
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
                // Item count badge
                if (sub.count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${sub.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            sub.name,
            style: AppTextStyles.label(color: AppColors.text1),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
