import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LiveCodeScreen extends StatelessWidget {
  const LiveCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    size: 12,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Session',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _HeaderPill(
                    icon: Icons.schedule,
                    label: '23:45',
                    color: const Color(0xFFF3F0FF),
                    textColor: const Color(0xFF5B53F6),
                  ),
                  const SizedBox(width: 8),
                  _HeaderPill(
                    icon: Icons.call_end,
                    label: 'End',
                    color: const Color(0xFFFFEFEF),
                    textColor: AppColors.error,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                children: [
                  Row(
                    children: const [
                      _ParticipantAvatar(label: 'A'),
                      SizedBox(width: 8),
                      _ParticipantAvatar(label: 'M'),
                      SizedBox(width: 8),
                      _ParticipantAvatar(label: 'D'),
                      SizedBox(width: 8),
                      _ParticipantAvatar(label: '+3'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE7EAF3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFD),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          child: Row(
                            children: const [
                              _Dot(Color(0xFFF87171)),
                              SizedBox(width: 6),
                              _Dot(Color(0xFFFBBF24)),
                              SizedBox(width: 6),
                              _Dot(Color(0xFF34D399)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _CodeLine(
                                number: '1',
                                code: "import { useEffect } from 'react';",
                                color: Color(0xFF60A5FA),
                              ),
                              _CodeLine(
                                number: '2',
                                code: "const DevConnect = () => {",
                                color: Color(0xFFA78BFA),
                              ),
                              _CodeLine(
                                number: '3',
                                code: "  return <LiveCodeRoom />;",
                                color: Color(0xFF34D399),
                              ),
                              _CodeLine(
                                number: '4',
                                code: "};",
                                color: Color(0xFFFBBF24),
                              ),
                              _CodeLine(
                                number: '5',
                                code: "export default DevConnect;",
                                color: Color(0xFFF472B6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B53F6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Let me use the new API hook so we can keep state in sync.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE7EAF3))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: const [
                    _ActionCircle(Icons.mic_none),
                    SizedBox(width: 12),
                    _ActionCircle(Icons.videocam_outlined),
                    SizedBox(width: 12),
                    _ActionCircle(Icons.screen_share_outlined),
                    Spacer(),
                    _ActionCircle(Icons.chat_bubble_outline, primary: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFECEEFF),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5B53F6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({
    required this.number,
    required this.code,
    required this.color,
  });

  final String number;
  final String code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              code,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                height: 1.4,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle(this.icon, {this.primary = false});

  final IconData icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: primary ? const Color(0xFF5B53F6) : const Color(0xFFF4F6FA),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: primary ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
