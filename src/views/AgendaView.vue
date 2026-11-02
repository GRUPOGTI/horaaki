<script setup lang="ts">
import { ref, computed } from 'vue'
import { useBookings } from '../composables/useBookings'
import { useCompany } from '../composables/useCompany'
import { formatDate, formatPrice, statusLabels, statusColors } from '../lib/format'
import { supabase, type Service, type Booking, type Professional, type Client } from '../lib/supabase'

const { bookings, updateBookingStatus, deleteBooking } = useBookings()
const { company } = useCompany()

const services = ref<Service[]>([])
const professionals = ref<Professional[]>([])
const clients = ref<Client[]>([])
const showCreateModal = ref(false)
const createLoading = ref(false)
const createError = ref('')

const createForm = ref({
  client_id: '' as string,
  client_name: '',
  client_phone: '',
  service_id: '' as string,
  professional_id: '' as string,
  booking_date: '',
  booking_time: '',
  notes: '',
  new_client_cpf: '',
})

const filteredClients = computed(() => {
  if (!createForm.value.client_name.trim()) return []
  const q = createForm.value.client_name.toLowerCase().trim()
  return clients.value.filter(
    (c) => c.name.toLowerCase().includes(q) || c.phone.includes(q)
  ).slice(0, 10)
})

const timeSlots = [
  '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
  '11:00', '11:30', '13:00', '13:30', '14:00', '14:30',
  '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
  '18:00', '18:30',
]

const bookedSlots = computed(() => {
  if (!createForm.value.booking_date) return new Set<string>()
  return new Set(
    bookings.value
      .filter((b) => b.booking_date === createForm.value.booking_date && b.status !== 'cancelled')
      .map((b) => b.booking_time)
  )
})

const availableSlots = computed(() =>
  timeSlots.filter((t) => !bookedSlots.value.has(t))
)

function selectExistingClient(c: Client) {
  createForm.value.client_id = c.id
  createForm.value.client_name = c.name
  createForm.value.client_phone = c.phone
  createForm.value.new_client_cpf = c.cpf || ''
}

function clearClientSelection() {
  createForm.value.client_id = ''
  createForm.value.new_client_cpf = ''
}

function openCreateModal() {
  createForm.value = {
    client_id: '',
    client_name: '',
    client_phone: '',
    service_id: '',
    professional_id: '',
    booking_date: '',
    booking_time: '',
    notes: '',
    new_client_cpf: '',
  }
  createError.value = ''
  showCreateModal.value = true
}

function closeCreateModal() {
  showCreateModal.value = false
}

async function handleCreateBooking() {
  createError.value = ''
  const f = createForm.value
  if (!f.client_name.trim() || !f.client_phone.trim() || !f.service_id || !f.booking_date || !f.booking_time) {
    createError.value = 'Preencha todos os campos obrigatórios.'
    return
  }

  createLoading.value = true
  try {
    const companyId = company.value?.id
    if (!companyId) throw new Error('Empresa não carregada.')

    const service = services.value.find((s) => s.id === f.service_id)
    if (!service) throw new Error('Serviço inválido.')

    let clientId: string | null = f.client_id || null

    // If no existing client selected, create one (or find by phone)
    if (!clientId) {
      const { data: existing, error: findErr } = await supabase
        .from('clients')
        .select('id')
        .eq('empresa_id', companyId)
        .eq('phone', f.client_phone.trim())
        .maybeSingle()

      if (findErr) throw findErr

      if (existing) {
        clientId = existing.id
      } else {
        const { data: newClient, error: clientErr } = await supabase
          .from('clients')
          .insert({
            empresa_id: companyId,
            name: f.client_name.trim(),
            phone: f.client_phone.trim(),
            cpf: f.new_client_cpf.trim() || null,
          })
          .select('id')
          .maybeSingle()

        if (clientErr) throw clientErr
        if (newClient) clientId = newClient.id
      }
    }

    const insertPayload: Record<string, unknown> = {
      client_name: f.client_name.trim(),
      client_phone: f.client_phone.trim(),
      service_id: f.service_id,
      service_name: service.name,
      booking_date: f.booking_date,
      booking_time: f.booking_time,
      notes: f.notes.trim() || null,
      status: 'confirmed',
      empresa_id: companyId,
      client_id: clientId,
      professional_id: f.professional_id || null,
    }

    const { error: bookingErr } = await supabase.from('bookings').insert(insertPayload)
    if (bookingErr) throw bookingErr

    // Reload clients list
    await loadClients()
    showSuccess('Agendamento criado com sucesso.')
    showCreateModal.value = false
  } catch (err: any) {
    createError.value = err.message || 'Erro ao criar agendamento.'
  } finally {
    createLoading.value = false
  }
}

const filterStatus = ref('all')
const filterDate = ref('')
const searchQuery = ref('')
const actionLoading = ref('')
const errorMsg = ref('')
const successMsg = ref('')
const viewMode = ref<'list' | 'calendar'>('list')
const calendarMonth = ref(new Date())
const selectedDateBookings = ref<Booking[] | null>(null)

const filteredBookings = computed(() => {
  let list = [...bookings.value]

  if (filterStatus.value !== 'all') {
    list = list.filter((b) => b.status === filterStatus.value)
  }

  if (filterDate.value) {
    list = list.filter((b) => b.booking_date === filterDate.value)
  }

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim()
    list = list.filter(
      (b) =>
        b.client_name.toLowerCase().includes(q) ||
        b.client_phone.includes(q) ||
        b.service_name.toLowerCase().includes(q)
    )
  }

  return list.sort((a, b) => {
    const aKey = a.booking_date + ' ' + a.booking_time
    const bKey = b.booking_date + ' ' + b.booking_time
    return bKey.localeCompare(aKey)
  })
})

const calendarDays = computed(() => {
  const year = calendarMonth.value.getFullYear()
  const month = calendarMonth.value.getMonth()
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  const startWeekday = firstDay.getDay()
  const totalDays = lastDay.getDate()

  const days: Array<{ date: string | null; day: number | null; bookings: Booking[] }> = []

  for (let i = 0; i < startWeekday; i++) {
    days.push({ date: null, day: null, bookings: [] })
  }

  for (let d = 1; d <= totalDays; d++) {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`
    const dayBookings = bookings.value
      .filter((b) => b.booking_date === dateStr && b.status !== 'cancelled')
      .sort((a, b) => a.booking_time.localeCompare(b.booking_time))
    days.push({ date: dateStr, day: d, bookings: dayBookings })
  }

  const remaining = (7 - (days.length % 7)) % 7
  for (let i = 0; i < remaining; i++) {
    days.push({ date: null, day: null, bookings: [] })
  }

  return days
})

const calendarTitle = computed(() => {
  const months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
  return `${months[calendarMonth.value.getMonth()]} ${calendarMonth.value.getFullYear()}`
})

const todayStr = new Date().toISOString().split('T')[0]

function prevMonth() {
  const d = new Date(calendarMonth.value)
  d.setMonth(d.getMonth() - 1)
  calendarMonth.value = d
}

function nextMonth() {
  const d = new Date(calendarMonth.value)
  d.setMonth(d.getMonth() + 1)
  calendarMonth.value = d
}

function goToday() {
  calendarMonth.value = new Date()
}

function openDayBookings(dateStr: string) {
  const dayBookings = bookings.value
    .filter((b) => b.booking_date === dateStr)
    .sort((a, b) => a.booking_time.localeCompare(b.booking_time))
  selectedDateBookings.value = dayBookings
}

function closeDayBookings() {
  selectedDateBookings.value = null
}

async function loadServices() {
  let query = supabase.from('services').select('*').eq('active', true)
  if (company.value?.id) {
    query = query.eq('empresa_id', company.value.id)
  }
  const { data } = await query
  if (data) services.value = data
}

async function loadProfessionals() {
  if (!company.value?.id) return
  const { data } = await supabase
    .from('professionals')
    .select('*')
    .eq('empresa_id', company.value.id)
    .eq('active', true)
    .order('display_order', { ascending: true })
  if (data) professionals.value = data
}

async function loadClients() {
  if (!company.value?.id) return
  const { data } = await supabase
    .from('clients')
    .select('*')
    .eq('empresa_id', company.value.id)
    .order('name', { ascending: true })
  if (data) clients.value = data
}

loadServices()
loadProfessionals()
loadClients()

function getServicePrice(serviceId: string | null): string {
  if (!serviceId) return '-'
  const svc = services.value.find((s) => s.id === serviceId)
  return svc ? formatPrice(svc.price) : '-'
}

function showSuccess(msg: string) {
  successMsg.value = msg
  setTimeout(() => { successMsg.value = '' }, 3000)
}

async function handleStatusChange(id: string, status: string) {
  actionLoading.value = id
  errorMsg.value = ''
  try {
    await updateBookingStatus(id, status)
    showSuccess('Status atualizado com sucesso.')
    if (selectedDateBookings.value) {
      selectedDateBookings.value = selectedDateBookings.value.map((b) =>
        b.id === id ? { ...b, status } : b
      )
    }
  } catch (err: any) {
    errorMsg.value = 'Erro ao atualizar status.'
  } finally {
    actionLoading.value = ''
  }
}

async function handleDelete(id: string) {
  if (!confirm('Deseja realmente excluir este agendamento?')) return
  actionLoading.value = id
  errorMsg.value = ''
  try {
    await deleteBooking(id)
    showSuccess('Agendamento excluído.')
    if (selectedDateBookings.value) {
      selectedDateBookings.value = selectedDateBookings.value.filter((b) => b.id !== id)
    }
  } catch (err: any) {
    errorMsg.value = 'Erro ao excluir agendamento.'
  } finally {
    actionLoading.value = ''
  }
}

function clearFilters() {
  filterStatus.value = 'all'
  filterDate.value = ''
  searchQuery.value = ''
}

function getStatusLabel(status: string): string {
  return statusLabels[status] || status
}

function getStatusColor(status: string): string {
  return statusColors[status] || 'warning'
}
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Agenda</h1>
        <p class="page-subtitle">Gerencie todos os agendamentos</p>
      </div>
      <div class="header-actions">
        <button class="btn btn-primary btn-new-booking" @click="openCreateModal">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14" /></svg>
          Novo Agendamento
        </button>
        <div class="view-toggle">
          <button
            class="toggle-btn"
            :class="{ active: viewMode === 'list' }"
            @click="viewMode = 'list'"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01" /></svg>
            Lista
          </button>
          <button
            class="toggle-btn"
            :class="{ active: viewMode === 'calendar' }"
            @click="viewMode = 'calendar'"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" /></svg>
            Calendário
          </button>
        </div>
      </div>
    </div>

    <p v-if="errorMsg" class="error-banner" role="alert">{{ errorMsg }}</p>
    <p v-if="successMsg" class="success-banner" role="status">{{ successMsg }}</p>

    <!-- LIST VIEW -->
    <template v-if="viewMode === 'list'">
      <div class="filters-bar">
        <div class="filter-group">
          <label for="filter-status">Status</label>
          <select id="filter-status" v-model="filterStatus">
            <option value="all">Todos</option>
            <option value="pending">Pendentes</option>
            <option value="confirmed">Confirmados</option>
            <option value="completed">Concluídos</option>
            <option value="cancelled">Cancelados</option>
          </select>
        </div>
        <div class="filter-group">
          <label for="filter-date">Data</label>
          <input id="filter-date" v-model="filterDate" type="date" />
        </div>
        <div class="filter-group filter-search">
          <label for="filter-search">Buscar</label>
          <input id="filter-search" v-model="searchQuery" type="text" placeholder="Nome, telefone ou serviço..." />
        </div>
        <button class="btn-clear" @click="clearFilters">Limpar filtros</button>
      </div>

      <div v-if="filteredBookings.length === 0" class="empty-state">
        <p>Nenhum agendamento encontrado.</p>
      </div>

      <div v-else class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr>
              <th>Cliente</th>
              <th>Telefone</th>
              <th>Serviço</th>
              <th>Data</th>
              <th>Hora</th>
              <th>Valor</th>
              <th>Status</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="b in filteredBookings" :key="b.id">
              <td class="td-client">{{ b.client_name }}</td>
              <td class="td-phone">{{ b.client_phone }}</td>
              <td class="td-service">{{ b.service_name }}</td>
              <td>{{ formatDate(b.booking_date) }}</td>
              <td class="td-time">{{ b.booking_time }}</td>
              <td class="td-price">{{ getServicePrice(b.service_id) }}</td>
              <td>
                <span class="status-badge" :class="`status-${getStatusColor(b.status)}`">
                  {{ getStatusLabel(b.status) }}
                </span>
              </td>
              <td class="td-actions">
                <div class="action-buttons">
                  <select
                    class="action-select"
                    :value="b.status"
                    :disabled="actionLoading === b.id"
                    @change="handleStatusChange(b.id, ($event.target as HTMLSelectElement).value)"
                  >
                    <option value="pending">Pendente</option>
                    <option value="confirmed">Confirmar</option>
                    <option value="completed">Concluir</option>
                    <option value="cancelled">Cancelar</option>
                  </select>
                  <button
                    class="action-delete"
                    :disabled="actionLoading === b.id"
                    @click="handleDelete(b.id)"
                    aria-label="Excluir agendamento"
                  >
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6" /></svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <!-- CALENDAR VIEW -->
    <template v-else>
      <div class="calendar-toolbar">
        <div class="cal-nav">
          <button class="cal-nav-btn" @click="prevMonth" aria-label="Mês anterior">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 18l-6-6 6-6" /></svg>
          </button>
          <h3 class="cal-title">{{ calendarTitle }}</h3>
          <button class="cal-nav-btn" @click="nextMonth" aria-label="Próximo mês">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6" /></svg>
          </button>
        </div>
        <button class="btn-today" @click="goToday" aria-label="Ir para hoje">Hoje</button>
      </div>

      <div class="calendar-grid">
        <div class="cal-weekday" v-for="wd in ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']" :key="wd">{{ wd }}</div>
        <div
          v-for="(day, i) in calendarDays"
          :key="i"
          class="cal-day"
          :class="{
            'cal-day-empty': !day.date,
            'cal-day-today': day.date === todayStr,
            'cal-day-has': day.date && day.bookings.length > 0,
          }"
          :tabindex="day.date && day.bookings.length > 0 ? 0 : -1"
          :role="day.date && day.bookings.length > 0 ? 'button' : undefined"
          :aria-label="day.date && day.bookings.length > 0 ? `${day.bookings.length} agendamento(s) em ${day.date}` : undefined"
          @click="day.date && day.bookings.length > 0 && openDayBookings(day.date)"
          @keydown.enter="day.date && day.bookings.length > 0 && openDayBookings(day.date)"
          @keydown.space.prevent="day.date && day.bookings.length > 0 && openDayBookings(day.date)"
        >
          <span v-if="day.day" class="cal-day-num">{{ day.day }}</span>
          <div v-if="day.bookings.length > 0" class="cal-day-events">
            <div
              v-for="b in day.bookings.slice(0, 3)"
              :key="b.id"
              class="cal-event"
              :class="`status-${getStatusColor(b.status)}`"
            >
              <span class="cal-event-time">{{ b.booking_time }}</span>
              <span class="cal-event-name">{{ b.client_name }}</span>
            </div>
            <span v-if="day.bookings.length > 3" class="cal-more">+{{ day.bookings.length - 3 }} mais</span>
          </div>
        </div>
      </div>
    </template>

    <!-- Day detail modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="selectedDateBookings" class="modal-overlay" @click="closeDayBookings">
          <div class="modal" role="dialog" aria-modal="true" aria-label="Detalhes do dia" @click.stop>
            <div class="modal-header">
              <h3>{{ formatDate(selectedDateBookings[0]?.booking_date || '') }}</h3>
              <button class="modal-close" @click="closeDayBookings" aria-label="Fechar">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12" /></svg>
              </button>
            </div>

            <div v-if="selectedDateBookings.length === 0" class="empty-state">
              <p>Nenhum agendamento neste dia.</p>
            </div>

            <div v-else class="day-booking-list">
              <div v-for="b in selectedDateBookings" :key="b.id" class="day-booking-item">
                <div class="day-booking-time">{{ b.booking_time }}</div>
                <div class="day-booking-info">
                  <span class="day-booking-client">{{ b.client_name }}</span>
                  <span class="day-booking-service">{{ b.service_name }}</span>
                  <span class="day-booking-phone">{{ b.client_phone }}</span>
                </div>
                <div class="day-booking-actions">
                  <span class="status-badge" :class="`status-${getStatusColor(b.status)}`">
                    {{ getStatusLabel(b.status) }}
                  </span>
                  <select
                    class="action-select"
                    :value="b.status"
                    :disabled="actionLoading === b.id"
                    @change="handleStatusChange(b.id, ($event.target as HTMLSelectElement).value)"
                  >
                    <option value="pending">Pendente</option>
                    <option value="confirmed">Confirmar</option>
                    <option value="completed">Concluir</option>
                    <option value="cancelled">Cancelar</option>
                  </select>
                  <button
                    class="action-delete"
                    :disabled="actionLoading === b.id"
                    @click="handleDelete(b.id)"
                    title="Excluir"
                  >
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6" /></svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
    <!-- Create booking modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showCreateModal" class="modal-overlay" @click="closeCreateModal">
          <div class="modal create-modal" role="dialog" aria-modal="true" aria-label="Novo agendamento" @click.stop>
            <div class="modal-header">
              <h3>Novo Agendamento</h3>
              <button class="modal-close" @click="closeCreateModal" aria-label="Fechar">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12" /></svg>
              </button>
            </div>

            <p v-if="createError" class="error-banner" role="alert">{{ createError }}</p>

            <form class="create-form" @submit.prevent="handleCreateBooking">
              <div class="form-group">
                <label for="new-client-name">Cliente *</label>
                <input
                  id="new-client-name"
                  v-model="createForm.client_name"
                  type="text"
                  placeholder="Nome do cliente"
                  required
                  @input="clearClientSelection"
                />
                <div v-if="!createForm.client_id && filteredClients.length > 0" class="client-suggestions">
                  <button
                    v-for="c in filteredClients"
                    :key="c.id"
                    type="button"
                    class="client-suggestion"
                    @click="selectExistingClient(c)"
                  >
                    {{ c.name }} — {{ c.phone }}
                  </button>
                </div>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label for="new-client-phone">Telefone *</label>
                  <input
                    id="new-client-phone"
                    v-model="createForm.client_phone"
                    type="tel"
                    placeholder="(00) 00000-0000"
                    required
                  />
                </div>
                <div class="form-group">
                  <label for="new-client-cpf">CPF</label>
                  <input
                    id="new-client-cpf"
                    v-model="createForm.new_client_cpf"
                    type="text"
                    placeholder="000.000.000-00"
                  />
                </div>
              </div>

              <div class="form-group">
                <label for="new-service">Serviço *</label>
                <select id="new-service" v-model="createForm.service_id" required>
                  <option value="" disabled>Selecione um serviço</option>
                  <option v-for="s in services" :key="s.id" :value="s.id">
                    {{ s.name }} — {{ formatPrice(s.price) }}
                  </option>
                </select>
              </div>

              <div class="form-group" v-if="professionals.length > 0">
                <label for="new-professional">Profissional</label>
                <select id="new-professional" v-model="createForm.professional_id">
                  <option value="">Sem profissional específico</option>
                  <option v-for="p in professionals" :key="p.id" :value="p.id">
                    {{ p.name }} — {{ p.role }}
                  </option>
                </select>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label for="new-date">Data *</label>
                  <input
                    id="new-date"
                    v-model="createForm.booking_date"
                    type="date"
                    :min="todayStr"
                    required
                  />
                </div>
                <div class="form-group">
                  <label for="new-time">Horário *</label>
                  <select id="new-time" v-model="createForm.booking_time" required>
                    <option value="" disabled>Selecione um horário</option>
                    <option v-for="t in availableSlots" :key="t" :value="t">{{ t }}</option>
                  </select>
                </div>
              </div>

              <div class="form-group">
                <label for="new-notes">Observações</label>
                <textarea
                  id="new-notes"
                  v-model="createForm.notes"
                  rows="2"
                  placeholder="Opcional"
                ></textarea>
              </div>

              <div class="form-actions">
                <button type="button" class="btn btn-outline" @click="closeCreateModal">Cancelar</button>
                <button type="submit" class="btn btn-primary" :disabled="createLoading">
                  {{ createLoading ? 'Criando...' : 'Criar Agendamento' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.page {
  max-width: 1200px;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.page-title {
  font-size: 2rem;
  margin-bottom: 4px;
}

.page-subtitle {
  color: var(--color-text-secondary);
  font-size: 0.95rem;
}

.view-toggle {
  display: flex;
  gap: 4px;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 4px;
}

.toggle-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border-radius: var(--radius-sm);
  color: var(--color-text-muted);
  font-size: 0.85rem;
  font-weight: 500;
  transition: all var(--transition);
}

.toggle-btn svg {
  width: 16px;
  height: 16px;
}

.toggle-btn.active {
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  color: var(--color-bg);
}

.error-banner {
  color: var(--color-error);
  font-size: 0.9rem;
  padding: 12px 16px;
  background: rgba(248,113,113,0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(248,113,113,0.2);
  margin-bottom: 20px;
}

.success-banner {
  color: var(--color-success);
  font-size: 0.9rem;
  padding: 12px 16px;
  background: rgba(74,222,128,0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(74,222,128,0.2);
  margin-bottom: 20px;
}

.filters-bar {
  display: flex;
  gap: 16px;
  align-items: flex-end;
  margin-bottom: 24px;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.filter-group label {
  font-size: 0.8rem;
  color: var(--color-text-muted);
  font-weight: 500;
}

.filter-group input,
.filter-group select {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 10px 14px;
  color: var(--color-text);
  font-size: 0.9rem;
  transition: border-color var(--transition);
}

.filter-group input:focus,
.filter-group select:focus {
  outline: none;
  border-color: var(--color-gold);
}

.filter-search {
  flex: 1;
  min-width: 200px;
}

.btn-clear {
  padding: 10px 16px;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border-light);
  color: var(--color-text-secondary);
  font-size: 0.85rem;
  transition: all var(--transition);
}

.btn-clear:hover {
  border-color: var(--color-gold-muted);
  color: var(--color-text);
}

.empty-state {
  padding: 60px 24px;
  text-align: center;
  color: var(--color-text-muted);
  font-size: 0.95rem;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.table-wrapper {
  overflow-x: auto;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table thead {
  background: var(--color-bg-alt);
}

.data-table th {
  text-align: left;
  padding: 14px 16px;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  white-space: nowrap;
}

.data-table td {
  padding: 14px 16px;
  font-size: 0.9rem;
  border-top: 1px solid var(--color-border);
  white-space: nowrap;
}

.data-table tbody tr {
  transition: background var(--transition);
}

.data-table tbody tr:hover {
  background: var(--color-bg-alt);
}

.td-client { font-weight: 500; }
.td-phone { color: var(--color-text-secondary); }
.td-service { color: var(--color-text-secondary); }
.td-time { color: var(--color-gold); font-weight: 500; }
.td-price { font-weight: 500; }

.status-badge {
  font-size: 0.75rem;
  font-weight: 500;
  padding: 4px 12px;
  border-radius: var(--radius-full);
  white-space: nowrap;
}

.status-warning { background: rgba(251,191,36,0.15); color: var(--color-warning); }
.status-success { background: rgba(74,222,128,0.15); color: var(--color-success); }
.status-gold { background: rgba(212,175,55,0.15); color: var(--color-gold); }
.status-error { background: rgba(248,113,113,0.15); color: var(--color-error); }

.action-buttons {
  display: flex;
  gap: 8px;
  align-items: center;
}

.action-select {
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-sm);
  padding: 6px 10px;
  color: var(--color-text);
  font-size: 0.82rem;
  cursor: pointer;
}

.action-select:focus {
  outline: none;
  border-color: var(--color-gold-muted);
}

.action-select:disabled {
  opacity: 0.5;
}

.action-delete {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-muted);
  transition: all var(--transition);
}

.action-delete:hover:not(:disabled) {
  background: rgba(248,113,113,0.1);
  color: var(--color-error);
}

.action-delete svg {
  width: 16px;
  height: 16px;
}

.action-delete:disabled {
  opacity: 0.5;
}

/* Calendar */
.calendar-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.cal-nav {
  display: flex;
  align-items: center;
  gap: 16px;
}

.cal-nav-btn {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border-light);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-secondary);
  transition: all var(--transition);
}

.cal-nav-btn:hover {
  border-color: var(--color-gold-muted);
  color: var(--color-text);
}

.cal-nav-btn svg {
  width: 18px;
  height: 18px;
}

.cal-title {
  font-size: 1.2rem;
  font-weight: 600;
  min-width: 200px;
  text-align: center;
}

.btn-today {
  padding: 8px 16px;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border-light);
  color: var(--color-text-secondary);
  font-size: 0.85rem;
  transition: all var(--transition);
}

.btn-today:hover {
  border-color: var(--color-gold-muted);
  color: var(--color-text);
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: var(--color-border);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.cal-weekday {
  background: var(--color-bg-alt);
  padding: 10px 8px;
  text-align: center;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.cal-day {
  background: var(--color-bg-card);
  min-height: 100px;
  padding: 8px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  transition: background var(--transition);
}

.cal-day-empty {
  background: var(--color-bg-alt);
  opacity: 0.4;
}

.cal-day-today {
  background: rgba(212,175,55,0.05);
}

.cal-day-today .cal-day-num {
  color: var(--color-gold);
  font-weight: 700;
}

.cal-day-has {
  cursor: pointer;
}

.cal-day-has:hover {
  background: var(--color-bg-alt);
}

.cal-day-num {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.cal-day-events {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.cal-event {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 3px 6px;
  border-radius: var(--radius-sm);
  font-size: 0.72rem;
  overflow: hidden;
}

.cal-event.status-warning { background: rgba(251,191,36,0.15); }
.cal-event.status-success { background: rgba(74,222,128,0.15); }
.cal-event.status-gold { background: rgba(212,175,55,0.15); }
.cal-event.status-error { background: rgba(248,113,113,0.15); }

.cal-event-time {
  font-weight: 600;
  color: var(--color-gold);
  white-space: nowrap;
}

.cal-event-name {
  color: var(--color-text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.cal-more {
  font-size: 0.7rem;
  color: var(--color-text-muted);
  padding: 2px 6px;
}

/* Day modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  background: rgba(0,0,0,0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.modal {
  width: 100%;
  max-width: 600px;
  max-height: 85vh;
  overflow-y: auto;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 32px;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

.modal-header h3 {
  font-size: 1.3rem;
}

.modal-close {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-muted);
  transition: all var(--transition);
}

.modal-close:hover {
  background: var(--color-bg-alt);
  color: var(--color-text);
}

.modal-close svg {
  width: 20px;
  height: 20px;
}

.day-booking-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.day-booking-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  background: var(--color-bg-alt);
  border-radius: var(--radius-md);
}

.day-booking-time {
  font-family: var(--font-heading);
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--color-gold);
  min-width: 60px;
}

.day-booking-info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.day-booking-client {
  font-weight: 500;
  font-size: 0.95rem;
}

.day-booking-service {
  font-size: 0.82rem;
  color: var(--color-text-muted);
}

.day-booking-phone {
  font-size: 0.78rem;
  color: var(--color-text-muted);
}

.day-booking-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

@media (max-width: 900px) {
  .calendar-grid {
    grid-template-columns: repeat(7, 1fr);
  }
  .cal-day {
    min-height: 70px;
  }
  .cal-event-name {
    display: none;
  }
}

@media (max-width: 768px) {
  .filters-bar {
    flex-direction: column;
  }
  .filter-search {
    width: 100%;
  }
  .data-table {
    font-size: 0.82rem;
  }
  .page-header {
    flex-direction: column;
  }
  .day-booking-item {
    flex-wrap: wrap;
  }
  .day-booking-actions {
    flex-wrap: wrap;
    width: 100%;
  }
}

@media (max-width: 600px) {
  .cal-day {
    min-height: 50px;
    padding: 4px;
  }
  .cal-day-num {
    font-size: 0.72rem;
  }
  .cal-event {
    font-size: 0.62rem;
    padding: 2px 4px;
  }
  .cal-more {
    display: none;
  }
}
.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.btn-new-booking {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
  font-size: 0.9rem;
}

.btn-new-booking svg {
  width: 18px;
  height: 18px;
}

.create-modal {
  max-width: 560px;
}

.create-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.create-form .form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.create-form .form-group label {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.create-form .form-group input,
.create-form .form-group select,
.create-form .form-group textarea {
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 12px 14px;
  color: var(--color-text);
  font-size: 0.92rem;
  transition: border-color var(--transition);
}

.create-form .form-group input:focus,
.create-form .form-group select:focus,
.create-form .form-group textarea:focus {
  outline: none;
  border-color: var(--color-gold);
}

.create-form .form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.client-suggestions {
  display: flex;
  flex-direction: column;
  gap: 4px;
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 4px;
  max-height: 160px;
  overflow-y: auto;
}

.client-suggestion {
  text-align: left;
  padding: 8px 12px;
  border-radius: var(--radius-sm);
  font-size: 0.88rem;
  color: var(--color-text-secondary);
  transition: background var(--transition);
}

.client-suggestion:hover {
  background: var(--color-bg-card);
  color: var(--color-text);
}

.create-form .form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 8px;
}

@media (max-width: 600px) {
  .create-form .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
