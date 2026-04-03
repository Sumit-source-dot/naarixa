class AssessService {
  int assessRiskScore({
    required bool routeDeviation,
    required bool noResponse,
  }) {
    var score = 0;
    if (routeDeviation) score += 50;
    if (noResponse) score += 50;
    return score;
  }
}
