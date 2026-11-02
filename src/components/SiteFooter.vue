<script setup lang="ts">
import { computed } from 'vue'
import type { Company } from '../lib/supabase'

const props = defineProps<{ company: Company | null }>()

const year = new Date().getFullYear()
const companyName = computed(() => props.company?.name ?? 'Nadja Gomes')
const companyInitial = computed(() => (props.company?.name ?? 'N').charAt(0).toUpperCase())
const phone = computed(() => props.company?.whatsapp ?? '(75) 99999-9999')
const email = computed(() => props.company?.email ?? 'contato@salonadjagomes.com.br')
const address = computed(() => props.company?.address ?? 'Rua das Flores, 123 — Centro')
const hours = computed(() => props.company?.hours ?? 'Seg–Sáb: 08h às 19h')
</script>

<template>
  <footer class="footer">
    <div class="container footer-inner">
      <div class="footer-brand">
        <div class="footer-logo">
          <span class="logo-mark">{{ companyInitial }}</span>
          <span class="logo-name">{{ companyName }}</span>
        </div>
        <p class="footer-tag">Salão de Beleza</p>
        <p class="footer-desc">
          Realçando a beleza de cada cliente com profissionalismo,
          cuidado e dedicação.
        </p>
      </div>

      <div class="footer-links">
        <h4>Navegação</h4>
        <a href="#home">Início</a>
        <a href="#servicos">Serviços</a>
        <a href="#galeria">Galeria</a>
        <a href="#sobre">Sobre</a>
        <a href="#contato">Contato</a>
      </div>

      <div class="footer-contact">
        <h4>Contato</h4>
        <p>{{ phone }}</p>
        <p>{{ email }}</p>
        <p>{{ address }}</p>
        <p>{{ hours }}</p>
      </div>
    </div>

    <div class="footer-bottom">
      <div class="container">
        <p>&copy; {{ year }} {{ companyName }}. Todos os direitos reservados.</p>
      </div>
    </div>
  </footer>
</template>

<style scoped>
.footer {
  background: var(--color-bg-alt);
  border-top: 1px solid var(--color-border);
  padding-top: 64px;
}

.footer-inner {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 48px;
  padding-bottom: 48px;
}

.footer-logo {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.logo-mark {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--color-gold), var(--color-gold-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-heading);
  font-weight: 700;
  font-size: 1.3rem;
  color: var(--color-bg);
}

.logo-name {
  font-family: var(--font-heading);
  font-size: 1.2rem;
  font-weight: 600;
}

.footer-tag {
  color: var(--color-gold);
  font-size: 0.82rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin-bottom: 16px;
}

.footer-desc {
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  max-width: 320px;
}

.footer-links h4,
.footer-contact h4 {
  font-family: var(--font-body);
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-text);
  margin-bottom: 20px;
}

.footer-links {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.footer-links a {
  color: var(--color-text-secondary);
  font-size: 0.92rem;
  transition: color var(--transition);
}

.footer-links a:hover {
  color: var(--color-gold);
}

.footer-contact {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.footer-contact p {
  color: var(--color-text-secondary);
  font-size: 0.92rem;
}

.footer-bottom {
  border-top: 1px solid var(--color-border);
  padding: 24px 0;
}

.footer-bottom p {
  text-align: center;
  font-size: 0.85rem;
  color: var(--color-text-muted);
}

@media (max-width: 768px) {
  .footer-inner {
    grid-template-columns: 1fr;
    gap: 32px;
    text-align: center;
  }
  .footer-logo {
    justify-content: center;
  }
  .footer-desc {
    margin: 0 auto;
  }
  .footer-links,
  .footer-contact {
    align-items: center;
  }
}
</style>
