<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useAuth } from '../composables/useAuth'
import AgendaQrCode from '../components/AgendaQrCode.vue'
import { useCompany } from '../composables/useCompany'
import { useBookings } from '../composables/useBookings'

const { user } = useAuth()
const { company, companyLoading, loadCompanyByUser, createCompany, updateCompany } = useCompany()
const { loadBookings } = useBookings()

const saving = ref(false)
const errorMsg = ref('')
const successMsg = ref('')
const noCompany = ref(false)

const form = reactive({
  name: '',
  slug: '',
  description: '',
  logo_url: '',
  banner_url: '',
  primary_color: '#d4af37',
  whatsapp: '',
  email: '',
  address: '',
  hours: '',
  is_open: true,
  instagram_url: '',
  facebook_url: '',
  tiktok_url: '',
})

function fillForm(c: typeof form & { [key: string]: any }) {
  form.name = c.name || ''
  form.slug = c.slug || ''
  form.description = c.description || ''
  form.logo_url = c.logo_url || ''
  form.banner_url = c.banner_url || ''
  form.primary_color = c.primary_color || '#d4af37'
  form.whatsapp = c.whatsapp || ''
  form.email = c.email || ''
  form.address = c.address || ''
  form.hours = c.hours || ''
  form.is_open = c.is_open ?? true
  form.instagram_url = c.instagram_url || ''
  form.facebook_url = c.facebook_url || ''
  form.tiktok_url = c.tiktok_url || ''
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function onNameChange() {
  if (!company.value) {
    form.slug = slugify(form.name)
  }
}

const bookingLink = ref('')
function updateBookingLink() {
  bookingLink.value = `/agenda/${form.slug || 'sua-empresa'}`
}

const copied = ref(false)
function copyLink() {
  const fullUrl = window.location.origin + bookingLink.value
  navigator.clipboard.writeText(fullUrl).then(() => {
    copied.value = true
    setTimeout(() => (copied.value = false), 2000)
  })
}

const publicUrl = computed(() => `${window.location.origin}/agenda/${company.value?.slug ?? ''}`)

function openPublicPage() {
  if (form.slug) window.open(`/agenda/${form.slug}`, '_blank')
}

async function handleSubmit() {
  errorMsg.value = ''
  successMsg.value = ''

  if (!form.name.trim()) {
    errorMsg.value = 'O nome da empresa é obrigatório.'
    return
  }
  if (!form.slug.trim()) {
    errorMsg.value = 'O slug (link público) é obrigatório.'
    return
  }

  saving.value = true
  try {
    const payload = {
      name: form.name.trim(),
      slug: slugify(form.slug),
      description: form.description.trim() || null,
      logo_url: form.logo_url.trim() || null,
      banner_url: form.banner_url.trim() || null,
      primary_color: form.primary_color,
      whatsapp: form.whatsapp.trim() || null,
      email: form.email.trim() || null,
      address: form.address.trim() || null,
      hours: form.hours.trim() || null,
      is_open: form.is_open,
      instagram_url: form.instagram_url.trim() || null,
      facebook_url: form.facebook_url.trim() || null,
      tiktok_url: form.tiktok_url.trim() || null,
    }

    if (company.value) {
      await updateCompany(company.value.id, payload)
      successMsg.value = 'Configurações salvas com sucesso.'
    } else {
      await createCompany(payload)
      successMsg.value = 'Empresa criada com sucesso.'
      noCompany.value = false
    }
    updateBookingLink()
    await loadBookings(company.value?.id)
  } catch (err: any) {
    errorMsg.value = err.message || 'Erro ao salvar configurações.'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await loadCompanyByUser()
  if (company.value) {
    fillForm(company.value as any)
  } else {
    noCompany.value = true
    form.email = user.value?.email || ''
  }
  updateBookingLink()
})
</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1 class="page-title">Configurações</h1>
      <p class="page-subtitle">Personalize a página pública do seu estabelecimento</p>
    </div>

    <div v-if="companyLoading" class="loading-state">Carregando...</div>

    <template v-else>
      <div v-if="noCompany" class="info-banner">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10" /><path d="M12 16v-4M12 8h.01" /></svg>
        <span>Você ainda não configurou sua empresa. Preencha os dados abaixo para criar sua página pública.</span>
      </div>

      <p v-if="errorMsg" class="error-banner">{{ errorMsg }}</p>
      <p v-if="successMsg" class="success-banner">{{ successMsg }}</p>

      <form @submit.prevent="handleSubmit" class="config-form">
        <!-- Identidade -->
        <div class="config-panel">
          <h3 class="panel-title">Identidade da empresa</h3>

          <div class="form-group">
            <label>Nome da empresa *</label>
            <input v-model="form.name" type="text" placeholder="Ex: Salão Nadja Gomes" required @input="onNameChange" />
          </div>

          <div class="form-group">
            <label>Link público (slug) *</label>
            <div class="slug-input">
              <span class="slug-prefix">/agenda/</span>
              <input v-model="form.slug" type="text" placeholder="sua-empresa" required @input="updateBookingLink" />
            </div>
            <div class="link-preview">
              <span>{{ bookingLink }}</span>
              <button type="button" class="btn-sm" @click="copyLink">{{ copied ? 'Copiado!' : 'Copiar' }}</button>
              <button type="button" class="btn-sm btn-sm-gold" v-if="form.slug" @click="openPublicPage">Abrir página</button>
            </div>
          </div>

          <AgendaQrCode v-if="company?.slug" :url="publicUrl" file-name="qr-code-agenda.png" />

          <div class="form-group">
            <label>Descrição</label>
            <textarea v-model="form.description" rows="3" placeholder="Descreva seu estabelecimento..."></textarea>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>URL do logo</label>
              <input v-model="form.logo_url" type="text" placeholder="https://... (deixe vazio para usar a inicial do nome)" />
            </div>
            <div class="form-group">
              <label>URL do banner (hero)</label>
              <input v-model="form.banner_url" type="text" placeholder="https://... (imagem de destaque)" />
            </div>
          </div>

          <div class="form-group">
            <label>Cor principal da marca</label>
            <div class="color-row">
              <input v-model="form.primary_color" type="color" class="color-picker" />
              <input v-model="form.primary_color" type="text" class="color-text" />
            </div>
          </div>
        </div>

        <!-- Contato -->
        <div class="config-panel">
          <h3 class="panel-title">Contato e localização</h3>

          <div class="form-row">
            <div class="form-group">
              <label>WhatsApp / Telefone</label>
              <input v-model="form.whatsapp" type="text" placeholder="(00) 00000-0000" />
            </div>
            <div class="form-group">
              <label>E-mail</label>
              <input v-model="form.email" type="email" placeholder="contato@suaempresa.com" />
            </div>
          </div>

          <div class="form-group">
            <label>Endereço</label>
            <input v-model="form.address" type="text" placeholder="Rua, número, bairro, cidade" />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Horário de funcionamento</label>
              <input v-model="form.hours" type="text" placeholder="Seg–Sáb: 08h às 19h" />
            </div>
            <div class="form-group">
              <label>Status</label>
              <div class="toggle-row">
                <label class="toggle-label">
                  <input type="checkbox" v-model="form.is_open" />
                  <span>{{ form.is_open ? 'Aberto' : 'Fechado' }}</span>
                </label>
              </div>
            </div>
          </div>
        </div>

        <!-- Redes sociais -->
        <div class="config-panel">
          <h3 class="panel-title">Redes sociais</h3>

          <div class="form-group">
            <label>Instagram</label>
            <input v-model="form.instagram_url" type="text" placeholder="https://instagram.com/suaempresa" />
          </div>

          <div class="form-group">
            <label>Facebook</label>
            <input v-model="form.facebook_url" type="text" placeholder="https://facebook.com/suaempresa" />
          </div>

          <div class="form-group">
            <label>TikTok</label>
            <input v-model="form.tiktok_url" type="text" placeholder="https://tiktok.com/@suaempresa" />
          </div>
        </div>

        <!-- Conta -->
        <div class="config-panel">
          <h3 class="panel-title">Conta</h3>
          <div class="config-list">
            <div class="config-item">
              <span class="config-label">E-mail de acesso</span>
              <span class="config-value">{{ user?.email ?? '—' }}</span>
            </div>
            <div class="config-item">
              <span class="config-label">Plano</span>
              <span class="config-value">
                <span class="plan-badge">Gratuito</span>
              </span>
            </div>
          </div>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn btn-primary" :disabled="saving">
            {{ saving ? 'Salvando...' : (noCompany ? 'Criar empresa' : 'Salvar alterações') }}
          </button>
        </div>
      </form>
    </template>
  </div>
</template>

<style scoped>
.page {
  max-width: 800px;
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

.info-banner {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: rgba(96,165,250,0.1);
  border: 1px solid rgba(96,165,250,0.2);
  border-radius: var(--radius-md);
  color: #60a5fa;
  font-size: 0.9rem;
  margin-bottom: 24px;
}

.info-banner svg {
  width: 22px;
  height: 22px;
  flex-shrink: 0;
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

.success-banner {
  color: var(--color-success);
  font-size: 0.9rem;
  padding: 12px 16px;
  background: rgba(74,222,128,0.1);
  border-radius: var(--radius-md);
  border: 1px solid rgba(74,222,128,0.2);
  margin-bottom: 20px;
}

.config-form {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.config-panel {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 24px;
}

.panel-title {
  font-family: var(--font-body);
  font-size: 0.9rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text-secondary);
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--color-border);
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 18px;
}

.form-group:last-child {
  margin-bottom: 0;
}

.form-group label {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.form-group input,
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
.form-group textarea:focus {
  outline: none;
  border-color: var(--color-gold);
}

.form-group textarea {
  resize: vertical;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.slug-input {
  display: flex;
  align-items: stretch;
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  overflow: hidden;
  background: var(--color-bg-alt);
}

.slug-prefix {
  padding: 12px 14px;
  color: var(--color-text-muted);
  font-size: 0.88rem;
  background: var(--color-bg);
  border-right: 1px solid var(--color-border);
  white-space: nowrap;
}

.slug-input input {
  border: none;
  border-radius: 0;
  flex: 1;
}

.link-preview {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 8px;
}

.link-preview span {
  font-size: 0.82rem;
  color: var(--color-gold);
  font-family: 'Courier New', monospace;
}

.btn-sm {
  padding: 5px 12px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border-light);
  color: var(--color-text-secondary);
  font-size: 0.78rem;
  transition: all var(--transition);
}

.btn-sm:hover {
  border-color: var(--color-gold-muted);
  color: var(--color-text);
}

.btn-sm-gold {
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  color: var(--color-bg);
  border-color: transparent;
}

.color-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.color-picker {
  width: 48px;
  height: 40px;
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  cursor: pointer;
  background: var(--color-bg-alt);
  padding: 4px;
}

.color-text {
  width: 120px;
}

.toggle-row {
  display: flex;
  align-items: center;
  height: 42px;
}

.toggle-label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-size: 0.92rem;
  color: var(--color-text);
}

.toggle-label input[type="checkbox"] {
  width: 20px;
  height: 20px;
  accent-color: var(--color-gold);
}

.config-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.config-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.config-label {
  font-size: 0.78rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.config-value {
  font-size: 0.95rem;
  color: var(--color-text);
}

.plan-badge {
  display: inline-block;
  background: linear-gradient(135deg, rgba(212,175,55,0.2), rgba(212,175,55,0.05));
  border: 1px solid rgba(212,175,55,0.3);
  color: var(--color-gold);
  padding: 3px 12px;
  border-radius: var(--radius-full);
  font-size: 0.82rem;
  font-weight: 500;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
