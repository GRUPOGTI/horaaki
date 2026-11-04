/*
# Client accounts linked to a single client record per company

1. Summary
- Clients can now sign up and log in (email and password) to book appointments.
- Each client account is linked to exactly one client record per company, identified by phone.
- Bookings made by a logged-in client are always attached to that same client record.

2. Modified tables
- `clients`: new column `auth_user_id` (links to the Supabase login account, nullable).
- `clients`: new partial unique index so one login account maps to at most one record per company.

3. New functions
- `link_client_account(p_empresa)`: returns the client record linked to the logged-in account for that company. On first use it reuses an existing record with the same phone (if not linked yet) or creates one from the profile saved at sign-up.
- `update_my_client(p_empresa, p_name, p_phone)`: lets a logged-in client edit their own name and phone.
- `update_client_profile(...)`: internal helper that validates and updates a client record and blocks phone duplicates inside a company.
- `create_booking`: when the caller is logged in and linked to the company, the booking uses that client record and keeps its name and phone in sync.

4. Security
- `upsert_client` and `update_client_profile` are no longer callable by anonymous or logged-in users directly; they only run inside the functions above.
- `link_client_account` and `update_my_client` are callable only by logged-in users.
- No new table policies are opened; clients still read data through the company's own members only.

5. Notes
- Phone is normalized to digits only, so formats like (11) 99999-9999 and 11999999999 match.
- Existing client records are never deleted; the migration is safe to re-run.
*/

ALTER TABLE clients ADD COLUMN IF NOT EXISTS auth_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS clients_empresa_auth_user_uidx
ON clients (empresa_id, auth_user_id)
WHERE auth_user_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.update_client_profile(p_client uuid, p_empresa uuid, p_name text, p_phone text)
RETURNS clients
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_name text := trim(coalesce(p_name, ''));
  v_phone text := normalize_phone(p_phone);
  v_row clients;
BEGIN
  IF char_length(v_name) < 2 OR char_length(v_name) > 120 THEN
    RAISE EXCEPTION 'Nome inválido';
  END IF;
  IF char_length(v_phone) NOT BETWEEN 10 AND 13 THEN
    RAISE EXCEPTION 'Telefone inválido';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_empresa::text || ':client:' || v_phone, 0));

  IF EXISTS (
    SELECT 1 FROM clients WHERE empresa_id = p_empresa AND phone = v_phone AND id <> p_client
  ) THEN
    RAISE EXCEPTION 'Telefone já cadastrado para outro cliente';
  END IF;

  UPDATE clients SET name = v_name, phone = v_phone
  WHERE id = p_client AND empresa_id = p_empresa
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$;

CREATE OR REPLACE FUNCTION public.link_client_account(p_empresa uuid)
RETURNS clients
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_meta jsonb;
  v_email text;
  v_name text;
  v_phone text;
  v_row clients;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM companies WHERE id = p_empresa) THEN
    RAISE EXCEPTION 'Empresa não encontrada';
  END IF;

  SELECT * INTO v_row FROM clients WHERE empresa_id = p_empresa AND auth_user_id = v_uid;
  IF FOUND THEN
    RETURN v_row;
  END IF;

  SELECT raw_user_meta_data, email INTO v_meta, v_email FROM auth.users WHERE id = v_uid;
  v_name := trim(coalesce(v_meta->>'name', ''));
  v_phone := normalize_phone(v_meta->>'phone');
  IF char_length(v_name) < 2 OR char_length(v_phone) NOT BETWEEN 10 AND 13 THEN
    RAISE EXCEPTION 'Cadastro incompleto';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_empresa::text || ':client:' || v_phone, 0));

  SELECT * INTO v_row FROM clients WHERE empresa_id = p_empresa AND phone = v_phone;
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
  VALUES (p_empresa, v_name, v_phone, v_email, v_uid)
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_my_client(p_empresa uuid, p_name text, p_phone text)
RETURNS clients
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_id uuid;
BEGIN
  SELECT id INTO v_id FROM clients WHERE empresa_id = p_empresa AND auth_user_id = auth.uid();
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'Conta não vinculada a esta empresa';
  END IF;
  RETURN update_client_profile(v_id, p_empresa, p_name, p_phone);
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_booking(p_empresa uuid, p_service uuid, p_date date, p_time text, p_name text, p_phone text, p_cpf text DEFAULT NULL::text, p_notes text DEFAULT NULL::text, p_professional uuid DEFAULT NULL::uuid, p_status text DEFAULT 'pending'::text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
v_name text := trim(coalesce(p_name, ''));
v_phone text := normalize_phone(p_phone);
v_cpf text := normalize_cpf(p_cpf);
v_notes text := NULLIF(trim(coalesce(p_notes, '')), '');
v_service_name text;
v_client_id uuid;
v_booking_id uuid;
BEGIN
IF char_length(v_name) < 2 OR char_length(v_name) > 120 THEN
RAISE EXCEPTION 'Nome inválido';
END IF;
IF char_length(v_phone) NOT BETWEEN 10 AND 13 THEN
RAISE EXCEPTION 'Telefone inválido';
END IF;
IF p_cpf IS NOT NULL AND trim(p_cpf) <> '' AND (v_cpf IS NULL OR char_length(v_cpf) <> 11) THEN
RAISE EXCEPTION 'CPF inválido';
END IF;
IF v_notes IS NOT NULL AND char_length(v_notes) > 500 THEN
RAISE EXCEPTION 'Observações muito longas';
END IF;
IF p_status NOT IN ('pending', 'confirmed') THEN
RAISE EXCEPTION 'Status inválido';
END IF;
IF p_status = 'confirmed' AND NOT is_company_member(p_empresa) THEN
RAISE EXCEPTION 'Não autorizado';
END IF;
IF NOT EXISTS (SELECT 1 FROM companies WHERE id = p_empresa) THEN
RAISE EXCEPTION 'Empresa não encontrada';
END IF;
IF p_professional IS NOT NULL AND NOT EXISTS (
SELECT 1 FROM professionals WHERE id = p_professional AND empresa_id = p_empresa AND active
) THEN
RAISE EXCEPTION 'Profissional inválido';
END IF;

SELECT name INTO v_service_name
FROM services
WHERE id = p_service AND empresa_id = p_empresa AND active;
IF v_service_name IS NULL THEN
RAISE EXCEPTION 'Serviço inválido';
END IF;

PERFORM pg_advisory_xact_lock(hashtextextended(p_empresa::text || ':' || p_date::text, 0));

IF NOT EXISTS (
SELECT 1 FROM get_available_slots(p_empresa, p_service, p_date, p_professional) s WHERE s = p_time
) THEN
RAISE EXCEPTION 'Horário indisponível';
END IF;

IF auth.uid() IS NOT NULL THEN
SELECT id INTO v_client_id FROM clients WHERE empresa_id = p_empresa AND auth_user_id = auth.uid();
END IF;

IF v_client_id IS NULL THEN
v_client_id := upsert_client(p_empresa, v_name, v_phone, v_cpf);
ELSE
PERFORM update_client_profile(v_client_id, p_empresa, v_name, v_phone);
END IF;

INSERT INTO bookings (
empresa_id, client_id, client_name, client_phone, professional_id,
service_id, service_name, booking_date, booking_time, notes, status
)
VALUES (
p_empresa, v_client_id, v_name, v_phone, p_professional,
p_service, v_service_name, p_date, p_time, v_notes, p_status
)
RETURNING id INTO v_booking_id;

RETURN v_booking_id;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.upsert_client(uuid, text, text, text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_client_profile(uuid, uuid, text, text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.link_client_account(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_my_client(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.link_client_account(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_my_client(uuid, text, text) TO authenticated;
