import '../models/fiber_color_result.dart';

class FiberCalculator {
  static final List<String> _fiberColors = [
    "Blue",
    "Orange",
    "Green",
    "Brown",
    "Slate",
    "White",
    "Red",
    "Black",
    "Yellow",
    "Violet",
    "Rose",
    "Aqua",
  ];

  static FiberColorResult calculateFiberColor(int coreNumber) {
    if (coreNumber <= 0) {
      throw ArgumentError("Core number ต้องมากกว่า 0");
    }

    int tubeNumber = ((coreNumber - 1) ~/ _fiberColors.length) + 1;
    int coreNumberInTube = ((coreNumber - 1) % _fiberColors.length) + 1;

    String tubeColorName = _fiberColors[(tubeNumber - 1) % _fiberColors.length];
    String coreColorName = _fiberColors[(coreNumberInTube - 1)];

    return FiberColorResult(
      tubeNumber: tubeNumber,
      tubeColorName: tubeColorName,
      coreNumberInTube: coreNumberInTube,
      coreColorName: coreColorName,
    );
  }
}
