<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth'
import ClientProfileForm from '../components/ClientProfileForm.vue'
import ClientBookingsList from '../components/ClientBookingsList.vue'

const router = useRouter()
const { signOut } = useAuth()

async function handleSignOut() {
  await signOut()
  router.push('/login')
}
</script>

<template>
  <div class="client-area">
    <header class="client-header">
      <div class="client-header-inner">
        <a href="/" class="brand" aria-label="Horaki - início">
          <span class="brand-mark" aria-hidden="true">H</span>
          <span class="brand-name">Horaki</span>
        </a>
        <button type="button" class="btn btn-outline" @click="handleSignOut">Sair</button>
      </div>
    </header>

    <main id="main-content" class="client-main" tabindex="-1">
      <h1 class="client-title">Minha área</h1>
      <p class="client-subtitle">Gerencie seus dados e acompanhe seus agendamentos.</p>

      <div class="client-sections">
        <ClientProfileForm />
        <ClientBookingsList />
      </div>
    </main>
  </div>
</template>

<style scoped>
.client-area {
  min-height: 100vh;
  background: var(--color-bg);
}

.client-header {
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg-card);
}

.client-header-inner {
  max-width: 880px;
  margin: 0 auto;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
}

.brand-mark {
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
}

.brand-name {
  font-family: var(--font-heading);
  font-size: 1.3rem;
  font-weight: 600;
}

.client-main {
  max-width: 880px;
  margin: 0 auto;
  padding: 48px 24px;
}

.client-main:focus {
  outline: none;
}

.client-title {
  font-size: 1.75rem;
  margin-bottom: 8px;
}

.client-subtitle {
  color: var(--color-text-secondary);
  margin-bottom: 32px;
}

.client-sections {
  display: flex;
  flex-direction: column;
  gap: 24px;
}
</style>
