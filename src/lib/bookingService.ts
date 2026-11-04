import { supabase, type Service } from './supabase'

export interface BookingRequest {
  empresaId: string
  serviceId: string
  date: string
  time: string
  name: string
  phone: string
  cpf?: string | null
  notes?: string | null
  professionalId?: string | null
  status: 'pending' | 'confirmed'
}

export async function loadActiveServices(empresaId: string): Promise<Service[]> {
  const { data, error } = await supabase
    .from('services')
    .select('*')
    .eq('empresa_id', empresaId)
    .eq('active', true)
    .order('display_order', { ascending: true })
  if (error) throw new Error('Não foi possível carregar os serviços.')
  return data ?? []
}

export async function fetchAvailableSlots(
  empresaId: string,
  serviceId: string,
  date: string,
  professionalId?: string | null,
): Promise<string[]> {
  const { data, error } = await supabase.rpc('get_available_slots', {
    p_empresa: empresaId,
    p_service: serviceId,
    p_date: date,
    p_professional: professionalId || null,
  })
  if (error) throw new Error('Não foi possível carregar os horários.')
  return (data ?? []) as string[]
}

export async function createBooking(request: BookingRequest): Promise<void> {
  const { error } = await supabase.rpc('create_booking', {
    p_empresa: request.empresaId,
    p_service: request.serviceId,
    p_date: request.date,
    p_time: request.time,
    p_name: request.name.trim(),
    p_phone: request.phone.trim(),
    p_cpf: request.cpf?.trim() || null,
    p_notes: request.notes?.trim() || null,
    p_professional: request.professionalId || null,
    p_status: request.status,
  })
  if (error) throw new Error(bookingErrorMessage(error.message))
}

function bookingErrorMessage(raw: string): string {
  if (raw.includes('Horário indisponível')) return 'Este horário não está mais disponível. Escolha outro horário.'
  if (raw.includes('Nome inválido')) return 'Informe um nome válido.'
  if (raw.includes('Telefone inválido')) return 'Informe um telefone válido com DDD.'
  if (raw.includes('CPF inválido')) return 'Informe um CPF válido com 11 números.'
  if (raw.includes('Observações muito longas')) return 'As observações devem ter no máximo 500 caracteres.'
  if (raw.includes('Serviço inválido')) return 'Este serviço não está disponível.'
  if (raw.includes('Profissional inválido')) return 'Este profissional não está disponível.'
  if (raw.includes('Telefone já cadastrado')) return 'Este telefone já pertence a outro cliente. Confira o número informado.'
  return 'Não foi possível concluir o agendamento. Tente novamente.'
}
