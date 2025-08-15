enum PlanMediaShape {
  wide16x9,   // TVs, laptops
  square1x1,  // fashion, shoes, bags
  tall4x5,    // dresses, portraits
}

extension PlanMediaShapeX on PlanMediaShape {
  double get ratio {
    switch (this) {
      case PlanMediaShape.wide16x9: return 16 / 9;
      case PlanMediaShape.square1x1: return 1.0;
      case PlanMediaShape.tall4x5:   return 4 / 5; // width/height = 0.8
    }
  }
}
