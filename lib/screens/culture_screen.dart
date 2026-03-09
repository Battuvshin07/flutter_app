import 'package:flutter/material.dart';
import 'culture_list_screen.dart';

/// FR-07: Соёл, нийгмийн амьдралын мэдээлэл таниулах
/// Delegates to the redesigned CultureListScreen for backward compatibility.
class CultureScreen extends StatelessWidget {
  const CultureScreen({super.key});

  @override
  Widget build(BuildContext context) => const CultureListScreen();
}
