class AnalysisService {
  String getWaterSafetyLabel(double value) {
    if (value < 30) return 'Safe';
    if (value < 60) return 'Monitor';
    return 'Unsafe';
  }
}
