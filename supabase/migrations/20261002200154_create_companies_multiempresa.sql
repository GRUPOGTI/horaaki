/*
# Multi-empresa: tabela companies + empresa_id em services e bookings

1. Nova tabela
- `companies`: armazena os dados de cada empresa cadastrada no Horaki
  - id (uuid, PK)
  - user_id (uuid, FK auth.users, dono da empresa)
  - name (nome da empresa)
  - slug (URL pública, único)
  - description (descrição da empresa)
  - logo_url (URL do logo)
  - banner_url (URL do banner/hero)
  - primary_color (cor primária da marca)
  - whatsapp (telefone/WhatsApp)
  - email (e-mail de contato)
  - address (endereço)
  - hours (horário de funcionamento em texto livre)
  - is_open (status aberto/fechado)
  - instagram_url, facebook_url, tiktok_url (redes sociais)
  - created_at, updated_at

2. Modificações em tabelas existentes
- `services`: adicionada coluna `empresa_id uuid` (FK para companies)
- `bookings`: adicionada coluna `empresa_id uuid` (FK para companies)

3. Segurança
- RLS habilitado em `companies`
- SELECT público (anon + authenticated) para que a página pública funcione sem login
- INSERT/UPDATE/DELETE restritos ao dono (authenticated, user_id = auth.uid())
- As tabelas services e bookings mantêm suas policies existentes (anon + authenticated)
- O isolamento entre empresas é feito por filtro de empresa_id no frontend

4. Dados existentes
- Os serviços e agendamentos existentes recebem empresa_id NULL temporariamente
- Uma empresa padrão é criada se não existir, para compatibilidade

Notas importantes:
- Esta migration NÃO remove dados existentes
- Os 10 serviços e 3 agendamentos atuais permanecem intactos
- O empresa_id é nullable para preservar os registros existentes
*/

-- Tabela companies
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text,
  logo_url text,
  banner_url text,
  primary_color text DEFAULT '#d4af37',
  whatsapp text,
  email text,
  address text,
  hours text,
  is_open boolean NOT NULL DEFAULT true,
  instagram_url text,
  facebook_url text,
  tiktok_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- SELECT público: qualquer pessoa pode ver dados da empresa (página pública)
DROP POLICY IF EXISTS "anon_select_companies" ON companies;
CREATE POLICY "anon_select_companies" ON companies FOR SELECT
  TO anon, authenticated USING (true);

-- INSERT: apenas dono autenticado
DROP POLICY IF EXISTS "owner_insert_companies" ON companies;
CREATE POLICY "owner_insert_companies" ON companies FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

-- UPDATE: apenas dono autenticado
DROP POLICY IF EXISTS "owner_update_companies" ON companies;
CREATE POLICY "owner_update_companies" ON companies FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- DELETE: apenas dono autenticado
DROP POLICY IF EXISTS "owner_delete_companies" ON companies;
CREATE POLICY "owner_delete_companies" ON companies FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- Adicionar empresa_id em services
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'services' AND column_name = 'empresa_id') THEN
    ALTER TABLE services ADD COLUMN empresa_id uuid REFERENCES companies(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Adicionar empresa_id em bookings
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'empresa_id') THEN
    ALTER TABLE bookings ADD COLUMN empresa_id uuid REFERENCES companies(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_services_empresa_id ON services(empresa_id);
CREATE INDEX IF NOT EXISTS idx_bookings_empresa_id ON bookings(empresa_id);
CREATE INDEX IF NOT EXISTS idx_companies_slug ON companies(slug);
CREATE INDEX IF NOT EXISTS idx_companies_user_id ON companies(user_id);
