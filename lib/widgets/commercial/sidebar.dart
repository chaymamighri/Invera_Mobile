import 'package:flutter/material.dart';
import 'package:invera_mobile/models/utilisateur.dart';

const Color _sidebarTeal = Color(0xFF14B8A6);
const Color _sidebarBlue = Color(0xFF2553D4);
const Color _sidebarInk = Color(0xFF10203A);
const Color _sidebarMuted = Color(0xFF607089);
const Color _sidebarSection = Color(0xFF98A2B3);
const Color _sidebarActiveBg = Color(0xFFEAF9FF);
const Color _sidebarBorder = Color(0xFFE6EAF2);

double _phoneScale(BuildContext context, {double min = 0.84}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) return 1;

  final normalizedWidth = width.clamp(320.0, 600.0).toDouble();
  final progress = (normalizedWidth - 320.0) / 280.0;
  return min + ((1 - min) * progress);
}

/// Widget qui affiche la barre laterale du module commercial.
class CommercialSidebar extends StatelessWidget {
  final User user;
  final String appTitle;
  final String appSubtitle;
  final String activePage;
  final List<CommercialSidebarSection> sections;
  final bool collapsed;
  final bool mobile;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onSelectPage;
  final VoidCallback onOpenProfile;
  final VoidCallback onConfirmLogout;

  const CommercialSidebar({
    super.key,
    required this.user,
    required this.appTitle,
    required this.appSubtitle,
    required this.activePage,
    required this.sections,
    required this.collapsed,
    required this.mobile,
    required this.onToggleCollapsed,
    required this.onSelectPage,
    required this.onOpenProfile,
    required this.onConfirmLogout,
  });

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return 'Administrateur';
      case UserRole.RESPONSABLE_ACHAT:
        return 'Responsable achat';
      case UserRole.RESPONSABLE_VENTE:
        return 'Responsable vente';
      case UserRole.COMMERCIAL:
        return 'Commercial';
    }
  }

  String _initials() {
    final name = '${user.prenom} ${user.nom}'.trim();
    if (name.isEmpty) return 'US';

    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'US';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _selectPage(BuildContext context, String pageId) {
    onSelectPage(pageId);
    if (mobile && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = mobile ? _phoneScale(context, min: 0.84) : 1.0;

    final sidebar = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _sidebarBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              16 * scale,
              18 * scale,
              12 * scale,
              16 * scale,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _sidebarBorder),
              ),
            ),
            child: Row(
              children: [
                if (!collapsed) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40 * scale,
                          height: 40 * scale,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _sidebarBlue.withValues(alpha: 0.12),
                                _sidebarTeal.withValues(alpha: 0.16),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14 * scale),
                          ),
                          padding: EdgeInsets.all(7 * scale),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.business, color: _sidebarBlue),
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Text(
                          appTitle,
                          style: TextStyle(
                            fontSize: 18.5 * scale,
                            fontWeight: FontWeight.w800,
                            color: _sidebarBlue,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          appSubtitle,
                          style: TextStyle(
                            fontSize: 11.5 * scale,
                            color: _sidebarMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Spacer(),
                IconButton(
                  onPressed: mobile
                      ? () => Navigator.pop(context)
                      : onToggleCollapsed,
                  icon: Icon(
                    mobile
                        ? Icons.close
                        : (collapsed
                              ? Icons.chevron_right
                              : Icons.chevron_left),
                    color: _sidebarInk,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(11 * scale),
              children: [
                for (final section in sections) ...[
                  if (!collapsed)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        8 * scale,
                        8 * scale,
                        8 * scale,
                        8 * scale,
                      ),
                      child: Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 10.5 * scale,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w700,
                          color: _sidebarSection,
                        ),
                      ),
                    ),
                  for (final item in section.items) ...[
                    _CommercialSidebarItemTile(
                      item: item,
                      activePage: activePage,
                      collapsed: collapsed,
                      mobile: mobile,
                      onSelect: (pageId) => _selectPage(context, pageId),
                    ),
                    SizedBox(height: 6 * scale),
                  ],
                  SizedBox(height: 8 * scale),
                ],
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(12 * scale, 0, 12 * scale, 14 * scale),
            padding: EdgeInsets.all((collapsed ? 10 : 12) * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(color: _sidebarBorder),
            ),
            child: collapsed
                ? Column(
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: CircleAvatar(
                          radius: 17 * scale,
                          backgroundColor: _sidebarBlue.withValues(alpha: 0.12),
                          child: Text(
                            _initials(),
                            style: TextStyle(
                              color: _sidebarBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5 * scale,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      IconButton(
                        tooltip: 'Deconnexion',
                        onPressed: onConfirmLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFB42318),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: CircleAvatar(
                          radius: 17 * scale,
                          backgroundColor: _sidebarBlue.withValues(alpha: 0.12),
                          child: Text(
                            _initials(),
                            style: TextStyle(
                              color: _sidebarBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5 * scale,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.prenom} ${user.nom}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5 * scale,
                                fontWeight: FontWeight.w700,
                                color: _sidebarInk,
                              ),
                            ),
                            Text(
                              _roleLabel(user.role),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5 * scale,
                                color: _sidebarMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Deconnexion',
                        onPressed: onConfirmLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFB42318),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );

    if (!mobile) return sidebar;

    return SafeArea(child: sidebar);
  }
}

class _CommercialSidebarItemTile extends StatelessWidget {
  final CommercialSidebarItem item;
  final String activePage;
  final bool collapsed;
  final bool mobile;
  final ValueChanged<String> onSelect;

  const _CommercialSidebarItemTile({
    required this.item,
    required this.activePage,
    required this.collapsed,
    required this.mobile,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activePage == item.id;
    final compact = mobile || MediaQuery.sizeOf(context).width < 600;
    final scale = compact ? _phoneScale(context, min: 0.84) : 1.0;

    final itemWidget = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * scale),
        onTap: () => onSelect(item.id),
        child: Container(
          height: (compact ? 44 : 48) * scale,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 13 * scale),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [_sidebarActiveBg, Color(0xFFEAF9FF)],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18 * scale),
            border: Border.all(
              color: isActive
                  ? _sidebarBlue.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: (compact ? 18 : 20) * scale,
                color: isActive ? _sidebarBlue : _sidebarMuted,
              ),
              if (!collapsed) ...[
                SizedBox(width: 9 * scale),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: (compact ? 12.5 : 13.5) * scale,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? _sidebarBlue : _sidebarMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!collapsed) return itemWidget;

    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: itemWidget,
    );
  }
}

/// Petit modele utilitaire qui stocke les donnees de la section de barre laterale.
class CommercialSidebarSection {
  final String title;
  final List<CommercialSidebarItem> items;

  const CommercialSidebarSection({required this.title, required this.items});
}

/// Petit modele utilitaire qui stocke les donnees de l'element de barre laterale.
class CommercialSidebarItem {
  final String id;
  final String label;
  final IconData icon;

  const CommercialSidebarItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
