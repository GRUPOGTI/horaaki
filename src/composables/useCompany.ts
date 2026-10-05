import { ref } from 'vue'
import { supabase, type Company, type CompanyMember } from '../lib/supabase'
import { useAuth } from './useAuth'

const company = ref<Company | null>(null)
const companyLoading = ref(false)
const members = ref<CompanyMember[]>([])

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

    // First try via company_members (new system)
    const { data: memberData } = await supabase
      .from('company_members')
      .select('company_id')
      .eq('user_id', user.value.id)
      .maybeSingle()

    if (memberData) {
      const { data: compData, error: compError } = await supabase
        .from('companies')
        .select('*')
        .eq('id', memberData.company_id)
        .maybeSingle()

      if (!compError && compData) {
        company.value = compData as Company
        companyLoading.value = false
        return company.value
      }
    }

    // Fallback: try via companies.user_id (legacy)
    const { data: legacyData, error: legacyError } = await supabase
      .from('companies')
      .select('*')
      .eq('user_id', user.value.id)
      .maybeSingle()

    if (!legacyError && legacyData) {
      company.value = legacyData as Company
      // Auto-create a company_members entry for the owner
      await supabase
        .from('company_members')
        .insert({
          company_id: legacyData.id,
          user_id: user.value.id,
          role: 'owner',
        })
      companyLoading.value = false
      return company.value
    }

    company.value = null
    companyLoading.value = false
    return null
  }

  async function loadMembers(companyId: string) {
    const { data, error } = await supabase
      .from('company_members')
      .select('*')
      .eq('company_id', companyId)
      .order('created_at', { ascending: true })

    if (!error && data) {
      members.value = data as CompanyMember[]
    }
    return members.value
  }

  async function inviteMember(companyId: string, email: string, role: string = 'admin') {
    const { data, error } = await supabase
      .from('company_members')
      .insert({
        company_id: companyId,
        invited_email: email.trim().toLowerCase(),
        role,
      })
      .select('*')
      .maybeSingle()

    if (error) throw error
    if (data) {
      members.value = [...members.value, data as CompanyMember]
    }
    return data
  }

  async function removeMember(memberId: string) {
    const { error } = await supabase
      .from('company_members')
      .delete()
      .eq('id', memberId)

    if (error) throw error
    members.value = members.value.filter((m) => m.id !== memberId)
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
      // Add creator as owner in company_members
      await supabase
        .from('company_members')
        .insert({
          company_id: data.id,
          user_id: user.value.id,
          role: 'owner',
        })
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
    members,
    loadCompanyBySlug,
    loadCompanyByUser,
    loadMembers,
    inviteMember,
    removeMember,
    createCompany,
    updateCompany,
  }
}
