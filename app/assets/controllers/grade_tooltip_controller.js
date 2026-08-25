import { Controller } from "@hotwired/stimulus";

// A single shared tooltip for every grade cell inside this element, instead
// of instantiating a bootstrap.Tooltip per cell (the table can hold hundreds
// of them). Styled with Bootstrap's own tooltip CSS classes.

export default class extends Controller {
    connect() {
        this.tip = document.createElement("div");
        this.tip.className = "tooltip bs-tooltip-top grade-tooltip";
        this.tip.setAttribute("role", "tooltip");
        this.tip.innerHTML = '<div class="tooltip-arrow"></div><div class="tooltip-inner"></div>';
        this.tip.style.position = "fixed";
        this.tip.style.pointerEvents = "none";
        this.tip.style.display = "none";
        document.body.append(this.tip);

        this.onOver = this.onOver.bind(this);
        this.onOut = this.onOut.bind(this);
        this.element.addEventListener("mouseover", this.onOver);
        this.element.addEventListener("mouseout", this.onOut);
    }

    disconnect() {
        this.element.removeEventListener("mouseover", this.onOver);
        this.element.removeEventListener("mouseout", this.onOut);
        this.tip.remove();
    }

    onOver(event) {
        var target = event.target.closest("[data-pset-name]");
        if (!target || target === this.current) return;
        this.show(target);
    }

    onOut(event) {
        var target = event.target.closest("[data-pset-name]");
        if (!target || target !== this.current) return;
        if (event.relatedTarget && target.contains(event.relatedTarget)) return;
        this.hide();
    }

    show(target) {
        this.current = target;
        this.tip.querySelector(".tooltip-inner").textContent = target.dataset.psetName;
        this.tip.style.display = "block";

        var rect = target.getBoundingClientRect();
        var tipRect = this.tip.getBoundingClientRect();
        var top = rect.top - tipRect.height - 6;
        var left = rect.left + rect.width / 2 - tipRect.width / 2;
        this.tip.style.top = Math.max(4, top) + "px";
        this.tip.style.left = Math.max(4, Math.min(left, window.innerWidth - tipRect.width - 4)) + "px";

        // Bootstrap's tooltip CSS starts at opacity 0 and relies on this
        // class to reveal it.
        this.tip.classList.add("show");
    }

    hide() {
        this.current = null;
        this.tip.classList.remove("show");
        this.tip.style.display = "none";
    }
}
