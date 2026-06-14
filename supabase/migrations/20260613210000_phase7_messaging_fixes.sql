-- Phase 7 — Corrections de la Messagerie (Réactions, Invitations, Suppressions)

-- 1. Table des réactions aux messages
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    emoji TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id, emoji)
);

ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Voir les réactions"
    ON public.message_reactions FOR SELECT
    USING (true);

CREATE POLICY "Ajouter une réaction"
    ON public.message_reactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Supprimer sa réaction"
    ON public.message_reactions FOR DELETE
    USING (auth.uid() = user_id);

-- 2. Table des invitations de groupe
CREATE TABLE IF NOT EXISTS public.group_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.chat_groups(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.group_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Créer une invitation"
    ON public.group_invitations FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Voir les invitations"
    ON public.group_invitations FOR SELECT
    USING (true);

-- 3. Autoriser la mise à jour des messages (pour la suppression logique)
-- Note: Les politiques peuvent déjà exister, donc on utilise un bloc DO
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'messages' AND policyname = 'Modifier ses propres messages'
    ) THEN
        CREATE POLICY "Modifier ses propres messages"
            ON public.messages FOR UPDATE
            USING (auth.uid() = sender_id)
            WITH CHECK (auth.uid() = sender_id);
    END IF;
END
$$;

-- Ajouter les nouvelles tables au Realtime
DO $$ BEGIN
  alter publication supabase_realtime add table public.message_reactions;
  alter publication supabase_realtime add table public.group_invitations;
EXCEPTION WHEN duplicate_object THEN null; END $$;
