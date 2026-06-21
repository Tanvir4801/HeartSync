class HeartsyncUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? coupleId;

  const HeartsyncUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.coupleId,
  });
}
