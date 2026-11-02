<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { supabase, type Service, type SiteConfig } from '../lib/supabase'

const props = defineProps<{ empresaId?: string | null; config?: SiteConfig }>()

const services = ref<Service[]>([])
const loading = ref(true)
const error = ref(false)
const activeCategory = ref('Todos')

const categories = computed(() => {
  const cats = new Set(services.value.map((s) => s.category))
  return ['Todos', ...Array.from(cats)]
})

const filteredServices = computed(() => {
  if (activeCategory.value === 'Todos') return services.value
  return services.value.filter((s) => s.category === activeCategory.value)
})

function formatPrice(price: number): string {
  return price.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

function formatDuration(min: number): string {
  if (min < 60) return `${min}min`
  const h = Math.floor(min / 60)
  const m = min % 60
  return m > 0 ? `${h}h${m}min` : `${h}h`
}

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

function selectService(service: Service) {
  const event = new CustomEvent('select-service', { detail: service })
  window.dispatchEvent(event)
  const el = document.querySelector('#agendar')
  if (el) el.scrollIntoView({ behavior: 'smooth' })
}

async function loadServices() {
  loading.value = true
  error.value = false
  let query = supabase
    .from('services')
    .select('*')
    .eq('active', true)
    .order('display_order', { ascending: true })

  if (props.empresaId) {
    query = query.eq('empresa_id', props.empresaId)
  }

  const { data, error: err } = await query

  if (err) {
    error.value = true
  } else {
    services.value = data || []
  }
  loading.value = false
}

onMounted(loadServices)
watch(() => props.empresaId, loadServices)
</script>

<template>
  <section id="servicos" class="section">
    <div class="container">
      <h2 class="section-title">{{ (props.config?.services_title ?? 'Nossos Serviços').split(' ').slice(0, -1).join(' ') }} <span class="gold-text">{{ (props.config?.services_title ?? 'Nossos Serviços').split(' ').slice(-1)[0] }}</span></h2>
      <p class="section-subtitle">
        {{ props.config?.services_subtitle ?? 'Oferecemos uma ampla gama de serviços de beleza com profissionais experientes e produtos de alta qualidade.' }}
      </p>

      <div v-if="loading" class="loading-grid" aria-live="polite" aria-busy="true">
        <div v-for="i in 6" :key="i" class="skeleton-card"></div>
      </div>

      <div v-else-if="error" class="error-msg" role="alert">
        Não foi possível carregar os serviços. Tente novamente mais tarde.
      </div>

      <template v-else>
        <div class="categories" role="tablist" aria-label="Filtrar serviços por categoria">
          <button
            v-for="cat in categories"
            :key="cat"
            class="category-chip"
            :class="{ active: activeCategory === cat }"
            @click="activeCategory = cat"
            role="tab"
            :aria-selected="activeCategory === cat"
            :aria-pressed="activeCategory === cat"
          >
            {{ cat }}
          </button>
        </div>

        <div class="services-grid">
          <article
            v-for="service in filteredServices"
            :key="service.id"
            class="service-card"
            tabindex="0"
            role="button"
            :aria-label="`Agendar ${service.name}`"
            @click="selectService(service)"
            @keydown.enter="selectService(service)"
            @keydown.space.prevent="selectService(service)"
          >
            <div class="service-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <path :d="iconPaths[service.icon] || iconPaths.scissors" />
              </svg>
            </div>
            <h3 class="service-name">{{ service.name }}</h3>
            <p class="service-desc">{{ service.description }}</p>
            <div class="service-meta">
              <span class="service-price">{{ formatPrice(service.price) }}</span>
              <span class="service-duration">{{ formatDuration(service.duration_min) }}</span>
            </div>
            <button class="service-btn" @click.stop="selectService(service)">Agendar</button>
          </article>
        </div>
      </template>
    </div>
  </section>
</template>

<style scoped>
.loading-grid,
.services-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
}

.skeleton-card {
  height: 260px;
  border-radius: var(--radius-lg);
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  animation: pulse 1.5s ease infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 0.8; }
}

.error-msg {
  text-align: center;
  color: var(--color-error);
  padding: 40px;
}

.categories {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: center;
  margin-bottom: 40px;
}

.category-chip {
  padding: 8px 20px;
  border-radius: var(--radius-full);
  border: 1px solid var(--color-border-light);
  color: var(--color-text-secondary);
  font-size: 0.88rem;
  transition: all var(--transition);
}

.category-chip:hover {
  border-color: var(--color-gold-muted);
  color: var(--color-text);
}

.category-chip.active {
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  color: var(--color-bg);
  border-color: transparent;
  font-weight: 500;
}

.service-card {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 32px;
  transition: all var(--transition);
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  position: relative;
  overflow: hidden;
}

.service-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: linear-gradient(90deg, var(--color-gold), transparent);
  opacity: 0;
  transition: opacity var(--transition);
}

.service-card:hover {
  transform: translateY(-6px);
  border-color: var(--color-gold-muted);
  box-shadow: var(--shadow-lg);
}

.service-card:hover::before {
  opacity: 1;
}

.service-icon {
  width: 56px;
  height: 56px;
  border-radius: var(--radius-md);
  background: linear-gradient(135deg, rgba(212,175,55,0.15), rgba(212,175,55,0.05));
  border: 1px solid rgba(212,175,55,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
}

.service-icon svg {
  width: 28px;
  height: 28px;
  color: var(--color-gold);
}

.service-name {
  font-size: 1.25rem;
  margin-bottom: 8px;
}

.service-desc {
  font-size: 0.9rem;
  color: var(--color-text-secondary);
  margin-bottom: 20px;
  flex-grow: 1;
}

.service-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  margin-bottom: 20px;
}

.service-price {
  font-family: var(--font-heading);
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--color-gold);
}

.service-duration {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  background: var(--color-bg-alt);
  padding: 4px 12px;
  border-radius: var(--radius-full);
}

.service-btn {
  width: 100%;
  padding: 12px;
  border-radius: var(--radius-md);
  background: var(--color-bg-alt);
  border: 1px solid var(--color-border-light);
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  font-weight: 500;
  transition: all var(--transition);
}

.service-card:hover .service-btn {
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  color: var(--color-bg);
  border-color: transparent;
}

@media (max-width: 768px) {
  .loading-grid,
  .services-grid {
    grid-template-columns: 1fr;
  }
}
</style>
