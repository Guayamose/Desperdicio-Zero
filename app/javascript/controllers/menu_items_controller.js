import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "count"]

  connect() {
    this.refreshCount()
  }

  add(event) {
    event.preventDefault()
    if (!this.hasTemplateTarget || !this.hasContainerTarget) return

    const index = Date.now().toString()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", index)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
    this.refreshCount()
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-menu-item]")
    if (!item) return

    const destroyField = item.querySelector("input[name*='[_destroy]']")
    if (destroyField) {
      destroyField.value = "1"
      item.classList.add("is-hidden")
    } else {
      item.remove()
    }

    this.refreshCount()
  }

  refreshCount() {
    if (!this.hasCountTarget || !this.hasContainerTarget) return

    const visibleItems = this.containerTarget.querySelectorAll("[data-menu-item]:not(.is-hidden)").length
    this.countTarget.textContent = visibleItems.toString()
  }
}
