# Tickets — Suppressions (`DEL`)

> Règle commune : avant toute suppression, `grep` du symbole/fichier dans tout
> le dépôt et mention du résultat dans la PR. Une suppression de colonne/table
> en base se fait en **deux temps** (dépréciation puis suppression à la version
> suivante) pour ne pas casser les applications mobiles déjà installées.

---

### DEL-001 — Supprimer `supabase/APPLY_ALL.sql`
**Type** : Suppression · **Priorité** : P1 · **Estimation** : XS · **Composant** : supabase/db
**Dépendances** : REL-001, REL-002, REL-003

**Contexte** — Copie manuelle et divergente des migrations (cf. REL-004).

**Critères d'acceptation**
- [ ] Fichier supprimé ; aucune référence restante dans `docs/`
- [ ] `supabase db reset` reproduit le schéma complet en CI

---

### DEL-002 — Supprimer le script de debug `bin/test_quran.dart`
**Type** : Suppression · **Priorité** : P3 · **Estimation** : XS · **Composant** : flutter

**Contexte** — Script d'exploration (`print(q.getSurahAndVersesFromJuz(1))`) sans valeur de test ;
la logique est couverte par `test/quran_service_test.dart`.

**Critères d'acceptation**
- [ ] Fichier et dossier `bin/` supprimés ; `flutter analyze` et `flutter test` verts

---

### DEL-003 — Ranger ou supprimer `generate_quizzes.py`
**Type** : Suppression · **Priorité** : P3 · **Estimation** : XS · **Composant** : outillage

**Contexte** — Script Python à la racine qui génère `assets/data/quizzes.json`. On ne sait pas lequel est
la source de vérité ; un humain qui édite le JSON verra ses changements écrasés.

**Critères d'acceptation**
- [ ] Décision tracée dans la PR : soit le JSON est la source (script supprimé), soit le script est déplacé dans `tool/` avec un README et un job CI qui vérifie que le JSON est à jour
- [ ] Contenu religieux validé par le référent (CDC §8 « validation par un érudit »)

---

### DEL-004 — Supprimer la documentation dépréciée `docs/SUPABASE_AUTH_OTP.md`
**Type** : Suppression · **Priorité** : P3 · **Estimation** : XS · **Composant** : docs

**Critères d'acceptation**
- [ ] Fichier supprimé, liens éventuels redirigés vers `SUPABASE_AUTH.md`

---

### DEL-005 — Supprimer le widget inutilisé `PlaceholderSection`
**Type** : Suppression · **Priorité** : P3 · **Estimation** : XS · **Composant** : flutter

**Contexte** — `lib/shared/widgets/placeholder_section.dart` n'est référencé nulle part.

**Critères d'acceptation**
- [ ] Fichier supprimé ; analyse verte

---

### DEL-006 — Retirer les plateformes desktop non ciblées (Linux, Windows, macOS)
**Type** : Suppression · **Priorité** : P2 · **Estimation** : XS · **Composant** : flutter
**Dépendances** : ADR-0002

**Contexte** — Le CDC cible Android, iOS et Web. Les dossiers `linux/`, `windows/`, `macos/` ne sont ni
testés ni buildés, et plusieurs plugins utilisés (`record`, `speech_to_text`, `geolocator`, notifications
programmées) n'y sont pas tous supportés. Ils alourdissent la maintenance et les montées de version.

**Critères d'acceptation**
- [ ] Décision confirmée par le PO (ADR-0002 accepté) ; dossiers supprimés
- [ ] Les plateformes peuvent être recréées plus tard via `flutter create --platforms=...` (documenté)

---

### DEL-007 — Déprécier la valeur d'enum `staff`
**Type** : Suppression · **Priorité** : P2 · **Estimation** : S · **Composant** : supabase/db, flutter
**Dépendances** : SEC-021

**Contexte** — `staff` doublonne `moderator`/`section_lead` (cf. SEC-021). PostgreSQL ne permet pas de retirer
une valeur d'enum simplement.

**Critères d'acceptation**
- [ ] Les profils `staff` sont migrés vers le rôle cible ; contrainte `check (role <> 'staff')`
- [ ] Plus aucune référence à `'staff'` dans `lib/` et dans les policies

---

### DEL-008 — Remplacer le README Flutter par défaut
**Type** : Suppression · **Priorité** : P2 · **Estimation** : S · **Composant** : docs
**Statut** : ✅ Livré avec la mise en place du backlog (le guide d'onboarding complet reste dans AMEL-014)

**Critères d'acceptation**
- [x] Le texte « A new Flutter project » est supprimé et remplacé par un README projet

---

### DEL-009 — Retirer `.env` des assets et le paquet `flutter_dotenv`
**Type** : Suppression · **Priorité** : P1 · **Estimation** : XS · **Composant** : flutter
**Dépendances** : SEC-019

**Critères d'acceptation**
- [ ] `.env` absent de `pubspec.yaml` ; `flutter_dotenv` absent de `pubspec.lock`

---

### DEL-010 — Supprimer les dépendances inutilisées ou en double
**Type** : Suppression · **Priorité** : P2 · **Estimation** : S · **Composant** : flutter

**Contexte** — Deux lecteurs audio : `just_audio` (Coran) **et** `audioplayers` (messages vocaux) ;
`permission_handler` et `cupertino_icons` ne sont importés nulle part dans `lib/`. Chaque dépendance augmente
la taille de l'APK, la surface d'attaque et le coût des montées de version.

**Critères d'acceptation**
- [ ] Un seul paquet audio (`just_audio`) pour la lecture
- [ ] Dépendances non importées retirées (vérifié par `dart run dependency_validator` en CI)
- [ ] Taille de l'APK release mesurée avant/après dans la PR

---

### DEL-011 — Supprimer les policies RLS en double sur `events`
**Type** : Suppression · **Priorité** : P1 · **Estimation** : XS · **Composant** : supabase/db
**Dépendances** : SEC-021

**Contexte** — `events` cumule « Staff crée des événements » (phase 1) et « Staff can create events » (phase 9),
idem `update`/`delete`. Les policies permissives s'additionnent (OR) : la plus large l'emporte, ce qui rend
la sécurité difficile à raisonner.

**Critères d'acceptation**
- [ ] Une policy par opération ; test pgTAP qui compte les policies par table/opération

---

### DEL-012 — Sortir les données de démonstration des migrations
**Type** : Suppression · **Priorité** : P2 · **Estimation** : S · **Composant** : supabase/db

**Contexte** — Les migrations `phase1_mvp`, `phase2_complement`, `fix_policies` insèrent un verset, une
campagne « Fonds Ramadan 2026 », des besoins mosquée, un événement et une annonce de démo **en production**.

**Critères d'acceptation**
- [ ] Données de démo déplacées dans `supabase/seed.sql` (chargé uniquement en local/CI)
- [ ] Les données de référence indispensables (catégories financières, groupe Général) restent en migration
- [ ] Une nouvelle migration nettoie les données de démo en production après validation du bureau
