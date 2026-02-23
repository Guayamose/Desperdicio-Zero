import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "barcode",
    "product",
    "productName",
    "status",
    "preview",
    "previewName",
    "previewBrand",
    "previewCategory",
    "previewAllergens"
  ]

  static values = {
    scanUrl: String
  }

  connect() {
    this.lastBarcode = null
  }

  async lookup(event) {
    if (event) event.preventDefault()
    if (!this.hasBarcodeTarget || !this.hasScanUrlValue) return

    const barcode = this.sanitizeBarcode(this.barcodeTarget.value)
    if (!barcode || barcode.length < 6) {
      this.setStatus("Introduce un codigo valido (minimo 6 digitos).", true)
      return
    }

    if (barcode === this.lastBarcode) return

    this.setStatus("Buscando producto en OpenFoodFacts...")

    try {
      const response = await fetch(this.scanUrlValue, {
        method: "POST",
        headers: this.requestHeaders(),
        body: JSON.stringify({ barcode, source: "usb" })
      })

      const payload = await response.json()
      if (!response.ok) {
        const message = payload?.message || payload?.code || "No se pudo consultar el producto"
        throw new Error(message)
      }

      const product = payload?.data?.product
      if (!product) throw new Error("Respuesta invalida del escaneo")

      this.lastBarcode = barcode
      this.syncForm(product)
      this.setStatus(`Producto cargado: ${product.name}`)
    } catch (error) {
      this.setStatus(`No se pudo autorellenar: ${error.message}`, true)
    }
  }

  syncForm(product) {
    if (this.hasProductTarget) this.productTarget.value = product.id
    if (this.hasProductNameTarget && product.name) this.productNameTarget.value = product.name

    this.renderPreview(product)
  }

  renderPreview(product) {
    if (this.hasPreviewTarget) this.previewTarget.classList.remove("is-hidden")
    if (this.hasPreviewNameTarget) this.previewNameTarget.textContent = product.name || "-"
    if (this.hasPreviewBrandTarget) this.previewBrandTarget.textContent = product.brand || "-"
    if (this.hasPreviewCategoryTarget) this.previewCategoryTarget.textContent = product.category || "-"

    if (this.hasPreviewAllergensTarget) {
      const allergens = Array.isArray(product.allergensJson) ? product.allergensJson : []
      this.previewAllergensTarget.textContent = allergens.length > 0 ? allergens.join(", ") : "Ninguno"
    }
  }

  requestHeaders() {
    return {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": this.csrfToken()
    }
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  sanitizeBarcode(raw) {
    return (raw || "").replace(/\s+/g, "").trim()
  }

  setStatus(message, isError = false) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("text-danger", isError)
  }
}
