/*
# Separate client accounts from company (panel) accounts

1. New Tables
- `client_profiles`: one row per client account. Holds the client's own name and phone, independent of any company. Keyed by the login user id.

2. Modified Functions
- `reject_client_as_system_user()`: also blocks client accounts from owning or joining a company.
- `link_client_account(p_empresa)`: reads name and phone from the client profile instead of sign-up metadata. Still refuses company accounts.

3. New Functions
- `get_account_type()`: returns 'system' (company owner or member), 'client' or 'none' for the signed-in user.
- `register_client_account(p_name, p_phone)`: creates or updates the signed-in user's client profile.
- `get_my_bookings()`: lists only the signed-in client's own bookings.
- `update_my_client_profile(p_name, p_phone)`: updates the client's own profile and linked company records.
- `cancel_my_booking(p_booking)`: cancels a pending or confirmed booking that belongs to the signed-in client.

4. Security
- RLS enabled on `client_profiles`; clients can read only their own row. No direct writes: all changes go through the functions above.
- A client profile cannot be created for a company account, and a company account cannot own or join a company while it has a client profile (enforced by triggers in the database).
- All new functions run as SECURITY DEFINER with a fixed search_path, EXECUTE is revoked from PUBLIC and anon, and granted only to authenticated.

5. Data Backfill
- Existing client accounts (already linked to a company) and sign-ups that stored name and phone get a client profile. Company accounts are never backfilled.
*/

CREATE TABLE IF NOT EXISTS client_profiles (
  auth_user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(name) BETWEEN 2 AND 120),
  phone text NOT NULL CHECK (char_length(phone) BETWEEN 10 AND 13),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE client_profiles ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON client_profiles TO authenticated;

DROP POLICY IF EXISTS "select_own_client_profile" ON client_profiles;
CREATE POLICY "select_own_client_profile" ON client_profiles FOR SELECT
  TO authenticated USING (auth.uid() = auth_user_id);

INSERT INTO client_profiles (auth_user_id, name, phone)
SELECT s.uid, s.name, s.phone
FROM (
  SELECT
    u.id AS uid,
    COALESCE(c.name, trim(u.raw_user_meta_data->>'name')) AS name,
    COALESCE(c.phone, normalize_phone(u.raw_user_meta_data->>'phone')) AS phone
  FROM auth.users u
  LEFT JOIN LATERAL (
    SELECT cl.name, cl.phone FROM clients cl
    WHERE cl.auth_user_id = u.id
    ORDER BY cl.created_at
    LIMIT 1
  ) c ON true
  WHERE NOT EXISTS (SELECT 1 FROM companies co WHERE co.user_id = u.id)
    AND NOT EXISTS (SELECT 1 FROM company_members m WHERE m.user_id = u.id)
) s
WHERE char_length(s.name) BETWEEN 2 AND 120
  AND char_length(s.phone) BETWEEN 10 AND 13
ON CONFLICT (auth_user_id) DO NOTHING;

CREATE OR REPLACE FUNCTION reject_client_as_system_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF EXISTS (SELECT 1 FROM clients WHERE auth_user_id = NEW.user_id)
    OR EXISTS (SELECT 1 FROM client_profiles WHERE auth_user_id = NEW.user_id) THEN
    RAISE EXCEPTION 'Esta conta é de cliente e não pode acessar o painel administrativo';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION reject_system_as_client()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF EXISTS (SELECT 1 FROM companies WHERE user_id = NEW.auth_user_id)
    OR EXISTS (SELECT 1 FROM company_members WHERE user_id = NEW.auth_user_id) THEN
    RAISE EXCEPTION 'Esta conta é de usuário do sistema e não pode ser usada como cliente';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS client_profiles_block_system ON client_profiles;
CREATE TRIGGER client_profiles_block_system
  BEFORE INSERT ON client_profiles
  FOR EACH ROW EXECUTE FUNCTION reject_system_as_client();

CREATE OR REPLACE FUNCTION link_client_account(p_empresa uuid)
RETURNS clients
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_profile client_profiles;
  v_email text;
  v_row clients;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM companies WHERE id = p_empresa) THEN
    RAISE EXCEPTION 'Empresa não encontrada';
  END IF;
  IF EXISTS (SELECT 1 FROM companies WHERE user_id = v_uid)
    OR EXISTS (SELECT 1 FROM company_members WHERE user_id = v_uid) THEN
    RAISE EXCEPTION 'Esta conta é de usuário do sistema e não pode agendar como cliente';
  END IF;

  SELECT * INTO v_row FROM clients WHERE empresa_id = p_empresa AND auth_user_id = v_uid;
  IF FOUND THEN
    RETURN v_row;
  END IF;

  SELECT * INTO v_profile FROM client_profiles WHERE auth_user_id = v_uid;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cadastro incompleto';
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = v_uid;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_empresa::text || ':client:' || v_profile.phone, 0));

  SELECT * INTO v_row FROM clients WHERE empresa_id = p_empresa AND phone = v_profile.phone;
  IF FOUND THEN
    IF v_row.auth_user_id IS NOT NULL AND v_row.auth_user_id <> v_uid THEN
      RAISE EXCEPTION 'Telefone já vinculado a outra conta';
    END IF;
    UPDATE clients SET auth_user_id = v_uid, email = coalesce(v_email, email)
    WHERE id = v_row.id
    RETURNING * INTO v_row;
    RETURN v_row;
  END IF;

  INSERT INTO clients (empresa_id, name, phone, email, auth_user_id)
  VALUES (p_empresa, v_profile.name, v_profile.phone, v_email, v_uid)
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$;

CREATE OR REPLACE FUNCTION get_account_type()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN 'none';
  END IF;
  IF EXISTS (SELECT 1 FROM companies WHERE user_id = v_uid)
    OR EXISTS (SELECT 1 FROM company_members WHERE user_id = v_uid) THEN
    RETURN 'system';
  END IF;
  IF EXISTS (SELECT 1 FROM client_profiles WHERE auth_user_id = v_uid) THEN
    RETURN 'client';
  END IF;
  RETURN 'none';
END;
$function$;

CREATE OR REPLACE FUNCTION register_client_account(p_name text, p_phone text)
RETURNS client_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_phone text := normalize_phone(p_phone);
  v_row client_profiles;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;
  IF char_length(v_name) < 2 OR char_length(v_name) > 120 THEN
    RAISE EXCEPTION 'Nome inválido';
  END IF;
  IF char_length(v_phone) NOT BETWEEN 10 AND 13 THEN
    RAISE EXCEPTION 'Telefone inválido';
  END IF;

  INSERT INTO client_profiles (auth_user_id, name, phone)
  VALUES (v_uid, v_name, v_phone)
  ON CONFLICT (auth_user_id) DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$;

CREATE OR REPLACE FUNCTION update_my_client_profile(p_name text, p_phone text)
RETURNS client_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_name text := trim(coalesce(p_name, ''));
  v_phone text := normalize_phone(p_phone);
  v_row client_profiles;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;
  IF char_length(v_name) < 2 OR char_length(v_name) > 120 THEN
    RAISE EXCEPTION 'Nome inválido';
  END IF;
  IF char_length(v_phone) NOT BETWEEN 10 AND 13 THEN
    RAISE EXCEPTION 'Telefone inválido';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM client_profiles WHERE auth_user_id = v_uid) THEN
    RAISE EXCEPTION 'Cadastro incompleto';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM clients mine
    JOIN clients other ON other.empresa_id = mine.empresa_id AND other.id <> mine.id
    WHERE mine.auth_user_id = v_uid AND other.phone = v_phone
  ) THEN
    RAISE EXCEPTION 'Telefone já cadastrado para outro cliente';
  END IF;

  UPDATE client_profiles SET name = v_name, phone = v_phone
  WHERE auth_user_id = v_uid
  RETURNING * INTO v_row;

  UPDATE clients SET name = v_name, phone = v_phone
  WHERE auth_user_id = v_uid;

  RETURN v_row;
END;
$function$;

CREATE OR REPLACE FUNCTION get_my_bookings()
RETURNS TABLE (
  booking_id uuid,
  company_name text,
  company_slug text,
  service_name text,
  booking_date date,
  booking_time text,
  status text,
  notes text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT b.id, co.name, co.slug, b.service_name, b.booking_date, b.booking_time, b.status, b.notes
  FROM bookings b
  JOIN clients cl ON cl.id = b.client_id
  JOIN companies co ON co.id = b.empresa_id
  WHERE cl.auth_user_id = auth.uid()
  ORDER BY b.booking_date DESC, b.booking_time DESC;
$function$;

CREATE OR REPLACE FUNCTION cancel_my_booking(p_booking uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE bookings b SET status = 'cancelled'
  FROM clients cl
  WHERE b.id = p_booking
    AND cl.id = b.client_id
    AND cl.auth_user_id = auth.uid()
    AND b.status IN ('pending', 'confirmed');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Agendamento não pode ser cancelado';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION reject_system_as_client() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION get_account_type() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION register_client_account(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION update_my_client_profile(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION get_my_bookings() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION cancel_my_booking(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION link_client_account(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION get_account_type() TO authenticated;
GRANT EXECUTE ON FUNCTION register_client_account(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_my_client_profile(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_bookings() TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_my_booking(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION link_client_account(uuid) TO authenticated;
