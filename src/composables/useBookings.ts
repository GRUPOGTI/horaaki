import { ref } from 'vue'
import { supabase, type Booking } from '../lib/supabase'

const bookings = ref<Booking[]>([])
const newBookingCount = ref(0)
let initialized = false
let currentEmpresaId: string | null = null

function sortBookings(list: Booking[]): Booking[] {
  return [...list].sort((a, b) => {
    const aDate = a.booking_date + ' ' + a.booking_time
    const bDate = b.booking_date + ' ' + b.booking_time
    return aDate.localeCompare(bDate)
  })
}

export function useBookings() {
  async function loadBookings(empresaId?: string) {
    if (empresaId) currentEmpresaId = empresaId

    let query = supabase.from('bookings').select('*')
    if (currentEmpresaId) {
      query = query.eq('empresa_id', currentEmpresaId)
    }
    const { data, error } = await query.order('created_at', { ascending: false })

    if (!error && data) {
      bookings.value = sortBookings(data)
    }
  }

  function initRealtime() {
    if (initialized) return
    initialized = true

    supabase
      .channel('bookings-realtime')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'bookings' },
        (payload) => {
          const newBooking = payload.new as Booking
          if (currentEmpresaId && newBooking.empresa_id !== currentEmpresaId) return
          if (!bookings.value.find((b) => b.id === newBooking.id)) {
            bookings.value = sortBookings([...bookings.value, newBooking])
            newBookingCount.value++
          }
        }
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'bookings' },
        (payload) => {
          const updated = payload.new as Booking
          if (currentEmpresaId && updated.empresa_id !== currentEmpresaId) return
          bookings.value = sortBookings(
            bookings.value.map((b) => (b.id === updated.id ? updated : b))
          )
        }
      )
      .on(
        'postgres_changes',
        { event: 'DELETE', schema: 'public', table: 'bookings' },
        (payload) => {
          const deleted = payload.old as Booking
          bookings.value = bookings.value.filter((b) => b.id !== deleted.id)
        }
      )
      .subscribe()
  }

  initRealtime()

  function clearNewBookingCount() {
    newBookingCount.value = 0
  }

  async function updateBookingStatus(id: string, status: string) {
    const { error } = await supabase
      .from('bookings')
      .update({ status })
      .eq('id', id)

    if (error) throw error

    bookings.value = sortBookings(
      bookings.value.map((b) => (b.id === id ? { ...b, status } : b))
    )
  }

  async function deleteBooking(id: string) {
    const { error } = await supabase
      .from('bookings')
      .delete()
      .eq('id', id)

    if (error) throw error

    bookings.value = bookings.value.filter((b) => b.id !== id)
  }

  return {
    bookings,
    newBookingCount,
    loadBookings,
    clearNewBookingCount,
    updateBookingStatus,
    deleteBooking,
  }
}
