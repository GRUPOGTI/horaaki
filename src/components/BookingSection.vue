<script setup lang="ts">
import { ref, onMounted, onUnmounted, reactive, computed, watch } from 'vue'
import { supabase, type Service, type SiteConfig } from '../lib/supabase'
import { loadActiveServices, fetchAvailableSlots, createBooking } from '../lib/bookingService'
import { signOutClient, linkClientAccount, type ClientProfile } from '../lib/clientAccount'
import { formatPrice, formatDuration } from '../lib/format'
import ClientAuthForm from './ClientAuthForm.vue'

const props = defineProps<{ empresaId?: string | null; config?: SiteConfig }>()

const services = ref<Service[]>([])
const availableSlots = ref<string[]>([])
const slotsLoading = ref(false)
const loading = ref(false)
const submitted = ref(false)
const submitError = ref('')
const client = ref<ClientProfile | null>(null)
const sessionChecked = ref(false)
let authSubscription: { unsubscribe: () => void } | null = null

const form = reactive({
  client_name: '',
  client_phone: '',
  service_id: '' as string,
  booking_date: '',
  booking_time: '',
  notes: '',
})

const today = new Date().toISOString().split('T')[0]

const selectedService = computed(() => {
  return services.value.find((s) => s.id === form.service_id)
})

function formatDate(dateStr: string): string {
  if (!dateStr) return ''
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' })
}

async function refreshSlots() {
  form.booking_time = ''
  availableSlots.value = []
  const { empresaId } = props
  if (!empresaId || !form.service_id || !form.booking_date) return

  const requestKey = `${form.service_id}|${form.booking_date}`
  slotsLoading.value = true
  try {
    const slots = await fetchAvailableSlots(empresaId, form.service_id, form.booking_date)
    if (requestKey === `${form.service_id}|${form.booking_date}`) availableSlots.value = slots
  } catch (cause) {
    console.error('slot load failed', cause)
    submitError.value = 'Não foi possível carregar os horários. Tente novamente.'
  } finally {
    slotsLoading.value = false
  }
}

async function handleSubmit() {
  submitError.value = ''
  if (!client.value) {
    submitError.value = 'Entre na sua conta para solicitar um agendamento.'
    return
  }
  const { empresaId } = props
  if (!form.client_name.trim() || !form.client_phone.trim() || !form.service_id || !form.booking_date || !form.booking_time) {
    submitError.value = 'Por favor, preencha todos os campos obrigatórios.'
    return
  }
  if (!empresaId) {
    submitError.value = 'Não foi possível identificar o estabelecimento.'
    return
  }

  loading.value = true
  try {
    await createBooking({
      empresaId,
      serviceId: form.service_id,
      date: form.booking_date,
      time: form.booking_time,
      name: form.client_name,
      phone: form.client_phone,
      notes: form.notes,
      status: 'pending',
    })
    submitted.value = true
  } catch (cause) {
    submitError.value = (cause as Error).message
    refreshSlots()
  } finally {
    loading.value = false
  }
}

function resetForm() {
  submitted.value = false
  applyClientProfile()
  form.service_id = ''
  form.booking_date = ''
  form.booking_time = ''
  form.notes = ''
  availableSlots.value = []
}

function applyClientProfile() {
  form.client_name = client.value?.name ?? ''
  form.client_phone = client.value?.phone ?? ''
}

async function connectClient() {
  const { empresaId } = props
  if (!empresaId) return
  try {
    client.value = await linkClientAccount(empresaId)
    applyClientProfile()
  } catch (cause) {
    console.error('client link failed', cause)
    client.value = null
  }
}

async function restoreSession() {
  sessionChecked.value = false
  const { data } = await supabase.auth.getSession()
  if (data.session) await connectClient()
  sessionChecked.value = true
}

function handleAuthenticated(profile: ClientProfile) {
  client.value = profile
  applyClientProfile()
  submitError.value = ''
}

async function handleSignOut() {
  try {
    await signOutClient()
  } catch (cause) {
    submitError.value = (cause as Error).message
    return
  }
  client.value = null
  submitted.value = false
  applyClientProfile()
}

async function loadServices() {
  const { empresaId } = props
  if (!empresaId) return
  try {
    services.value = await loadActiveServices(empresaId)
  } catch (cause) {
    console.error('service load failed', cause)
    submitError.value = 'Não foi possível carregar os serviços. Tente novamente.'
  }
}

function handleSelectService(e: Event) {
  const service = (e as CustomEvent).detail as Service
  form.service_id = service.id
}

onMounted(() => {
  loadServices()
  restoreSession()
  window.addEventListener('select-service', handleSelectService)
  const { data } = supabase.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT') client.value = null
  })
  authSubscription = data.subscription
})

onUnmounted(() => {
  window.removeEventListener('select-service', handleSelectService)
  authSubscription?.unsubscribe()
})

watch(() => props.empresaId, () => {
  form.service_id = ''
  availableSlots.value = []
  loadServices()
  restoreSession()
})

watch([() => form.service_id, () => form.booking_date], refreshSlots)
</script>

<template>
  <section id="agendar" class="section booking-section">
    <div class="container">
      <h2 class="section-title">{{ (props.config?.booking_title ?? 'Agende seu Horário').split(' ').slice(0, -1).join(' ') }} <span class="gold-text">{{ (props.config?.booking_title ?? 'Agende seu Horário').split(' ').slice(-1)[0] }}</span></h2>
      <p class="section-subtitle">
        {{ props.config?.booking_subtitle ?? 'Preencha o formulário abaixo e entraremos em contato para confirmar seu agendamento.' }}
      </p>

      <div class="booking-card">
        <p v-if="!sessionChecked" class="auth-loading">Carregando...</p>
        <ClientAuthForm v-else-if="!client" :empresa-id="props.empresaId ?? ''" @authenticated="handleAuthenticated" />
        <template v-else>
        <div class="client-bar">
          <span>Olá, <strong>{{ client?.name }}</strong></span>
          <button type="button" class="client-logout" @click="handleSignOut">Sair</button>
        </div>
        <Transition name="fade" mode="out-in">
          <div v-if="submitted" key="success" class="success-state" role="status" aria-live="polite">
            <div class="success-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 6L9 17l-5-5" />
              </svg>
            </div>
            <h3>Agendamento Solicitado!</h3>
            <p>
              Recebemos seu pedido de agendamento para
              <strong>{{ selectedService?.name }}</strong>
              em <strong>{{ formatDate(form.booking_date) }}</strong>
              às <strong>{{ form.booking_time }}</strong>.
            </p>
            <p class="success-note">
              Entraremos em contato pelo telefone informado para confirmar.
            </p>
            <button class="btn btn-outline" @click="resetForm">Novo Agendamento</button>
          </div>

          <form v-else key="form" class="booking-form" @submit.prevent="handleSubmit">
            <div class="form-row">
              <div class="form-group">
                <label for="name">Nome completo *</label>
                <input
                  id="name"
                  v-model="form.client_name"
                  type="text"
                  placeholder="Seu nome"
                  required
                />
              </div>
              <div class="form-group">
                <label for="phone">Telefone / WhatsApp *</label>
                <input
                  id="phone"
                  v-model="form.client_phone"
                  type="tel"
                  placeholder="(00) 00000-0000"
                  required
                />
              </div>
            </div>

            <div class="form-group">
              <label for="service">Serviço *</label>
              <select id="service" v-model="form.service_id" required>
                <option value="" disabled>Selecione um serviço</option>
                <option v-for="s in services" :key="s.id" :value="s.id">
                  {{ s.name }} — {{ formatPrice(s.price) }} ({{ formatDuration(s.duration_min) }})
                </option>
              </select>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="date">Data *</label>
                <input
                  id="date"
                  v-model="form.booking_date"
                  type="date"
                  :min="today"
                  required
                />
              </div>
              <div class="form-group">
                <label for="time">Horário *</label>
                <select
                  id="time"
                  v-model="form.booking_time"
                  required
                  :disabled="!form.service_id || !form.booking_date || slotsLoading"
                  :aria-describedby="form.service_id && form.booking_date && !slotsLoading && availableSlots.length === 0 ? 'time-empty' : undefined"
                >
                  <option value="" disabled>
                    {{ slotsLoading ? 'Carregando horários...' : 'Selecione um horário' }}
                  </option>
                  <option v-for="t in availableSlots" :key="t" :value="t">{{ t }}</option>
                </select>
                <p v-if="form.service_id && form.booking_date && !slotsLoading && availableSlots.length === 0" id="time-empty" class="field-hint">
                  Nenhum horário disponível nesta data.
                </p>
              </div>
            </div>

            <div class="form-group">
              <label for="notes">Observações (opcional)</label>
              <textarea
                id="notes"
                v-model="form.notes"
                rows="3"
                placeholder="Alguma preferência ou informação adicional?"
              ></textarea>
            </div>

            <div v-if="selectedService" class="booking-summary">
              <div class="summary-item">
                <span class="summary-label">Serviço</span>
                <span class="summary-value">{{ selectedService.name }}</span>
              </div>
              <div class="summary-item">
                <span class="summary-label">Duração</span>
                <span class="summary-value">{{ formatDuration(selectedService.duration_min) }}</span>
              </div>
              <div class="summary-item">
                <span class="summary-label">Valor</span>
                <span class="summary-value gold-text">{{ formatPrice(selectedService.price) }}</span>
              </div>
            </div>

            <p v-if="submitError" class="form-error" role="alert">{{ submitError }}</p>

            <button type="submit" class="btn btn-primary booking-submit" :disabled="loading">
              <span v-if="loading" class="spinner"></span>
              <span>{{ loading ? 'Enviando...' : 'Solicitar Agendamento' }}</span>
            </button>
          </form>
        </Transition>
        </template>
      </div>
    </div>
  </section>
</template>

<style scoped>
.booking-section {
  background: var(--color-bg-alt);
}

.booking-card {
  max-width: 680px;
  margin: 0 auto;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 48px;
  box-shadow: var(--shadow-md);
}

.booking-form {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 0.88rem;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.form-group input,
.form-group select,
.form-group textarea {
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 14px 16px;
  color: var(--color-text);
  transition: border-color var(--transition);
  font-size: 0.95rem;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: var(--color-gold);
  box-shadow: 0 0 0 3px rgba(212,175,55,0.1);
}

.form-group input::placeholder,
.form-group textarea::placeholder {
  color: var(--color-text-muted);
}

.form-group select {
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%23b0b0b0' stroke-width='2'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 16px center;
  padding-right: 40px;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.form-group input[type="date"] {
  cursor: pointer;
}

.form-group select:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.field-hint {
  font-size: 0.85rem;
  color: var(--color-text-muted);
}

.booking-summary {
  display: flex;
  gap: 24px;
  padding: 20px;
  background: var(--color-bg-alt);
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
}

.summary-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}

.summary-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.summary-value {
  font-size: 0.95rem;
  font-weight: 500;
}

.form-error {
  color: var(--color-error);
  font-size: 0.9rem;
  text-align: center;
  padding: 12px;
  background: rgba(248,113,113,0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(248,113,113,0.2);
}

.booking-submit {
  width: 100%;
  padding: 16px;
  font-size: 1rem;
  margin-top: 8px;
}

.booking-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid rgba(10,10,10,0.3);
  border-top-color: var(--color-bg);
  border-radius: 50%;
  animation: spin 600ms linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.success-state {
  text-align: center;
  padding: 32px 0;
}

.success-icon {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 24px;
}

.success-icon svg {
  width: 40px;
  height: 40px;
  color: var(--color-bg);
}

.success-state h3 {
  font-size: 1.6rem;
  margin-bottom: 16px;
}

.success-state p {
  color: var(--color-text-secondary);
  margin-bottom: 8px;
  font-size: 1rem;
}

.success-note {
  color: var(--color-text-muted) !important;
  font-size: 0.9rem !important;
  margin-top: 16px !important;
  margin-bottom: 32px !important;
}

.auth-loading {
  text-align: center;
  color: var(--color-text-muted);
}

.client-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 24px;
  padding: 12px 16px;
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  color: var(--color-text-secondary);
  font-size: 0.95rem;
}

.client-logout {
  color: var(--color-gold);
  font-size: 0.9rem;
  text-decoration: underline;
}

@media (max-width: 600px) {
  .booking-card {
    padding: 24px;
  }
  .form-row {
    grid-template-columns: 1fr;
  }
  .booking-summary {
    flex-direction: column;
    gap: 12px;
  }
}
</style>
