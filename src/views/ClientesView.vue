<script setup lang="ts">
import { ref, computed } from 'vue'
import { useBookings } from '../composables/useBookings'
import { supabase, type Service } from '../lib/supabase'
import { formatDate, formatPrice, statusLabels, statusColors } from '../lib/format'

const { bookings } = useBookings()

const services = ref<Service[]>([])
const searchQuery = ref('')
const selectedClient = ref<ClientSummary | null>(null)

interface ClientSummary {
  name: string
  phone: string
  totalBookings: number
  pendingCount: number
  confirmedCount: number
  completedCount: number
  cancelledCount: number
  lastVisit: string
  totalSpent: number
  bookings: Array<{
    id: string
    service_name: string
    booking_date: string
    booking_time: string
    status: string
  }>
}

const clients = computed<ClientSummary[]>(() => {
  const map = new Map<string, ClientSummary>()

  for (const b of bookings.value) {
    const key = b.client_phone
    if (!map.has(key)) {
      map.set(key, {
        name: b.client_name,
        phone: b.client_phone,
        totalBookings: 0,
        pendingCount: 0,
        confirmedCount: 0,
        completedCount: 0,
        cancelledCount: 0,
        lastVisit: '',
        totalSpent: 0,
        bookings: [],
      })
    }

    const client = map.get(key)!
    client.totalBookings++
    client.bookings.push({
      id: b.id,
      service_name: b.service_name,
      booking_date: b.booking_date,
      booking_time: b.booking_time,
      status: b.status,
    })

    if (b.status === 'pending') client.pendingCount++
    if (b.status === 'confirmed') client.confirmedCount++
    if (b.status === 'completed') {
      client.completedCount++
      const svc = services.value.find((s) => s.id === b.service_id)
      if (svc) client.totalSpent += svc.price
    }
    if (b.status === 'cancelled') client.cancelledCount++

    if (!client.lastVisit || b.booking_date > client.lastVisit) {
      client.lastVisit = b.booking_date
    }
  }

  return Array.from(map.values()).sort((a, b) => b.totalBookings - a.totalBookings)
})

const filteredClients = computed(() => {
  if (!searchQuery.value.trim()) return clients.value
  const q = searchQuery.value.toLowerCase().trim()
  return clients.value.filter(
    (c) => c.name.toLowerCase().includes(q) || c.phone.includes(q)
  )
})

function openClient(client: ClientSummary) {
  selectedClient.value = client
}

function closeClient() {
  selectedClient.value = null
}

function getStatusLabel(status: string): string {
  return statusLabels[status] || status
}

function getStatusColor(status: string): string {
  return statusColors[status] || 'warning'
}

async function loadServices() {
  const { data } = await supabase.from('services').select('*')
  if (data) services.value = data
}
loadServices()
</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1 class="page-title">Clientes</h1>
      <p class="page-subtitle">{{ clients.length }} cliente(s) cadastrado(s) através de agendamentos</p>
    </div>

    <div class="filter-bar">
      <input v-model="searchQuery" type="text" placeholder="Buscar por nome ou telefone..." class="search-input" />
    </div>

    <div v-if="filteredClients.length === 0" class="empty-state">
      <p>Nenhum cliente encontrado.</p>
    </div>

    <div v-else class="clients-grid">
      <div
        v-for="client in filteredClients"
        :key="client.phone"
        class="client-card"
        @click="openClient(client)"
      >
        <div class="client-avatar">
          {{ client.name.charAt(0).toUpperCase() }}
        </div>
        <div class="client-info">
          <span class="client-name">{{ client.name }}</span>
          <span class="client-phone">{{ client.phone }}</span>
        </div>
        <div class="client-stats">
          <span class="client-stat">{{ client.totalBookings }} agendamento(s)</span>
          <span v-if="client.completedCount > 0" class="client-spent">{{ formatPrice(client.totalSpent) }}</span>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="fade">
        <div v-if="selectedClient" class="modal-overlay" @click="closeClient">
          <div class="modal" @click.stop>
            <div class="modal-header">
              <div class="modal-client">
                <div class="client-avatar large">{{ selectedClient.name.charAt(0).toUpperCase() }}</div>
                <div>
                  <h3>{{ selectedClient.name }}</h3>
                  <p>{{ selectedClient.phone }}</p>
                </div>
              </div>
              <button class="modal-close" @click="closeClient">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12" /></svg>
              </button>
            </div>

            <div class="modal-stats">
              <div class="modal-stat">
                <span class="modal-stat-value">{{ selectedClient.totalBookings }}</span>
                <span class="modal-stat-label">Total</span>
              </div>
              <div class="modal-stat">
                <span class="modal-stat-value">{{ selectedClient.pendingCount }}</span>
                <span class="modal-stat-label">Pendentes</span>
              </div>
              <div class="modal-stat">
                <span class="modal-stat-value">{{ selectedClient.confirmedCount }}</span>
                <span class="modal-stat-label">Confirmados</span>
              </div>
              <div class="modal-stat">
                <span class="modal-stat-value">{{ selectedClient.completedCount }}</span>
                <span class="modal-stat-label">Concluídos</span>
              </div>
              <div class="modal-stat">
                <span class="modal-stat-value gold-text">{{ formatPrice(selectedClient.totalSpent) }}</span>
                <span class="modal-stat-label">Total gasto</span>
              </div>
            </div>

            <h4 class="modal-section-title">Histórico de agendamentos</h4>
            <div class="modal-history">
              <div v-for="b in selectedClient.bookings" :key="b.id" class="history-item">
                <div class="history-info">
                  <span class="history-service">{{ b.service_name }}</span>
                  <span class="history-date">{{ formatDate(b.booking_date) }} às {{ b.booking_time }}</span>
                </div>
                <span class="status-badge" :class="`status-${getStatusColor(b.status)}`">
                  {{ getStatusLabel(b.status) }}
                </span>
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
  margin-bottom: 24px;
}

.page-title {
  font-size: 2rem;
  margin-bottom: 4px;
}

.page-subtitle {
  color: var(--color-text-secondary);
  font-size: 0.95rem;
}

.filter-bar {
  margin-bottom: 24px;
}

.search-input {
  width: 100%;
  max-width: 400px;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 12px 16px;
  color: var(--color-text);
  font-size: 0.92rem;
  transition: border-color var(--transition);
}

.search-input:focus {
  outline: none;
  border-color: var(--color-gold);
}

.search-input::placeholder {
  color: var(--color-text-muted);
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

.clients-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.client-card {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  cursor: pointer;
  transition: all var(--transition);
}

.client-card:hover {
  border-color: var(--color-gold-muted);
  transform: translateY(-2px);
}

.client-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: var(--color-bg);
  flex-shrink: 0;
}

.client-avatar.large {
  width: 56px;
  height: 56px;
  font-size: 1.3rem;
}

.client-info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.client-name {
  font-weight: 500;
  font-size: 0.95rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.client-phone {
  font-size: 0.82rem;
  color: var(--color-text-muted);
}

.client-stats {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  flex-shrink: 0;
}

.client-stat {
  font-size: 0.78rem;
  color: var(--color-text-secondary);
}

.client-spent {
  font-size: 0.82rem;
  color: var(--color-gold);
  font-weight: 500;
}

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
  max-width: 560px;
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

.modal-client {
  display: flex;
  align-items: center;
  gap: 16px;
}

.modal-client h3 {
  font-size: 1.3rem;
}

.modal-client p {
  font-size: 0.88rem;
  color: var(--color-text-muted);
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

.modal-stats {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  padding: 20px;
  background: var(--color-bg-alt);
  border-radius: var(--radius-md);
  margin-bottom: 24px;
}

.modal-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
  min-width: 80px;
}

.modal-stat-value {
  font-family: var(--font-heading);
  font-size: 1.4rem;
  font-weight: 700;
}

.modal-stat-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.modal-section-title {
  font-family: var(--font-body);
  font-size: 0.9rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text-secondary);
  margin-bottom: 12px;
}

.modal-history {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.history-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--color-bg-alt);
  border-radius: var(--radius-md);
}

.history-info {
  display: flex;
  flex-direction: column;
}

.history-service {
  font-size: 0.9rem;
  font-weight: 500;
}

.history-date {
  font-size: 0.78rem;
  color: var(--color-text-muted);
}

.status-badge {
  font-size: 0.72rem;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: var(--radius-full);
  white-space: nowrap;
}

.status-warning { background: rgba(251,191,36,0.15); color: var(--color-warning); }
.status-success { background: rgba(74,222,128,0.15); color: var(--color-success); }
.status-gold { background: rgba(212,175,55,0.15); color: var(--color-gold); }
.status-error { background: rgba(248,113,113,0.15); color: var(--color-error); }

@media (max-width: 768px) {
  .clients-grid {
    grid-template-columns: 1fr;
  }
  .modal {
    padding: 24px 20px;
  }
  .modal-stats {
    gap: 12px;
  }
  .modal-stat-value {
    font-size: 1.1rem;
  }
}
</style>
