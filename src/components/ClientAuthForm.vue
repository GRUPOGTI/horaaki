<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import {
  signUpClient,
  signInClient,
  signOutClient,
  linkClientAccount,
  type ClientProfile,
} from '../lib/clientAccount'

const props = defineProps<{ empresaId: string }>()
const emit = defineEmits<{ authenticated: [profile: ClientProfile] }>()

const mode = ref<'login' | 'signup'>('login')
const loading = ref(false)
const error = ref('')
const form = ref({ name: '', phone: '', email: '', password: '' })

function setMode(next: 'login' | 'signup') {
  mode.value = next
  error.value = ''
}

async function handleSubmit() {
  error.value = ''
  loading.value = true
  try {
    if (mode.value === 'signup') {
      await signUpClient(form.value)
    } else {
      await signInClient(form.value.email, form.value.password)
    }

    const { data } = await supabase.auth.getSession()
    if (!data.session) throw new Error('Confirme seu e-mail para continuar.')

    const profile = await linkClientAccount(props.empresaId)
    emit('authenticated', profile)
  } catch (cause) {
    error.value = (cause as Error).message
    await signOutClient().catch(() => undefined)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="client-auth">
    <div class="auth-tabs" role="group" aria-label="Acesso do cliente">
      <button type="button" class="auth-tab" :aria-pressed="mode === 'login'" @click="setMode('login')">
        Entrar
      </button>
      <button type="button" class="auth-tab" :aria-pressed="mode === 'signup'" @click="setMode('signup')">
        Criar conta
      </button>
    </div>

    <p class="auth-intro">
      {{ mode === 'login'
        ? 'Entre na sua conta para solicitar um agendamento.'
        : 'Crie sua conta de cliente para agendar. Leva menos de um minuto.' }}
    </p>

    <form class="auth-form" @submit.prevent="handleSubmit">
      <template v-if="mode === 'signup'">
        <div class="form-group">
          <label for="client-auth-name">Nome completo *</label>
          <input id="client-auth-name" v-model="form.name" type="text" autocomplete="name" required />
        </div>
        <div class="form-group">
          <label for="client-auth-phone">Telefone / WhatsApp *</label>
          <input id="client-auth-phone" v-model="form.phone" type="tel" autocomplete="tel" placeholder="(00) 00000-0000" required />
        </div>
      </template>

      <div class="form-group">
        <label for="client-auth-email">E-mail *</label>
        <input id="client-auth-email" v-model="form.email" type="email" autocomplete="email" required />
      </div>

      <div class="form-group">
        <label for="client-auth-password">Senha *</label>
        <input
          id="client-auth-password"
          v-model="form.password"
          type="password"
          :autocomplete="mode === 'signup' ? 'new-password' : 'current-password'"
          minlength="6"
          required
        />
      </div>

      <p v-if="error" class="form-error" role="alert">{{ error }}</p>

      <button type="submit" class="btn btn-primary auth-submit" :disabled="loading">
        <span v-if="loading" class="spinner"></span>
        <span>{{ loading ? 'Aguarde...' : mode === 'login' ? 'Entrar' : 'Criar conta' }}</span>
      </button>
    </form>
  </div>
</template>

<style scoped>
.client-auth {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.auth-tabs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  padding: 4px;
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.auth-tab {
  padding: 12px;
  border-radius: var(--radius-sm);
  color: var(--color-text-secondary);
  transition: background var(--transition), color var(--transition);
}

.auth-tab[aria-pressed='true'] {
  background: var(--color-bg-card);
  color: var(--color-text);
  box-shadow: var(--shadow-sm);
}

.auth-intro {
  color: var(--color-text-secondary);
  font-size: 0.95rem;
  text-align: center;
}

.auth-form {
  display: flex;
  flex-direction: column;
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

.form-group input {
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 14px 16px;
  color: var(--color-text);
  font-size: 0.95rem;
  transition: border-color var(--transition);
}

.form-group input:focus {
  outline: none;
  border-color: var(--color-gold);
  box-shadow: 0 0 0 3px rgba(212, 175, 55, 0.1);
}

.form-error {
  color: var(--color-error);
  font-size: 0.9rem;
  text-align: center;
  padding: 12px;
  background: rgba(248, 113, 113, 0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(248, 113, 113, 0.2);
}

.auth-submit {
  width: 100%;
  padding: 16px;
  font-size: 1rem;
}

.auth-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid rgba(10, 10, 10, 0.3);
  border-top-color: var(--color-bg);
  border-radius: 50%;
  animation: spin 600ms linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
