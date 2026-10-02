<script setup lang="ts">
import { ref, computed } from 'vue'
import { useBookings } from '../composables/useBookings'
import { formatDate, formatPrice, statusLabels, statusColors } from '../lib/format'
import { supabase, type Service, type Booking } from '../lib/supabase'

const { bookings, updateBookingStatus, deleteBooking } = useBookings()

const services = ref<Service[]>([])
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
  const { data } = await supabase.from('services').select('*')
  if (data) services.value = data
}
loadServices()

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

    <p v-if="errorMsg" class="error-banner">{{ errorMsg }}</p>
    <p v-if="successMsg" class="success-banner">{{ successMsg }}</p>

    <!-- LIST VIEW -->
    <template v-if="viewMode === 'list'">
      <div class="filters-bar">
        <div class="filter-group">
          <label>Status</label>
          <select v-model="filterStatus">
            <option value="all">Todos</option>
            <option value="pending">Pendentes</option>
            <option value="confirmed">Confirmados</option>
            <option value="completed">Concluídos</option>
            <option value="cancelled">Cancelados</option>
          </select>
        </div>
        <div class="filter-group">
          <label>Data</label>
          <input v-model="filterDate" type="date" />
        </div>
        <div class="filter-group filter-search">
          <label>Buscar</label>
          <input v-model="searchQuery" type="text" placeholder="Nome, telefone ou serviço..." />
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
                    title="Excluir"
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
          <button class="cal-nav-btn" @click="prevMonth">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 18l-6-6 6-6" /></svg>
          </button>
          <h3 class="cal-title">{{ calendarTitle }}</h3>
          <button class="cal-nav-btn" @click="nextMonth">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6" /></svg>
          </button>
        </div>
        <button class="btn-today" @click="goToday">Hoje</button>
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
            'cal-day-has': day.bookings.length > 0,
          }"
          @click="day.date && day.bookings.length > 0 && openDayBookings(day.date)"
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
          <div class="modal" @click.stop>
            <div class="modal-header">
              <h3>{{ formatDate(selectedDateBookings[0]?.booking_date || '') }}</h3>
              <button class="modal-close" @click="closeDayBookings">
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
</style>
