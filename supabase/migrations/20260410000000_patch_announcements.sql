-- Patch : titre annonce + notification de bienvenue pour utilisateurs existants

update public.announcements
set title = 'Bienvenue sur AEEMG',
    content = 'La plateforme officielle de communication de l''AEEMG est en ligne. Rejoignez le groupe Général pour rester informé.'
where title like '%AEEMG Connect%';
