-- Phase 9: Admin Fixes (Foreign Keys and Events)
-- Resolves constraints preventing user deletion and announcement viewing

-- 0. Add staff role to enum if it doesn't exist
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'staff';

-- 1. Fix user deletion (donations reference)
ALTER TABLE public.donations
  DROP CONSTRAINT IF EXISTS donations_user_id_fkey,
  ADD CONSTRAINT donations_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES profiles(id) 
  ON DELETE SET NULL;

-- 2. Fix announcement viewing (announcement_reads reference)
ALTER TABLE public.announcement_reads
  DROP CONSTRAINT IF EXISTS announcement_reads_announcement_id_fkey,
  ADD CONSTRAINT announcement_reads_announcement_id_fkey 
  FOREIGN KEY (announcement_id) 
  REFERENCES announcements(id) 
  ON DELETE CASCADE;

-- 3. Add any missing policies for events creation by admin/staff
-- (assuming events table already exists but checking policies)
CREATE POLICY "Staff can create events" ON public.events
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'staff')
    )
  );

CREATE POLICY "Staff can update events" ON public.events
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'staff')
    )
  );

CREATE POLICY "Staff can delete events" ON public.events
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'staff')
    )
  );
