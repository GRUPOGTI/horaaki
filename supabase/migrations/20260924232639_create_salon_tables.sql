/*
# Create Salão Nadja Gomes - Services and Bookings tables

1. New Tables
- `services`: Stores salon services (name, description, price, duration, category, icon)
- `bookings`: Stores appointment bookings (client name, phone, service, date, time, notes, status)
2. Security
- Enable RLS on both tables.
- Allow anon + authenticated CRUD because this is a single-tenant public app (no sign-in).
*/

-- Services table
CREATE TABLE IF NOT EXISTS services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price numeric(10,2) NOT NULL DEFAULT 0,
  duration_min integer NOT NULL DEFAULT 30,
  category text NOT NULL DEFAULT 'Geral',
  icon text DEFAULT 'scissors',
  display_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_services" ON services;
CREATE POLICY "anon_select_services" ON services FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_services" ON services;
CREATE POLICY "anon_insert_services" ON services FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_services" ON services;
CREATE POLICY "anon_update_services" ON services FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_services" ON services;
CREATE POLICY "anon_delete_services" ON services FOR DELETE
  TO anon, authenticated USING (true);

-- Bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_name text NOT NULL,
  client_phone text NOT NULL,
  service_id uuid REFERENCES services(id) ON DELETE SET NULL,
  service_name text NOT NULL,
  booking_date date NOT NULL,
  booking_time text NOT NULL,
  notes text,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_bookings" ON bookings;
CREATE POLICY "anon_select_bookings" ON bookings FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_bookings" ON bookings;
CREATE POLICY "anon_insert_bookings" ON bookings FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_bookings" ON bookings;
CREATE POLICY "anon_update_bookings" ON bookings FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_bookings" ON bookings;
CREATE POLICY "anon_delete_bookings" ON bookings FOR DELETE
  TO anon, authenticated USING (true);

-- Seed default services
INSERT INTO services (name, description, price, duration_min, category, icon, display_order) VALUES
('Corte Feminino', 'Corte personalizado com finalização e escova', 80.00, 60, 'Cabelo', 'scissors', 1),
('Corte Masculino', 'Corte moderno com acabamento', 45.00, 30, 'Cabelo', 'scissors', 2),
('Coloração', 'Coloração completa com produtos de alta qualidade', 150.00, 120, 'Cabelo', 'palette', 3),
('Mecha e Luzes', 'Técnica de mechas para iluminar os fios', 220.00, 180, 'Cabelo', 'sparkles', 4),
('Hidratação Profunda', 'Tratamento intensivo para recuperar os fios', 70.00, 45, 'Tratamento', 'droplet', 5),
('Progressiva', 'Alisamento progressivo com formol', 350.00, 240, 'Tratamento', 'wind', 6),
('Manicure', 'Manicure completa com esmaltação', 35.00, 45, 'Unhas', 'hand', 7),
('Pedicure', 'Pedicure completa com esfoliação e esmaltação', 40.00, 50, 'Unhas', 'foot', 8),
('Design de Sobrancelhas', 'Design e henna para sobrancelhas', 30.00, 30, 'Estética', 'eye', 9),
('Maquiagem', 'Maquiagem profissional para eventos', 120.00, 60, 'Estética', 'brush', 10)
ON CONFLICT DO NOTHING;
