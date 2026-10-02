<script setup lang="ts">
const contactInfo = [
  {
    icon: 'M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.36 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.34 1.85.573 2.81.7A2 2 0 0 1 22 16.92z',
    label: 'Telefone',
    value: '(75) 99999-9999',
    href: 'tel:+75999999999',
  },
  {
    icon: 'M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0zM12 13a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
    label: 'Endereço',
    value: 'Rua das Flores, 123 — Centro, Cidade/BA',
    href: 'https://maps.google.com',
  },
  {
    icon: 'M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM22 7l-10 5L2 7',
    label: 'E-mail',
    value: 'contato@salonadjagomes.com.br',
    href: 'mailto:contato@salonadjagomes.com.br',
  },
  {
    icon: 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zM12 6v6l4 2',
    label: 'Horário',
    value: 'Seg–Sáb: 08h às 19h',
    href: '',
  },
]

const socialLinks = [
  { name: 'Instagram', icon: 'M12 2.16c3.2 0 3.58.01 4.85.07 1.17.05 1.8.25 2.23.41.56.22.96.48 1.38.9.42.42.68.82.9 1.38.16.42.36 1.06.41 2.23.06 1.27.07 1.65.07 4.85s-.01 3.58-.07 4.85c-.05 1.17-.25 1.8-.41 2.23-.22.56-.48.96-.9 1.38-.42.42-.82.68-1.38.9-.42.16-1.06.36-2.23.41-1.27.06-1.65.07-4.85.07s-3.58-.01-4.85-.07c-1.17-.05-1.8-.25-2.23-.41a3.72 3.72 0 0 1-1.38-.9 3.72 3.72 0 0 1-.9-1.38c-.16-.42-.36-1.06-.41-2.23C2.17 15.58 2.16 15.2 2.16 12s.01-3.58.07-4.85c.05-1.17.25-1.8.41-2.23.22-.56.48-.96.9-1.38.42-.42.82-.68 1.38-.9.42-.16 1.06-.36 2.23-.41C8.42 2.17 8.8 2.16 12 2.16zM12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10zm0 8.24a3.24 3.24 0 1 1 0-6.48 3.24 3.24 0 0 1 0 6.48zm5.2-8.44a1.17 1.17 0 1 0 0 2.34 1.17 1.17 0 0 0 0-2.34z' },
  { name: 'WhatsApp', icon: 'M17.47 14.38c-.3-.15-1.77-.87-2.04-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.95 1.17-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.48-.89-.79-1.49-1.77-1.66-2.07-.17-.3-.02-.46.13-.61.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.07-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51l-.57-.01c-.2 0-.52.07-.79.37-.27.3-1.04 1.02-1.04 2.48 0 1.46 1.06 2.87 1.21 3.07.15.2 2.09 3.2 5.07 4.49.71.31 1.26.49 1.69.62.71.23 1.36.2 1.87.12.57-.08 1.77-.72 2.02-1.42.25-.7.25-1.3.17-1.42-.07-.12-.27-.2-.57-.35zM12 2a10 10 0 0 0-8.5 15.3L2 22l4.8-1.5A10 10 0 1 0 12 2z' },
  { name: 'Facebook', icon: 'M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z' },
]
</script>

<template>
  <section id="contato" class="section">
    <div class="container">
      <h2 class="section-title">Fale <span class="gold-text">Conosco</span></h2>
      <p class="section-subtitle">
        Entre em contato ou venha nos visitar. Estamos prontas para
        atender você.
      </p>

      <div class="contact-grid">
        <div class="contact-info">
          <a
            v-for="item in contactInfo"
            :key="item.label"
            :href="item.href || undefined"
            class="contact-item"
            :class="{ 'no-link': !item.href }"
          >
            <div class="contact-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <path :d="item.icon" />
              </svg>
            </div>
            <div>
              <span class="contact-label">{{ item.label }}</span>
              <span class="contact-value">{{ item.value }}</span>
            </div>
          </a>

          <div class="social-links">
            <a
              v-for="s in socialLinks"
              :key="s.name"
              href="#"
              class="social-link"
              :aria-label="s.name"
            >
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path :d="s.icon" />
              </svg>
            </a>
          </div>
        </div>

        <div class="contact-map">
          <div class="map-placeholder">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
            <p>Mapa interativo</p>
            <span>Rua das Flores, 123 — Centro</span>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.contact-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 48px;
  align-items: start;
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.contact-item {
  display: flex;
  gap: 16px;
  align-items: center;
  padding: 20px;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  transition: all var(--transition);
}

.contact-item:not(.no-link):hover {
  border-color: var(--color-gold-muted);
  transform: translateX(4px);
}

.contact-icon {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-md);
  background: linear-gradient(135deg, rgba(212,175,55,0.15), rgba(212,175,55,0.05));
  border: 1px solid rgba(212,175,55,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.contact-icon svg {
  width: 24px;
  height: 24px;
  color: var(--color-gold);
}

.contact-label {
  display: block;
  font-size: 0.78rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 4px;
}

.contact-value {
  font-size: 1rem;
  color: var(--color-text);
}

.social-links {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

.social-link {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--transition);
}

.social-link:hover {
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  border-color: transparent;
  transform: translateY(-3px);
}

.social-link:hover svg {
  color: var(--color-bg);
}

.social-link svg {
  width: 20px;
  height: 20px;
  color: var(--color-text-secondary);
  transition: color var(--transition);
}

.contact-map {
  border-radius: var(--radius-lg);
  overflow: hidden;
  border: 1px solid var(--color-border);
  height: 400px;
}

.map-placeholder {
  height: 100%;
  background: var(--color-bg-card);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
}

.map-placeholder svg {
  width: 64px;
  height: 64px;
  color: var(--color-gold-muted);
}

.map-placeholder p {
  font-family: var(--font-heading);
  font-size: 1.2rem;
  color: var(--color-text-secondary);
}

.map-placeholder span {
  font-size: 0.9rem;
  color: var(--color-text-muted);
}

@media (max-width: 768px) {
  .contact-grid {
    grid-template-columns: 1fr;
    gap: 32px;
  }
  .contact-map {
    height: 280px;
  }
}
</style>
