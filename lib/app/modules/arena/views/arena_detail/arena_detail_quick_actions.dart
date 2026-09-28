import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:url_launcher/url_launcher.dart';

/// One-tap ways to reach the cafe. Actions without data (no phone, no
/// address) are left out rather than shown disabled.
class ArenaDetailQuickActions extends StatelessWidget {
  const ArenaDetailQuickActions({
    super.key,
    required this.title,
    required this.address,
    required this.phone,
    required this.email,
    required this.onShare,
  });

  final String title;
  final String address;
  final String phone;
  final String email;
  final VoidCallback onShare;

  static bool _present(String v) {
    final t = v.trim().toLowerCase();
    return t.isNotEmpty && t != 'null' && t != 'address not available';
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch failed');
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Couldn\'t open that on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <_Action>[
      if (_present(address))
        _Action(
          icon: Icons.near_me_rounded,
          label: 'Directions',
          onTap: () => _open(
            context,
            Uri.https('www.google.com', '/maps/search/', {
              'api': '1',
              'query': '$title, $address',
            }),
          ),
        ),
      if (_present(phone))
        _Action(
          icon: Icons.call_rounded,
          label: 'Call',
          onTap: () => _open(context, Uri(scheme: 'tel', path: phone.trim())),
        ),
      if (_present(email))
        _Action(
          icon: Icons.mail_rounded,
          label: 'Email',
          onTap: () =>
              _open(context, Uri(scheme: 'mailto', path: email.trim())),
        ),
      _Action(icon: Icons.ios_share_rounded, label: 'Share', onTap: onShare),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _ActionTile(action: actions[i])),
        ],
      ],
    );
  }
}

class _Action {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _Action action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HomeTokens.hairline),
            ),
            child: Column(
              children: [
                Icon(action.icon, color: HomeTokens.green, size: 22),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: HomeTokens.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
