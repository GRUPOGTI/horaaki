<script setup lang="ts">
import { computed } from 'vue'
import type { Company, SiteConfig } from '../lib/supabase'

const props = defineProps<{ company: Company | null; config: SiteConfig }>()

const defaultAboutImg = 'https://images.pexels.com/photos/7195803/pexels-photo-7195803.jpeg?auto=compress&cs=tinysrgb&w=900'
const aboutImg = computed(() => props.config.about_image || props.company?.banner_url || defaultAboutImg)
const companyName = computed(() => props.company?.name ?? 'Nadja Gomes')
const aboutImgAlt = computed(() => `Interior do ${companyName.value}`)

const features = computed(() => props.config.about_features ?? [])
const text1 = computed(() => props.config.about_text_1 ?? `O ${companyName.value} nasceu da paixão por realçar a beleza de cada cliente. Com anos de experiência, nossa equipe oferece serviços de alta qualidade em um ambiente acolhedor e sofisticado.`)
const text2 = computed(() => props.config.about_text_2 ?? 'Acreditamos que cada pessoa é única, por isso oferecemos um atendimento personalizado, escutando seus desejos e necessidades para criar o visual perfeito para você.')
const badgeNum = computed(() => props.config.about_badge_num ?? '15+')
const badgeLabel = computed(() => props.config.about_badge_label ?? 'Anos de experiência')
</script>

<template>
  <section id="sobre" class="section about-section">
    <div class="container about-container">
      <div class="about-image">
        <img :src="aboutImg" :alt="aboutImgAlt" />
        <div class="about-badge">
          <span class="badge-num">{{ badgeNum }}</span>
          <span class="badge-label" v-html="badgeLabel.replace(/\n/g, '<br>')"></span>
        </div>
      </div>

      <div class="about-content">
        <p class="about-eyebrow">{{ config.about_eyebrow ?? 'Sobre nós' }}</p>
        <h2 class="about-title"><span class="gold-text">{{ (config.about_title ?? 'Beleza e cuidado em cada detalhe').split(' ').slice(0, -1).join(' ') }}</span> {{ (config.about_title ?? 'Beleza e cuidado em cada detalhe').split(' ').slice(-1)[0] }}</h2>
        <p class="about-text">
          {{ text1 }}
        </p>
        <p class="about-text">
          {{ text2 }}
        </p>

        <div class="features-grid">
          <div v-for="f in features" :key="f.title" class="feature-item">
            <div class="feature-check">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 6L9 17l-5-5" />
              </svg>
            </div>
            <div>
              <h4 class="feature-title">{{ f.title }}</h4>
              <p class="feature-desc">{{ f.desc }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.about-section {
  background: var(--color-bg-alt);
}

.about-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 64px;
  align-items: center;
}

.about-image {
  position: relative;
}

.about-image img {
  width: 100%;
  height: 560px;
  object-fit: cover;
  border-radius: var(--radius-lg);
  border: 1px solid var(--color-border);
}

.about-badge {
  position: absolute;
  bottom: -24px;
  right: -24px;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  color: var(--color-bg);
  padding: 24px 32px;
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: var(--shadow-gold);
}

.badge-num {
  font-family: var(--font-heading);
  font-size: 3rem;
  font-weight: 700;
  line-height: 1;
}

.badge-label {
  font-size: 0.85rem;
  font-weight: 500;
  line-height: 1.3;
}

.about-eyebrow {
  color: var(--color-gold);
  font-size: 0.85rem;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  margin-bottom: 12px;
}

.about-title {
  font-size: 2.5rem;
  margin-bottom: 24px;
}

.about-text {
  color: var(--color-text-secondary);
  margin-bottom: 16px;
  font-size: 1.02rem;
}

.features-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-top: 40px;
}

.feature-item {
  display: flex;
  gap: 12px;
  align-items: flex-start;
}

.feature-check {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: rgba(212,175,55,0.15);
  border: 1px solid rgba(212,175,55,0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.feature-check svg {
  width: 14px;
  height: 14px;
  color: var(--color-gold);
}

.feature-title {
  font-family: var(--font-body);
  font-size: 0.95rem;
  font-weight: 600;
  margin-bottom: 4px;
}

.feature-desc {
  font-size: 0.85rem;
  color: var(--color-text-muted);
}

@media (max-width: 900px) {
  .about-container {
    grid-template-columns: 1fr;
    gap: 48px;
  }
  .about-image img {
    height: 360px;
  }
  .about-badge {
    bottom: -16px;
    right: 16px;
    padding: 16px 24px;
  }
  .badge-num {
    font-size: 2.2rem;
  }
  .features-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .about-title {
    font-size: 1.8rem;
  }
}
</style>
