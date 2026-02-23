import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "trigger"]

  connect() {
    this.boundResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundResize)
    this.handleResize()
  }

  disconnect() {
    window.removeEventListener("resize", this.boundResize)
  }

  toggle() {
    if (!this.hasMenuTarget) return

    const isOpen = this.menuTarget.classList.toggle("is-open")
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", isOpen ? "true" : "false")
    }
  }

  handleResize() {
    if (!this.hasMenuTarget) return

    if (window.innerWidth > 760) {
      this.menuTarget.classList.remove("is-open")
      if (this.hasTriggerTarget) {
        this.triggerTarget.setAttribute("aria-expanded", "false")
      }
    }
  }
}
