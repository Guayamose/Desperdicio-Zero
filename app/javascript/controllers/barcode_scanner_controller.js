import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["barcode", "source", "status", "form", "preview"]
  static values = { autoSubmit: Boolean }

  async scanWithCamera() {
    if (!this.browserSupportsCameraScan()) {
      this.setStatus("Tu navegador no soporta BarcodeDetector. Usa lector USB o entrada manual.", true)
      return
    }

    const detector = new BarcodeDetector({ formats: ["ean_13", "ean_8", "upc_a", "upc_e", "code_128"] })

    try {
      this.setStatus("Abriendo camara...")
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
      const video = document.createElement("video")
      video.srcObject = stream
      video.setAttribute("playsinline", "true")
      if (this.hasPreviewTarget) {
        this.previewTarget.innerHTML = ""
        this.previewTarget.appendChild(video)
      }
      await video.play()

      const startedAt = Date.now()
      const timeoutMs = 6000
      let foundCode = null

      while (Date.now() - startedAt < timeoutMs) {
        const codes = await detector.detect(video)
        if (codes.length > 0) {
          foundCode = codes[0].rawValue
          break
        }
        await this.wait(150)
      }

      stream.getTracks().forEach((track) => track.stop())

      if (foundCode) {
        this.barcodeTarget.value = foundCode
        if (this.hasSourceTarget) this.sourceTarget.value = "camera"
        this.setStatus(`Codigo detectado: ${foundCode}`)
        if (this.hasFormTarget && this.autoSubmitValue) this.formTarget.requestSubmit()
      } else {
        this.setStatus("No se detecto codigo en 6 segundos. Intenta de nuevo o usa entrada manual.", true)
      }
    } catch (error) {
      this.setStatus(`No se pudo usar la camara: ${error.message}`, true)
    }
  }

  browserSupportsCameraScan() {
    return "BarcodeDetector" in window && navigator.mediaDevices?.getUserMedia
  }

  setStatus(message, isError = false) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("text-danger", isError)
  }

  wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }
}
