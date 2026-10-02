import { ref } from 'vue'
import { supabase, type Company } from '../lib/supabase'
import { useAuth } from './useAuth'

const company = ref<Company | null>(null)
const companyLoading = ref(false)

export function useCompany() {
  const { user } = useAuth()

  async function loadCompanyBySlug(slug: string) {
    companyLoading.value = true
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('slug', slug)
      .maybeSingle()

    if (!error && data) {
      company.value = data as Company
    } else {
      company.value = null
    }
    companyLoading.value = false
    return company.value
  }

  async function loadCompanyByUser() {
    if (!user.value) {
      company.value = null
      return null
    }

    companyLoading.value = true
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('user_id', user.value.id)
      .maybeSingle()

    if (!error && data) {
      company.value = data as Company
    } else {
      company.value = null
    }
    companyLoading.value = false
    return company.value
  }

  async function createCompany(payload: Partial<Company>): Promise<Company | null> {
    if (!user.value) return null

    const { data, error } = await supabase
      .from('companies')
      .insert({
        user_id: user.value.id,
        name: payload.name || 'Minha Empresa',
        slug: payload.slug || 'minha-empresa',
        description: payload.description || null,
        logo_url: payload.logo_url || null,
        banner_url: payload.banner_url || null,
        primary_color: payload.primary_color || '#d4af37',
        whatsapp: payload.whatsapp || null,
        email: payload.email || null,
        address: payload.address || null,
        hours: payload.hours || null,
        is_open: payload.is_open ?? true,
        instagram_url: payload.instagram_url || null,
        facebook_url: payload.facebook_url || null,
        tiktok_url: payload.tiktok_url || null,
      })
      .select('*')
      .maybeSingle()

    if (error) throw error
    if (data) {
      company.value = data as Company
    }
    return company.value
  }

  async function updateCompany(id: string, payload: Partial<Company>): Promise<Company | null> {
    const { data, error } = await supabase
      .from('companies')
      .update({
        name: payload.name,
        slug: payload.slug,
        description: payload.description,
        logo_url: payload.logo_url,
        banner_url: payload.banner_url,
        primary_color: payload.primary_color,
        whatsapp: payload.whatsapp,
        email: payload.email,
        address: payload.address,
        hours: payload.hours,
        is_open: payload.is_open,
        instagram_url: payload.instagram_url,
        facebook_url: payload.facebook_url,
        tiktok_url: payload.tiktok_url,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select('*')
      .maybeSingle()

    if (error) throw error
    if (data) {
      company.value = data as Company
    }
    return company.value
  }

  return {
    company,
    companyLoading,
    loadCompanyBySlug,
    loadCompanyByUser,
    createCompany,
    updateCompany,
  }
}
