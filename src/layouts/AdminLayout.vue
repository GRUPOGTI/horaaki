<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, RouterLink, RouterView } from 'vue-router'
import { useAuth } from '../composables/useAuth'
import { useBookings } from '../composables/useBookings'
import { useCompany } from '../composables/useCompany'

const router = useRouter()
const { user, signOut } = useAuth()
const { bookings, newBookingCount, clearNewBookingCount, loadBookings } = useBookings()
const { company, loadCompanyByUser } = useCompany()
const sidebarOpen = ref(false)

const pendingCount = computed(() => bookings.value.filter((b) => b.status === 'pending').length)

function onNavClick(name: string) {
  sidebarOpen.value = false
  if (name === 'painel' || name === 'agenda') {
    clearNewBookingCount()
  }
}

const navItems = [
  { name: 'painel', label: 'Dashboard', icon: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z' },
  { name: 'agenda', label: 'Agenda', icon: 'M8 2v4M16 2v4M3 10h18M5 6h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z' },
  { name: 'clientes', label: 'Clientes', icon: 'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75' },
  { name: 'servicos-admin', label: 'Serviços', icon: 'M6 4l6 8 6-8M6 20l6-8 6 8' },
  { name: 'usuarios', label: 'Usuários', icon: 'M17 20h5v-2a4 4 0 0 0-3-3.87M9 20v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75' },
  { name: 'configuracoes', label: 'Configurações', icon: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z' },
]

onMounted(async () => {
  await loadCompanyByUser()
})

watch(
  () => company.value?.id,
  (newId) => {
    if (newId) {
      loadBookings(newId)
    }
  },
  { immediate: true }
)

watch(
  () => company.value?.name,
  (name) => {
    document.title = name ? `${name} · Painel` : 'Painel Administrativo'
  },
  { immediate: true },
)

async function handleSignOut() {
  await signOut()
  router.push('/login')
}


</script>

<template>
  <div class="admin-layout">
    <aside class="sidebar" :class="{ open: sidebarOpen }" aria-label="Barra lateral de navegação">
      <div class="sidebar-header">
        <router-link to="/painel" class="sidebar-logo">
          <span class="logo-mark">{{ company?.name?.charAt(0).toUpperCase() ?? 'H' }}</span>
          <span class="logo-name">{{ company?.name || 'Painel' }}</span>
        </router-link>
      </div>

      <nav class="sidebar-nav" aria-label="Navegação do painel">
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          :to="{ name: item.name }"
          class="nav-item"
          @click="onNavClick(item.name)"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path :d="item.icon" />
          </svg>
          <span>{{ item.label }}</span>
          <span v-if="item.name === 'agenda' && pendingCount > 0" class="nav-badge">{{ pendingCount }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar-footer">
        <div class="user-info">
          <span class="user-avatar">{{ user?.email?.charAt(0).toUpperCase() ?? '?' }}</span>
          <span class="user-email">{{ user?.email ?? '' }}</span>
        </div>
        <button class="btn-signout" @click="handleSignOut" aria-label="Sair da conta">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9" />
          </svg>
          <span>Sair</span>
        </button>
      </div>
    </aside>

    <div v-if="sidebarOpen" class="sidebar-overlay" @click="sidebarOpen = false" aria-hidden="true"></div>

    <div class="admin-main">
      <header class="admin-topbar">
        <button class="menu-btn" @click="sidebarOpen = !sidebarOpen" :aria-expanded="sidebarOpen" aria-label="Abrir menu lateral">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12h18M3 6h18M3 18h18" /></svg>
        </button>
        <h2 class="topbar-title">{{ company?.name || 'Painel Administrativo' }}</h2>
        <a v-if="company?.slug" class="public-link" :href="`/agenda/${company.slug}`" target="_blank" rel="noopener">
          Ver página pública
        </a>
        <div v-if="newBookingCount > 0" class="new-booking-alert">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M15 17h5l-1.405-1.405A2.032 2.032 0 0 1 18 14.158V11a6.002 6.002 0 0 0-4-5.659V5a2 2 0 1 0-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 1 1-6 0v-1m6 0H9" /></svg>
          <span>{{ newBookingCount }} novo(s) agendamento(s)</span>
        </div>
      </header>

      <div class="admin-content">
        <main id="main-content">
          <RouterView />
        </main>
      </div>
    </div>
  </div>
</template>

<style scoped>
.admin-layout {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: 260px;
  background: var(--color-bg-alt);
  border-right: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  z-index: 50;
  transition: transform var(--transition);
}

.sidebar-header {
  padding: 24px 20px;
  border-bottom: 1px solid var(--color-border);
}

.sidebar-logo {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-mark {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-heading);
  font-weight: 700;
  font-size: 1.3rem;
  color: var(--color-bg);
  flex-shrink: 0;
}

.logo-name {
  font-family: var(--font-heading);
  font-size: 1.15rem;
  font-weight: 600;
}

.sidebar-nav {
  flex: 1;
  padding: 16px 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  overflow-y: auto;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: var(--radius-md);
  color: var(--color-text-secondary);
  font-size: 0.92rem;
  transition: all var(--transition);
}

.nav-item svg {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
}

.nav-item:hover {
  background: var(--color-bg-card);
  color: var(--color-text);
}

.nav-item.router-link-active {
  background: linear-gradient(135deg, rgba(212,175,55,0.15), rgba(212,175,55,0.05));
  color: var(--color-gold);
  border: 1px solid rgba(212,175,55,0.2);
}

.nav-badge {
  margin-left: auto;
  background: var(--color-warning);
  color: var(--color-bg);
  font-size: 0.72rem;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: var(--radius-full);
  min-width: 20px;
  text-align: center;
}

.new-booking-alert {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  background: rgba(251,191,36,0.12);
  border: 1px solid rgba(251,191,36,0.3);
  border-radius: var(--radius-full);
  color: var(--color-warning);
  font-size: 0.82rem;
  font-weight: 500;
  animation: pulseAlert 2s ease infinite;
}

.new-booking-alert svg {
  width: 18px;
  height: 18px;
}

@keyframes pulseAlert {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.sidebar-footer {
  padding: 16px 12px;
  border-top: 1px solid var(--color-border);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  margin-bottom: 8px;
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: var(--color-bg);
  flex-shrink: 0;
}

.user-email {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.btn-signout {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  width: 100%;
  border-radius: var(--radius-md);
  color: var(--color-error);
  font-size: 0.92rem;
  transition: all var(--transition);
}

.btn-signout svg {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
}

.btn-signout:hover {
  background: rgba(248,113,113,0.1);
}

.admin-main {
  flex: 1;
  margin-left: 260px;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.admin-topbar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 24px;
  background: var(--color-bg-alt);
  border-bottom: 1px solid var(--color-border);
  position: sticky;
  top: 0;
  z-index: 40;
}

.menu-btn {
  display: none;
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  align-items: center;
  justify-content: center;
}

.menu-btn svg {
  width: 20px;
  height: 20px;
}

.public-link {
  margin-left: auto;
  color: var(--color-gold);
  font-size: 0.9rem;
  text-decoration: underline;
  white-space: nowrap;
}

.topbar-title {
  font-family: var(--font-body);
  font-size: 1.1rem;
  font-weight: 500;
}

.admin-content {
  padding: 32px 24px;
  flex: 1;
}

.sidebar-overlay {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 45;
}

@media (max-width: 900px) {
  .sidebar {
    transform: translateX(-100%);
  }
  .sidebar.open {
    transform: translateX(0);
  }
  .admin-main {
    margin-left: 0;
  }
  .menu-btn {
    display: flex;
  }
  .sidebar-overlay {
    display: block;
  }
}

@media (max-width: 768px) {
  .admin-content {
    padding: 20px 16px;
  }
}
</style>
