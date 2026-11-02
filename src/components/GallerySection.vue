<script setup lang="ts">
import { ref, onUnmounted, onMounted, nextTick } from 'vue'

const galleryImages = [
  { url: 'https://images.pexels.com/photos/7195812/pexels-photo-7195812.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Interior do salão com produtos e recepção' },
  { url: 'https://images.pexels.com/photos/7750108/pexels-photo-7750108.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Salão com cadeiras e espelhos iluminados' },
  { url: 'https://images.pexels.com/photos/8834072/pexels-photo-8834072.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Cabelereista cortando cabelo' },
  { url: 'https://images.pexels.com/photos/7195811/pexels-photo-7195811.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Cadeiras de lavagem modernas' },
  { url: 'https://images.pexels.com/photos/7750124/pexels-photo-7750124.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Salão elegante com iluminação moderna' },
  { url: 'https://images.pexels.com/photos/3993445/pexels-photo-3993445.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Estilista cortando cabelo na água' },
  { url: 'https://images.pexels.com/photos/29877719/pexels-photo-29877719.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Manicure em processo' },
  { url: 'https://images.pexels.com/photos/7750109/pexels-photo-7750109.jpeg?auto=compress&cs=tinysrgb&w=800', alt: 'Espaço chic do salão' },
]

const lightboxIndex = ref<number | null>(null)
const lightboxRef = ref<HTMLElement | null>(null)
let lastFocused: HTMLElement | null = null

function openLightbox(i: number) {
  lightboxIndex.value = i
  document.body.style.overflow = 'hidden'
  lastFocused = document.activeElement as HTMLElement
  nextTick(() => {
    const closeBtn = lightboxRef.value?.querySelector('.lightbox-close') as HTMLElement
    closeBtn?.focus()
  })
}

function closeLightbox() {
  lightboxIndex.value = null
  document.body.style.overflow = ''
  lastFocused?.focus()
}

function nextImage() {
  if (lightboxIndex.value === null) return
  lightboxIndex.value = (lightboxIndex.value + 1) % galleryImages.length
}

function prevImage() {
  if (lightboxIndex.value === null) return
  lightboxIndex.value = (lightboxIndex.value - 1 + galleryImages.length) % galleryImages.length
}

function trapFocus(e: KeyboardEvent) {
  if (lightboxIndex.value === null) return
  if (e.key === 'Escape') closeLightbox()
  if (e.key === 'ArrowRight') nextImage()
  if (e.key === 'ArrowLeft') prevImage()
  if (e.key === 'Tab' && lightboxRef.value) {
    const focusable = lightboxRef.value.querySelectorAll<HTMLElement>('button, [href], [tabindex]:not([tabindex="-1"])')
    if (focusable.length === 0) return
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault()
      first.focus()
    }
  }
}

function handleKey(e: KeyboardEvent) {
  trapFocus(e)
}

onMounted(() => window.addEventListener('keydown', handleKey))
onUnmounted(() => {
  window.removeEventListener('keydown', handleKey)
  document.body.style.overflow = ''
})
</script>

<template>
  <section id="galeria" class="section">
    <div class="container">
      <h2 class="section-title">Nossa <span class="gold-text">Galeria</span></h2>
      <p class="section-subtitle">
        Conheça nosso espaço e os momentos de transformação que criamos
        para nossas clientes.
      </p>

      <div class="gallery-grid">
        <div
          v-for="(img, i) in galleryImages"
          :key="i"
          class="gallery-item"
          :class="{ 'tall': i === 0 || i === 5 }"
          tabindex="0"
          role="button"
          :aria-label="`Ampliar imagem: ${img.alt}`"
          @click="openLightbox(i)"
          @keydown.enter="openLightbox(i)"
          @keydown.space.prevent="openLightbox(i)"
        >
          <img :src="img.url" :alt="img.alt" loading="lazy" />
          <div class="gallery-overlay" aria-hidden="true">
            <span class="gallery-zoom">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                <circle cx="11" cy="11" r="8" />
                <path d="M21 21l-4.35-4.35M11 8v6M8 11h6" />
              </svg>
            </span>
          </div>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="fade">
        <div
          v-if="lightboxIndex !== null"
          ref="lightboxRef"
          class="lightbox"
          role="dialog"
          aria-modal="true"
          aria-label="Visualização ampliada de imagem"
          @click="closeLightbox"
        >
          <button class="lightbox-close" @click.stop="closeLightbox" aria-label="Fechar visualização">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12" /></svg>
          </button>
          <button class="lightbox-nav prev" @click.stop="prevImage" aria-label="Imagem anterior">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 18l-6-6 6-6" /></svg>
          </button>
          <img
            :src="galleryImages[lightboxIndex].url"
            :alt="galleryImages[lightboxIndex].alt"
            @click.stop
          />
          <button class="lightbox-nav next" @click.stop="nextImage" aria-label="Próxima imagem">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6" /></svg>
          </button>
        </div>
      </Transition>
    </Teleport>
  </section>
</template>

<style scoped>
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-auto-rows: 200px;
  gap: 16px;
}

.gallery-item {
  position: relative;
  overflow: hidden;
  border-radius: var(--radius-md);
  cursor: pointer;
  border: 1px solid var(--color-border);
}

.gallery-item.tall {
  grid-row: span 2;
}

.gallery-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 600ms ease;
}

.gallery-item:hover img {
  transform: scale(1.1);
}

.gallery-overlay {
  position: absolute;
  inset: 0;
  background: rgba(10,10,10,0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity var(--transition);
}

.gallery-item:hover .gallery-overlay {
  opacity: 1;
}

.gallery-zoom {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: rgba(212,175,55,0.9);
  display: flex;
  align-items: center;
  justify-content: center;
}

.gallery-zoom svg {
  width: 24px;
  height: 24px;
  color: var(--color-bg);
}

.lightbox {
  position: fixed;
  inset: 0;
  z-index: 200;
  background: rgba(0,0,0,0.95);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.lightbox img {
  max-width: 90vw;
  max-height: 85vh;
  border-radius: var(--radius-md);
  object-fit: contain;
}

.lightbox-close,
.lightbox-nav {
  position: absolute;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: rgba(255,255,255,0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text);
  transition: all var(--transition);
}

.lightbox-close:hover,
.lightbox-nav:hover {
  background: rgba(212,175,55,0.3);
}

.lightbox-close {
  top: 24px;
  right: 24px;
}

.lightbox-close svg,
.lightbox-nav svg {
  width: 24px;
  height: 24px;
}

.lightbox-nav.prev {
  left: 24px;
  top: 50%;
  transform: translateY(-50%);
}

.lightbox-nav.next {
  right: 24px;
  top: 50%;
  transform: translateY(-50%);
}

@media (max-width: 768px) {
  .gallery-grid {
    grid-template-columns: repeat(2, 1fr);
    grid-auto-rows: 160px;
  }
  .lightbox {
    padding: 20px;
  }
  .lightbox-nav {
    width: 40px;
    height: 40px;
  }
  .lightbox-nav.prev {
    left: 8px;
  }
  .lightbox-nav.next {
    right: 8px;
  }
}
</style>
