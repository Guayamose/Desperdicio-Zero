import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

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

    // Lock body scroll when menu is open
    document.body.classList.toggle("nav-open", isOpen)
  }

  handleResize() {
    if (!this.hasMenuTarget) return

    if (window.innerWidth > 940) {
      this.menuTarget.classList.remove("is-open")
      document.body.classList.remove("nav-open")
    }
  }
}
