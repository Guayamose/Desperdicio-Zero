import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: Number }

  connect() {
    const timeout = this.timeoutValue || 5000
    this.timer = window.setTimeout(() => this.dismiss(), timeout)
  }

  disconnect() {
    if (this.timer) window.clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.add("is-hidden")
  }
}
