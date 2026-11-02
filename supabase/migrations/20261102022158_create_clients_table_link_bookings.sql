/*
# Create clients table and link bookings to clients + professionals

1. New Tables
- `clients` — stores unique customers per company, identified by
  CPF or phone to prevent duplicates.
  - `id` (uuid PK)
  - `empresa_id` (uuid FK to companies, NOT NULL)
  - `name` (text, NOT NULL)
  - `phone` (text, NOT NULL)
  - `cpf` (text, nullable)
  - `email` (text, nullable)
  - `notes` (text, nullable)
  - `created_at` (timestamptz)
  - UNIQUE constraint on (empresa_id, phone) — one client per phone per company.
  - UNIQUE constraint on (empresa_id, cpf) WHERE cpf IS NOT NULL — one client per CPF per company.

2. Modified Tables
- `bookings` — adds two nullable columns:
  - `client_id` (uuid FK to clients, nullable) — links booking to a registered client.
  - `professional_id` (uuid FK to professionals, nullable) — links booking to a professional.
  Both are nullable to preserve existing booking rows that were created
  before clients/professionals were linked.

3. Security
- RLS enabled on `clients`.
- Grants: anon + authenticated get SELECT (public pages need to check
  if a client exists by phone when creating a booking). Only
  authenticated members can INSERT/UPDATE/DELETE.
- Policies:
  - SELECT: anon + authenticated can read (public booking page needs to
    look up clients by phone/empresa_id).
  - INSERT/UPDATE/DELETE: only company members (owner/admin).
- Existing bookings policies already allow anon INSERT (public booking
  form), so the new nullable columns don't break existing inserts.
*/

CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text NOT NULL,
  cpf text,
  email text,
  notes text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Unique constraints: one client per phone per company, one per CPF per company
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'clients_empresa_id_phone_key') THEN
    ALTER TABLE clients ADD CONSTRAINT clients_empresa_id_phone_key UNIQUE (empresa_id, phone);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'clients_empresa_id_cpf_key') THEN
    ALTER TABLE clients ADD CONSTRAINT clients_empresa_id_cpf_key UNIQUE (empresa_id, cpf);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_clients_empresa_id ON clients(empresa_id);
CREATE INDEX IF NOT EXISTS idx_clients_phone ON clients(phone);

-- Grants
GRANT SELECT ON clients TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON clients TO authenticated;

-- Policies
DROP POLICY IF EXISTS "anon_select_clients" ON clients;
CREATE POLICY "anon_select_clients" ON clients FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "member_insert_clients" ON clients;
CREATE POLICY "member_insert_clients" ON clients FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = clients.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = clients.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role = ANY(ARRAY['owner','admin'])
        )
      )
    )
  );

DROP POLICY IF EXISTS "member_update_clients" ON clients;
CREATE POLICY "member_update_clients" ON clients FOR UPDATE
  TO authenticated USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = clients.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = clients.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role = ANY(ARRAY['owner','admin'])
        )
      )
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = clients.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = clients.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role = ANY(ARRAY['owner','admin'])
        )
      )
    )
  );

DROP POLICY IF EXISTS "member_delete_clients" ON clients;
CREATE POLICY "member_delete_clients" ON clients FOR DELETE
  TO authenticated USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = clients.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = clients.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role = ANY(ARRAY['owner','admin'])
        )
      )
    )
  );

-- Add client_id and professional_id to bookings (nullable, preserves existing rows)
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS client_id uuid REFERENCES clients(id) ON DELETE SET NULL;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS professional_id uuid REFERENCES professionals(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_bookings_client_id ON bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_professional_id ON bookings(professional_id);
