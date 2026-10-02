<script setup lang="ts">
const heroImg = 'https://images.pexels.com/photos/7195803/pexels-photo-7195803.jpeg?auto=compress&cs=tinysrgb&w=1920'

function scrollTo(href: string) {
  const el = document.querySelector(href)
  if (el) el.scrollIntoView({ behavior: 'smooth' })
}
</script>

<template>
  <section id="home" class="hero">
    <div class="hero-bg" :style="{ backgroundImage: `url(${heroImg})` }"></div>
    <div class="hero-overlay"></div>

    <div class="container hero-content">
      <p class="hero-eyebrow">Bem-vinda ao</p>
      <h1 class="hero-title">Salão <span class="gold-text">Nadja Gomes</span></h1>
      <p class="hero-desc">
        Sua beleza é nossa arte. Oferecemos cortes, coloração, tratamentos
        e serviços de estética com profissionais experientes e produtos
        de alta qualidade.
      </p>
      <div class="hero-actions">
        <button class="btn btn-primary" @click="scrollTo('#agendar')">
          Agendar Horário
        </button>
        <button class="btn btn-outline" @click="scrollTo('#servicos')">
          Ver Serviços
        </button>
      </div>

      <div class="hero-stats">
        <div class="stat">
          <span class="stat-num">15+</span>
          <span class="stat-label">Anos de experiência</span>
        </div>
        <div class="stat-divider"></div>
        <div class="stat">
          <span class="stat-num">10+</span>
          <span class="stat-label">Serviços</span>
        </div>
        <div class="stat-divider"></div>
        <div class="stat">
          <span class="stat-num">2k+</span>
          <span class="stat-label">Clientes satisfeitas</span>
        </div>
      </div>
    </div>

    <div class="hero-scroll" @click="scrollTo('#servicos')">
      <span>Role para descobrir</span>
      <span class="scroll-line"></span>
    </div>
  </section>
</template>

<style scoped>
.hero {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.hero-bg {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  transform: scale(1.1);
  animation: heroZoom 20s ease-in-out infinite alternate;
}

@keyframes heroZoom {
  from { transform: scale(1.1); }
  to { transform: scale(1.2); }
}

.hero-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(10,10,10,0.7) 0%, rgba(10,10,10,0.5) 40%, rgba(10,10,10,0.95) 100%);
}

.hero-content {
  position: relative;
  z-index: 1;
  text-align: center;
  max-width: 800px;
  padding-top: 80px;
}

.hero-eyebrow {
  font-size: 0.9rem;
  color: var(--color-gold);
  letter-spacing: 0.15em;
  text-transform: uppercase;
  margin-bottom: 16px;
  opacity: 0;
  animation: fadeUp 800ms ease forwards;
}

.hero-title {
  font-size: 4.5rem;
  font-weight: 700;
  margin-bottom: 24px;
  opacity: 0;
  animation: fadeUp 800ms ease 200ms forwards;
}

.hero-desc {
  font-size: 1.15rem;
  color: var(--color-text-secondary);
  max-width: 560px;
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

.hero-stats {
  display: flex;
  align-items: center;
  gap: 32px;
  margin-top: 64px;
  opacity: 0;
  animation: fadeUp 800ms ease 800ms forwards;
}

.stat {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stat-num {
  font-family: var(--font-heading);
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--color-gold);
}

.stat-label {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.stat-divider {
  width: 1px;
  height: 40px;
  background: var(--color-border-light);
}

.hero-scroll {
  position: absolute;
  bottom: 32px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  font-size: 0.78rem;
  color: var(--color-text-muted);
  cursor: pointer;
  z-index: 1;
}

.scroll-line {
  width: 1px;
  height: 40px;
  background: var(--color-gold-muted);
  position: relative;
  overflow: hidden;
}

.scroll-line::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 50%;
  background: var(--color-gold);
  animation: scrollDown 2s ease-in-out infinite;
}

@keyframes scrollDown {
  0% { top: -50%; }
  100% { top: 100%; }
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

@media (max-width: 768px) {
  .hero-title {
    font-size: 2.8rem;
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
  .hero-stats {
    gap: 20px;
  }
  .stat-num {
    font-size: 1.8rem;
  }
  .stat-label {
    font-size: 0.7rem;
  }
  .hero-scroll {
    display: none;
  }
}
</style>
