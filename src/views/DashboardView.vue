<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase, type Service } from '../lib/supabase'
import { useBookings } from '../composables/useBookings'
import { useCompany } from '../composables/useCompany'
import { formatPrice, formatDate, timeAgo, statusLabels, statusColors } from '../lib/format'

const { bookings, clearNewBookingCount } = useBookings()
const { company } = useCompany()

const services = ref<Service[]>([])
const loading = ref(true)

const todayStr = new Date().toISOString().split('T')[0]

const stats = computed(() => {
  const pending = bookings.value.filter((b) => b.status === 'pending').length
  const today = bookings.value.filter(
    (b) => b.booking_date === todayStr && b.status !== 'cancelled'
  ).length
  const total = bookings.value.length
  const revenue = bookings.value
    .filter((b) => b.status === 'completed')
    .reduce((sum, b) => {
      const svc = services.value.find((s) => s.id === b.service_id)
      return sum + (svc?.price ?? 0)
    }, 0)

  return { pending, today, total, revenue, serviceCount: services.value.length }
})

const recentBookings = computed(() => {
  return [...bookings.value]
    .sort((a, b) => b.created_at.localeCompare(a.created_at))
    .slice(0, 6)
})

const todayBookings = computed(() => {
  return bookings.value
    .filter((b) => b.booking_date === todayStr && b.status !== 'cancelled')
    .sort((a, b) => a.booking_time.localeCompare(b.booking_time))
})

onMounted(async () => {
  let query = supabase
    .from('services')
    .select('*')
    .order('display_order', { ascending: true })

  if (company.value?.id) {
    query = query.eq('empresa_id', company.value.id)
  }

  const { data } = await query

  if (data) services.value = data
  loading.value = false
  clearNewBookingCount()
})
</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1 class="page-title">Dashboard</h1>
      <p class="page-subtitle">Visão geral do seu estabelecimento</p>
    </div>

    <div v-if="loading" class="loading-state" aria-live="polite" aria-busy="true">Carregando...</div>

    <template v-else>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon stat-icon-warning">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />
            </svg>
          </div>
          <div class="stat-content">
            <span class="stat-label">Pendentes</span>
            <span class="stat-value">{{ stats.pending }}</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon-gold">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" />
            </svg>
          </div>
          <div class="stat-content">
            <span class="stat-label">Hoje</span>
            <span class="stat-value">{{ stats.today }}</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon-info">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M9 11l3 3L22 4" /><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
            </svg>
          </div>
          <div class="stat-content">
            <span class="stat-label">Total agendamentos</span>
            <span class="stat-value">{{ stats.total }}</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon-success">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
            </svg>
          </div>
          <div class="stat-content">
            <span class="stat-label">Receita concluída</span>
            <span class="stat-value">{{ formatPrice(stats.revenue) }}</span>
          </div>
        </div>
      </div>

      <div class="dashboard-grid">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Agendamentos de hoje</h3>
            <span class="panel-badge">{{ todayBookings.length }}</span>
          </div>

          <div v-if="todayBookings.length === 0" class="empty-state">
            <p>Nenhum agendamento para hoje.</p>
          </div>

          <div v-else class="booking-list">
            <div v-for="b in todayBookings" :key="b.id" class="booking-item">
              <div class="booking-time">{{ b.booking_time }}</div>
              <div class="booking-info">
                <span class="booking-client">{{ b.client_name }}</span>
                <span class="booking-service">{{ b.service_name }}</span>
              </div>
              <span class="status-badge" :class="`status-${statusColors[b.status] || 'warning'}`">
                {{ statusLabels[b.status] || b.status }}
              </span>
            </div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Últimos agendamentos</h3>
            <span class="panel-badge">{{ recentBookings.length }}</span>
          </div>

          <div v-if="recentBookings.length === 0" class="empty-state">
            <p>Nenhum agendamento ainda.</p>
          </div>

          <div v-else class="booking-list">
            <div v-for="b in recentBookings" :key="b.id" class="booking-item">
              <div class="booking-info">
                <span class="booking-client">{{ b.client_name }}</span>
                <span class="booking-service">{{ b.service_name }} · {{ formatDate(b.booking_date) }} às {{ b.booking_time }}</span>
              </div>
              <div class="booking-meta">
                <span class="booking-ago">{{ timeAgo(b.created_at) }}</span>
                <span class="status-badge" :class="`status-${statusColors[b.status] || 'warning'}`">
                  {{ statusLabels[b.status] || b.status }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.page {
  max-width: 1200px;
}

.page-header {
  margin-bottom: 32px;
}

.page-title {
  font-size: 2rem;
  margin-bottom: 4px;
}

.page-subtitle {
  color: var(--color-text-secondary);
  font-size: 0.95rem;
}

.loading-state {
  color: var(--color-text-muted);
  padding: 40px 0;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
}

.stat-card {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 16px;
  transition: border-color var(--transition);
}

.stat-card:hover {
  border-color: var(--color-border-light);
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-icon svg {
  width: 24px;
  height: 24px;
}

.stat-icon-warning { background: rgba(251,191,36,0.12); }
.stat-icon-warning svg { color: var(--color-warning); }
.stat-icon-gold { background: rgba(212,175,55,0.12); }
.stat-icon-gold svg { color: var(--color-gold); }
.stat-icon-info { background: rgba(96,165,250,0.12); }
.stat-icon-info svg { color: #60a5fa; }
.stat-icon-success { background: rgba(74,222,128,0.12); }
.stat-icon-success svg { color: var(--color-success); }

.stat-content {
  display: flex;
  flex-direction: column;
}

.stat-label {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.stat-value {
  font-family: var(--font-heading);
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--color-text);
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.panel {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--color-border);
}

.panel-title {
  font-family: var(--font-body);
  font-size: 1rem;
  font-weight: 600;
}

.panel-badge {
  background: var(--color-bg-alt);
  color: var(--color-text-muted);
  font-size: 0.8rem;
  padding: 2px 10px;
  border-radius: var(--radius-full);
}

.empty-state {
  padding: 32px 24px;
  text-align: center;
  color: var(--color-text-muted);
  font-size: 0.9rem;
}

.booking-list {
  display: flex;
  flex-direction: column;
}

.booking-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 24px;
  border-bottom: 1px solid var(--color-border);
  transition: background var(--transition);
}

.booking-item:last-child {
  border-bottom: none;
}

.booking-item:hover {
  background: var(--color-bg-alt);
}

.booking-time {
  font-family: var(--font-heading);
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--color-gold);
  min-width: 60px;
}

.booking-info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.booking-client {
  font-weight: 500;
  font-size: 0.95rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.booking-service {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.booking-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.booking-ago {
  font-size: 0.78rem;
  color: var(--color-text-muted);
}

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

@media (max-width: 768px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
  .stats-grid {
    grid-template-columns: 1fr 1fr;
  }
  .stat-value {
    font-size: 1.4rem;
  }
}
</style>
