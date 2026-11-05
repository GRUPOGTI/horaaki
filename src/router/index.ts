import { createRouter, createWebHistory } from 'vue-router'
import { useAuth } from '../composables/useAuth'
import { ACCOUNT_HOME, getAccountType, type AccountType } from '../lib/accountType'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'landing',
      component: () => import('../views/LandingView.vue'),
    },
    {
      path: '/agenda/:slug',
      name: 'agenda-publica',
      component: () => import('../views/PublicSite.vue'),
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/criar-conta',
      name: 'criar-conta',
      component: () => import('../views/CadastroView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/criar-conta-cliente',
      name: 'criar-conta-cliente',
      component: () => import('../views/ClientSignupView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/recuperar-senha',
      name: 'recuperar-senha',
      component: () => import('../views/RecuperarSenhaView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/painel',
      component: () => import('../layouts/AdminLayout.vue'),
      meta: { requiredAccount: 'system' satisfies AccountType },
      children: [
        {
          path: '',
          name: 'painel',
          component: () => import('../views/DashboardView.vue'),
        },
        {
          path: 'agenda',
          name: 'agenda',
          component: () => import('../views/AgendaView.vue'),
        },
        {
          path: 'clientes',
          name: 'clientes',
          component: () => import('../views/ClientesView.vue'),
        },
        {
          path: 'servicos',
          name: 'servicos-admin',
          component: () => import('../views/ServicosAdminView.vue'),
        },
        {
          path: 'configuracoes',
          name: 'configuracoes',
          component: () => import('../views/ConfiguracoesView.vue'),
        },
        {
          path: 'usuarios',
          name: 'usuarios',
          component: () => import('../views/UsuariosView.vue'),
        },
      ],
    },
    {
      path: '/minha-conta',
      name: 'minha-conta',
      component: () => import('../views/ClientAreaView.vue'),
      meta: { requiredAccount: 'client' satisfies AccountType },
    },
  ],
})

async function resolveAccountType(): Promise<AccountType | null> {
  try {
    return await getAccountType()
  } catch {
    return null
  }
}

router.beforeEach(async (to) => {
  const { user, loading } = useAuth()

  if (loading.value) {
    await new Promise<void>((resolve) => {
      const check = () => {
        if (!loading.value) resolve()
        else setTimeout(check, 50)
      }
      check()
    })
  }

  const requiredAccount = to.meta.requiredAccount as AccountType | undefined
  if (!requiredAccount && !to.meta.guestOnly) return

  if (!user.value) {
    return requiredAccount ? { name: 'login' } : undefined
  }

  const type = await resolveAccountType()

  if (requiredAccount) {
    if (type === requiredAccount) return
    if (type === 'system' || type === 'client') return ACCOUNT_HOME[type]
    return { name: 'login' }
  }

  if (type === 'system' || type === 'client') return ACCOUNT_HOME[type]
  return undefined
})

export default router
