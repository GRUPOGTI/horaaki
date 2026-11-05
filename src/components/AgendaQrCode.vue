<script setup lang="ts">
import { ref, watch } from 'vue'
import QRCode from 'qrcode'

const props = defineProps<{ url: string; fileName: string }>()

const dataUrl = ref('')
const error = ref('')

watch(
  () => props.url,
  async (url) => {
    error.value = ''
    try {
      dataUrl.value = await QRCode.toDataURL(url, {
        width: 512,
        margin: 2,
        color: { dark: '#000000', light: '#ffffff' },
      })
    } catch (cause) {
      console.error('qr generation failed', cause)
      dataUrl.value = ''
      error.value = 'Não foi possível gerar o QR Code.'
    }
  },
  { immediate: true },
)
</script>

<template>
  <div class="qr-card">
    <img
      v-if="dataUrl"
      :src="dataUrl"
      :alt="`QR Code que leva à página de agendamento: ${url}`"
      width="160"
      height="160"
      class="qr-image"
    />
    <p v-else-if="error" class="qr-error" role="alert">{{ error }}</p>
    <div class="qr-info">
      <p class="qr-title">QR Code da agenda</p>
      <p class="qr-hint">Exiba ou imprima este código para que os clientes abram a página de agendamento.</p>
      <a v-if="dataUrl" :href="dataUrl" :download="fileName" class="btn-sm btn-sm-gold">Baixar imagem</a>
    </div>
  </div>
</template>

<style scoped>
.qr-card {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 24px;
  padding: 16px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-bg-alt);
}

.qr-image {
  background: #ffffff;
  padding: 8px;
  border-radius: var(--radius-sm);
}

.qr-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
  min-width: 200px;
}

.qr-title {
  font-weight: 600;
  color: var(--color-text);
}

.qr-hint {
  font-size: 0.9rem;
  color: var(--color-text-secondary);
}

.qr-error {
  color: var(--color-error);
  font-size: 0.9rem;
}
</style>
