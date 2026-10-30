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
    ];
    // The hero already has a share button; only fill an otherwise empty row.
    if (actions.isEmpty) {
      actions.add(
        _Action(icon: Icons.ios_share_rounded, label: 'Share', onTap: onShare),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final a in actions) _ActionTile(action: a)],
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
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(
          side: BorderSide(color: HomeTokens.hairline),
        ),
        child: InkWell(
          onTap: action.onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, color: HomeTokens.green, size: 17),
                const SizedBox(width: 6),
                Text(
                  action.label,
                  style: GoogleFonts.inter(
                    color: HomeTokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
