import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onRightLogoTap;

  const CustomAppBar({
    super.key,
    this.onRightLogoTap,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(45.0);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool isAlertOn = true;

  Future<void> _callHelpNumber() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '100');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 45,
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Image.asset(
              'assets/finalleftlogo.png',
              height: 45,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7D9CC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ALERTS',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isAlertOn = !isAlertOn;
                      });
                    },
                    child: Container(
                      width: 46,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isAlertOn ? Colors.green : Colors.grey[300],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                              ),
                              child: Text(
                                'ON',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isAlertOn ? Colors.white : Colors.blueGrey[900],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !isAlertOn ? Colors.red : Colors.grey[300],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              child: Text(
                                'OFF',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: !isAlertOn ? Colors.white : Colors.blueGrey[900],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (widget.onRightLogoTap != null) {
                  widget.onRightLogoTap!();
                }
                await _callHelpNumber();
              },
              child: Image.asset(
                'assets/finalrightlogo.png',
                width: 28,
                height: 27,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 