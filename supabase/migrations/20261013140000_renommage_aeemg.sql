-- Renommage du produit « AEEMG Connect » → « AEEMG » (ADR-0023, décision du bureau).
--
-- Les migrations historiques ne sont pas modifiées (ADR-0010) : 20260410000000 renommait
-- déjà l'annonce de bienvenue ; celle-ci couvre toute autre occurrence restante en base.
-- Idempotente : sans occurrence, aucune ligne n'est modifiée.

update public.announcements
   set title = replace(title, 'AEEMG Connect', 'AEEMG'),
       content = replace(content, 'AEEMG Connect', 'AEEMG')
 where title like '%AEEMG Connect%' or content like '%AEEMG Connect%';

update public.notifications
   set title = replace(title, 'AEEMG Connect', 'AEEMG'),
       body = replace(body, 'AEEMG Connect', 'AEEMG')
 where title like '%AEEMG Connect%' or body like '%AEEMG Connect%';
