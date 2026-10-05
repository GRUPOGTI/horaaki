/*
# Tabela company_members: vincula usuários a empresas com papel (owner/admin)

1. Nova tabela
- `company_members`: associação entre auth.users e companies
  - id (uuid, PK)
  - company_id (uuid, FK companies, ON DELETE CASCADE)
  - user_id (uuid, FK auth.users, ON DELETE CASCADE)
  - role (text: 'owner' ou 'admin', default 'admin')
  - invited_email (text, nullable — e-mail de convite pendente)
  - created_at (timestamptz)

2. Modificações em `companies`
- Remove a coluna `user_id` (não destrutivo: a coluna passa a não ser mais usada)
  NOTA: NÃO removemos a coluna para preservar dados. Apenas deixamos de depender dela.
  O novo relacionamento é via company_members.

3. Segurança
- RLS habilitado em company_members
- SELECT: anon pode ler (para descobrir a empresa pela URL pública) + authenticated
- INSERT: apenas authenticated, e apenas se o usuário for owner/admin da mesma empresa
- UPDATE/DELETE: apenas authenticated, e apenas se for owner/admin da mesma empresa
- Constraint UNIQUE em (company_id, user_id) para evitar duplicatas

4. Notas
- O owner original da empresa (user_id em companies) continua funcionando
- Novos usuários podem ser convidados como 'admin' para uma empresa existente
- Cada empresa pode ter 1 owner + N admins
*/

CREATE TABLE IF NOT EXISTS company_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'admin',
  invited_email text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(company_id, user_id)
);

ALTER TABLE company_members ENABLE ROW LEVEL SECURITY;

-- SELECT: qualquer pessoa pode ver os membros (precisa para página pública saber da empresa)
DROP POLICY IF EXISTS "anon_select_company_members" ON company_members;
CREATE POLICY "anon_select_company_members" ON company_members FOR SELECT
  TO anon, authenticated USING (true);

-- INSERT: apenas authenticated usuários que já são owner/admin da mesma empresa
DROP POLICY IF EXISTS "member_insert_company_members" ON company_members;
CREATE POLICY "member_insert_company_members" ON company_members FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_members.company_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- UPDATE: apenas owner/admin da mesma empresa
DROP POLICY IF EXISTS "member_update_company_members" ON company_members;
CREATE POLICY "member_update_company_members" ON company_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_members.company_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_members.company_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- DELETE: apenas owner/admin da mesma empresa
DROP POLICY IF EXISTS "member_delete_company_members" ON company_members;
CREATE POLICY "member_delete_company_members" ON company_members FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_members.company_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Índices
CREATE INDEX IF NOT EXISTS idx_company_members_company_id ON company_members(company_id);
CREATE INDEX IF NOT EXISTS idx_company_members_user_id ON company_members(user_id);
