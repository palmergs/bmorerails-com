import { Controller } from "@hotwired/stimulus"

// Toggles the small-screen navigation panel and keeps aria-expanded honest.
export default class extends Controller {
  static targets = ["panel", "button"]

  toggle() {
    this.panelTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
