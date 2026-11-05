<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useCompany } from '../composables/useCompany'
import { getSiteConfig, applyCompanyTheme } from '../lib/siteConfig'
import SiteHeader from '../components/SiteHeader.vue'
import HeroSection from '../components/HeroSection.vue'
import ServicesSection from '../components/ServicesSection.vue'
import GallerySection from '../components/GallerySection.vue'
import AboutSection from '../components/AboutSection.vue'
import BookingSection from '../components/BookingSection.vue'
import ContactSection from '../components/ContactSection.vue'
import SiteFooter from '../components/SiteFooter.vue'

const route = useRoute()
const { loadCompanyBySlug, company, companyLoading } = useCompany()

const notFound = ref(false)

async function load() {
  const slug = route.params.slug as string
  if (!slug) {
    notFound.value = true
    return
  }
  notFound.value = false
  const data = await loadCompanyBySlug(slug)
  if (!data) notFound.value = true
}

load()
watch(() => route.params.slug, load)

const displayCompany = computed(() => company.value)
const empresaId = computed(() => company.value?.id ?? null)
const siteConfig = computed(() => getSiteConfig(company.value))

watch(
  displayCompany,
  (c) => {
    applyCompanyTheme(c?.primary_color ?? null)
  },
  { immediate: true }
)
</script>

<template>
  <div v-if="companyLoading" class="page-loading" aria-live="polite" aria-busy="true">
    <div class="spinner-lg"></div>
    <p>Carregando...</p>
  </div>

  <div v-else-if="notFound" class="not-found">
    <div class="not-found-card">
      <h1>Empresa não encontrada</h1>
      <p>O link que você acessou não corresponde a nenhuma empresa cadastrada.</p>
      <a href="/" class="btn btn-primary">Voltar ao início</a>
    </div>
  </div>

  <template v-else-if="displayCompany">
    <SiteHeader :company="displayCompany" />
    <main id="main-content" tabindex="-1">
      <HeroSection :company="displayCompany" :config="siteConfig" />
      <ServicesSection :empresa-id="empresaId" :config="siteConfig" />
      <GallerySection :config="siteConfig" />
      <AboutSection :company="displayCompany" :config="siteConfig" />
      <BookingSection :empresa-id="empresaId" :config="siteConfig" />
      <ContactSection :company="displayCompany" :config="siteConfig" />
    </main>
    <SiteFooter :company="displayCompany" />
  </template>
</template>

<style scoped>
main {
  min-height: 100vh;
}

.page-loading {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 24px;
  color: var(--color-text-secondary);
}

.spinner-lg {
  width: 48px;
  height: 48px;
  border: 3px solid var(--color-border);
  border-top-color: var(--color-gold);
  border-radius: 50%;
  animation: spin 800ms linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.not-found {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.not-found-card {
  text-align: center;
  max-width: 440px;
}

.not-found-card h1 {
  font-size: 2rem;
  margin-bottom: 16px;
}

.not-found-card p {
  color: var(--color-text-secondary);
  margin-bottom: 32px;
}
</style>
