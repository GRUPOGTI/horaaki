/*
# Multi-tenant isolation: link existing data, add professionals, tighten RLS

1. Data migration
   - Link all existing services (empresa_id = NULL) to the Nadja Gomes company
   - Link all existing bookings (empresa_id = NULL) to the Nadja Gomes company
   - Ensure the Nadja Gomes company has correct name (not just the slug)

2. New table: professionals
   - `professionals`: stores professionals/staff for each company
     - id (uuid, PK)
     - empresa_id (uuid, FK companies, ON DELETE CASCADE)
     - name (text, not null)
     - role (text, e.g. "Cabeleireira", "Manicure")
     - bio (text, nullable)
     - photo_url (text, nullable)
     - active (boolean, default true)
     - display_order (integer, default 0)
     - created_at (timestamptz)

3. Security changes on services & bookings
   - SELECT stays public (anon + authenticated) so public pages work without login
   - INSERT/UPDATE/DELETE restricted to authenticated company members (owner/admin)
   - This prevents anon from creating/modifying services or bookings via the API
     while still allowing public read access and the booking form (which inserts
     via the anon key — handled by a separate anon-allowable INSERT policy on bookings)

4. RLS on professionals
   - SELECT public (anon + authenticated)
   - INSERT/UPDATE/DELETE restricted to company members

5. Important notes
   - The /agenda/nadja-gomes page continues to work exactly as before
   - Existing services and bookings are preserved, just linked to the company
   - The public booking form still allows anon INSERT on bookings (clients booking appointments)
*/

-- Fix company name to be the display name, not the slug
UPDATE companies SET name = 'Nadja Gomes' WHERE slug = 'nadja-gomes' AND name = 'nadja-gomes';

-- Link existing services to the Nadja Gomes company
UPDATE services SET empresa_id = (SELECT id FROM companies WHERE slug = 'nadja-gomes')
WHERE empresa_id IS NULL;

-- Link existing bookings to the Nadja Gomes company
UPDATE bookings SET empresa_id = (SELECT id FROM companies WHERE slug = 'nadja-gomes')
WHERE empresa_id IS NULL;

-- Create professionals table
CREATE TABLE IF NOT EXISTS professionals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  role text NOT NULL DEFAULT 'Profissional',
  bio text,
  photo_url text,
  active boolean NOT NULL DEFAULT true,
  display_order integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE professionals ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON professionals TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON professionals TO authenticated;

-- Public SELECT on professionals
DROP POLICY IF EXISTS "anon_select_professionals" ON professionals;
CREATE POLICY "anon_select_professionals" ON professionals FOR SELECT
  TO anon, authenticated USING (true);

-- Company members can INSERT professionals
DROP POLICY IF EXISTS "member_insert_professionals" ON professionals;
CREATE POLICY "member_insert_professionals" ON professionals FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = professionals.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Company members can UPDATE professionals
DROP POLICY IF EXISTS "member_update_professionals" ON professionals;
CREATE POLICY "member_update_professionals" ON professionals FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = professionals.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = professionals.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Company members can DELETE professionals
DROP POLICY IF EXISTS "member_delete_professionals" ON professionals;
CREATE POLICY "member_delete_professionals" ON professionals FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = professionals.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Tighten services RLS: keep public SELECT, restrict writes to company members
-- SELECT stays as-is (anon + authenticated, USING true)

DROP POLICY IF EXISTS "anon_insert_services" ON services;
CREATE POLICY "member_insert_services" ON services FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = services.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

DROP POLICY IF EXISTS "anon_update_services" ON services;
CREATE POLICY "member_update_services" ON services FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = services.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = services.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

DROP POLICY IF EXISTS "anon_delete_services" ON services;
CREATE POLICY "member_delete_services" ON services FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = services.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Tighten bookings RLS: keep public SELECT + anon INSERT (booking form), restrict UPDATE/DELETE
-- SELECT stays as-is (anon + authenticated, USING true)
-- INSERT stays as anon + authenticated (clients book without login)

DROP POLICY IF EXISTS "anon_update_bookings" ON bookings;
CREATE POLICY "member_update_bookings" ON bookings FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = bookings.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = bookings.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

DROP POLICY IF EXISTS "anon_delete_bookings" ON bookings;
CREATE POLICY "member_delete_bookings" ON bookings FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = bookings.empresa_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Grant authenticated role access to services/bookings writes
GRANT INSERT, UPDATE, DELETE ON services TO authenticated;
GRANT UPDATE, DELETE ON bookings TO authenticated;

-- Index on professionals
CREATE INDEX IF NOT EXISTS idx_professionals_empresa_id ON professionals(empresa_id);
