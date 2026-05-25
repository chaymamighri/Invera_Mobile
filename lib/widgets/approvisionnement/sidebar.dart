import 'package:flutter/material.dart';
import 'package:invera_mobile/models/utilisateur.dart';

const Color _sidebarTeal = Color(0xFF14B8A6);
const Color _sidebarStart = Color(0xFF0B1730);
const Color _sidebarEnd = Color(0xFF15367A);

/// Widget qui affiche la barre laterale du module approvisionnement.
class ApprovisionnementSidebar extends StatelessWidget {
  final User user;
  final String activePage;
  final List<ApprovisionnementSidebarSection> sections;
  final bool collapsed;
  final bool mobile;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onSelectPage;
  final VoidCallback onOpenProfile;
  final VoidCallback onConfirmLogout;

  const ApprovisionnementSidebar({
    super.key,
    required this.user,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_sidebarStart, _sidebarEnd],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 12, 18),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.18),
                                _sidebarTeal.withValues(alpha: 0.16),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.business, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Approvisionnement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Produits, commandes et suivi achat',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD3DDEB),
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
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final section in sections) ...[
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFAFC0D9),
                        ),
                      ),
                    ),
                  for (final item in section.items) ...[
                    _ApprovisionnementSidebarItemTile(
                      item: item,
                      activePage: activePage,
                      collapsed: collapsed,
                      onSelect: onSelectPage,
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            padding: EdgeInsets.all(collapsed ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: collapsed
                ? Column(
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Deconnexion',
                        onPressed: onConfirmLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFFFC0C0),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.prenom} ${user.nom}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _roleLabel(user.role),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD3DDEB),
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
                          color: Color(0xFFFFC0C0),
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

class _ApprovisionnementSidebarItemTile extends StatelessWidget {
  final ApprovisionnementSidebarItem item;
  final String activePage;
  final bool collapsed;
  final ValueChanged<String> onSelect;

  const _ApprovisionnementSidebarItemTile({
    required this.item,
    required this.activePage,
    required this.collapsed,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activePage == item.id;

    final itemWidget = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSelect(item.id),
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      _sidebarTeal.withValues(alpha: 0.16),
                    ],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.24)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isActive ? Colors.white : const Color(0xFFD7E1EF),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : const Color(0xFFE2EAF5),
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
class ApprovisionnementSidebarSection {
  final String title;
  final List<ApprovisionnementSidebarItem> items;

  const ApprovisionnementSidebarSection({
    required this.title,
    required this.items,
  });
}

/// Petit modele utilitaire qui stocke les donnees de l'element de barre laterale.
class ApprovisionnementSidebarItem {
  final String id;
  final String label;
  final IconData icon;

  const ApprovisionnementSidebarItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
