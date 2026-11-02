/*
# Add site_config JSONB column to companies

1. Schema changes
- Adds `site_config` (JSONB, nullable) to `companies`.
  Stores full visual customization for the public agenda page:
  hero title, subtitle, description, stats, about text, gallery images,
  section titles/subtitles, feature list, and any other per-company text.

2. Seed Nadja Gomes
- Backfills `site_config` for the `nadja-gomes` company with a complete
  default configuration matching the current hardcoded page, so
  /agenda/nadja-gomes looks identical before and after.

3. Default config for new companies
- Adds a PL/pgSQL function `default_site_config()` that returns a
  ready-to-use default configuration object, so any new company created
  via the admin panel starts with a sensible layout and identity without
  having to configure everything from scratch. The admin panel will
  call this on company creation.

4. Security
- No new tables; RLS already enabled on `companies`.
- Existing grants/policies cover the new column (column-level grants
  are not in use on this table).
*/

ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS site_config JSONB;

-- Backfill Nadja Gomes with the current hardcoded page content
UPDATE companies
SET site_config = jsonb_build_object(
  'hero_eyebrow', 'Bem-vinda ao',
  'hero_title', 'Salão Nadja Gomes',
  'hero_description', 'Sua beleza é nossa arte. Oferecemos cortes, coloração, tratamentos e serviços de estética com profissionais experientes e produtos de alta qualidade.',
  'hero_button_primary', 'Agendar Horário',
  'hero_button_secondary', 'Ver Serviços',
  'hero_stats', jsonb_build_array(
    jsonb_build_object('num', '15+', 'label', 'Anos de experiência'),
    jsonb_build_object('num', '10+', 'label', 'Serviços'),
    jsonb_build_object('num', '2k+', 'label', 'Clientes satisfeitas')
  ),
  'services_title', 'Nossos Serviços',
  'services_subtitle', 'Oferecemos uma ampla gama de serviços de beleza com profissionais experientes e produtos de alta qualidade.',
  'gallery_title', 'Nossa Galeria',
  'gallery_subtitle', 'Conheça nosso espaço e os momentos de transformação que criamos para nossas clientes.',
  'gallery_images', jsonb_build_array(
    'https://images.pexels.com/photos/7195812/pexels-photo-7195812.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7750108/pexels-photo-7750108.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/8834072/pexels-photo-8834072.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7195811/pexels-photo-7195811.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7750124/pexels-photo-7750124.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/3993445/pexels-photo-3993445.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/29877719/pexels-photo-29877719.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7750109/pexels-photo-7750109.jpeg?auto=compress&cs=tinysrgb&w=800'
  ),
  'about_eyebrow', 'Sobre nós',
  'about_title', 'Beleza e cuidado em cada detalhe',
  'about_text_1', 'O Salão Nadja Gomes nasceu da paixão por realçar a beleza de cada cliente. Com anos de experiência, nossa equipe oferece serviços de alta qualidade em um ambiente acolhedor e sofisticado.',
  'about_text_2', 'Acreditamos que cada pessoa é única, por isso oferecemos um atendimento personalizado, escutando seus desejos e necessidades para criar o visual perfeito para você.',
  'about_badge_num', '15+',
  'about_badge_label', 'Anos de experiência',
  'about_image', 'https://images.pexels.com/photos/7195803/pexels-photo-7195803.jpeg?auto=compress&cs=tinysrgb&w=900',
  'about_features', jsonb_build_array(
    jsonb_build_object('title', 'Profissionais Experientes', 'desc', 'Equipe com mais de 15 anos de experiência no mercado da beleza.'),
    jsonb_build_object('title', 'Produtos de Qualidade', 'desc', 'Trabalhamos apenas com marcas premium e reconhecidas.'),
    jsonb_build_object('title', 'Ambiente Acolhedor', 'desc', 'Um espaço pensado para o seu conforto e bem-estar.'),
    jsonb_build_object('title', 'Atendimento Personalizado', 'desc', 'Cada cliente recebe um atendimento único e exclusivo.')
  ),
  'booking_title', 'Agende seu Horário',
  'booking_subtitle', 'Preencha o formulário abaixo e entraremos em contato para confirmar seu agendamento.',
  'contact_title', 'Fale Conosco',
  'contact_subtitle', 'Entre em contato ou venha nos visitar. Estamos prontas para atender você.'
)
WHERE slug = 'nadja-gomes';

-- Function returning a default site_config for brand-new companies
CREATE OR REPLACE FUNCTION default_site_config()
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT jsonb_build_object(
    'hero_eyebrow', 'Bem-vinda ao',
    'hero_title', NULL,
    'hero_description', NULL,
    'hero_button_primary', 'Agendar Horário',
    'hero_button_secondary', 'Ver Serviços',
    'hero_stats', jsonb_build_array(
      jsonb_build_object('num', '15+', 'label', 'Anos de experiência'),
      jsonb_build_object('num', '10+', 'label', 'Serviços'),
      jsonb_build_object('num', '2k+', 'label', 'Clientes satisfeitas')
    ),
    'services_title', 'Nossos Serviços',
    'services_subtitle', 'Oferecemos uma ampla gama de serviços de beleza com profissionais experientes e produtos de alta qualidade.',
    'gallery_title', 'Nossa Galeria',
    'gallery_subtitle', 'Conheça nosso espaço e os momentos de transformação que criamos para nossas clientes.',
    'gallery_images', jsonb_build_array(
      'https://images.pexels.com/photos/7195812/pexels-photo-7195812.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7750108/pexels-photo-7750108.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/8834072/pexels-photo-8834072.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7195811/pexels-photo-7195811.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7750124/pexels-photo-7750124.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/3993445/pexels-photo-3993445.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/29877719/pexels-photo-29877719.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7750109/pexels-photo-7750109.jpeg?auto=compress&cs=tinysrgb&w=800'
    ),
    'about_eyebrow', 'Sobre nós',
    'about_title', 'Beleza e cuidado em cada detalhe',
    'about_text_1', NULL,
    'about_text_2', NULL,
    'about_badge_num', '15+',
    'about_badge_label', 'Anos de experiência',
    'about_image', 'https://images.pexels.com/photos/7195803/pexels-photo-7195803.jpeg?auto=compress&cs=tinysrgb&w=900',
    'about_features', jsonb_build_array(
      jsonb_build_object('title', 'Profissionais Experientes', 'desc', 'Equipe com mais de 15 anos de experiência no mercado da beleza.'),
      jsonb_build_object('title', 'Produtos de Qualidade', 'desc', 'Trabalhamos apenas com marcas premium e reconhecidas.'),
      jsonb_build_object('title', 'Ambiente Acolhedor', 'desc', 'Um espaço pensado para o seu conforto e bem-estar.'),
      jsonb_build_object('title', 'Atendimento Personalizado', 'desc', 'Cada cliente recebe um atendimento único e exclusivo.')
    ),
    'booking_title', 'Agende seu Horário',
    'booking_subtitle', 'Preencha o formulário abaixo e entraremos em contato para confirmar seu agendamento.',
    'contact_title', 'Fale Conosco',
    'contact_subtitle', 'Entre em contato ou venha nos visitar. Estamos prontas para atender você.'
  )
$$;
