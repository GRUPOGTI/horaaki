<script setup lang="ts">
function scrollTo(href: string) {
  const el = document.querySelector(href)
  if (el) el.scrollIntoView({ behavior: 'smooth' })
}

const features = [
  {
    icon: 'M8 2v4M16 2v4M3 10h18M5 6h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z',
    title: 'Agenda Online',
    desc: 'Seus clientes agendam horários a qualquer hora, sem ligações.',
  },
  {
    icon: 'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75',
    title: 'Gestão de Clientes',
    desc: 'Mantenha o histórico e dados de cada cliente em um só lugar.',
  },
  {
    icon: 'M6 4l6 8 6-8M6 20l6-8 6 8',
    title: 'Serviços e Preços',
    desc: 'Cadastre seus serviços com preços e durações personalizadas.',
  },
  {
    icon: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
    title: 'Painel Completo',
    desc: 'Visualize agenda, faturamento e relatórios em tempo real.',
  },
  {
    icon: 'M5 12h14M12 5l7 7-7 7',
    title: 'Link Exclusivo',
    desc: 'Cada empresa tem seu próprio link público de agendamento.',
  },
  {
    icon: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z',
    title: 'Simples e Rápido',
    desc: 'Configure em minutos. Sem complicação, sem instalação.',
  },
]

const steps = [
  { num: '01', title: 'Crie sua conta', desc: 'Cadastre sua empresa no Horaki em poucos minutos.' },
  { num: '02', title: 'Configure serviços', desc: 'Adicione seus serviços, horários e profissionais.' },
  { num: '03', title: 'Compartilhe seu link', desc: 'Divulgue seu link exclusivo para seus clientes.' },
  { num: '04', title: 'Receba agendamentos', desc: 'Acompanhe tudo pelo painel em tempo real.' },
]
</script>

<template>
  <div class="landing">
    <header class="landing-header">
      <div class="container header-inner">
        <div class="brand">
          <span class="brand-mark">H</span>
          <span class="brand-name">Horaki</span>
        </div>
        <nav class="header-nav">
          <a href="#recursos" @click.prevent="scrollTo('#recursos')">Recursos</a>
          <a href="#como-funciona" @click.prevent="scrollTo('#como-funciona')">Como funciona</a>
        </nav>
        <div class="header-actions">
          <router-link to="/login" class="btn btn-outline">Entrar</router-link>
          <router-link to="/criar-conta" class="btn btn-primary">Criar conta</router-link>
        </div>
      </div>
    </header>

    <section class="hero">
      <div class="container hero-content">
        <p class="hero-eyebrow">Plataforma de agendamento</p>
        <h1 class="hero-title">
          O jeito mais simples de
          <span class="gold-text">gerenciar agendamentos</span>
          do seu negócio
        </h1>
        <p class="hero-desc">
          Com o Horaki, sua empresa tem uma página de agendamento online
          com link próprio. Seus clientes marcam horário sozinhos e você
          controla tudo pelo painel.
        </p>
        <div class="hero-actions">
          <router-link to="/criar-conta" class="btn btn-primary">Começar agora</router-link>
          <a href="#como-funciona" class="btn btn-outline" @click.prevent="scrollTo('#como-funciona')">
            Ver como funciona
          </a>
        </div>
      </div>
    </section>

    <section id="recursos" class="section">
      <div class="container">
        <h2 class="section-title">Tudo que você precisa <span class="gold-text">em um lugar</span></h2>
        <p class="section-subtitle">
          Recursos pensados para facilitar a gestão do seu salão, barbearia
          ou clínica.
        </p>
        <div class="features-grid">
          <div v-for="f in features" :key="f.title" class="feature-card">
            <div class="feature-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <path :d="f.icon" />
              </svg>
            </div>
            <h3 class="feature-title">{{ f.title }}</h3>
            <p class="feature-desc">{{ f.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <section id="como-funciona" class="section steps-section">
      <div class="container">
        <h2 class="section-title">Como <span class="gold-text">funciona</span></h2>
        <p class="section-subtitle">Em 4 passos simples seu negócio já está no ar.</p>
        <div class="steps-grid">
          <div v-for="s in steps" :key="s.num" class="step-card">
            <span class="step-num">{{ s.num }}</span>
            <h3 class="step-title">{{ s.title }}</h3>
            <p class="step-desc">{{ s.desc }}</p>
          </div>
        </div>
        <div class="steps-cta">
          <router-link to="/criar-conta" class="btn btn-primary">Criar minha conta</router-link>
        </div>
      </div>
    </section>

    <footer class="landing-footer">
      <div class="container">
        <div class="footer-brand">
          <span class="brand-mark">H</span>
          <span class="brand-name">Horaki</span>
        </div>
        <p>&copy; {{ new Date().getFullYear() }} Horaki. Plataforma de agendamento online.</p>
      </div>
    </footer>
  </div>
</template>

<style scoped>
.landing {
  min-height: 100vh;
  background: var(--color-bg);
}

.landing-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  padding: 16px 0;
  background: rgba(10, 10, 10, 0.85);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--color-border);
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
}

.brand-mark {
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

.brand-name {
  font-family: var(--font-heading);
  font-size: 1.25rem;
  font-weight: 600;
}

.header-nav {
  display: flex;
  gap: 32px;
}

.header-nav a {
  color: var(--color-text-secondary);
  font-size: 0.95rem;
  transition: color var(--transition);
}

.header-nav a:hover {
  color: var(--color-text);
}

.header-actions {
  display: flex;
  gap: 12px;
}

.header-actions .btn {
  padding: 10px 24px;
  font-size: 0.9rem;
}

.hero {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 80px 24px 40px;
}

.hero-content {
  max-width: 800px;
}

.hero-eyebrow {
  color: var(--color-gold);
  font-size: 0.9rem;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  margin-bottom: 16px;
  opacity: 0;
  animation: fadeUp 800ms ease forwards;
}

.hero-title {
  font-size: 3.8rem;
  font-weight: 700;
  margin-bottom: 24px;
  opacity: 0;
  animation: fadeUp 800ms ease 200ms forwards;
}

.hero-desc {
  font-size: 1.15rem;
  color: var(--color-text-secondary);
  max-width: 600px;
  margin: 0 auto 40px;
  opacity: 0;
  animation: fadeUp 800ms ease 400ms forwards;
}

.hero-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
  opacity: 0;
  animation: fadeUp 800ms ease 600ms forwards;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.feature-card {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 32px;
  transition: all var(--transition);
}

.feature-card:hover {
  transform: translateY(-4px);
  border-color: var(--color-gold-muted);
  box-shadow: var(--shadow-lg);
}

.feature-icon {
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

.feature-icon svg {
  width: 28px;
  height: 28px;
  color: var(--color-gold);
}

.feature-title {
  font-size: 1.2rem;
  margin-bottom: 8px;
}

.feature-desc {
  font-size: 0.92rem;
  color: var(--color-text-secondary);
}

.steps-section {
  background: var(--color-bg-alt);
}

.steps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 24px;
}

.step-card {
  text-align: center;
  padding: 32px 24px;
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
}

.step-num {
  font-family: var(--font-heading);
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--color-gold);
  display: block;
  margin-bottom: 12px;
}

.step-title {
  font-size: 1.15rem;
  margin-bottom: 8px;
}

.step-desc {
  font-size: 0.9rem;
  color: var(--color-text-secondary);
}

.steps-cta {
  text-align: center;
  margin-top: 48px;
}

.landing-footer {
  padding: 32px 0;
  border-top: 1px solid var(--color-border);
  text-align: center;
}

.footer-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  justify-content: center;
  margin-bottom: 12px;
}

.landing-footer p {
  font-size: 0.85rem;
  color: var(--color-text-muted);
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 900px) {
  .header-nav {
    display: none;
  }
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 2.4rem;
  }
  .hero-desc {
    font-size: 1rem;
  }
  .hero-actions {
    flex-direction: column;
    width: 100%;
    max-width: 280px;
    margin: 0 auto;
  }
  .hero-actions .btn {
    width: 100%;
  }
  .header-actions .btn-outline {
    display: none;
  }
  .header-actions .btn-primary {
    padding: 10px 20px;
    font-size: 0.88rem;
  white-space: nowrap;
  }
}
</style>
