import type { Company, SiteConfig } from './supabase'

export const DEFAULT_SITE_CONFIG: SiteConfig = {
  hero_eyebrow: 'Bem-vinda ao',
  hero_title: null,
  hero_description: null,
  hero_button_primary: 'Agendar Horário',
  hero_button_secondary: 'Ver Serviços',
  hero_stats: [
    { num: '15+', label: 'Anos de experiência' },
    { num: '10+', label: 'Serviços' },
    { num: '2k+', label: 'Clientes satisfeitas' },
  ],
  services_title: 'Nossos Serviços',
  services_subtitle: 'Oferecemos uma ampla gama de serviços de beleza com profissionais experientes e produtos de alta qualidade.',
  gallery_title: 'Nossa Galeria',
  gallery_subtitle: 'Conheça nosso espaço e os momentos de transformação que criamos para nossas clientes.',
  gallery_images: [
    'https://images.pexels.com/photos/7195812/pexels-photo-7195812.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7750108/pexels-photo-7750108.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/8834072/pexels-photo-8834072.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7195811/pexels-photo-7195811.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7750124/pexels-photo-7750124.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/3993445/pexels-photo-3993445.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/29877719/pexels-photo-29877719.jpeg?auto=compress&cs=tinysrgb&w=800',
    'https://images.pexels.com/photos/7750109/pexels-photo-7750109.jpeg?auto=compress&cs=tinysrgb&w=800',
  ],
  about_eyebrow: 'Sobre nós',
  about_title: 'Beleza e cuidado em cada detalhe',
  about_text_1: null,
  about_text_2: null,
  about_badge_num: '15+',
  about_badge_label: 'Anos de experiência',
  about_image: 'https://images.pexels.com/photos/7195803/pexels-photo-7195803.jpeg?auto=compress&cs=tinysrgb&w=900',
  about_features: [
    { title: 'Profissionais Experientes', desc: 'Equipe com mais de 15 anos de experiência no mercado da beleza.' },
    { title: 'Produtos de Qualidade', desc: 'Trabalhamos apenas com marcas premium e reconhecidas.' },
    { title: 'Ambiente Acolhedor', desc: 'Um espaço pensado para o seu conforto e bem-estar.' },
    { title: 'Atendimento Personalizado', desc: 'Cada cliente recebe um atendimento único e exclusivo.' },
  ],
  booking_title: 'Agende seu Horário',
  booking_subtitle: 'Preencha o formulário abaixo e entraremos em contato para confirmar seu agendamento.',
  contact_title: 'Fale Conosco',
  contact_subtitle: 'Entre em contato ou venha nos visitar. Estamos prontas para atender você.',
}

export function getSiteConfig(company: Company | null): SiteConfig {
  return { ...DEFAULT_SITE_CONFIG, ...(company?.site_config ?? {}) }
}

function hexToRgb(hex: string): string | null {
  const m = hex.replace('#', '').match(/^([a-f0-9]{6}|[a-f0-9]{3})$/i)
  if (!m) return null
  const h = m[1]
  const full = h.length === 3 ? h.split('').map((c) => c + c).join('') : h
  const r = parseInt(full.slice(0, 2), 16)
  const g = parseInt(full.slice(2, 4), 16)
  const b = parseInt(full.slice(4, 6), 16)
  return `${r}, ${g}, ${b}`
}

function shade(hex: string, percent: number): string {
  const rgb = hexToRgb(hex)
  if (!rgb) return hex
  const [r, g, b] = rgb.split(', ').map(Number)
  const f = (c: number) => {
    const v = percent < 0
      ? c * (1 + percent)
      : c + (255 - c) * percent
    return Math.round(v)
  }
  const toHex = (c: number) => {
    const h = Math.max(0, Math.min(255, c)).toString(16)
    return h.length === 1 ? '0' + h : h
  }
  return `#${toHex(f(r))}${toHex(f(g))}${toHex(f(b))}`
}

export function applyCompanyTheme(primaryColor: string | null) {
  const root = document.documentElement
  const color = primaryColor || '#d4af37'
  root.style.setProperty('--color-gold', color)
  root.style.setProperty('--color-gold-dark', shade(color, -0.2))
  root.style.setProperty('--color-gold-muted', shade(color, -0.35))
}
