<script setup lang="ts">
import { watch, nextTick } from 'vue'
import { RouterView, useRoute } from 'vue-router'

const route = useRoute()

watch(
  () => route.path,
  async () => {
    await nextTick()
    document.getElementById('main-content')?.focus()
  },
)
</script>

<template>
  <RouterView />
</template>

<style>
.skip-link {
  position: fixed;
  top: -100px;
  left: 0;
  z-index: 9999;
  padding: 12px 24px;
  background: var(--color-gold);
  color: var(--color-bg);
  font-weight: 600;
  border-radius: 0 0 var(--radius-md) 0;
  text-decoration: none;
  transition: top var(--transition);
}
.skip-link:focus {
  top: 0;
}
</style>
