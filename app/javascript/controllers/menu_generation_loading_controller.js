import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "cancelButton"]
  static values = { cancelPath: String }

  connect() {
    this.loading = false
    this.formSubmission = null
    this.handleBeforeCache = this.beforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this.handleBeforeCache)
    this.unlock()
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.handleBeforeCache)
    this.unlock()
    this.formSubmission = null
  }

  start() {
    this.lock()
  }

  captureSubmission(event) {
    this.formSubmission = event?.detail?.formSubmission || null
    this.lock()
  }

  finish() {
    this.formSubmission = null
    this.unlock()
  }

  cancel(event) {
    event.preventDefault()

    if (this.formSubmission && typeof this.formSubmission.stop === "function") {
      this.formSubmission.stop()
    }

    if (typeof window.stop === "function") window.stop()

    this.formSubmission = null
    this.unlock()

    if (window.history.length > 1) {
      window.history.back()
      return
    }

    const fallbackPath = this.hasCancelPathValue ? this.cancelPathValue : "/"
    window.location.assign(fallbackPath)
  }

  beforeCache() {
    this.formSubmission = null
    this.unlock()
  }

  lock() {
    if (this.loading) return

    this.loading = true
    document.body.classList.add("menu-generation-loading-active")

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("is-active")
      this.overlayTarget.setAttribute("aria-hidden", "false")
    }

    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.focus()
    }
  }

  unlock() {
    this.loading = false
    document.body.classList.remove("menu-generation-loading-active")

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("is-active")
      this.overlayTarget.setAttribute("aria-hidden", "true")
    }
  }
}
