import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/host_verification_controller.dart';
import 'community_theme.dart';

/// Host verification form — POST /hosts/verification.
class HostVerificationView extends GetView<HostVerificationController> {
  const HostVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      appBar: AppBar(
        backgroundColor: CT.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: CT.onSurface),
        title: Text('Host Verification', style: CT.headline(18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Verify your identity', style: CT.display(22)),
          const SizedBox(height: 6),
          Text(
            'We use these details to verify you as an official host and to send '
            'your payouts. Everything stays private.',
            style: CT.body(14),
          ),
          const SizedBox(height: 20),
          _Field(label: 'Full name', controller: controller.name),
          _Field(
            label: 'Email',
            controller: controller.email,
            keyboardType: TextInputType.emailAddress,
          ),
          _Field(
            label: 'Phone',
            controller: controller.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _Field(
            label: 'UPI ID (for payouts)',
            controller: controller.upiId,
            hint: 'name@bank',
          ),
          _Field(
            label: 'Address',
            controller: controller.address,
            maxLines: 3,
          ),
          _Field(
            label: 'Government ID reference (optional)',
            controller: controller.govIdRef,
          ),
          Obx(
            () => controller.error.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(controller.error.value!,
                        style: CT.body(13, color: CT.error)),
                  ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed:
                    controller.submitting.value ? null : controller.submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CT.primary,
                  disabledBackgroundColor: CT.surfaceHigh,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: controller.submitting.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Submit for Verification',
                        style: CT.headline(15, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: CT.mono(10)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: CT.body(15, color: CT.onSurface),
            cursorColor: CT.secondary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: CT.body(15, color: CT.muted),
              filled: true,
              fillColor: CT.bg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CT.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CT.secondary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
