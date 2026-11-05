<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth'

const router = useRouter()
const { signIn } = useAuth()

const form = reactive({
  email: '',
  password: '',
})

const errorMsg = ref('')
const loading = ref(false)

async function handleSubmit() {
  errorMsg.value = ''
  if (!form.email || !form.password) {
    errorMsg.value = 'Preencha e-mail e senha.'
    return
  }

  loading.value = true
  try {
    await signIn(form.email, form.password)
    router.push('/painel')
  } catch (err: any) {
    errorMsg.value = err.message || 'Erro ao entrar. Verifique seus dados.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <main id="main-content" class="auth-card" tabindex="-1">
      <a href="/" class="auth-logo">
        <span class="logo-mark">H</span>
        <span class="logo-name">Horaki</span>
      </a>

      <h1 class="auth-title">Entrar</h1>
      <p class="auth-subtitle">Acesse o painel da sua empresa</p>

      <form @submit.prevent="handleSubmit" class="auth-form">
        <div class="form-group">
          <label for="email">E-mail</label>
          <input
            id="email"
            v-model="form.email"
            type="email"
            placeholder="seu@email.com"
            autocomplete="email"
            required
          />
        </div>

        <div class="form-group">
          <label for="password">Senha</label>
          <input
            id="password"
            v-model="form.password"
            type="password"
            placeholder="Sua senha"
            autocomplete="current-password"
            required
          />
        </div>

        <p v-if="errorMsg" class="form-error" role="alert">{{ errorMsg }}</p>

        <button type="submit" class="btn btn-primary auth-submit" :disabled="loading">
          <span v-if="loading" class="spinner"></span>
          <span>{{ loading ? 'Entrando...' : 'Entrar' }}</span>
        </button>
      </form>

      <div class="auth-links">
        <router-link to="/criar-conta">Criar conta</router-link>
        <router-link to="/recuperar-senha">Esqueci minha senha</router-link>
      </div>

      <a href="/" class="back-link">← Voltar para o site</a>
    </main>
  </div>
</template>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: var(--color-bg);
}

.auth-card {
  width: 100%;
  max-width: 420px;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 48px 40px;
  box-shadow: var(--shadow-lg);
}

.auth-logo {
  display: flex;
  align-items: center;
  gap: 12px;
  justify-content: center;
  margin-bottom: 32px;
}

.logo-mark {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-heading);
  font-weight: 700;
  font-size: 1.6rem;
  color: var(--color-bg);
}

.logo-name {
  font-family: var(--font-heading);
  font-size: 1.4rem;
  font-weight: 600;
}

.auth-title {
  font-size: 1.5rem;
  text-align: center;
  margin-bottom: 8px;
}

.auth-subtitle {
  text-align: center;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  margin-bottom: 32px;
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
  box-shadow: 0 0 0 3px rgba(212,175,55,0.1);
}

.form-group input::placeholder {
  color: var(--color-text-muted);
}

.form-error {
  color: var(--color-error);
  font-size: 0.88rem;
  text-align: center;
  padding: 10px 14px;
  background: rgba(248,113,113,0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(248,113,113,0.2);
}

.auth-submit {
  width: 100%;
  padding: 14px;
  font-size: 1rem;
  margin-top: 4px;
}

.auth-submit:disabled {
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

.auth-links {
  display: flex;
  justify-content: space-between;
  margin-top: 24px;
  font-size: 0.88rem;
}

.auth-links a {
  color: var(--color-gold);
  transition: color var(--transition);
}

.auth-links a:hover {
  color: var(--color-gold-light);
}

.back-link {
  display: block;
  text-align: center;
  margin-top: 32px;
  font-size: 0.85rem;
  color: var(--color-text-muted);
  transition: color var(--transition);
}

.back-link:hover {
  color: var(--color-text);
}
</style>
