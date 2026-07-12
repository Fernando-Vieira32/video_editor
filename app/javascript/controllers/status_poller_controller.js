import { Controller } from "@hotwired/stimulus"

// Polls the task's status endpoint while it is pending/processing and swaps the
// status card's HTML. Plain fetch + innerHTML — reliable and independent of
// WebSocket timing or Turbo Stream rendering.
export default class extends Controller {
  static targets = ["status"]
  static values = { url: String, active: Boolean }

  connect() {
    if (this.activeValue) this.timer = setInterval(() => this.poll(), 1500)
  }

  disconnect() { this.clear() }

  async poll() {
    const response = await fetch(this.urlValue, { headers: { Accept: "text/html" } })
    if (!response.ok) return
    this.statusTarget.innerHTML = await response.text()
    if (this.finished()) this.clear()
  }

  finished() {
    const html = this.statusTarget.innerHTML
    return html.includes("status-card--completed") || html.includes("status-card--failed")
  }

  clear() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }
}
