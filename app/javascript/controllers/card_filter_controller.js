import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "card", "empty"]

  connect() {
    this.filter()
  }

  filter() {
    const query = this.hasQueryTarget ? this.queryTarget.value.trim().toLowerCase() : ""
    let visibleCount = 0

    // Toggle clear button visibility if it exists
    const clearBtn = document.getElementById('search-clear-btn')
    if (clearBtn) {
      clearBtn.style.display = query.length > 0 ? "flex" : "none"
    }

    // Sincronizar estado visual de los chips (botones)
    document.querySelectorAll('.suggest-chip').forEach(c => {
      if (query && c.dataset.value && query === c.dataset.value.toLowerCase()) {
        c.classList.add('is-active')
      } else {
        c.classList.remove('is-active')
      }
    });

    this.cardTargets.forEach((card) => {
      const search = (card.dataset.search || "").toLowerCase()
      const visible = query === "" || search.includes(query)

      const wasHidden = card.style.display === "none" || card.classList.contains("is-hidden")

      // Eliminar is-hidden para evitar conflictos si en algún momento se añade
      card.classList.remove("is-hidden")
      card.style.display = visible ? "" : "none"

      if (visible) {
        visibleCount += 1
        // Add a small entrance animation if becoming visible
        if (wasHidden) {
          card.style.animation = "none"
          card.offsetHeight // trigger reflow
          card.style.animation = "fadeInUp 0.4s ease forwards"
        }
      }
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.remove("is-hidden")
      this.emptyTarget.style.display = visibleCount > 0 ? "none" : ""
    }
  }

  clear() {
    if (this.hasQueryTarget) {
      this.queryTarget.value = ""
      this.filter()
      this.queryTarget.focus()
    }
  }

  suggest(event) {
    const chip = event.currentTarget
    const val = chip.dataset.value

    if (chip.classList.contains('is-active')) {
      // Despulsar
      if (this.hasQueryTarget) {
        this.queryTarget.value = ""
        this.filter()
      }
      return
    }

    // Seleccionar nuevo
    if (this.hasQueryTarget && val) {
      this.queryTarget.value = val
      this.filter()
    }
  }
}
