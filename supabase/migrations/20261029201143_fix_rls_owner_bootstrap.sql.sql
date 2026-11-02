/*
# Fix RLS: allow company owner to bootstrap membership and manage services/bookings

1. Problem
   - The company_members INSERT policy requires an existing membership row for the
     authenticated user in the same company. This creates a chicken-and-egg problem:
     the company owner cannot insert their own owner membership record, so no one
     ever becomes a member. Without membership, all service/booking write policies
     (which check company_members) also fail.
   - The companies table has a `user_id` column (the original owner) that can be used
     to authorize the first membership insert without requiring a prior membership.

2. Fix: company_members INSERT policy
   - Allow INSERT if the authenticated user is the company owner (companies.user_id = auth.uid())
     OR already a member (owner/admin) of the company.
   - This lets the owner bootstrap their own membership and then invite others.

3. Fix: company_members UPDATE/DELETE policies
   - Same expansion: allow if owner via companies.user_id OR existing member (owner/admin).

4. Fix: services INSERT/UPDATE/DELETE policies
   - Allow if the authenticated user is the company owner (companies.user_id = auth.uid())
     for the empresa_id, OR is a member (owner/admin) via company_members.

5. Fix: bookings UPDATE/DELETE policies
   - Same expansion for company owner or member.
   - INSERT remains open to anon (clients booking without login).

6. Important notes
   - The /agenda/nadja-gomes page is unaffected: SELECT policies stay public.
   - No data is changed or deleted.
   - Existing services and bookings remain linked to the Nadja Gomes company.
*/

-- Fix company_members INSERT: allow company owner (via companies.user_id) OR existing member
DROP POLICY IF EXISTS "member_insert_company_members" ON company_members;
CREATE POLICY "member_insert_company_members" ON company_members FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = company_members.company_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm2
          WHERE cm2.company_id = company_members.company_id
          AND cm2.user_id = auth.uid()
          AND cm2.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix company_members UPDATE: same expansion
DROP POLICY IF EXISTS "member_update_company_members" ON company_members;
CREATE POLICY "member_update_company_members" ON company_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = company_members.company_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm2
          WHERE cm2.company_id = company_members.company_id
          AND cm2.user_id = auth.uid()
          AND cm2.role IN ('owner', 'admin')
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = company_members.company_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm2
          WHERE cm2.company_id = company_members.company_id
          AND cm2.user_id = auth.uid()
          AND cm2.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix company_members DELETE: same expansion
DROP POLICY IF EXISTS "member_delete_company_members" ON company_members;
CREATE POLICY "member_delete_company_members" ON company_members FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = company_members.company_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm2
          WHERE cm2.company_id = company_members.company_id
          AND cm2.user_id = auth.uid()
          AND cm2.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix services INSERT: allow company owner OR member
DROP POLICY IF EXISTS "member_insert_services" ON services;
CREATE POLICY "member_insert_services" ON services FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = services.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = services.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix services UPDATE
DROP POLICY IF EXISTS "member_update_services" ON services;
CREATE POLICY "member_update_services" ON services FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = services.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = services.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = services.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = services.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix services DELETE
DROP POLICY IF EXISTS "member_delete_services" ON services;
CREATE POLICY "member_delete_services" ON services FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = services.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = services.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix bookings UPDATE: allow company owner OR member
DROP POLICY IF EXISTS "member_update_bookings" ON bookings;
CREATE POLICY "member_update_bookings" ON bookings FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = bookings.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = bookings.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = bookings.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = bookings.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix bookings DELETE
DROP POLICY IF EXISTS "member_delete_bookings" ON bookings;
CREATE POLICY "member_delete_bookings" ON bookings FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = bookings.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = bookings.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );

-- Fix professionals INSERT/UPDATE/DELETE: same pattern
DROP POLICY IF EXISTS "member_insert_professionals" ON professionals;
CREATE POLICY "member_insert_professionals" ON professionals FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = professionals.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = professionals.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );

DROP POLICY IF EXISTS "member_update_professionals" ON professionals;
CREATE POLICY "member_update_professionals" ON professionals FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = professionals.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = professionals.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = professionals.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = professionals.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );

DROP POLICY IF EXISTS "member_delete_professionals" ON professionals;
CREATE POLICY "member_delete_professionals" ON professionals FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = professionals.empresa_id
      AND (
        c.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM company_members cm
          WHERE cm.company_id = professionals.empresa_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('owner', 'admin')
        )
      )
    )
  );
