import 'package:flutter/material.dart';

/// PyQuest colour language: a warm, hand-painted storybook island.
/// Outlines and headings use a warm dark "ink" brown instead of black.
abstract final class PQColors {
  static const ink = Color(0xFF2E1D12);
  static const inkSoft = Color(0xFF5A4334);
  static const inkFaint = Color(0xFF8F7A69);

  static const parchment = Color(0xFFFFF5DE);
  static const parchmentDeep = Color(0xFFF4DFB2);
  static const parchmentEdge = Color(0xFFD9B77E);
  static const cream = Color(0xFFFFFBF3);

  static const sea = Color(0xFF38C5D8);
  static const seaDeep = Color(0xFF1C8FB0);
  static const grass = Color(0xFF7DCB45);
  static const grassDeep = Color(0xFF4A9A2A);
  static const sun = Color(0xFFFFC83D);
  static const sunDeep = Color(0xFFDB9410);
  static const coral = Color(0xFFFF7A59);
  static const coralDeep = Color(0xFFD24F2E);
  static const berry = Color(0xFFEC5C93);
  static const grape = Color(0xFF8D6EF2);
  static const grapeDeep = Color(0xFF6346CC);
  static const sky = Color(0xFF5AAEF2);
  static const skyDeep = Color(0xFF2E7DD0);
  static const pyBlue = Color(0xFF3F7DCB);
  static const pyBlueDeep = Color(0xFF2A5C9E);
  static const pyYellow = Color(0xFFFFD43B);
  static const teal = Color(0xFF2EC4B6);
  static const tealDeep = Color(0xFF1A9286);
  static const night = Color(0xFF1D2350);
  static const nightDeep = Color(0xFF111536);
  static const wood = Color(0xFFB9783F);
  static const woodDeep = Color(0xFF8A5426);

  // Skin tones shared by the human members of the cast (Nova, Ada, Kai).
  static const skin = Color(0xFFF2C79A);
  static const skinLight = Color(0xFFFFE0BE);

  static const energy = Color(0xFFFFB627);
  static const success = Color(0xFF35B36F);
  static const successDeep = Color(0xFF23864F);
  static const danger = Color(0xFFE5484D);
  static const dangerDeep = Color(0xFFB4282E);
  static const disabled = Color(0xFFCDC3B5);
  static const disabledDeep = Color(0xFFA89D8E);

  // Code editor ("Py's chalkboard").
  static const codeBg = Color(0xFF1E2341);
  static const codeBgSoft = Color(0xFF2A3157);
  static const codeLine = Color(0xFF6E77A8);
  static const codeText = Color(0xFFF1F3FF);
  static const codeKeyword = Color(0xFFFF8FB1);
  static const codeString = Color(0xFFFFD66B);
  static const codeNumber = Color(0xFF8BE9C4);
  static const codeBuiltin = Color(0xFF7CC7FF);
  static const codeComment = Color(0xFF8C93B8);
  static const codeOp = Color(0xFFFFB86C);
}

/// A themed colour pair for chunky 3D buttons: face + darker "depth".
class PQTone {
  const PQTone(this.face, this.depth, {this.text = Colors.white});
  final Color face;
  final Color depth;
  final Color text;

  static const sun = PQTone(PQColors.sun, PQColors.sunDeep, text: PQColors.ink);
  static const grass = PQTone(PQColors.grass, PQColors.grassDeep);
  static const sea = PQTone(PQColors.sea, PQColors.seaDeep);
  static const coral = PQTone(PQColors.coral, PQColors.coralDeep);
  static const grape = PQTone(PQColors.grape, PQColors.grapeDeep);
  static const sky = PQTone(PQColors.sky, PQColors.skyDeep);
  static const teal = PQTone(PQColors.teal, PQColors.tealDeep);
  static const py = PQTone(PQColors.pyBlue, PQColors.pyBlueDeep);
  static const success = PQTone(PQColors.success, PQColors.successDeep);
  static const danger = PQTone(PQColors.danger, PQColors.dangerDeep);
  static const parchment = PQTone(PQColors.cream, PQColors.parchmentEdge, text: PQColors.ink);
  static const disabled = PQTone(PQColors.disabled, PQColors.disabledDeep, text: Color(0xFF6F655A));
  static const night = PQTone(Color(0xFF3A3F86), PQColors.nightDeep);
  static const wood = PQTone(PQColors.wood, PQColors.woodDeep);
}
