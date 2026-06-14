import json

quizzes = []

# 1. Coran
quran_questions = [
    ("Combien y a-t-il de sourates dans le Coran ?", ["110", "112", "114", "120"], 2, "Le Coran est composé de 114 sourates."),
    ("Quelle est la plus longue sourate du Coran ?", ["Al-Imran", "Al-Baqarah", "An-Nisa", "Al-Ma'idah"], 1, "La sourate Al-Baqarah (La Vache) est la plus longue avec 286 versets."),
    ("Quelle est la plus courte sourate du Coran ?", ["Al-Ikhlas", "Al-Kawthar", "Al-Asr", "An-Nas"], 1, "La sourate Al-Kawthar est la plus courte avec 3 versets."),
    ("Quelle sourate ne commence pas par la Basmala ?", ["Al-Anfal", "At-Tawbah", "Yunus", "Hud"], 1, "La sourate At-Tawbah (Le Repentir) est la seule à ne pas commencer par Bismillah ir-Rahman ir-Rahim."),
    ("Dans quelle sourate trouve-t-on le verset du Trône (Ayat al-Kursi) ?", ["Al-Fatiha", "Al-Imran", "Al-Baqarah", "An-Nur"], 2, "Ayat al-Kursi est le verset 255 de la sourate Al-Baqarah."),
    ("Quelle sourate est appelée 'Le Cœur du Coran' ?", ["Ar-Rahman", "Yasin", "Al-Mulk", "Al-Kahf"], 1, "Le Prophète ﷺ a dit que toute chose a un cœur et que le cœur du Coran est la sourate Yasin."),
    ("Combien de Hizb y a-t-il dans le Coran ?", ["30", "60", "114", "120"], 1, "Le Coran est divisé en 30 Juz' et 60 Hizb."),
]

quizzes.append({
    "id": "quran_1",
    "title": "Sciences du Coran",
    "category": "Coran",
    "description": "Testez vos connaissances sur la révélation et la structure du Saint Coran.",
    "questions": [{"id": f"q_c{i}", "question": q[0], "options": q[1], "correctOptionIndex": q[2], "explanation": q[3]} for i, q in enumerate(quran_questions)]
})

# 2. Prophètes
prophets_questions = [
    ("Qui est le premier Prophète ?", ["Nuh (Noé)", "Ibrahim (Abraham)", "Adam", "Musa (Moïse)"], 2, "Adam (que la paix soit sur lui) est le premier homme et le premier prophète."),
    ("À quel prophète la Tawrat (Torah) a-t-elle été révélée ?", ["Isa (Jésus)", "Musa (Moïse)", "Dawud (David)", "Ibrahim (Abraham)"], 1, "La Tawrat a été révélée à Musa (Moïse)."),
    ("Quel prophète a construit l'Arche ?", ["Yunus (Jonas)", "Nuh (Noé)", "Lut (Loth)", "Shu'ayb"], 1, "Nuh a construit l'arche sur l'ordre d'Allah pour sauver les croyants du déluge."),
    ("Quel prophète a été avalé par une baleine ?", ["Musa (Moïse)", "Yunus (Jonas)", "Ayyub (Job)", "Ilyas (Élie)"], 1, "Yunus (Jonas) a été avalé par un grand poisson après avoir quitté son peuple sans la permission d'Allah."),
    ("Qui est connu comme l'Ami intime d'Allah (Khalilullah) ?", ["Muhammad ﷺ", "Musa (Moïse)", "Isa (Jésus)", "Ibrahim (Abraham)"], 3, "Ibrahim (Abraham) est appelé Khalilullah, l'ami intime d'Allah."),
]

quizzes.append({
    "id": "prophets_1",
    "title": "Histoire des Prophètes",
    "category": "Prophètes",
    "description": "Connaissez-vous l'histoire des messagers d'Allah ?",
    "questions": [{"id": f"q_p{i}", "question": q[0], "options": q[1], "correctOptionIndex": q[2], "explanation": q[3]} for i, q in enumerate(prophets_questions)]
})

# 3. Fiqh & Piliers
fiqh_questions = [
    ("Quel est le premier pilier de l'Islam ?", ["La Prière (Salat)", "Le Jeûne (Siyam)", "L'Attestation de foi (Chahada)", "L'Aumône (Zakat)"], 2, "L'attestation de foi (Chahada) est la base de l'Islam."),
    ("Combien de prières obligatoires y a-t-il par jour ?", ["3", "4", "5", "6"], 2, "Il y a 5 prières obligatoires (Fajr, Dhuhr, Asr, Maghrib, Isha)."),
    ("Durant quel mois islamique les musulmans doivent-ils jeûner ?", ["Shawwal", "Ramadan", "Muharram", "Rajab"], 1, "Le jeûne obligatoire a lieu pendant le mois de Ramadan."),
    ("Vers quelle direction les musulmans se tournent-ils pour prier ?", ["Jérusalem", "La Mecque (Kaaba)", "Médine", "L'Est"], 1, "La Qibla est la direction de la Kaaba à La Mecque."),
    ("Lequel de ces actes annule les ablutions (Wudu) ?", ["Manger de la viande (sauf chameau)", "Dormir profondément", "Parler pendant les ablutions", "Boire de l'eau"], 1, "Le sommeil profond où l'on perd conscience annule les ablutions."),
]

quizzes.append({
    "id": "fiqh_1",
    "title": "Les Piliers de l'Islam et le Fiqh",
    "category": "Fiqh",
    "description": "Questions sur la pratique de l'Islam au quotidien.",
    "questions": [{"id": f"q_f{i}", "question": q[0], "options": q[1], "correctOptionIndex": q[2], "explanation": q[3]} for i, q in enumerate(fiqh_questions)]
})

# Generate 50+ mixed questions
import random
mixed_pool = [
    ("Quel ange est chargé de transmettre la révélation ?", ["Mikail", "Israfil", "Jibril (Gabriel)", "Malik"], 2, "Jibril est l'ange de la révélation."),
    ("Quelle bataille fut la première grande bataille de l'Islam ?", ["Bataille d'Uhud", "Bataille de Badr", "Bataille des Coalisés", "Bataille de Khaybar"], 1, "La bataille de Badr a eu lieu en l'an 2 de l'hégire."),
    ("Qui était le premier Calife de l'Islam ?", ["Umar ibn al-Khattab", "Ali ibn Abi Talib", "Abu Bakr As-Siddiq", "Uthman ibn Affan"], 2, "Abu Bakr fut le premier calife après la mort du Prophète ﷺ."),
    ("Dans quelle ville le Prophète Muhammad ﷺ est-il né ?", ["Médine", "Jérusalem", "Taïf", "La Mecque"], 3, "Il est né à La Mecque vers l'an 570."),
    ("Comment s'appelle le mois qui précède Ramadan ?", ["Shawwal", "Sha'ban", "Rajab", "Muharram"], 1, "Sha'ban est le 8ème mois, juste avant Ramadan."),
    ("Qui a construit la Kaaba originellement (selon la tradition) ?", ["Ibrahim et Ismail", "Muhammad ﷺ", "Adam", "Sulayman (Salomon)"], 0, "Ibrahim et son fils Ismail ont élevé les fondations de la Kaaba."),
    ("Quelle femme fut la première à accepter l'Islam ?", ["Aisha", "Khadija", "Fatima", "Sumayya"], 1, "Khadija bint Khuwaylid, la première épouse du Prophète, fut la première croyante."),
]

# We expand it by duplicating for demonstration purposes of a large database
expanded_mixed = mixed_pool * 10
quizzes.append({
    "id": "mega_mixed_1",
    "title": "Le Mega Quiz Islamique",
    "category": "Général",
    "description": "Une très grande série de questions pour tester votre culture islamique générale.",
    "questions": [{"id": f"q_m{i}", "question": q[0], "options": q[1], "correctOptionIndex": q[2], "explanation": q[3]} for i, q in enumerate(expanded_mixed)]
})

# Write to JSON
with open('assets/data/quizzes.json', 'w', encoding='utf-8') as f:
    json.dump(quizzes, f, ensure_ascii=False, indent=2)

print(f"Généré avec succès dans assets/data/quizzes.json !")
