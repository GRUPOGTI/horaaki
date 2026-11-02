# Project memory

## Product intent & audience

- Agenda/scheduling SaaS where multiple companies (empresas) each have their own public booking page at `/agenda/:slug`
- End customers visit a company's agenda page to view services and book appointments
- Company owners/admins manage their data via `/painel` (admin dashboard) after login at `/login`

## Brand personality & voice

- Portuguese-language product (Brazilian Portuguese); user communicates in PT-BR
- Direct, helpful tone explaining what was fixed and how to use features

## Visual design & UX direction

- Public site composed of section components: HeroSection, ServicesSection, BookingSection, ContactSection, AboutSection, SiteFooter
- Parent `PublicSite.vue` receives route slug, fetches company data, passes `:company` and `:empresa-id` props to children
- Each child component accepts `company` and/or `empresaId` props to display company-specific content
- Booking form inserts `empresa_id` to isolate appointments per company
- 404-style "empresa não encontrada" message for invalid slugs

## Decisions, constraints & rationale

- `empresa_id` must propagate through all public-facing components so data is isolated per company
- Services are filtered by `empresa_id` on both display and insert
- Replaced hardcoded company data (previously fixed to "Nadja Gomes") with dynamic data loaded from DB by slug
- Social links previously hardcoded to `href="#"` — fixed to use actual company social URLs
- Vue + Vite frontend; build verification done after component updates
- Routing: `/agenda/:slug` for public pages, `/login` → `/painel` for admin

## Open questions & assumptions

- Backend API endpoints and auth flow details not yet documented
- Database schema for `empresas`, `servicos`, `agendamentos` tables inferred but not confirmed
- Whether professional/staff scheduling (profissionais) filtering is also needed per company
- Admin panel (`/painel`) component structure and multi-tenant isolation status unknown