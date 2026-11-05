import { supabase } from './supabase'

export interface ClientProfile {
  id: string
  name: string
  phone: string
  email: string | null
}

export interface ClientSignUpInput {
  name: string
  email: string
  phone: string
  password: string
}

export interface MyClientProfile {
  name: string
  phone: string
}

export interface ClientBooking {
  booking_id: string
  company_name: string
  company_slug: string
  service_name: string
  booking_date: string
  booking_time: string
  status: string
  notes: string | null
}

export async function signUpClient(input: ClientSignUpInput): Promise<void> {
  const { error } = await supabase.auth.signUp({
    email: input.email.trim(),
    password: input.password,
  })
  if (error) throw new Error(authErrorMessage(error.message))

  const { data } = await supabase.auth.getSession()
  if (!data.session) throw new Error('Confirme seu e-mail para continuar.')

  const { error: registerError } = await supabase.rpc('register_client_account', {
    p_name: input.name.trim(),
    p_phone: input.phone.replace(/\D/g, ''),
  })
  if (registerError) {
    await supabase.auth.signOut()
    throw new Error(clientErrorMessage(registerError.message))
  }
}

export async function signInClient(email: string, password: string): Promise<void> {
  const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
  if (error) throw new Error(authErrorMessage(error.message))
}

export async function signOutClient(): Promise<void> {
  const { error } = await supabase.auth.signOut()
  if (error) throw new Error('Não foi possível sair da conta. Tente novamente.')
}

export async function linkClientAccount(empresaId: string): Promise<ClientProfile> {
  const { data, error } = await supabase.rpc('link_client_account', { p_empresa: empresaId })
  if (error) throw new Error(clientErrorMessage(error.message))
  const profile = data as ClientProfile | null
  if (!profile || typeof profile.id !== 'string') {
    throw new Error('Não foi possível carregar sua conta. Tente novamente.')
  }
  return profile
}

export async function getMyClientProfile(): Promise<MyClientProfile | null> {
  const { data, error } = await supabase
    .from('client_profiles')
    .select('name, phone')
    .maybeSingle()
  if (error) throw new Error('Não foi possível carregar seus dados. Tente novamente.')
  return data as MyClientProfile | null
}

export async function updateMyClientProfile(name: string, phone: string): Promise<MyClientProfile> {
  const { data, error } = await supabase.rpc('update_my_client_profile', {
    p_name: name.trim(),
    p_phone: phone.replace(/\D/g, ''),
  })
  if (error) throw new Error(clientErrorMessage(error.message))
  const profile = data as MyClientProfile | null
  if (!profile || typeof profile.name !== 'string') {
    throw new Error('Não foi possível salvar seus dados. Tente novamente.')
  }
  return profile
}

export async function listMyBookings(): Promise<ClientBooking[]> {
  const { data, error } = await supabase.rpc('get_my_bookings')
  if (error) throw new Error('Não foi possível carregar seus agendamentos. Tente novamente.')
  return (data ?? []) as ClientBooking[]
}

export async function cancelMyBooking(bookingId: string): Promise<void> {
  const { error } = await supabase.rpc('cancel_my_booking', { p_booking: bookingId })
  if (error) throw new Error(clientErrorMessage(error.message))
}

function authErrorMessage(raw: string): string {
  if (raw.includes('already registered')) return 'Já existe uma conta com este e-mail. Entre com sua senha.'
  if (raw.includes('Invalid login credentials')) return 'E-mail ou senha incorretos.'
  if (raw.includes('Password should be at least')) return 'A senha deve ter pelo menos 6 caracteres.'
  if (raw.includes('Email not confirmed')) return 'Confirme seu e-mail para continuar.'
  if (raw.includes('valid email')) return 'Informe um e-mail válido.'
  return 'Não foi possível concluir. Tente novamente.'
}

function clientErrorMessage(raw: string): string {
  if (raw.includes('usuário do sistema')) return 'Esta conta é de usuário do painel e não pode agendar. Use uma conta de cliente.'
  if (raw.includes('Cadastro incompleto')) return 'Esta conta não é de cliente. Crie uma conta de cliente para agendar.'
  if (raw.includes('Telefone já vinculado')) return 'Este telefone já está vinculado a outra conta. Fale com a empresa.'
  if (raw.includes('Telefone já cadastrado para outro cliente')) return 'Este telefone já está cadastrado para outro cliente.'
  if (raw.includes('Empresa não encontrada')) return 'Este estabelecimento não foi encontrado.'
  if (raw.includes('Nome inválido')) return 'Informe um nome válido.'
  if (raw.includes('Telefone inválido')) return 'Informe um telefone válido com DDD.'
  if (raw.includes('Agendamento não pode ser cancelado')) return 'Este agendamento não pode mais ser cancelado.'
  return 'Não foi possível concluir. Tente novamente.'
}
