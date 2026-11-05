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

export async function signUpClient(input: ClientSignUpInput): Promise<void> {
  const { error } = await supabase.auth.signUp({
    email: input.email.trim(),
    password: input.password,
    options: {
      data: {
        name: input.name.trim(),
        phone: input.phone.replace(/\D/g, ''),
      },
    },
  })
  if (error) throw new Error(authErrorMessage(error.message))
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
  if (error) throw new Error(linkErrorMessage(error.message))
  const profile = data as ClientProfile | null
  if (!profile || typeof profile.id !== 'string') {
    throw new Error('Não foi possível carregar sua conta. Tente novamente.')
  }
  return profile
}

function authErrorMessage(raw: string): string {
  if (raw.includes('already registered')) return 'Já existe uma conta com este e-mail. Entre com sua senha.'
  if (raw.includes('Invalid login credentials')) return 'E-mail ou senha incorretos.'
  if (raw.includes('Password should be at least')) return 'A senha deve ter pelo menos 6 caracteres.'
  if (raw.includes('Email not confirmed')) return 'Confirme seu e-mail para continuar.'
  if (raw.includes('valid email')) return 'Informe um e-mail válido.'
  return 'Não foi possível concluir. Tente novamente.'
}

function linkErrorMessage(raw: string): string {
  if (raw.includes('usuário do sistema')) return 'Esta conta é de usuário do painel e não pode agendar. Use uma conta de cliente.'
  if (raw.includes('Cadastro incompleto')) return 'Esta conta não é de cliente. Crie uma conta de cliente para agendar.'
  if (raw.includes('Telefone já vinculado')) return 'Este telefone já está vinculado a outra conta. Fale com a empresa.'
  if (raw.includes('Empresa não encontrada')) return 'Este estabelecimento não foi encontrado.'
  return 'Não foi possível carregar sua conta. Tente novamente.'
}
