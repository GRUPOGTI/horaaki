<script setup lang="ts">
import SiteHeader from '../components/SiteHeader.vue'
import HeroSection from '../components/HeroSection.vue'
import ServicesSection from '../components/ServicesSection.vue'
import GallerySection from '../components/GallerySection.vue'
import AboutSection from '../components/AboutSection.vue'
import BookingSection from '../components/BookingSection.vue'
import ContactSection from '../components/ContactSection.vue'
import SiteFooter from '../components/SiteFooter.vue'
</script>

<template>
  <SiteHeader />
  <main>
    <HeroSection />
    <ServicesSection />
    <GallerySection />
    <AboutSection />
    <BookingSection />
    <ContactSection />
  </main>
  <SiteFooter />
</template>

<style scoped>
main {
  min-height: 100vh;
}
</style>
