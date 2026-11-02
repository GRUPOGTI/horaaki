import { ref, readonly } from 'vue'
import { supabase, type Company, type CompanyMember } from '../lib/supabase'
import { useAuth } from './useAuth'

const company = ref<Company | null>(null)
const companyLoading = ref(false)
const members = ref<CompanyMember[]>([])
const userCompanies = ref<Company[]>([])
const activeCompanyId = ref<string | null>(null)

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
      activeCompanyId.value = data.id
    } else {
      company.value = null
    }
    companyLoading.value = false
    return company.value
  }

  async function loadUserCompanies() {
    if (!user.value) {
      userCompanies.value = []
      return userCompanies.value
    }

    const { data, error } = await supabase
      .from('company_members')
      .select('company_id, companies(*)')
      .eq('user_id', user.value.id)

    if (!error && data) {
      userCompanies.value = (data as any[]).map((row) => row.companies as Company).filter(Boolean)
    } else {
      userCompanies.value = []
    }
    return userCompanies.value
  }

  async function loadCompanyByUser() {
    if (!user.value) {
      company.value = null
      return null
    }

    companyLoading.value = true

    // Load all companies this user belongs to
    await loadUserCompanies()

    if (userCompanies.value.length === 0) {
      // Fallback: try via companies.user_id (legacy)
      const { data: legacyData, error: legacyError } = await supabase
        .from('companies')
        .select('*')
        .eq('user_id', user.value.id)
        .maybeSingle()

      if (!legacyError && legacyData) {
        company.value = legacyData as Company
        activeCompanyId.value = legacyData.id
        userCompanies.value = [legacyData as Company]
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

    // If we have an active company ID stored, use it; otherwise use the first
    const targetId = activeCompanyId.value && userCompanies.value.some((c) => c.id === activeCompanyId.value)
      ? activeCompanyId.value
      : userCompanies.value[0].id

    const found = userCompanies.value.find((c) => c.id === targetId) || userCompanies.value[0]
    company.value = found
    activeCompanyId.value = found.id
    companyLoading.value = false
    return company.value
  }

  async function setActiveCompany(companyId: string) {
    const found = userCompanies.value.find((c) => c.id === companyId)
    if (found) {
      company.value = found
      activeCompanyId.value = companyId
    }
    return company.value
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
        site_config: payload.site_config ?? null,
      })
      .select('*')
      .maybeSingle()

    if (error) throw error
    if (data) {
      const newCompany = data as Company
      company.value = newCompany
      activeCompanyId.value = newCompany.id
      userCompanies.value = [...userCompanies.value, newCompany]
      // Add creator as owner in company_members
      await supabase
        .from('company_members')
        .insert({
          company_id: newCompany.id,
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
        site_config: payload.site_config ?? null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select('*')
      .maybeSingle()

    if (error) throw error
    if (data) {
      const updated = data as Company
      company.value = updated
      userCompanies.value = userCompanies.value.map((c) => (c.id === updated.id ? updated : c))
    }
    return company.value
  }

  return {
    company: readonly(company),
    companyLoading: readonly(companyLoading),
    members: readonly(members),
    userCompanies: readonly(userCompanies),
    activeCompanyId: readonly(activeCompanyId),
    loadCompanyBySlug,
    loadCompanyByUser,
    loadUserCompanies,
    setActiveCompany,
    loadMembers,
    inviteMember,
    removeMember,
    createCompany,
    updateCompany,
  }
}
