/*
# Remove unused client self-update function

1. Summary
- Clients now edit their name and phone through the booking form, which updates the same client record on submit.
- The separate self-update function was never called by the app, so it is removed.

2. Security
- No table or policy changes. The shared helper used by booking continues to exist.

3. Notes
- Removing a function does not touch any client or booking data.
*/

DROP FUNCTION IF EXISTS public.update_my_client(uuid, text, text);
