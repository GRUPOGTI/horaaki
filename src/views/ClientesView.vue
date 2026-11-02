<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useBookings } from '../composables/useBookings'
import { useCompany } from '../composables/useCompany'
import { supabase, type Service, type Client } from '../lib/supabase'
import { formatDate, formatPrice, statusLabels, statusColors } from '../lib/format'

const { bookings } = useBookings()
const { company } = useCompany()

const services = ref<Service[]>([])
const clients = ref<Client[]>([])
const searchQuery = ref('')
const selectedClient = ref<ClientWithStats | null>(null)
const loading = ref(true)
const showAddModal = ref(false)
const addLoading = ref(false)
const addError = ref('')

const addForm = ref({
  name: '',
  phone: '',
  cpf: '',
  email: '',
  notes: '',
})

interface BookingRecord {
  id: string
  service_name: string
  booking_date: string
  booking_time: string
  status: string
}

interface ClientWithStats extends Client {
  totalBookings: number
  pendingCount: number
  confirmedCount: number
  completedCount: number
  cancelledCount: number
  lastVisit: string
  totalSpent: number
  bookings: BookingRecord[]
}

function buildStats(c: Client): ClientWithStats {
  const clientBookings = bookings.value.filter(
    (b) => b.client_id === c.id || b.client_phone === c.phone
  )

  const stats: ClientWithStats = {
    ...c,
    totalBookings: clientBookings.length,
    pendingCount: 0,
    confirmedCount: 0,
    completedCount: 0,
    cancelledCount: 0,
    lastVisit: '',
    totalSpent: 0,
    bookings: clientBookings.map((b) => ({
      id: b.id,
      service_name: b.service_name,
      booking_date: b.booking_date,
      booking_time: b.booking_time,
      status: b.status,
    })),
  }

  for (const b of clientBookings) {
    if (b.status === 'pending') stats.pendingCount++
    if (b.status === 'confirmed') stats.confirmedCount++
    if (b.status === 'completed') {
      stats.completedCount++
      const svc = services.value.find((s) => s.id === b.service_id)
      if (svc) stats.totalSpent += svc.price
    }
    if (b.status === 'cancelled') stats.cancelledCount++
    if (!stats.lastVisit || b.booking_date > stats.lastVisit) {
      stats.lastVisit = b.booking_date
    }
  }

  return stats
}

const clientsWithStats = computed<ClientWithStats[]>(() =>
  clients.value.map(buildStats).sort((a, b) => b.totalBookings - a.totalBookings)
)

const filteredClients = computed(() => {
  if (!searchQuery.value.trim()) return clientsWithStats.value
  const q = searchQuery.value.toLowerCase().trim()
  return clientsWithStats.value.filter(
    (c) =>
      c.name.toLowerCase().includes(q) ||
      c.phone.includes(q) ||
      (c.cpf ?? '').includes(q)
  )
})

function openClient(client: ClientWithStats) {
  selectedClient.value = client
}

function closeClient() {
  selectedClient.value = null
}

function openAddModal() {
  addForm.value = { name: '', phone: '', cpf: '', email: '', notes: '' }
  addError.value = ''
  showAddModal.value = true
}

function closeAddModal() {
  showAddModal.value = false
}

async function handleAddClient() {
  addError.value = ''
  if (!addForm.value.name.trim() || !addForm.value.phone.trim()) {
    addError.value = 'Nome e telefone são obrigatórios.'
    return
  }

  const companyId = company.value?.id
  if (!companyId) {
    addError.value = 'Empresa não carregada.'
    return
  }

  addLoading.value = true
  try {
    const { data, error } = await supabase
      .from('clients')
      .insert({
        empresa_id: companyId,
        name: addForm.value.name.trim(),
        phone: addForm.value.phone.trim(),
        cpf: addForm.value.cpf.trim() || null,
        email: addForm.value.email.trim() || null,
        notes: addForm.value.notes.trim() || null,
      })
      .select('*')
      .maybeSingle()

    if (error) throw error
    if (data) {
      clients.value = [...clients.value, data as Client]
      showAddModal.value = false
    }
  } catch (err: any) {
    addError.value = err.message?.includes('unique')
      ? 'Já existe um cliente com este telefone ou CPF.'
      : err.message || 'Erro ao cadastrar cliente.'
  } finally {
    addLoading.value = false
  }
}

function getStatusLabel(status: string): string {
  return statusLabels[status] || status
}

function getStatusColor(status: string): string {
  return statusColors[status] || 'warning'
}

async function loadData() {
  const companyId = company.value?.id
  if (!companyId) return

  const [servicesRes, clientsRes] = await Promise.all([
    supabase.from('services').select('*').eq('empresa_id', companyId),
    supabase.from('clients').select('*').eq('empresa_id', companyId).order('name', { ascending: true }),
  ])

  if (servicesRes.data) services.value = servicesRes.data
  if (clientsRes.data) clients.value = clientsRes.data as Client[]
  loading.value = false
}

onMounted(loadData)
</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1 class="page-title">Clientes</h1>
      <p class="page-subtitle">{{ clients.length }} cliente(s) cadastrado(s)</p>
    </div>

    <div class="filter-bar">
      <input v-model="searchQuery" type="text" placeholder="Buscar por nome, telefone ou CPF..." class="search-input" />
      <button class="btn btn-primary btn-add-client" @click="openAddModal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14" /></svg>
        Novo Cliente
      </button>
    </div>

    <div v-if="loading" class="empty-state">
      <p>Carregando...</p>
    </div>

    <div v-else-if="filteredClients.length === 0" class="empty-state">
      <p>Nenhum cliente encontrado.</p>
    </div>

    <div v-else class="clients-grid">
      <div
        v-for="client in filteredClients"
        :key="client.id"
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

    <!-- Add client modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showAddModal" class="modal-overlay" @click="closeAddModal">
          <div class="modal" role="dialog" aria-modal="true" aria-label="Novo cliente" @click.stop>
            <div class="modal-header">
              <h3>Novo Cliente</h3>
              <button class="modal-close" @click="closeAddModal" aria-label="Fechar">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12" /></svg>
              </button>
            </div>

            <p v-if="addError" class="error-banner" role="alert">{{ addError }}</p>

            <form class="add-form" @submit.prevent="handleAddClient">
              <div class="form-group">
                <label for="client-name">Nome *</label>
                <input id="client-name" v-model="addForm.name" type="text" placeholder="Nome do cliente" required />
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label for="client-phone">Telefone *</label>
                  <input id="client-phone" v-model="addForm.phone" type="tel" placeholder="(00) 00000-0000" required />
                </div>
                <div class="form-group">
                  <label for="client-cpf">CPF</label>
                  <input id="client-cpf" v-model="addForm.cpf" type="text" placeholder="000.000.000-00" />
                </div>
              </div>
              <div class="form-group">
                <label for="client-email">E-mail</label>
                <input id="client-email" v-model="addForm.email" type="email" placeholder="cliente@email.com" />
              </div>
              <div class="form-group">
                <label for="client-notes">Observações</label>
                <textarea id="client-notes" v-model="addForm.notes" rows="2" placeholder="Opcional"></textarea>
              </div>
              <div class="form-actions">
                <button type="button" class="btn btn-outline" @click="closeAddModal">Cancelar</button>
                <button type="submit" class="btn btn-primary" :disabled="addLoading">
                  {{ addLoading ? 'Salvando...' : 'Cadastrar' }}
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
.filter-bar {
  display: flex;
  gap: 16px;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
}

.btn-add-client {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
  font-size: 0.9rem;
  white-space: nowrap;
}

.btn-add-client svg {
  width: 18px;
  height: 18px;
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

.add-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.add-form .form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.add-form .form-group label {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.add-form .form-group input,
.add-form .form-group textarea {
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 12px 14px;
  color: var(--color-text);
  font-size: 0.92rem;
  transition: border-color var(--transition);
}

.add-form .form-group input:focus,
.add-form .form-group textarea:focus {
  outline: none;
  border-color: var(--color-gold);
}

.add-form .form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.add-form .form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

@media (max-width: 600px) {
  .add-form .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
