class TotpRequiredException implements Exception {
  final String preAuthToken;
  TotpRequiredException(this.preAuthToken);
}
