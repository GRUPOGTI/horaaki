<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import type { Company } from '../lib/supabase'

const props = defineProps<{ company: Company | null }>()

const companyName = computed(() => props.company?.name ?? 'Nadja Gomes')
const companyInitial = computed(() => (props.company?.name ?? 'N').charAt(0).toUpperCase())

const scrolled = ref(false)
const mobileMenuOpen = ref(false)

const navLinks = [
  { label: 'Início', href: '#home' },
  { label: 'Serviços', href: '#servicos' },
  { label: 'Galeria', href: '#galeria' },
  { label: 'Sobre', href: '#sobre' },
  { label: 'Contato', href: '#contato' },
]

function handleScroll() {
  scrolled.value = window.scrollY > 40
}

function scrollTo(href: string) {
  mobileMenuOpen.value = false
  const el = document.querySelector(href)
  if (el) {
    el.setAttribute('tabindex', '-1')
    ;(el as HTMLElement).focus({ preventScroll: true })
    el.scrollIntoView({ behavior: 'smooth' })
  }
}

onMounted(() => window.addEventListener('scroll', handleScroll))
onUnmounted(() => window.removeEventListener('scroll', handleScroll))
</script>

<template>
  <header class="header" :class="{ scrolled }" @keydown.esc="mobileMenuOpen = false">
    <div class="container header-inner">
      <a href="#home" class="logo" @click.prevent="scrollTo('#home')">
        <span class="logo-mark">{{ companyInitial }}</span>
        <span class="logo-text">
          <span class="logo-name">{{ companyName }}</span>
          <span class="logo-tag">Salão de Beleza</span>
        </span>
      </a>

      <nav class="nav-desktop" aria-label="Navegação principal">
        <a
          v-for="link in navLinks"
          :key="link.href"
          :href="link.href"
          @click.prevent="scrollTo(link.href)"
        >
          {{ link.label }}
        </a>
      </nav>

      <button class="btn btn-primary btn-agendar" @click="scrollTo('#agendar')">
        Agendar
      </button>

      <button
        class="menu-toggle"
        @click="mobileMenuOpen = !mobileMenuOpen"
        :aria-expanded="mobileMenuOpen"
        :aria-controls="'mobile-menu'"
        :aria-label="mobileMenuOpen ? 'Fechar menu de navegação' : 'Abrir menu de navegação'"
      >
        <span :class="{ open: mobileMenuOpen }"></span>
      </button>
    </div>

    <Transition name="fade">
      <nav v-if="mobileMenuOpen" id="mobile-menu" class="nav-mobile" aria-label="Navegação mobile">
        <a
          v-for="link in navLinks"
          :key="link.href"
          :href="link.href"
          @click.prevent="scrollTo(link.href)"
        >
          {{ link.label }}
        </a>
        <button class="btn btn-primary" @click="scrollTo('#agendar')">Agendar Horário</button>
      </nav>
    </Transition>
  </header>
</template>

<style scoped>
.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  transition: all var(--transition);
  padding: 16px 0;
}

.header.scrolled {
  background: rgba(10, 10, 10, 0.92);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--color-border);
  padding: 10px 0;
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-mark {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-heading);
  font-weight: 700;
  font-size: 1.5rem;
  color: var(--color-bg);
  flex-shrink: 0;
}

.logo-text {
  display: flex;
  flex-direction: column;
  line-height: 1.1;
}

.logo-name {
  font-family: var(--font-heading);
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text);
}

.logo-tag {
  font-size: 0.72rem;
  color: var(--color-text-muted);
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.nav-desktop {
  display: flex;
  gap: 32px;
}

.nav-desktop a {
  font-size: 0.95rem;
  color: var(--color-text-secondary);
  transition: color var(--transition);
  position: relative;
}

.nav-desktop a::after {
  content: '';
  position: absolute;
  bottom: -4px;
  left: 0;
  width: 0;
  height: 2px;
  background: var(--color-gold);
  transition: width var(--transition);
}

.nav-desktop a:hover {
  color: var(--color-text);
}

.nav-desktop a:hover::after {
  width: 100%;
}

.btn-agendar {
  padding: 10px 24px;
  font-size: 0.9rem;
}

.menu-toggle {
  display: none;
  width: 40px;
  height: 40px;
  position: relative;
}

.menu-toggle span,
.menu-toggle span::before,
.menu-toggle span::after {
  content: '';
  position: absolute;
  width: 24px;
  height: 2px;
  background: var(--color-text);
  border-radius: 2px;
  transition: all var(--transition);
}

.menu-toggle span {
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.menu-toggle span::before {
  top: -8px;
}

.menu-toggle span::after {
  top: 8px;
}

.menu-toggle span.open {
  background: transparent;
}

.menu-toggle span.open::before {
  top: 0;
  transform: rotate(45deg);
}

.menu-toggle span.open::after {
  top: 0;
  transform: rotate(-45deg);
}

.nav-mobile {
  display: none;
  flex-direction: column;
  gap: 4px;
  padding: 16px 24px 24px;
  background: rgba(10, 10, 10, 0.98);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--color-border);
}

.nav-mobile a {
  padding: 14px 0;
  font-size: 1.05rem;
  color: var(--color-text-secondary);
  border-bottom: 1px solid var(--color-border);
  transition: color var(--transition);
}

.nav-mobile a:hover {
  color: var(--color-gold);
}

.nav-mobile .btn {
  margin-top: 16px;
}

@media (max-width: 900px) {
  .nav-desktop,
  .btn-agendar {
    display: none;
  }
  .menu-toggle {
    display: block;
  }
  .nav-mobile {
    display: flex;
  }
}
</style>
