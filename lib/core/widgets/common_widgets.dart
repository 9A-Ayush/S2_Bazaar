import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── S2 App Bar ───────────────────────────────────────────────────────────────
class S2AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;

  const S2AppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: showBack
          ? _BackButton(onTap: onBack ?? () => Navigator.pop(context))
          : leading,
      actions: actions,
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.text1),
        ),
      ),
    );
  }
}

// ─── Icon Button ─────────────────────────────────────────────────────────────
class S2IconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final Color bgColor;
  final double size;
  final double iconSize;

  const S2IconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.bgColor = AppColors.surface,
    this.size = 38,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? trailing;
  final String? subtitle;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: subtitle != null
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (subtitle != null) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: AppTextStyles.bodyBold(color: Colors.white)),
                        Text(subtitle!,
                            style: AppTextStyles.caption(
                                color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: trailing ??
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ),
                  ] else
                    Text(label),
                ],
              ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3()),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all', style: AppTextStyles.captionBold(color: AppColors.primary)),
          ),
      ],
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class S2SearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;

  const S2SearchBar({
    super.key,
    this.hint = 'Search groceries, food, clothes...',
    this.onTap,
    this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: AppColors.text3, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: readOnly
                  ? Text(hint, style: AppTextStyles.body(color: AppColors.text3))
                  : TextField(
                      controller: controller,
                      style: AppTextStyles.body(color: AppColors.text1),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: AppTextStyles.body(color: AppColors.text3),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Chip Filter ─────────────────────────────────────────────────────────────
class FilterChipRow extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const FilterChipRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isActive = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                labels[i],
                style: AppTextStyles.captionBold(
                    color: isActive ? Colors.white : AppColors.text2),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Quantity Control ─────────────────────────────────────────────────────────
class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Axis axis;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      _QtyBtn(icon: Icons.remove, onTap: onDecrement, isPrimary: false),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('$quantity', style: AppTextStyles.title()),
      ),
      _QtyBtn(icon: Icons.add, onTap: onIncrement, isPrimary: true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        border: Border.all(color: AppColors.border),
      ),
      child: axis == Axis.horizontal
          ? Row(mainAxisSize: MainAxisSize.min, children: children)
          : Column(mainAxisSize: MainAxisSize.min, children: children.reversed.toList()),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QtyBtn({required this.icon, required this.onTap, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isPrimary ? Colors.white : AppColors.text2,
        ),
      ),
    );
  }
}

// ─── Add to Cart Button ───────────────────────────────────────────────────────
class AddToCartButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const AddToCartButton({super.key, required this.onTap, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(Icons.add, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

// ─── Price Badge ─────────────────────────────────────────────────────────────
class DiscountBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const DiscountBadge({
    super.key,
    required this.label,
    this.color = AppColors.greenSoft,
    this.textColor = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(color: textColor),
      ),
    );
  }
}

// ─── Veg / Non-Veg Indicator ─────────────────────────────────────────────────
class VegIndicator extends StatelessWidget {
  final bool isVeg;
  final bool showLabel;

  const VegIndicator({super.key, required this.isVeg, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.green : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 5),
          Text(isVeg ? 'Veg' : 'Non-veg',
              style: AppTextStyles.caption(color: AppColors.text2)),
        ],
      ],
    );
  }
}

// ─── Shimmer Loader ───────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Status Pill ─────────────────────────────────────────────────────────────
class StatusPill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const StatusPill({
    super.key,
    required this.label,
    this.bgColor = AppColors.greenSoft,
    this.textColor = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(color: textColor),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    this.emoji = '',
    this.iconWidget,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ?? Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.h4(),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTextStyles.body(),
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
