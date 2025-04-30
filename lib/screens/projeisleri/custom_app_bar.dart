import 'package:flutter/material.dart';

class ProjeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onFilterToggled;
  final VoidCallback onRefresh;
  final bool showInactive;
  final double elevation;

  const ProjeAppBar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterToggled,
    required this.onRefresh,
    required this.showInactive,
    this.elevation = 1.5,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);

  @override
  State<ProjeAppBar> createState() => _ProjeAppBarState();
}

class _ProjeAppBarState extends State<ProjeAppBar> {
  bool _isSearchFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return AppBar(
      elevation: widget.elevation,
      shadowColor: Colors.black.withOpacity(0.15),
      surfaceTintColor: theme.colorScheme.surface,
      titleSpacing: isDesktop ? 24 : 16,
      title: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 480 : double.infinity,
          minHeight: 46,
        ),
        child: Focus(
          onFocusChange: (focused) =>
              setState(() => _isSearchFocused = focused),
          child: TextField(
            controller: widget.searchController,
            onChanged: widget.onSearchChanged,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.25,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Proje ara...',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: _isSearchFocused
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onSearchChanged('');
                        },
                      ),
                    )
                  : null,
              filled: true,
              fillColor: _isSearchFocused
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  width: 1.2,
                  color: theme.dividerColor.withOpacity(0.8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  width: 1.0,
                  color: theme.dividerColor.withOpacity(0.5),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
              isDense: true,
              constraints: const BoxConstraints(
                minHeight: 46,
              ),
            ),
          ),
        ),
      ),
      actions: [
        _buildFilterButton(context),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              size: 26,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
            onPressed: widget.onRefresh,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 26,
              color: widget.showInactive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.9),
            ),
            if (widget.showInactive)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () => _showFilterMenu(context),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final width = renderBox.size.width;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + width - 200,
        offset.dy + kToolbarHeight,
        offset.dx + width,
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          height: 42,
          child: _FilterMenuItem(
            title: 'Sadece aktif projeler',
            isSelected: !widget.showInactive,
          ),
          onTap: () => widget.onFilterToggled(false),
        ),
        PopupMenuItem(
          height: 42,
          child: _FilterMenuItem(
            title: 'Tüm projeleri göster',
            isSelected: widget.showInactive,
          ),
          onTap: () => widget.onFilterToggled(true),
        ),
      ],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _FilterMenuItem extends StatelessWidget {
  final String title;
  final bool isSelected;

  const _FilterMenuItem({
    required this.title,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          isSelected ? Icons.check_rounded : Icons.circle_outlined,
          size: 22,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
