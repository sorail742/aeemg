/// Normalise un numéro saisi par l'utilisateur au format E.164 (`+224620000000`).
///
/// Accepte les espaces, points, tirets et parenthèses, ainsi que le préfixe
/// international `00`. Retourne `null` si le résultat n'est pas un numéro E.164
/// valide : même règle que la contrainte `group_invitations_phone_e164` (SEC-004).
String? normalizeE164(String input) {
  var phone = input.trim().replaceAll(RegExp(r'[\s.\-()]'), '');
  if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
  return RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone) ? phone : null;
}
