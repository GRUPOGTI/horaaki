import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export interface Company {
  id: string
  user_id: string
  name: string
  slug: string
  description: string | null
  logo_url: string | null
  banner_url: string | null
  primary_color: string
  whatsapp: string | null
  email: string | null
  address: string | null
  hours: string | null
  is_open: boolean
  instagram_url: string | null
  facebook_url: string | null
  tiktok_url: string | null
  created_at: string
  updated_at: string
}

export interface Service {
  id: string
  name: string
  description: string | null
  price: number
  duration_min: number
  category: string
  icon: string
  display_order: number
  active: boolean
  empresa_id: string | null
  created_at: string
}

export interface CompanyMember {
  id: string
  company_id: string
  user_id: string | null
  role: string
  invited_email: string | null
  created_at: string
}

export interface Professional {
  id: string
  empresa_id: string
  name: string
  role: string
  bio: string | null
  photo_url: string | null
  active: boolean
  display_order: number
  created_at: string
}

export interface Booking {
  id: string
  client_name: string
  client_phone: string
  service_id: string | null
  service_name: string
  booking_date: string
  booking_time: string
  notes: string | null
  status: string
  empresa_id: string | null
  created_at: string
}
