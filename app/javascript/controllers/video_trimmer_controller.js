import { Controller } from "@hotwired/stimulus"

// Visual timeline trimmer: previews the selected file locally, lets the user
// mark an in/out range (drag handles, click-to-seek, or mark buttons) and
// writes the range into the hidden start/end fields the operation consumes.
export default class extends Controller {
  static targets = [
    "file", "stage", "video", "playButton", "timeline", "selection",
    "inHandle", "outHandle", "playhead", "inLabel", "outLabel",
    "durationLabel", "startField", "endField", "filmstrip"
  ]
  static values = { mode: String }

  connect() {
    this.dragging = null
    this.previewing = false
    this.onMove = this.onMove.bind(this)
    this.onUp = this.onUp.bind(this)
    document.addEventListener("mousemove", this.onMove)
    document.addEventListener("mouseup", this.onUp)
    this.videoTarget.addEventListener("loadedmetadata", () => this.onMetadata())
    this.videoTarget.addEventListener("timeupdate", () => this.onTimeUpdate())
    this.videoTarget.addEventListener("play", () => this.syncPlayButton())
    this.videoTarget.addEventListener("pause", () => this.syncPlayButton())
  }

  disconnect() {
    document.removeEventListener("mousemove", this.onMove)
    document.removeEventListener("mouseup", this.onUp)
    if (this.url) URL.revokeObjectURL(this.url)
  }

  load() {
    const file = this.fileTarget.files[0]
    if (!file) return
    if (this.url) URL.revokeObjectURL(this.url)
    this.url = URL.createObjectURL(file)
    this.videoTarget.src = this.url
    this.stageTarget.hidden = false
  }

  onMetadata() {
    this.duration = this.videoTarget.duration || 0
    this.inTime = this.duration * 0.25
    this.outTime = this.duration * 0.75
    this.durationLabelTarget.textContent = `Duração: ${this.format(this.duration)}`
    this.render()
    this.buildFilmstrip()
  }

  // --- filmstrip (client-side thumbnails) ------------------------------------

  async buildFilmstrip() {
    const token = (this.buildToken = {})
    this.filmstripTarget.innerHTML = ""
    const strip = document.createElement("video")
    strip.src = this.url
    strip.muted = true
    await this.metadataReady(strip)
    if (!strip.videoWidth || !this.duration) return
    await this.captureFrames(strip, token)
  }

  async captureFrames(strip, token) {
    const count = this.thumbCount(strip)
    const { canvas, ctx } = this.thumbCanvas(strip)
    for (let i = 0; i < count; i++) {
      if (token !== this.buildToken) return
      const time = ((i + 0.5) / count) * this.duration
      this.appendThumb(await this.captureAt(strip, time, canvas, ctx))
    }
  }

  captureAt(strip, time, canvas, ctx) {
    return new Promise((resolve) => {
      const onSeeked = () => {
        strip.removeEventListener("seeked", onSeeked)
        ctx.drawImage(strip, 0, 0, canvas.width, canvas.height)
        resolve(canvas.toDataURL("image/jpeg", 0.6))
      }
      strip.addEventListener("seeked", onSeeked)
      strip.currentTime = time
    })
  }

  appendThumb(dataUrl) {
    const img = document.createElement("img")
    img.src = dataUrl
    this.filmstripTarget.appendChild(img)
  }

  metadataReady(video) {
    return new Promise((resolve) => {
      if (video.readyState >= 1) return resolve()
      video.addEventListener("loadedmetadata", () => resolve(), { once: true })
    })
  }

  thumbCount(strip) {
    const rect = this.timelineTarget.getBoundingClientRect()
    const thumbWidth = this.timelineTarget.clientHeight * (strip.videoWidth / strip.videoHeight)
    return Math.min(Math.max(Math.ceil(rect.width / thumbWidth), 6), 16)
  }

  thumbCanvas(strip) {
    const canvas = document.createElement("canvas")
    canvas.height = 96
    canvas.width = Math.round(96 * (strip.videoWidth / strip.videoHeight))
    return { canvas, ctx: canvas.getContext("2d") }
  }

  // --- range editing ---------------------------------------------------------

  dragIn(event) { event.preventDefault(); this.dragging = "in" }
  dragOut(event) { event.preventDefault(); this.dragging = "out" }

  onMove(event) {
    if (!this.dragging) return
    const time = this.timeAt(event.clientX)
    if (this.dragging === "in") this.inTime = Math.min(time, this.outTime - 0.05)
    else this.outTime = Math.max(time, this.inTime + 0.05)
    this.render()
  }

  onUp() { this.dragging = null }

  markIn() { this.inTime = Math.min(this.videoTarget.currentTime, this.outTime - 0.05); this.render() }
  markOut() { this.outTime = Math.max(this.videoTarget.currentTime, this.inTime + 0.05); this.render() }

  seek(event) {
    if (event.target.classList.contains("timeline__handle")) return
    this.videoTarget.currentTime = this.timeAt(event.clientX)
  }

  // --- playback --------------------------------------------------------------

  togglePlay() {
    this.videoTarget.paused ? this.videoTarget.play() : this.videoTarget.pause()
  }

  togglePreview(event) {
    this.previewing = event.target.checked
    if (this.previewing) this.videoTarget.currentTime = this.previewStart()
  }

  onTimeUpdate() {
    this.positionPlayhead()
    if (this.previewing) this.applyPreview()
  }

  applyPreview() {
    const t = this.videoTarget.currentTime
    if (this.modeValue === "remove" && t >= this.inTime && t < this.outTime) {
      this.videoTarget.currentTime = this.outTime
    } else if (this.modeValue === "keep" && (t < this.inTime || t >= this.outTime)) {
      this.videoTarget.currentTime = this.inTime
    }
  }

  previewStart() { return this.modeValue === "keep" ? this.inTime : 0 }

  // --- rendering -------------------------------------------------------------

  render() {
    const inPct = this.pct(this.inTime)
    const outPct = this.pct(this.outTime)
    this.selectionTarget.style.left = `${inPct}%`
    this.selectionTarget.style.width = `${outPct - inPct}%`
    this.inHandleTarget.style.left = `${inPct}%`
    this.outHandleTarget.style.left = `${outPct}%`
    this.inLabelTarget.textContent = this.format(this.inTime)
    this.outLabelTarget.textContent = this.format(this.outTime)
    this.writeFields()
  }

  positionPlayhead() {
    this.playheadTarget.style.left = `${this.pct(this.videoTarget.currentTime)}%`
  }

  writeFields() {
    this.startFieldTarget.value = this.format(this.inTime)
    this.endFieldTarget.value = this.format(this.outTime)
  }

  syncPlayButton() {
    this.playButtonTarget.textContent = this.videoTarget.paused ? "▶ Play" : "⏸ Pause"
  }

  // --- helpers ---------------------------------------------------------------

  timeAt(clientX) {
    const rect = this.timelineTarget.getBoundingClientRect()
    const ratio = Math.min(Math.max((clientX - rect.left) / rect.width, 0), 1)
    return ratio * this.duration
  }

  pct(time) { return this.duration ? (time / this.duration) * 100 : 0 }

  format(seconds) {
    const total = Math.max(seconds || 0, 0)
    const h = String(Math.floor(total / 3600)).padStart(2, "0")
    const m = String(Math.floor((total % 3600) / 60)).padStart(2, "0")
    const s = String(Math.floor(total % 60)).padStart(2, "0")
    const ms = String(Math.round((total % 1) * 1000)).padStart(3, "0")
    return `${h}:${m}:${s}.${ms}`
  }
}
