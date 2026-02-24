import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["barcode", "source", "status", "form", "preview", "scanButton", "stopButton", "scanResult"]
  static values = { autoSubmit: Boolean }

  connect() {
    this.isScanning = false
    this.isResolvingDetection = false
    this.lastDetectedCode = null
    this.pendingCode = null
    this.pendingHits = 0

    this.quagga = null
    this.quaggaDetectedHandler = null
    this.quaggaRunning = false

    this.mediaStream = null
    this.videoEl = null
    this.detector = null
    this.detectorTimer = null

    this.updateButtons(false)
    this.renderScanResult(null)
    this.renderIdlePreview()
  }

  disconnect() {
    this.stopCamera()
  }

  async scanWithCamera() {
    if (this.isScanning) return

    if (!navigator.mediaDevices?.getUserMedia) {
      this.setStatus("Este navegador no permite camara. Usa Chrome, Edge o Safari recientes.", true)
      return
    }

    if (!window.isSecureContext && location.hostname !== "localhost" && location.hostname !== "127.0.0.1") {
      this.setStatus("La camara requiere HTTPS (o localhost).", true)
      return
    }

    this.isScanning = true
    this.isResolvingDetection = false
    this.lastDetectedCode = null
    this.pendingCode = null
    this.pendingHits = 0
    this.updateButtons(true)
    this.renderScanResult(null)

    try {
      this.setStatus("Solicitando permiso de camara...")

      const startedWithQuagga = await this.startWithQuagga()
      if (startedWithQuagga) {
        this.setStatus("Camara activa. Enfoca el codigo de barras.")
        return
      }

      const startedWithNative = await this.startWithNativeDetector()
      if (startedWithNative) {
        this.setStatus("Camara activa (modo compatibilidad). Enfoca el codigo de barras.")
        return
      }

      throw new Error("No se pudo activar un motor de lectura de codigo")
    } catch (error) {
      this.setStatus(`No se pudo iniciar la camara: ${error.message}`, true)
      await this.stopCamera({ keepStatus: true })
    }
  }

  async stopCamera(options = {}) {
    const { keepStatus = false } = options

    if (this.detectorTimer) {
      clearInterval(this.detectorTimer)
      this.detectorTimer = null
    }
    this.detector = null

    if (this.quagga && this.quaggaRunning) {
      try {
        if (this.quaggaDetectedHandler) {
          this.quagga.offDetected(this.quaggaDetectedHandler)
        }
      } catch (_error) { }

      try {
        this.quagga.stop()
      } catch (_error) { }
    }

    this.quagga = null
    this.quaggaDetectedHandler = null
    this.quaggaRunning = false

    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach((track) => track.stop())
      this.mediaStream = null
    }

    if (this.videoEl) {
      try {
        this.videoEl.pause()
      } catch (_error) { }
      this.videoEl.srcObject = null
      this.videoEl = null
    }

    this.isScanning = false
    this.isResolvingDetection = false
    this.pendingCode = null
    this.pendingHits = 0
    this.updateButtons(false)
    this.renderIdlePreview()

    if (!keepStatus) this.setStatus("Camara detenida.")
  }

  async startWithQuagga() {
    let mod = null

    try {
      mod = await import("https://cdn.jsdelivr.net/npm/@ericblade/quagga2@1.8.4/+esm")
    } catch (_error) {
      return false
    }

    const Quagga = mod?.default || mod?.Quagga || mod
    if (!Quagga || typeof Quagga.init !== "function") return false

    this.ensureScannerRegion()
    const scannerTarget = document.getElementById("camera-scanner-preview")
    if (!scannerTarget) return false

    const config = {
      inputStream: {
        name: "Live",
        type: "LiveStream",
        target: scannerTarget,
        constraints: {
          facingMode: "environment"
        }
      },
      locator: {
        patchSize: "large",
        halfSample: true
      },
      numOfWorkers: 1, /* Reduce heavy CPU load which can also cause timeouts */
      frequency: 10,
      locate: true,
      decoder: {
        readers: [
          "ean_reader",
          "ean_8_reader",
          "upc_reader",
          "upc_e_reader",
          "code_128_reader"
        ],
        multiple: false
      }
    }

    try {
      await new Promise((resolve, reject) => {
        Quagga.init(config, (error) => {
          if (error) reject(error)
          else resolve(true)
        })
      })

      this.quaggaDetectedHandler = (result) => {
        const code = result?.codeResult?.code?.trim()
        this.handleDetectionCandidate(code)
      }

      Quagga.onDetected(this.quaggaDetectedHandler)
      Quagga.start()

      this.quagga = Quagga
      this.quaggaRunning = true
      return true
    } catch (_error) {
      try {
        Quagga.stop()
      } catch (_stopError) { }
      this.quagga = null
      this.quaggaDetectedHandler = null
      this.quaggaRunning = false
      return false
    }
  }

  async startWithNativeDetector() {
    await this.startVideoPreview()

    const detector = await this.createNativeBarcodeDetector()
    if (!detector) {
      return false
    }

    this.detector = detector
    this.detectorTimer = setInterval(() => this.tryDetectWithNativeDetector(), 140)
    return true
  }

  async startVideoPreview() {
    this.ensureScannerRegion()

    const region = document.getElementById("camera-scanner-preview")
    const video = document.createElement("video")
    video.className = "camera-live-video"
    video.setAttribute("playsinline", "true")
    video.setAttribute("autoplay", "true")
    video.setAttribute("muted", "true")
    video.muted = true
    region.appendChild(video)
    this.videoEl = video

    const constraints = [
      {
        video: {
          facingMode: { ideal: "environment" },
          width: { ideal: 1920 },
          height: { ideal: 1080 }
        },
        audio: false
      },
      { video: true, audio: false }
    ]

    let stream = null
    let lastError = null

    for (const constraint of constraints) {
      try {
        stream = await navigator.mediaDevices.getUserMedia(constraint)
        break
      } catch (error) {
        lastError = error
      }
    }

    if (!stream) {
      throw lastError || new Error("No se pudo abrir la camara")
    }

    this.mediaStream = stream
    this.videoEl.srcObject = stream
    await this.videoEl.play()
    this.applyCameraTrackOptimizations(stream)
  }

  async createNativeBarcodeDetector() {
    if (!("BarcodeDetector" in window)) return null

    const desiredFormats = ["ean_13", "ean_8", "upc_a", "upc_e", "code_128", "code_39", "itf", "codabar"]

    try {
      if (typeof BarcodeDetector.getSupportedFormats === "function") {
        const supported = await BarcodeDetector.getSupportedFormats()
        const selected = desiredFormats.filter((format) => supported.includes(format))
        if (selected.length > 0) return new BarcodeDetector({ formats: selected })
      }
    } catch (_error) {
      // fallback abajo
    }

    try {
      return new BarcodeDetector({ formats: ["ean_13", "ean_8", "upc_a", "upc_e", "code_128"] })
    } catch (_error) {
      return null
    }
  }

  async tryDetectWithNativeDetector() {
    if (!this.videoEl || !this.detector || this.isResolvingDetection) return
    if (this.videoEl.readyState < 2) return

    try {
      const codes = await this.detector.detect(this.videoEl)
      if (!codes || codes.length === 0) return

      const code = (codes[0].rawValue || "").trim()
      this.handleDetectionCandidate(code)
    } catch (_error) {
      // error puntual de frame
    }
  }

  async handleDetectionCandidate(rawCode) {
    const code = this.normalizeDetectedCode(rawCode)
    if (!code || code === this.lastDetectedCode) return

    if (this.isGtinLike(code) && !this.isValidGtinChecksum(code)) {
      return
    }

    const requiredHits = this.requiredHitsFor(code)
    if (this.pendingCode !== code) {
      this.pendingCode = code
      this.pendingHits = 1
      return
    }

    this.pendingHits += 1
    if (this.pendingHits < requiredHits) return

    this.lastDetectedCode = code
    this.pendingCode = null
    this.pendingHits = 0
    await this.onDetectedCode(code)
  }

  async onDetectedCode(rawCode) {
    if (this.isResolvingDetection) return

    const code = (rawCode || "").trim()
    if (!code) return

    this.isResolvingDetection = true
    await this.stopCamera({ keepStatus: true })
    this.applyDetectedCode(code)
  }

  applyDetectedCode(code) {
    if (this.hasBarcodeTarget) {
      this.barcodeTarget.value = code
      this.barcodeTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }

    if (this.hasSourceTarget) this.sourceTarget.value = "camera"

    this.setStatus(`Codigo detectado: ${code}`)
    this.renderScanResult(code)

    if (this.hasFormTarget && this.autoSubmitValue) {
      this.formTarget.requestSubmit()
    }
  }

  normalizeDetectedCode(value) {
    return (value || "").toString().replace(/\s+/g, "").trim()
  }

  requiredHitsFor(code) {
    return this.isGtinLike(code) ? 2 : 3
  }

  isGtinLike(code) {
    return /^[0-9]{8}$/.test(code) || /^[0-9]{12}$/.test(code) || /^[0-9]{13}$/.test(code) || /^[0-9]{14}$/.test(code)
  }

  isValidGtinChecksum(code) {
    const digits = code.split("").map((d) => Number.parseInt(d, 10))
    if (digits.some((d) => Number.isNaN(d))) return false

    const checkDigit = digits.pop()
    let sum = 0
    let useThree = true

    for (let idx = digits.length - 1; idx >= 0; idx -= 1) {
      sum += digits[idx] * (useThree ? 3 : 1)
      useThree = !useThree
    }

    const expected = (10 - (sum % 10)) % 10
    return expected === checkDigit
  }

  ensureScannerRegion() {
    if (!this.hasPreviewTarget) return
    // Ensure the container itself exists without destroying Quagga's injection target mid-flight
    if (!document.getElementById("camera-scanner-preview")) {
      this.previewTarget.innerHTML = '<div id="camera-scanner-preview" class="camera-live-region" style="position: relative; width: 100%; height: 100%; overflow: hidden;"></div>'
    } else {
      // Clear idle message but preserve wrapper
      const idle = this.previewTarget.querySelector('.camera-idle')
      if (idle) idle.style.display = 'none'
    }

    // Inject dynamic CSS constraint so video and canvas sit exactly on top of each other, 
    // overriding the application CSS 'display: flex' that pushes them side-by-side
    let style = document.getElementById("quagga-style-override");
    if (!style) {
      style = document.createElement("style");
      style.id = "quagga-style-override";
      style.innerHTML = `
        #camera-scanner-preview {
          position: relative !important;
          display: block !important; 
        }
        #camera-scanner-preview video,
        #camera-scanner-preview canvas.drawingBuffer {
          position: absolute !important;
          top: 0 !important;
          left: 0 !important;
          width: 100% !important;
          height: 100% !important;
          object-fit: cover !important;
        }
        #camera-scanner-preview canvas.drawingBuffer {
          z-index: 2 !important;
        }
        #camera-scanner-preview video {
          z-index: 1 !important;
        }
      `;
      document.head.appendChild(style);
    }
  }

  renderIdlePreview() {
    if (!this.hasPreviewTarget) return

    this.previewTarget.innerHTML = `
      <div id="camera-scanner-preview" class="camera-live-region" style="position: relative; width: 100%; height: 100%; overflow: hidden;">
        <div class="camera-idle" style="position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 10; background: var(--bg);">
          <span style="font-size: 0.95rem;">Vista de cámara inactiva</span>
          <p style="font-size: 0.8rem; opacity: 0.8;">Pulsa "Activar" para empezar a leer.</p>
        </div>
      </div>
    `
  }

  renderScanResult(code) {
    if (!this.hasScanResultTarget) return

    const hasCode = !!code
    this.scanResultTarget.classList.toggle("is-success", hasCode)

    if (hasCode) {
      this.scanResultTarget.innerHTML = `
        <span class="scan-feedback-label">Escaneo correcto</span>
        <strong class="scan-feedback-code">${code}</strong>
      `
    } else {
      this.scanResultTarget.innerHTML = `
        <span class="scan-feedback-label">Ultimo codigo escaneado</span>
        <strong class="scan-feedback-code">Aun no se ha detectado ningun codigo</strong>
      `
    }
  }

  updateButtons(active) {
    if (this.hasScanButtonTarget) this.scanButtonTarget.disabled = active
    if (this.hasStopButtonTarget) this.stopButtonTarget.disabled = !active
  }

  setStatus(message, isError = false) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("text-danger", isError)
  }

  applyCameraTrackOptimizations(stream) {
    const track = stream?.getVideoTracks?.()[0]
    if (!track || !track.getCapabilities || !track.applyConstraints) return

    const capabilities = track.getCapabilities()
    const advanced = []

    if (Array.isArray(capabilities.focusMode) && capabilities.focusMode.includes("continuous")) {
      advanced.push({ focusMode: "continuous" })
    }

    if (typeof capabilities.zoom === "object" && capabilities.zoom?.max >= 1.5) {
      advanced.push({ zoom: Math.min(2, capabilities.zoom.max) })
    }

    if (advanced.length > 0) {
      track.applyConstraints({ advanced }).catch(() => { })
    }
  }
}
