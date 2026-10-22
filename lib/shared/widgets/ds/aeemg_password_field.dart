import 'package:flutter/material.dart';

/// Champ mot de passe (v3) : bouton œil pour afficher ou masquer la saisie, sans
/// correction automatique ni suggestions, compatible avec les gestionnaires de mots
/// de passe (`autofillHints`).
class AeemgPasswordField extends StatefulWidget {
  const AeemgPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.icon = Icons.key_outlined,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AeemgPasswordField> createState() => _AeemgPasswordFieldState();
}

class _AeemgPasswordFieldState extends State<AeemgPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, size: 20),
        suffixIcon: IconButton(
          tooltip: _obscure
              ? 'Afficher le mot de passe'
              : 'Masquer le mot de passe',
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
