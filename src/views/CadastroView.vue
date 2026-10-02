<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth'

const router = useRouter()
const { signIn, signUp } = useAuth()

const form = reactive({
  name: '',
  email: '',
  password: '',
  confirmPassword: '',
})

const errorMsg = ref('')
const loading = ref(false)

async function handleSubmit() {
  errorMsg.value = ''

  if (!form.name.trim() || !form.email.trim() || !form.password || !form.confirmPassword) {
    errorMsg.value = 'Preencha todos os campos.'
    return
  }

  if (form.password.length < 6) {
    errorMsg.value = 'A senha deve ter no mínimo 6 caracteres.'
    return
  }

  if (form.password !== form.confirmPassword) {
    errorMsg.value = 'As senhas não coincidem.'
    return
  }

  loading.value = true
  try {
    await signUp(form.email.trim(), form.password)
    await signIn(form.email.trim(), form.password)
    router.push('/painel')
  } catch (err: any) {
    errorMsg.value = err.message || 'Erro ao criar conta. Tente novamente.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-card">
      <a href="/" class="auth-logo">
        <span class="logo-mark">A</span>
        <span class="logo-name">Agendaki</span>
      </a>

      <h1 class="auth-title">Criar Conta</h1>
      <p class="auth-subtitle">Cadastre sua empresa no Agendaki</p>

      <form @submit.prevent="handleSubmit" class="auth-form">
        <div class="form-group">
          <label for="name">Nome</label>
          <input
            id="name"
            v-model="form.name"
            type="text"
            placeholder="Seu nome completo"
            autocomplete="name"
            required
          />
        </div>

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
            placeholder="Mínimo 6 caracteres"
            autocomplete="new-password"
            required
          />
        </div>

        <div class="form-group">
          <label for="confirmPassword">Confirmar senha</label>
          <input
            id="confirmPassword"
            v-model="form.confirmPassword"
            type="password"
            placeholder="Repita a senha"
            autocomplete="new-password"
            required
          />
        </div>

        <p v-if="errorMsg" class="form-error">{{ errorMsg }}</p>

        <button type="submit" class="btn btn-primary auth-submit" :disabled="loading">
          <span v-if="loading" class="spinner"></span>
          <span>{{ loading ? 'Criando...' : 'Criar conta' }}</span>
        </button>
      </form>

      <div class="auth-links-center">
        <router-link to="/login">Já tenho uma conta</router-link>
      </div>

      <a href="/" class="back-link">← Voltar para o site</a>
    </div>
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
  max-width: 440px;
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

.auth-links-center {
  text-align: center;
  margin-top: 24px;
  font-size: 0.88rem;
}

.auth-links-center a {
  color: var(--color-gold);
  transition: color var(--transition);
}

.auth-links-center a:hover {
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
