import { supabase } from './supabase'

export type AccountType = 'system' | 'client' | 'none'

export const ACCOUNT_HOME: Record<'system' | 'client', string> = {
  system: '/painel',
  client: '/minha-conta',
}

export async function getAccountType(): Promise<AccountType> {
  const { data, error } = await supabase.rpc('get_account_type')
  if (error || (data !== 'system' && data !== 'client' && data !== 'none')) {
    throw new Error('Não foi possível verificar o tipo da sua conta. Tente novamente.')
  }
  return data
}
