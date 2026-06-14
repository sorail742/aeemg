# AEEMG CONNECT

**Plateforme Numérique de Gestion Communautaire**  
Association des Élèves et Étudiants Musulmans de Guinée

**CAHIER DES CHARGES – VERSION 1.1**  
Avril 2026

---

> بسم الله الرحمن الرحيم  
> Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux

---

## RÉSUMÉ EXÉCUTIF

AEEMG Connect est une application **Flutter** (mobile iOS/Android et web) connectée à **Supabase**, conçue pour numériser et centraliser la gestion de la communauté estudiantine musulmane de Guinée. Fondée sur les résultats d'une étude de terrain menée auprès des membres, cette première version cible 9 fonctionnalités clés : Communication, Gestion des Événements, Finances, Notifications, Gestion des Membres, Dons, Gestion de la Mosquée, Rappels Islamiques et Calendrier.

---

## 1. Introduction

### 1.1. Contexte et Genèse du Projet

L'Association des Élèves et Étudiants Musulmans de Guinée (AEEMG) est une organisation estudiantine engagée dans la promotion de l'éducation islamique, de la fraternité et du développement des jeunes musulmans guinéens. La mosquée et les activités de l'AEEMG constituent un espace vital de rassemblement, de formation et d'entraide pour ses membres.

Une étude de terrain conduite en avril 2026 auprès de 16 membres a mis en lumière plusieurs défis opérationnels persistants :

- **Déficit de communication** : 56,25 % des membres sont informés via WhatsApp, mais 62,5 % reçoivent les informations en retard ou parfois en retard
- **Activités manquées** : 37,5 % des répondants ont déjà raté une activité faute d'information
- **Fort potentiel numérique** : 75 % possèdent un smartphone et 68,75 % ont accès à internet
- **Engagement bénévole** : 62,5 % sont prêts à s'inscrire comme bénévoles via un formulaire en ligne
- **Confiance institutionnelle élevée** : 62,5 % font totalement confiance à la gestion financière

### 1.2. Données de l'Étude de Terrain

| Question clé | Résultat | Implication pour l'app |
|---|---|---|
| Comment êtes-vous informé ? | WhatsApp (56%), Bouche à oreille (37%), Affiches (25%) | Renforcer les canaux numériques |
| Infos reçues en retard ? | Oui/Parfois : 62,5% | Système de notification instantanée |
| Activités ratées ? | 37,5% ont dit Oui | Agenda et rappels automatiques |
| Canal préféré | SMS (31%), WhatsApp (25%) | Multi-canal : SMS + app |
| Fréquence souhaitée | Instantanément : 62,5% | Notifications en temps réel |
| Fréquence à la mosquée | Tous les jours : 50% | Communauté très active |
| Prêts à utiliser un site | 68,75% Oui | App web responsive (Flutter Web) |
| Prêts à faire du bénévolat | 62,5% avec plaisir | Module bénévolat en ligne |
| Confiance financière | 62,5% totalement confiance | Transparence optionnelle |

### 1.3. Vision du Projet

AEEMG Connect aspire à devenir la plateforme de référence pour toutes les communautés musulmanes estudiantines de Guinée, en offrant un outil moderne, accessible et conforme aux valeurs islamiques. La vision à long terme inclut l'extension à d'autres associations similaires à travers l'Afrique de l'Ouest.

### 1.4. Public Cible

| Profil | Description |
|---|---|
| Membres actifs AEEMG | Étudiants et élèves inscrits à l'association |
| Administrateurs | Bureau exécutif, responsables de section |
| Fidèles de la mosquée | Communauté fréquentant la mosquée AEEMG |
| Bénévoles | Membres souhaitant participer aux activités |
| Donateurs | Sympathisants souhaitant soutenir l'association |

---

## 2. Objectifs du Projet

### 2.1. Objectifs Généraux

- Numériser et centraliser la gestion de la communauté AEEMG
- Améliorer drastiquement la communication entre les membres et les organisateurs
- Accroître la participation aux activités grâce à une information proactive
- Renforcer la transparence financière et encourager les dons
- Offrir un espace numérique ancré dans les valeurs islamiques

### 2.2. Objectifs Spécifiques de la Version 1

| Objectif Mesurable | Cible |
|---|---|
| Réduire les informations en retard | De 62,5% à moins de 10% grâce aux notifications |
| Augmenter la participation | Objectif : 0 activité ratée pour manque d'info |
| Centraliser les communications | Remplacer la communication fragmentée par une seule app |
| Faciliter le bénévolat | Permettre l'inscription en ligne pour 100% des volontaires |
| Renforcer les dons | Digitaliser le circuit des dons et assurer leur traçabilité |

---

## 3. Fonctionnalités de la Version 1

### 3.1. Module Communication

**Besoin identifié**
- 56% des membres utilisent WhatsApp mais 62% reçoivent les infos en retard
- Nécessité d'un canal officiel, structuré et centralisé

**Fonctionnalités détaillées**
- Messagerie interne : fil de discussion par groupe (général, section, comité)
  - Création de groupes thématiques (Coran, conférences, bénévolat…)
  - Épinglage de messages importants
  - Réactions et mentions (@membre)
- Annonces officielles : espace dédié aux communications du bureau
  - Différenciation visuelle annonce / discussion
  - Accusé de lecture pour les annonces importantes
- Partage de médias : images, documents PDF, fichiers audio (sermons) via **Supabase Storage**
- Archivage des communications pour consultation ultérieure

| Rôle | Permissions |
|---|---|
| Administrateur | Créer et gérer les groupes, publier les annonces officielles |
| Modérateur | Modérer les discussions, épingler, supprimer les messages |
| Membre | Lire, répondre, réagir aux messages dans les groupes autorisés |

### 3.2. Gestion des Événements

**Besoin identifié**
- 37,5% ont déjà raté une activité par manque d'information
- Activités préférées : Conférences (62,5%), Concours de Coran (62,5%), Sorties entre étudiants (37,5%)

**Fonctionnalités détaillées**
- Création d'événements : titre, description, date/heure, lieu, type d'activité
- Publication programmée : annoncer un événement avec délai configurable
- Inscription en ligne : bouton RSVP avec compteur de participants
- Rappels automatiques : J-7, J-3, J-1 et le jour J (via **Supabase Edge Functions** + cron)
- Galerie post-événement : partage de photos après l'activité
- Récurrence : pour les activités hebdomadaires (halaqas, récitations)
- Types prédéfinis : Conférence, Concours Coran, Sortie, Iftar, Halaqa, Formation

### 3.3. Gestion des Finances

**Fonctionnalités détaillées**
- Tableau de bord financier : solde actuel, entrées, sorties du mois
- Enregistrement des transactions : recettes (dons, cotisations) et dépenses
- Catégorisation : Activités, Mosquée, Fournitures, Iftar, Autres
- Rapport mensuel automatique : format résumé simple
- Publication optionnelle des bilans aux membres
- Historique complet pour les administrateurs
- Export PDF du bilan financier

| Rôle | Accès financier |
|---|---|
| Trésorier | Saisir, modifier, supprimer les transactions |
| Administrateur | Consulter tous les rapports, publier les bilans |
| Membre | Consulter uniquement les bilans publiés |

### 3.4. Système de Notifications

**Fonctionnalités détaillées**
- Notifications in-app en temps réel via **Supabase Realtime**
- Notifications push sur mobile (tokens stockés dans Supabase)
- SMS de secours via **Supabase Edge Functions** (Orange API Guinée / Africab SMS)
- Catégories configurables : Événements, Finances, Messages, Rappels islamiques
- Préférences personnalisées par membre
- Mode silencieux aux heures de prière
- Centre de notifications avec historique
- Badges de notifications non lues

### 3.5. Gestion des Membres

**Fonctionnalités détaillées**
- Annuaire des membres : profil avec photo, nom, section, spécialité
- Inscription en ligne : formulaire d'adhésion numérique
- Gestion des rôles : Président, Secrétaire, Trésorier, Responsable section, Membre, Bénévole
- Suivi de l'assiduité aux activités
- Renouvellement annuel de la cotisation
- Recherche et filtre : par section, disponibilité, compétence
- Confidentialité : contrôle de la visibilité des informations personnelles

### 3.6. Faire un Don

**Fonctionnalités détaillées**
- Interface simplifiée : montant libre ou suggéré (5 000, 10 000, 25 000 GNF)
- Catégories : Fonctionnement général, Ramadan/Iftar, Rénovation mosquée, Fonds d'urgence
- Modes de paiement : Orange Money, MTN Mobile Money, Virement bancaire, Espèces (via admin)
- Reçu numérique : confirmation SMS/email via Edge Functions
- Don récurrent mensuel
- Campagnes de collecte avec barre de progression
- Anonymat optionnel
- Historique des dons par membre

### 3.7. Gestion de la Mosquée

**Fonctionnalités détaillées**
- Tableau de bord : état général, projets en cours, besoins
- Gestion des besoins : eau, dattes, tapis, etc.
- Formulaire de bénévolat pour iftars et événements
- Planning d'occupation : vendredi, Aid
- Registre de maintenance : infiltration, climatisation, etc.
- Gestion des iftars du Ramadan
- Galerie photos

### 3.8. Rappels Islamiques

**Fonctionnalités détaillées**
- Verset du jour : traduction français et peul
- Hadith du jour avec source et commentaire
- Rappels programmés : dhikr, douaa, contenu spirituel
- Bibliothèque islamique : articles, conférences texte et audio
- Citation du vendredi (Jumua)
- Partage de versets et hadiths
- Favoris

### 3.9. Calendrier Islamique et Communautaire

**Fonctionnalités détaillées**
- Vue mensuelle et hebdomadaire des événements AEEMG
- Double calendrier Hijri et Grégorien
- Dates islamiques automatiques : Ramadan, Aïd, Mawlid
- Heures de prière pour Conakry/Labé avec alertes
- Export vers Google Calendar ou iCal
- Vue « Mes événements »
- Indicateur de conflit avec l'emploi du temps universitaire

---

## 4. Architecture Technique

### 4.1. Stack Technologique

| Composant | Technologie | Justification |
|---|---|---|
| Application (Mobile + Web) | **Flutter** | Un seul codebase pour iOS, Android et Web |
| Backend / API | **Supabase** | Backend-as-a-Service open-source, PostgreSQL intégré |
| Base de données | **Supabase PostgreSQL** | Fiable, relationnel, Row Level Security (RLS) |
| Authentification | **Supabase Auth** | OTP par téléphone, gestion des sessions |
| Stockage fichiers | **Supabase Storage** | Images, PDF, audio (sermons) |
| Temps réel | **Supabase Realtime** | Messagerie, notifications in-app |
| Logique serveur | **Supabase Edge Functions** | SMS, paiements, rappels automatiques, exports PDF |
| Notifications push | **Supabase + tokens FCM/APNs** | Alertes mobiles via Edge Functions |
| SMS | **Edge Functions** → Orange API / Africab SMS | Canal de secours pour membres sans internet |
| Paiement mobile | **Edge Functions** → Orange Money / MTN MoMo | Adapté au contexte guinéen |
| Hébergement | **Supabase Cloud** (ou self-hosted) | Coût maîtrisé, maintenance simplifiée |

### 4.2. Sécurité et Confidentialité

- Authentification : numéro de téléphone + OTP via Supabase Auth
- Chiffrement : HTTPS obligatoire, données sensibles protégées
- **Row Level Security (RLS)** sur toutes les tables PostgreSQL
- Gestion des rôles et permissions granulaires
- Sauvegarde automatique Supabase (point-in-time recovery)
- Conformité aux principes de protection des données personnelles

### 4.3. Accessibilité et Connectivité

- Mode hors ligne partiel : cache local (calendrier, contenus islamiques)
- Optimisation basse bande passante : images compressées, chargement progressif
- Interface en français (principale), support futur du peul et de l'arabe
- Compatible Android 6+ et iOS 12+ via Flutter

---

## 5. Gestion des Utilisateurs et Rôles

| Rôle | Permissions |
|---|---|
| Super Administrateur | Configuration, gestion des rôles, finances, export |
| Administrateur | Événements, membres, annonces, bilans |
| Modérateur | Modération des discussions, validation des inscriptions |
| Trésorier | Saisie et consultation des transactions financières |
| Responsable Section | Gestion de sa section (membres, événements locaux) |
| Membre | Lecture, inscription aux activités, dons |
| Bénévole | Profil bénévole, inscription aux missions |
| Visiteur | Infos publiques, formulaire d'adhésion |

---

## 6. Plan de Développement

Voir le fichier détaillé : [PHASES.md](./PHASES.md)

| Phase | Durée estimée | Livrable principal |
|---|---|---|
| Phase 0 – Préparation | 4 semaines | Maquettes, validation, setup technique |
| Phase 1 – MVP | 8 semaines | Communication, Événements, Notifications, Calendrier, Membres |
| Phase 2 – Complément | 6 semaines | Finances, Dons, Mosquée, Rappels Islamiques |
| Phase 3 – Tests & Lancement | 4 semaines | Tests, corrections, lancement officiel |
| Phase 4 – Évolution | En continu | Retours, nouvelles fonctionnalités |

### Critères de Succès de la Version 1

- Taux d'adoption : ≥ 70% des membres actifs inscrits en 3 mois
- Réduction des retards d'information : < 10%
- Participation aux événements : +20% par rapport à la période pré-app
- Dons en ligne : ≥ 5 transactions le premier mois
- Satisfaction : score moyen ≥ 4/5 post-lancement

---

## 7. Expérience Utilisateur (UX)

### 7.1. Principes de Design

- Simplicité avant tout
- Identité islamique : palette verte, typographie claire, tonalité respectueuse
- Mobile-first (75% des membres possèdent un smartphone)
- Accessibilité : police lisible, contraste élevé, navigation intuitive
- Chargement rapide : < 3 secondes sur connexion 3G

### 7.2. Navigation Principale (Bottom Tab Bar)

| Onglet | Contenu |
|---|---|
| Accueil | Fil d'actualité : annonces, prochain événement, verset du jour |
| Agenda | Calendrier des événements + calendrier islamique |
| Messages | Messagerie interne et annonces |
| Mosquée | Infos mosquée, iftars, bénévolat |
| Profil | Compte, dons, préférences, notifications |

---

## 8. Contraintes et Défis

| Contrainte | Solution proposée | Risque |
|---|---|---|
| Connectivité irrégulière | Cache local Flutter + compression | Moyen |
| Diversité des appareils | Flutter multi-plateforme | Faible |
| Adoption par les membres | Formation, interface simple | Élevé |
| Coût de maintenance | Supabase + équipe bénévole | Moyen |
| Contenu islamique authentique | Validation par un érudit | Faible |
| Protection des données | RLS Supabase, rôles stricts | Moyen |

---

## 9. Conclusion et Vision

AEEMG Connect est un outil au service de la Oumma estudiantine guinéenne. En répondant aux besoins exprimés sur le terrain, cette première version pose des bases solides pour une communauté mieux informée, plus unie et plus efficace.

**Vision à long terme**
- Extension aux autres sections AEEMG en Guinée
- Partenariats avec associations islamiques estudiantines en Afrique de l'Ouest
- E-learning islamique, bibliothèque numérique, réseau alumni
- Application modèle reproductible pour les communautés musulmanes du continent

---

> وَاعْتَصِمُوا بِحَبْلِ اللَّهِ جَمِيعًا وَلَا تَفَرَّقُوا  
> « Cramponnez-vous tous ensemble au câble d'Allah et ne vous divisez pas. » (Coran 3:103)

---

*Document préparé par AEEMG | Avril 2026 | Version 1.1 — Stack : Flutter + Supabase*
