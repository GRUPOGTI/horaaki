<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { listMyBookings, cancelMyBooking, type ClientBooking } from '../lib/clientAccount'
import { formatDate, statusLabels, statusColors } from '../lib/format'

const bookings = ref<ClientBooking[]>([])
const loading = ref(true)
const loadError = ref('')
const actionError = ref('')
const cancellingId = ref<string | null>(null)

function canCancel(booking: ClientBooking): boolean {
  return booking.status === 'pending' || booking.status === 'confirmed'
}

async function loadBookings() {
  loading.value = true
  loadError.value = ''
  try {
    bookings.value = await listMyBookings()
  } catch (err: any) {
    loadError.value = err.message
  } finally {
    loading.value = false
  }
}

async function cancelBooking(booking: ClientBooking) {
  const confirmed = window.confirm(
    `Cancelar o agendamento de ${booking.service_name} em ${formatDate(booking.booking_date)} às ${booking.booking_time}?`,
  )
  if (!confirmed) return

  cancellingId.value = booking.booking_id
  actionError.value = ''
  try {
    await cancelMyBooking(booking.booking_id)
    bookings.value = bookings.value.map((item) =>
      item.booking_id === booking.booking_id ? { ...item, status: 'cancelled' } : item,
    )
  } catch (err: any) {
    actionError.value = err.message
  } finally {
    cancellingId.value = null
  }
}

function badgeClass(status: string): string {
  return `status-${statusColors[status] || 'warning'}`
}

onMounted(loadBookings)
</script>

<template>
  <section class="card" aria-labelledby="client-bookings-title">
    <header class="card-header">
      <h2 id="client-bookings-title" class="card-title">Meus agendamentos</h2>
    </header>

    <p v-if="loading" class="card-muted" role="status">Carregando seus agendamentos...</p>
    <p v-else-if="loadError" class="form-error" role="alert">{{ loadError }}</p>
    <p v-else-if="bookings.length === 0" class="card-muted">Você ainda não tem agendamentos.</p>

    <template v-else>
      <p v-if="actionError" class="form-error" role="alert">{{ actionError }}</p>
      <ul class="booking-list">
        <li v-for="booking in bookings" :key="booking.booking_id" class="booking-item">
          <div class="booking-info">
            <p class="booking-service">{{ booking.service_name }}</p>
            <p class="booking-meta">
              {{ booking.company_name }} · {{ formatDate(booking.booking_date) }} às {{ booking.booking_time }}
            </p>
            <p v-if="booking.notes" class="booking-meta">Observações: {{ booking.notes }}</p>
          </div>
          <div class="booking-actions">
            <span class="status-badge" :class="badgeClass(booking.status)">
              {{ statusLabels[booking.status] || booking.status }}
            </span>
            <button
              v-if="canCancel(booking)"
              type="button"
              class="btn btn-outline btn-cancel"
              :disabled="cancellingId === booking.booking_id"
              @click="cancelBooking(booking)"
            >
              {{ cancellingId === booking.booking_id ? 'Cancelando...' : 'Cancelar' }}
            </button>
          </div>
        </li>
      </ul>
    </template>
  </section>
</template>

<style scoped>
.card {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-title {
  font-size: 1.15rem;
}

.card-muted {
  color: var(--color-text-secondary);
  font-size: 0.92rem;
}

.booking-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.booking-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
  padding: 16px;
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.booking-service {
  font-weight: 600;
}

.booking-meta {
  font-size: 0.88rem;
  color: var(--color-text-secondary);
  margin-top: 4px;
}

.booking-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.status-badge {
  font-size: 0.8rem;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 999px;
}

.status-warning { background: rgba(251, 191, 36, 0.15); color: var(--color-warning); }
.status-success { background: rgba(74, 222, 128, 0.15); color: var(--color-success); }
.status-gold { background: rgba(212, 175, 55, 0.15); color: var(--color-gold); }
.status-error { background: rgba(248, 113, 113, 0.15); color: var(--color-error); }

.btn-cancel:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.form-error {
  color: var(--color-error);
  font-size: 0.9rem;
  padding: 10px 14px;
  background: rgba(248, 113, 113, 0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(248, 113, 113, 0.2);
}
</style>
