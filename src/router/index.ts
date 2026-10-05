import { createRouter, createWebHistory } from 'vue-router'
import { useAuth } from '../composables/useAuth'

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
      path: '/recuperar-senha',
      name: 'recuperar-senha',
      component: () => import('../views/RecuperarSenhaView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/painel',
      component: () => import('../layouts/AdminLayout.vue'),
      meta: { requiresAuth: true },
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
  ],
})

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

  if (to.meta.requiresAuth && !user.value) {
    return { name: 'login' }
  }

  if (to.meta.guestOnly && user.value) {
    return { name: 'painel' }
  }
})

export default router
