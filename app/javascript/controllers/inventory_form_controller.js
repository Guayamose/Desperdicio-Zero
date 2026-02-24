import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "barcode",
    "product",
    "productName",
    "unknownBarcodeConfirmed",
    "status",
    "preview",
    "previewName",
    "previewBrand",
    "previewCategory",
    "previewAllergens"
  ]

  static values = {
    scanUrl: String,
    barcodeCheckUrl: String,
    allergenIconMap: Object
  }

  connect() {
    this.lastBarcode = null
    this.initialBarcode = this.hasBarcodeTarget ? this.sanitizeBarcode(this.barcodeTarget.value) : ""
    this.skipNextSubmitCheck = false
    this.barcodeCheckCache = new Map()
    this.inflightBarcodeChecks = new Map()
    this.barcodeCheckDebounceTimer = null
    this.pendingUnknownBarcodeAcknowledgement = null
    this.markUnknownBarcodeConfirmed(false)
  }

  disconnect() {
    if (this.barcodeCheckDebounceTimer) {
      clearTimeout(this.barcodeCheckDebounceTimer)
      this.barcodeCheckDebounceTimer = null
    }
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

      this.rememberLookupSource(barcode, payload?.data?.lookupSource)

      const product = payload?.data?.product
      if (!product) throw new Error("Respuesta invalida del escaneo")

      this.lastBarcode = barcode
      this.syncForm(product)
      this.setStatus(`Producto cargado: ${product.name}`)
    } catch (error) {
      this.setStatus(`No se pudo autorellenar: ${error.message}`, true)
    }
  }

  async confirmUnknownBarcode(event) {
    if (this.skipNextSubmitCheck) {
      this.skipNextSubmitCheck = false
      return
    }

    if (!this.hasBarcodeTarget || !this.hasBarcodeCheckUrlValue) return

    const barcode = this.sanitizeBarcode(this.barcodeTarget.value)
    if (!barcode || barcode.length < 6) {
      this.pendingUnknownBarcodeAcknowledgement = null
      this.markUnknownBarcodeConfirmed(false)
      return
    }
    if (this.isEditForm() && barcode === this.initialBarcode) {
      this.pendingUnknownBarcodeAcknowledgement = null
      this.markUnknownBarcodeConfirmed(false)
      return
    }

    const cachedExists = this.barcodeCheckCache.get(barcode)
    if (cachedExists === true) {
      this.pendingUnknownBarcodeAcknowledgement = null
      this.markUnknownBarcodeConfirmed(false)
      return
    }
    if (cachedExists === false) {
      if (this.pendingUnknownBarcodeAcknowledgement != barcode) {
        event.preventDefault()
        this.pendingUnknownBarcodeAcknowledgement = barcode
        this.markUnknownBarcodeConfirmed(false)
        this.setStatus("El alimento no existe en OpenFoodFacts. Pulsa Guardar de nuevo si quieres continuar.", true)
        return
      }

      this.markUnknownBarcodeConfirmed(true)
      return
    }

    event.preventDefault()
    this.setStatus("Comprobando codigo de barras en OpenFoodFacts...")

    let exists
    try {
      exists = await this.checkBarcodeExists(barcode)
    } catch (_error) {
      this.pendingUnknownBarcodeAcknowledgement = barcode
      this.markUnknownBarcodeConfirmed(false)
      this.setStatus("No se pudo verificar en OpenFoodFacts. Pulsa Guardar de nuevo si quieres continuar.", true)
      return
    }

    if (exists) {
      this.pendingUnknownBarcodeAcknowledgement = null
      this.submitForm(false)
      return
    }

    this.pendingUnknownBarcodeAcknowledgement = barcode
    this.markUnknownBarcodeConfirmed(false)
    this.setStatus("El alimento no existe en OpenFoodFacts. Pulsa Guardar de nuevo si quieres continuar.", true)
  }

  scheduleBarcodeCheck() {
    if (!this.hasBarcodeTarget || !this.hasBarcodeCheckUrlValue) return

    const barcode = this.sanitizeBarcode(this.barcodeTarget.value)
    if (this.barcodeCheckDebounceTimer) clearTimeout(this.barcodeCheckDebounceTimer)

    this.pendingUnknownBarcodeAcknowledgement = null
    this.markUnknownBarcodeConfirmed(false)
    if (!barcode || barcode.length < 6) return

    this.barcodeCheckDebounceTimer = setTimeout(() => {
      this.prefetchBarcodeCheck(barcode)
    }, 450)
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
      this.previewAllergensTarget.innerHTML = this.renderAllergenBadges(allergens)
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

  rememberLookupSource(barcode, lookupSource) {
    if (!barcode) return

    if (lookupSource === "openfoodfacts" || lookupSource === "openfoodfacts_refresh") {
      this.barcodeCheckCache.set(barcode, true)
      return
    }

    if (lookupSource === "manual_fallback") {
      this.barcodeCheckCache.set(barcode, false)
    }
  }

  async checkBarcodeExists(barcode) {
    if (this.barcodeCheckCache.has(barcode)) return this.barcodeCheckCache.get(barcode)
    if (this.inflightBarcodeChecks.has(barcode)) return this.inflightBarcodeChecks.get(barcode)

    const promise = (async () => {
      const response = await fetch(this.barcodeCheckUrlValue, {
        method: "POST",
        headers: this.requestHeaders(),
        body: JSON.stringify({ barcode })
      })

      const payload = await response.json().catch(() => ({}))
      if (!response.ok) {
        const message = payload?.message || payload?.code || "No se pudo verificar el codigo"
        throw new Error(message)
      }

      const exists = payload?.data?.exists === true
      this.barcodeCheckCache.set(barcode, exists)
      return exists
    })()

    this.inflightBarcodeChecks.set(barcode, promise)

    try {
      return await promise
    } finally {
      this.inflightBarcodeChecks.delete(barcode)
    }
  }

  isEditForm() {
    const method = this.element.querySelector("input[name='_method']")?.value?.toLowerCase()
    return method === "patch"
  }

  submitForm(unknownBarcodeConfirmed = false) {
    this.markUnknownBarcodeConfirmed(unknownBarcodeConfirmed)
    this.skipNextSubmitCheck = true
    this.element.requestSubmit()
  }

  async prefetchBarcodeCheck(barcode) {
    try {
      const exists = await this.checkBarcodeExists(barcode)
      if (this.sanitizeBarcode(this.barcodeTarget.value) !== barcode) return

      if (exists) {
        this.pendingUnknownBarcodeAcknowledgement = null
        this.setStatus("Codigo validado en OpenFoodFacts.")
      } else {
        this.pendingUnknownBarcodeAcknowledgement = barcode
        this.setStatus("El alimento no existe en OpenFoodFacts. Pulsa Guardar de nuevo si quieres continuar.", true)
      }
    } catch (_error) {
      if (this.sanitizeBarcode(this.barcodeTarget.value) !== barcode) return
      this.pendingUnknownBarcodeAcknowledgement = barcode
      this.setStatus("No se pudo verificar en OpenFoodFacts. Pulsa Guardar de nuevo si quieres continuar.", true)
    }
  }

  markUnknownBarcodeConfirmed(value) {
    if (!this.hasUnknownBarcodeConfirmedTarget) return

    this.unknownBarcodeConfirmedTarget.value = value ? "1" : "0"
  }

  renderAllergenBadges(allergens) {
    const values = Array.isArray(allergens)
      ? allergens.map((item) => `${item || ""}`.trim()).filter((item) => item.length > 0)
      : []

    if (values.length === 0) return "<span class=\"muted\">Ninguno</span>"

    return `
      <div class="allergen-badge-group">
        ${values.map((allergen) => this.renderAllergenBadge(allergen)).join("")}
      </div>
    `
  }

  renderAllergenBadge(allergen) {
    const safeLabel = this.escapeHtml(allergen)
    const iconUrl = this.allergenIconPath(allergen)

    if (!iconUrl) {
      return `
        <span class="allergen-badge allergen-badge-text-only" title="${safeLabel}">
          <span class="allergen-label">${safeLabel}</span>
        </span>
      `
    }

    return `
      <span class="allergen-badge" title="${safeLabel}">
        <img src="${iconUrl}" alt="Icono alergeno ${safeLabel}" class="allergen-icon" loading="lazy">
        <span class="allergen-label">${safeLabel}</span>
      </span>
    `
  }

  allergenIconPath(allergen) {
    if (!this.hasAllergenIconMapValue) return null

    const key = this.allergenIconKey(allergen)
    if (!key) return null

    return this.allergenIconMapValue[key] || null
  }

  allergenIconKey(allergen) {
    const normalized = this.normalizeAllergenName(allergen)

    if (/\b(gluten|trigo|cebada|centeno|avena|espelta|kamut)\b/.test(normalized)) return "gluten"
    if (/crustace|crustacean|shrimp|prawn/.test(normalized)) return "crustaceos"
    if (/huevo|egg/.test(normalized)) return "huevos"
    if (/pescado|fish/.test(normalized)) return "pescado"
    if (/\b(cacahuete|cacahuetes|mani|peanut|peanuts)\b/.test(normalized)) return "cacahuetes"
    if (/soja|soy/.test(normalized)) return "soja"
    if (/\b(lacteo|lacteos|lactosa|leche|milk)\b/.test(normalized)) return "lacteos"
    if (/frutos?\s+(de\s+)?cascara|frutos?\s+secos|nueces?|tree\s+nuts?/.test(normalized)) return "frutos_de_cascara"
    if (/apio|celery/.test(normalized)) return "apio"
    if (/mostaza|mustard/.test(normalized)) return "mostaza"
    if (/sesamo|sesame/.test(normalized)) return "sesamo"
    if (/sulfit|sulfat|dioxido\s+de\s+azufre|sulfur\s+dioxide/.test(normalized)) return "sulfitos"
    if (/altramuz|altramuces|lupin/.test(normalized)) return "altramuces"
    if (/molusco|mollusc|mollusk/.test(normalized)) return "moluscos"

    return null
  }

  normalizeAllergenName(value) {
    return `${value || ""}`
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, " ")
      .trim()
  }

  escapeHtml(value) {
    return `${value || ""}`
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }

  setStatus(message, isError = false) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("text-danger", isError)
  }
}
