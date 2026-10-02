<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { supabase, type Service } from '../lib/supabase'
import { formatPrice, formatDuration } from '../lib/format'

const services = ref<Service[]>([])
const loading = ref(true)
const errorMsg = ref('')
const saving = ref(false)
const showForm = ref(false)
const editingId = ref<string | null>(null)

const emptyForm = {
  name: '',
  description: '',
  price: 0,
  duration_min: 30,
  category: 'Geral',
  icon: 'scissors',
  display_order: 0,
  active: true,
}

const form = reactive({ ...emptyForm })

const categories = ['Cabelo', 'Tratamento', 'Unhas', 'Estética', 'Geral']

const iconOptions = [
  { value: 'scissors', label: 'Tesoura' },
  { value: 'palette', label: 'Paleta' },
  { value: 'sparkles', label: 'Brilho' },
  { value: 'droplet', label: 'Gota' },
  { value: 'wind', label: 'Ventos' },
  { value: 'hand', label: 'Mão' },
  { value: 'foot', label: 'Pé' },
  { value: 'eye', label: 'Olho' },
  { value: 'brush', label: 'Pincel' },
]

const iconPaths: Record<string, string> = {
  scissors: 'M6 4l6 8 6-8M6 20l6-8 6 8M6 4a2 2 0 1 0-4 0 2 2 0 0 0 4 0zM18 4a2 2 0 1 0 4 0 2 2 0 0 0-4 0zM6 20a2 2 0 1 0-4 0 2 2 0 0 0 4 0zM18 20a2 2 0 1 0 4 0 2 2 0 0 0-4 0z',
  palette: 'M12 2a10 10 0 0 0 0 20 2 2 0 0 0 2-2v-1a2 2 0 0 1 2-2h1a4 4 0 0 0 4-4 10 10 0 0 0-9-11zM7 14a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zM12 9a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zM17 9a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3z',
  sparkles: 'M12 3l1.9 5.8L20 11l-6.1 2.2L12 19l-1.9-5.8L4 11l6.1-2.2L12 3z',
  droplet: 'M12 2.5l6 7.5a8 8 0 1 1-12 0l6-7.5z',
  wind: 'M3 8h12a3 3 0 1 0-3-3M3 12h18a3 3 0 1 1-3 3M3 16h9a3 3 0 1 0-3 3',
  hand: 'M7 11V6a1.5 1.5 0 0 1 3 0v5M10 11V4.5a1.5 1.5 0 0 1 3 0V11M13 11V6a1.5 1.5 0 0 1 3 0v6a6 6 0 0 1-6 6h-1a4 4 0 0 1-4-4v-1l3-3',
  foot: 'M8 3a2 2 0 0 0-2 2v8a3 3 0 0 0 3 3h6a4 4 0 0 0 4-4V8a2 2 0 0 0-4 0v3a1 1 0 0 1-2 0V5a2 2 0 0 0-4 0v6a1 1 0 0 1-2 0V5a2 2 0 0 0-1-2z',
  eye: 'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  brush: 'M2 20l4-4M14 4l6 6-9 9-6-6 9-9zM11 7l6 6',
}

async function loadServices() {
  loading.value = true
  const { data, error } = await supabase
    .from('services')
    .select('*')
    .order('display_order', { ascending: true })

  if (error) {
    errorMsg.value = 'Erro ao carregar serviços.'
  } else {
    services.value = data || []
  }
  loading.value = false
}

function openNewForm() {
  editingId.value = null
  Object.assign(form, emptyForm)
  showForm.value = true
  errorMsg.value = ''
}

function openEditForm(service: Service) {
  editingId.value = service.id
  Object.assign(form, {
    name: service.name,
    description: service.description || '',
    price: service.price,
    duration_min: service.duration_min,
    category: service.category,
    icon: service.icon,
    display_order: service.display_order,
    active: service.active,
  })
  showForm.value = true
  errorMsg.value = ''
}

function closeForm() {
  showForm.value = false
  editingId.value = null
}

async function handleSubmit() {
  errorMsg.value = ''
  if (!form.name.trim()) {
    errorMsg.value = 'Nome do serviço é obrigatório.'
    return
  }

  saving.value = true
  const payload = {
    name: form.name.trim(),
    description: form.description.trim() || null,
    price: Number(form.price),
    duration_min: Number(form.duration_min),
    category: form.category,
    icon: form.icon,
    display_order: Number(form.display_order),
    active: form.active,
  }

  try {
    if (editingId.value) {
      const { error } = await supabase.from('services').update(payload).eq('id', editingId.value)
      if (error) throw error
    } else {
      const { error } = await supabase.from('services').insert(payload)
      if (error) throw error
    }
    await loadServices()
    closeForm()
  } catch (err: any) {
    errorMsg.value = err.message || 'Erro ao salvar serviço.'
  } finally {
    saving.value = false
  }
}

async function handleToggleActive(service: Service) {
  const { error } = await supabase
    .from('services')
    .update({ active: !service.active })
    .eq('id', service.id)

  if (error) {
    errorMsg.value = 'Erro ao atualizar serviço.'
  } else {
    await loadServices()
  }
}

async function handleDelete(service: Service) {
  if (!confirm(`Deseja excluir o serviço "${service.name}"?`)) return
  const { error } = await supabase.from('services').delete().eq('id', service.id)
  if (error) {
    errorMsg.value = 'Erro ao excluir serviço.'
  } else {
    await loadServices()
  }
}

onMounted(loadServices)
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Serviços</h1>
        <p class="page-subtitle">Gerencie os serviços oferecidos</p>
      </div>
      <button class="btn btn-primary" @click="openNewForm">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14" /></svg>
        Novo serviço
      </button>
    </div>

    <p v-if="errorMsg" class="error-banner">{{ errorMsg }}</p>

    <div v-if="loading" class="loading-state">Carregando...</div>

    <div v-else-if="services.length === 0" class="empty-state">
      <p>Nenhum serviço cadastrado.</p>
    </div>

    <div v-else class="services-list">
      <div v-for="svc in services" :key="svc.id" class="service-row" :class="{ inactive: !svc.active }">
        <div class="service-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path :d="iconPaths[svc.icon] || iconPaths.scissors" />
          </svg>
        </div>
        <div class="service-info">
          <span class="service-name">{{ svc.name }}</span>
          <span class="service-meta">{{ svc.category }} · {{ formatDuration(svc.duration_min) }}</span>
        </div>
        <span class="service-price">{{ formatPrice(svc.price) }}</span>
        <span class="service-status" :class="svc.active ? 'active' : 'inactive'">
          {{ svc.active ? 'Ativo' : 'Inativo' }}
        </span>
        <div class="service-actions">
          <button class="action-icon" @click="openEditForm(svc)" title="Editar">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></svg>
          </button>
          <button class="action-icon" @click="handleToggleActive(svc)" :title="svc.active ? 'Desativar' : 'Ativar'">
            <svg v-if="svc.active" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24M1 1l22 22" /></svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>
          </button>
          <button class="action-icon delete" @click="handleDelete(svc)" title="Excluir">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>
          </button>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showForm" class="modal-overlay" @click="closeForm">
          <div class="modal" @click.stop>
            <div class="modal-header">
              <h3>{{ editingId ? 'Editar serviço' : 'Novo serviço' }}</h3>
              <button class="modal-close" @click="closeForm">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12" /></svg>
              </button>
            </div>

            <form @submit.prevent="handleSubmit" class="service-form">
              <div class="form-row">
                <div class="form-group">
                  <label>Nome *</label>
                  <input v-model="form.name" type="text" placeholder="Nome do serviço" required />
                </div>
                <div class="form-group">
                  <label>Categoria</label>
                  <select v-model="form.category">
                    <option v-for="cat in categories" :key="cat" :value="cat">{{ cat }}</option>
                  </select>
                </div>
              </div>

              <div class="form-group">
                <label>Descrição</label>
                <textarea v-model="form.description" rows="2" placeholder="Descrição do serviço"></textarea>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label>Preço (R$) *</label>
                  <input v-model="form.price" type="number" min="0" step="0.01" required />
                </div>
                <div class="form-group">
                  <label>Duração (min) *</label>
                  <input v-model="form.duration_min" type="number" min="1" required />
                </div>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label>Ícone</label>
                  <select v-model="form.icon">
                    <option v-for="opt in iconOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Ordem de exibição</label>
                  <input v-model="form.display_order" type="number" min="0" />
                </div>
              </div>

              <div class="form-check">
                <label>
                  <input type="checkbox" v-model="form.active" />
                  <span>Serviço ativo (visível na página pública)</span>
                </label>
              </div>

              <p v-if="errorMsg" class="form-error">{{ errorMsg }}</p>

              <div class="form-actions">
                <button type="button" class="btn btn-outline" @click="closeForm">Cancelar</button>
                <button type="submit" class="btn btn-primary" :disabled="saving">
                  {{ saving ? 'Salvando...' : 'Salvar' }}
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
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
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

.btn svg {
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

.loading-state {
  color: var(--color-text-muted);
  padding: 40px 0;
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

.services-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.service-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  transition: border-color var(--transition);
}

.service-row:hover {
  border-color: var(--color-border-light);
}

.service-row.inactive {
  opacity: 0.55;
}

.service-icon {
  width: 44px;
  height: 44px;
  border-radius: var(--radius-md);
  background: linear-gradient(135deg, rgba(212,175,55,0.15), rgba(212,175,55,0.05));
  border: 1px solid rgba(212,175,55,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.service-icon svg {
  width: 22px;
  height: 22px;
  color: var(--color-gold);
}

.service-info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.service-name {
  font-weight: 500;
  font-size: 0.95rem;
}

.service-meta {
  font-size: 0.82rem;
  color: var(--color-text-muted);
}

.service-price {
  font-family: var(--font-heading);
  font-size: 1.2rem;
  font-weight: 600;
  color: var(--color-gold);
  white-space: nowrap;
}

.service-status {
  font-size: 0.75rem;
  font-weight: 500;
  padding: 4px 12px;
  border-radius: var(--radius-full);
  white-space: nowrap;
}

.service-status.active {
  background: rgba(74,222,128,0.15);
  color: var(--color-success);
}

.service-status.inactive {
  background: rgba(248,113,113,0.15);
  color: var(--color-error);
}

.service-actions {
  display: flex;
  gap: 4px;
  flex-shrink: 0;
}

.action-icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-muted);
  transition: all var(--transition);
}

.action-icon:hover {
  background: var(--color-bg-alt);
  color: var(--color-text);
}

.action-icon.delete:hover {
  background: rgba(248,113,113,0.1);
  color: var(--color-error);
}

.action-icon svg {
  width: 18px;
  height: 18px;
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
  max-width: 520px;
  max-height: 90vh;
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

.modal-header h3 {
  font-size: 1.3rem;
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

.service-form {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  font-size: 0.82rem;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.form-group input,
.form-group select,
.form-group textarea {
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 12px 14px;
  color: var(--color-text);
  font-size: 0.92rem;
  transition: border-color var(--transition);
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: var(--color-gold);
}

.form-group textarea {
  resize: vertical;
}

.form-check label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-size: 0.9rem;
  color: var(--color-text-secondary);
}

.form-check input[type="checkbox"] {
  width: 18px;
  height: 18px;
  accent-color: var(--color-gold);
}

.form-error {
  color: var(--color-error);
  font-size: 0.88rem;
  padding: 10px 14px;
  background: rgba(248,113,113,0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(248,113,113,0.2);
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 8px;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 16px;
  }
  .form-row {
    grid-template-columns: 1fr;
  }
  .service-row {
    flex-wrap: wrap;
  }
  .service-meta {
    display: none;
  }
  .modal {
    padding: 24px 20px;
  }
}
</style>
