<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useAuth } from '../composables/useAuth'
import { useCompany } from '../composables/useCompany'

const { user } = useAuth()
const { company, members, loadCompanyByUser, loadMembers, inviteMember, removeMember } = useCompany()

const loading = ref(true)
const errorMsg = ref('')
const successMsg = ref('')
const actionLoading = ref(false)

const inviteForm = reactive({
  email: '',
  role: 'admin',
})

const showInviteForm = ref(false)

const roleLabels: Record<string, string> = {
  owner: 'Proprietário',
  admin: 'Administrador',
}

const roleColors: Record<string, string> = {
  owner: 'gold',
  admin: 'success',
}

async function handleInvite() {
  errorMsg.value = ''
  successMsg.value = ''

  if (!inviteForm.email.trim()) {
    errorMsg.value = 'Digite o e-mail do usuário.'
    return
  }
  if (!company.value) {
    errorMsg.value = 'Empresa não carregada.'
    return
  }

  actionLoading.value = true
  try {
    await inviteMember(company.value.id, inviteForm.email, inviteForm.role)
    successMsg.value = `Convite enviado para ${inviteForm.email}. O usuário terá acesso quando criar conta com este e-mail.`
    inviteForm.email = ''
    showInviteForm.value = false
  } catch (err: any) {
    errorMsg.value = err.message || 'Erro ao convidar usuário.'
  } finally {
    actionLoading.value = false
  }
}

async function handleRemove(memberId: string, memberEmail: string) {
  if (!confirm(`Deseja remover ${memberEmail} da empresa?`)) return
  errorMsg.value = ''
  try {
    await removeMember(memberId)
    successMsg.value = 'Usuário removido.'
  } catch (err: any) {
    errorMsg.value = 'Erro ao remover usuário.'
  }
}

onMounted(async () => {
  await loadCompanyByUser()
  if (company.value) {
    await loadMembers(company.value.id)
  }
  loading.value = false
})
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Usuários</h1>
        <p class="page-subtitle">Gerencie quem tem acesso ao painel da empresa</p>
      </div>
      <button v-if="company" class="btn btn-primary" @click="showInviteForm = !showInviteForm">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14" /></svg>
        Convidar usuário
      </button>
    </div>

    <div v-if="loading" class="loading-state">Carregando...</div>

    <template v-else>
      <p v-if="errorMsg" class="error-banner">{{ errorMsg }}</p>
      <p v-if="successMsg" class="success-banner">{{ successMsg }}</p>

      <div v-if="showInviteForm" class="invite-panel">
        <h3 class="invite-title">Convidar novo administrador</h3>
        <p class="invite-desc">O usuário convidado deve criar uma conta no Horaki usando o mesmo e-mail para ter acesso à empresa.</p>
        <form @submit.prevent="handleInvite" class="invite-form">
          <div class="invite-row">
            <input v-model="inviteForm.email" type="email" placeholder="e-mail do novo administrador" required />
            <select v-model="inviteForm.role">
              <option value="admin">Administrador</option>
            </select>
            <button type="submit" class="btn btn-primary" :disabled="actionLoading">
              {{ actionLoading ? 'Enviando...' : 'Enviar convite' }}
            </button>
          </div>
        </form>
      </div>

      <div v-if="!company" class="empty-state">
        <p>Você precisa configurar sua empresa primeiro. Vá em Configurações.</p>
      </div>

      <div v-else-if="members.length === 0" class="empty-state">
        <p>Nenhum usuário vinculado à empresa além de você.</p>
      </div>

      <div v-else class="members-list">
        <div v-for="m in members" :key="m.id" class="member-row">
          <div class="member-avatar">
            {{ (m.invited_email || user?.email || '?').charAt(0).toUpperCase() }}
          </div>
          <div class="member-info">
            <span class="member-email">{{ m.invited_email || (m.user_id === user?.id ? user?.email : 'Usuário') }}</span>
            <span class="member-meta">Vinculado em {{ new Date(m.created_at).toLocaleDateString('pt-BR') }}</span>
          </div>
          <span class="role-badge" :class="`role-${roleColors[m.role] || 'success'}`">
            {{ roleLabels[m.role] || m.role }}
          </span>
          <button
            v-if="m.role !== 'owner' && m.user_id !== user?.id"
            class="action-remove"
            @click="handleRemove(m.id, m.invited_email || 'este usuário')"
            title="Remover"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6" /></svg>
          </button>
          <span v-else class="you-badge">Você</span>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.page {
  max-width: 800px;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
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

.loading-state {
  color: var(--color-text-muted);
  padding: 40px 0;
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

.invite-panel {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 24px;
  margin-bottom: 24px;
}

.invite-title {
  font-family: var(--font-body);
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 8px;
}

.invite-desc {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  margin-bottom: 16px;
}

.invite-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.invite-row {
  display: flex;
  gap: 12px;
  align-items: stretch;
}

.invite-row input {
  flex: 1;
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 10px 14px;
  color: var(--color-text);
  font-size: 0.9rem;
}

.invite-row input:focus {
  outline: none;
  border-color: var(--color-gold);
}

.invite-row select {
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  padding: 10px 14px;
  color: var(--color-text);
  font-size: 0.85rem;
  cursor: pointer;
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

.members-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.member-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  transition: border-color var(--transition);
}

.member-row:hover {
  border-color: var(--color-border-light);
}

.member-avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: var(--color-bg);
  flex-shrink: 0;
  font-size: 1.1rem;
}

.member-info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.member-email {
  font-weight: 500;
  font-size: 0.95rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.member-meta {
  font-size: 0.78rem;
  color: var(--color-text-muted);
}

.role-badge {
  font-size: 0.75rem;
  font-weight: 500;
  padding: 4px 12px;
  border-radius: var(--radius-full);
  white-space: nowrap;
  flex-shrink: 0;
}

.role-gold { background: rgba(212,175,55,0.15); color: var(--color-gold); }
.role-success { background: rgba(74,222,128,0.15); color: var(--color-success); }

.action-remove {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-muted);
  transition: all var(--transition);
  flex-shrink: 0;
}

.action-remove:hover {
  background: rgba(248,113,113,0.1);
  color: var(--color-error);
}

.action-remove svg {
  width: 18px;
  height: 18px;
}

.you-badge {
  font-size: 0.72rem;
  color: var(--color-text-muted);
  padding: 4px 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-full);
  white-space: nowrap;
  flex-shrink: 0;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
  }
  .invite-row {
    flex-direction: column;
  }
  .member-row {
    flex-wrap: wrap;
  }
  .member-meta {
    display: none;
  }
}
</style>
