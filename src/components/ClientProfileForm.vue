<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getMyClientProfile, updateMyClientProfile, type MyClientProfile } from '../lib/clientAccount'

const profile = ref<MyClientProfile | null>(null)
const loading = ref(true)
const loadError = ref('')
const editing = ref(false)
const saving = ref(false)
const saveError = ref('')
const successMsg = ref('')
const draft = ref({ name: '', phone: '' })

async function loadProfile() {
  loading.value = true
  loadError.value = ''
  try {
    profile.value = await getMyClientProfile()
  } catch (err: any) {
    loadError.value = err.message
  } finally {
    loading.value = false
  }
}

function startEditing() {
  if (!profile.value) return
  draft.value = { ...profile.value }
  saveError.value = ''
  successMsg.value = ''
  editing.value = true
}

function cancelEditing() {
  editing.value = false
  saveError.value = ''
}

async function saveProfile() {
  saving.value = true
  saveError.value = ''
  try {
    profile.value = await updateMyClientProfile(draft.value.name, draft.value.phone)
    editing.value = false
    successMsg.value = 'Seus dados foram atualizados.'
  } catch (err: any) {
    saveError.value = err.message
  } finally {
    saving.value = false
  }
}

onMounted(loadProfile)
</script>

<template>
  <section class="card" aria-labelledby="client-profile-title">
    <header class="card-header">
      <h2 id="client-profile-title" class="card-title">Meus dados</h2>
      <button v-if="profile && !editing" type="button" class="btn btn-outline" @click="startEditing">
        Editar dados
      </button>
    </header>

    <p v-if="loading" class="card-muted" role="status">Carregando seus dados...</p>
    <p v-else-if="loadError" class="form-error" role="alert">{{ loadError }}</p>
    <p v-else-if="!profile" class="card-muted">Não encontramos seus dados. Saia e entre novamente.</p>

    <dl v-else-if="!editing" class="profile-list">
      <div>
        <dt>Nome completo</dt>
        <dd>{{ profile.name }}</dd>
      </div>
      <div>
        <dt>Telefone / WhatsApp</dt>
        <dd>{{ profile.phone }}</dd>
      </div>
    </dl>

    <form v-else class="profile-form" @submit.prevent="saveProfile">
      <div class="form-group">
        <label for="profile-name">Nome completo *</label>
        <input id="profile-name" v-model="draft.name" type="text" autocomplete="name" required />
      </div>
      <div class="form-group">
        <label for="profile-phone">Telefone / WhatsApp *</label>
        <input id="profile-phone" v-model="draft.phone" type="tel" autocomplete="tel" required />
      </div>
      <p v-if="saveError" class="form-error" role="alert">{{ saveError }}</p>
      <div class="form-actions">
        <button type="button" class="btn btn-outline" :disabled="saving" @click="cancelEditing">Cancelar</button>
        <button type="submit" class="btn btn-primary" :disabled="saving">
          {{ saving ? 'Salvando...' : 'Salvar' }}
        </button>
      </div>
    </form>

    <p v-if="successMsg && !editing" class="form-success" role="status">{{ successMsg }}</p>
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

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.card-title {
  font-size: 1.15rem;
}

.card-muted {
  color: var(--color-text-secondary);
  font-size: 0.92rem;
}

.profile-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.profile-list dt {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.profile-list dd {
  font-size: 1rem;
  margin-top: 4px;
}

.profile-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
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
  padding: 12px 14px;
  color: var(--color-text);
  font-size: 0.95rem;
}

.form-group input:focus {
  outline: none;
  border-color: var(--color-gold);
  box-shadow: 0 0 0 3px rgba(212, 175, 55, 0.1);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  flex-wrap: wrap;
}

.form-error {
  color: var(--color-error);
  font-size: 0.9rem;
  padding: 10px 14px;
  background: rgba(248, 113, 113, 0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(248, 113, 113, 0.2);
}

.form-success {
  color: var(--color-success);
  font-size: 0.9rem;
}
</style>
