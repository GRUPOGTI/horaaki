/*
# Cadastro único de clientes e agendamento compartilhado

Plain-English summary: phone/WhatsApp becomes the main client identifier and CPF the secondary one. Public and admin bookings now go through the same database functions, which find or create the client, compute free time slots, and block conflicts inside the database.

1. New functions
- normalize_phone / normalize_cpf: keep digits only.
- is_company_member: true when the signed-in user owns or administers the company.
- upsert_client: finds a client by phone (then CPF) inside the company, or creates one. Never overwrites an existing name.
- get_available_slots: returns free start times for a service, date and optional professional, considering each booking's duration and the current time in Sao Paulo.
- create_booking: validates every input, locks the company/date, re-checks availability, links the client and inserts the booking. Public callers always create "pending" bookings; only company members can create "confirmed" ones.

2. Data
- Existing bookings without a client are linked to a client (backfill) using their phone. Bookings without a company or a valid phone are left untouched.
- Index on bookings(empresa_id, booking_date).

3. Security
- Removed public (anon) read access to clients and bookings, and the public update policy on bookings.
- Members can read clients and bookings of their own company.
- client_otps loses all policies and grants: no public access until a secure OTP flow is built.
- Public booking uses only create_booking and get_available_slots, which expose no personal data.

Notes
- Idempotent: policies are dropped before creation and functions use CREATE OR REPLACE.
*/

CREATE OR REPLACE FUNCTION normalize_phone(p_phone text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT regexp_replace(coalesce(p_phone, ''), '\D', '', 'g')
$$;

CREATE OR REPLACE FUNCTION normalize_cpf(p_cpf text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT NULLIF(regexp_replace(coalesce(p_cpf, ''), '\D', '', 'g'), '')
$$;

CREATE OR REPLACE FUNCTION is_company_member(p_empresa uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM companies c WHERE c.id = p_empresa AND c.user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = p_empresa AND cm.user_id = auth.uid() AND cm.role IN ('owner', 'admin')
    )
$$;

REVOKE EXECUTE ON FUNCTION is_company_member(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION is_company_member(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION upsert_client(p_empresa uuid, p_name text, p_phone text, p_cpf text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_phone text := normalize_phone(p_phone);
  v_cpf text := normalize_cpf(p_cpf);
  v_id uuid;
BEGIN
  SELECT id INTO v_id FROM clients WHERE empresa_id = p_empresa AND phone = v_phone;

  IF v_id IS NULL AND v_cpf IS NOT NULL THEN
    SELECT id INTO v_id FROM clients WHERE empresa_id = p_empresa AND cpf = v_cpf;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO clients (empresa_id, name, phone, cpf)
    VALUES (p_empresa, trim(p_name), v_phone, v_cpf)
    RETURNING id INTO v_id;
  ELSE
    UPDATE clients
    SET name = CASE WHEN trim(coalesce(name, '')) = '' THEN trim(p_name) ELSE name END
    WHERE id = v_id;

    IF v_cpf IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM clients o WHERE o.empresa_id = p_empresa AND o.cpf = v_cpf AND o.id <> v_id
    ) THEN
      UPDATE clients SET cpf = v_cpf WHERE id = v_id AND cpf IS NULL;
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION upsert_client(uuid, text, text, text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION get_available_slots(
  p_empresa uuid,
  p_service uuid,
  p_date date,
  p_professional uuid DEFAULT NULL
)
RETURNS SETOF text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_duration integer;
  v_today date := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
  v_now time := (now() AT TIME ZONE 'America/Sao_Paulo')::time;
BEGIN
  IF p_date IS NULL OR p_date < v_today THEN
    RETURN;
  END IF;

  SELECT duration_min INTO v_duration
  FROM services
  WHERE id = p_service AND empresa_id = p_empresa AND active;

  IF v_duration IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH slots AS (
    SELECT (time '08:00' + make_interval(mins => g.i * 30)) AS t
    FROM generate_series(0, 21) AS g(i)
  )
  SELECT substring(slots.t::text, 1, 5)
  FROM slots
  WHERE (p_date > v_today OR slots.t > v_now)
    AND NOT EXISTS (
      SELECT 1
      FROM bookings b
      LEFT JOIN services bs ON bs.id = b.service_id
      WHERE b.empresa_id = p_empresa
        AND b.booking_date = p_date
        AND b.status <> 'cancelled'
        AND (p_professional IS NULL OR b.professional_id IS NULL OR b.professional_id = p_professional)
        AND b.booking_time::time < slots.t + make_interval(mins => v_duration)
        AND b.booking_time::time + make_interval(mins => coalesce(bs.duration_min, 30)) > slots.t
    )
  ORDER BY slots.t;
END;
$$;

REVOKE EXECUTE ON FUNCTION get_available_slots(uuid, uuid, date, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_available_slots(uuid, uuid, date, uuid) TO anon, authenticated;

CREATE OR REPLACE FUNCTION create_booking(
  p_empresa uuid,
  p_service uuid,
  p_date date,
  p_time text,
  p_name text,
  p_phone text,
  p_cpf text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_professional uuid DEFAULT NULL,
  p_status text DEFAULT 'pending'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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

  v_client_id := upsert_client(p_empresa, v_name, v_phone, v_cpf);

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
$$;

REVOKE EXECUTE ON FUNCTION create_booking(uuid, uuid, date, text, text, text, text, text, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION create_booking(uuid, uuid, date, text, text, text, text, text, uuid, text) TO anon, authenticated;

DO $$
DECLARE
  r record;
  v_client uuid;
BEGIN
  FOR r IN
    SELECT id, empresa_id, client_name, client_phone
    FROM bookings
    WHERE client_id IS NULL AND empresa_id IS NOT NULL
  LOOP
    IF normalize_phone(r.client_phone) ~ '^[0-9]{10,13}$' THEN
      v_client := upsert_client(r.empresa_id, r.client_name, r.client_phone, NULL);
      UPDATE bookings
      SET client_id = v_client, client_phone = normalize_phone(r.client_phone)
      WHERE id = r.id;
    END IF;
  END LOOP;
END;
$$;

CREATE INDEX IF NOT EXISTS bookings_empresa_date_idx ON bookings (empresa_id, booking_date);

REVOKE ALL ON clients, bookings, client_otps FROM anon;

DROP POLICY IF EXISTS "anon_select_clients" ON clients;
DROP POLICY IF EXISTS "member_select_clients" ON clients;
CREATE POLICY "member_select_clients" ON clients FOR SELECT
TO authenticated
USING (is_company_member(empresa_id));

DROP POLICY IF EXISTS "anon_insert_bookings" ON bookings;
DROP POLICY IF EXISTS "anon_select_bookings" ON bookings;
DROP POLICY IF EXISTS "client_update_own_bookings" ON bookings;
DROP POLICY IF EXISTS "member_select_bookings" ON bookings;
CREATE POLICY "member_select_bookings" ON bookings FOR SELECT
TO authenticated
USING (is_company_member(empresa_id));

DROP POLICY IF EXISTS "anon_select_otps" ON client_otps;
DROP POLICY IF EXISTS "anon_insert_otps" ON client_otps;
DROP POLICY IF EXISTS "anon_update_otps" ON client_otps;
REVOKE ALL ON client_otps FROM authenticated;
