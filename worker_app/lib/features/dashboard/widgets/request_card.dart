import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../requests/screens/request_details_screen.dart';

class RequestCard extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const RequestCard({super.key, required this.requestData});

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final customerName =
        widget.requestData['customer_name'] ?? 'Customer Request';
    final payment = widget.requestData['estimated_payment'] ?? '₹450';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RequestDetailsScreen(requestData: widget.requestData),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.02 : 0.05),
              blurRadius: _isPressed ? 8 : 15,
              offset: Offset(0, _isPressed ? 4 : 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(
                          Icons.bolt_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 20,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2.seconds),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          payment,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
