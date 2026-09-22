import { Controller } from "@hotwired/stimulus"

// The room map is rendered by the server and re-rendered as a whole after every
// change, so this controller only does the two things the server cannot: it
// opens a popover on the table you clicked, and it filters the student list as
// you type. A room is hundreds of tables, so the listeners are delegated from
// the frame rather than attached per table.
//
// Everything that changes state goes through the hidden forms in the frame, so
// there is one code path for placement and one for switching a table off, both
// with the usual CSRF handling and both landing in the controller.

export default class extends Controller {
    static targets = [ "placeForm", "placeSeat", "placeSubmit", "placeReplace",
                       "placeSwap", "toggleForm", "toggleSeat" ]
    static values = { phase: String, students: Array, reload: Number }

    connect() {
        this.popover = null
        this.activeIndex = -1

        this.onClick = (e) => this.click(e)
        this.onContextMenu = (e) => this.contextMenu(e)
        this.onKeydown = (e) => this.keydown(e)
        this.onDocumentClick = (e) => this.documentClick(e)
        this.onDragStart = (e) => this.dragStart(e)
        this.onDragOver = (e) => this.dragOver(e)
        this.onDragLeave = (e) => this.dragLeave(e)
        this.onDrop = (e) => this.drop(e)
        this.onDragEnd = (e) => this.dragEnd(e)

        this.element.addEventListener("click", this.onClick)
        this.element.addEventListener("contextmenu", this.onContextMenu)
        this.element.addEventListener("keydown", this.onKeydown)
        document.addEventListener("click", this.onDocumentClick)

        if (this.phaseValue === "place") {
            this.element.addEventListener("dragstart", this.onDragStart)
            this.element.addEventListener("dragover", this.onDragOver)
            this.element.addEventListener("dragleave", this.onDragLeave)
            this.element.addEventListener("drop", this.onDrop)
            this.element.addEventListener("dragend", this.onDragEnd)
        }

        this.restoreFocus()

        // only the overview refreshes itself: a reload underneath an open
        // search box would throw away what you were typing
        if (this.reloadValue > 0) {
            this.timer = setInterval(() => {
                if (this.popover) return
                var frame = this.element.closest("turbo-frame")
                if (frame) frame.reload()
            }, this.reloadValue * 1000)
        }
    }

    disconnect() {
        this.element.removeEventListener("click", this.onClick)
        this.element.removeEventListener("contextmenu", this.onContextMenu)
        this.element.removeEventListener("keydown", this.onKeydown)
        document.removeEventListener("click", this.onDocumentClick)
        this.element.removeEventListener("dragstart", this.onDragStart)
        this.element.removeEventListener("dragover", this.onDragOver)
        this.element.removeEventListener("dragleave", this.onDragLeave)
        this.element.removeEventListener("drop", this.onDrop)
        this.element.removeEventListener("dragend", this.onDragEnd)
        clearInterval(this.timer)
        // the frame is being replaced, quite possibly by the redraw one of
        // this popover's own forms asked for, so leave the note about which
        // table was open for the next instance to pick up
        this.closePopover({ forget: false })
    }

    // --- events ---

    click(e) {
        if (e.target.closest(".room-popover")) return

        // a drag ends in a click in some browsers; that click is not a request
        // to open the search box on the table you dropped onto
        if (this.justDragged) {
            this.justDragged = false
            return
        }

        var seat = e.target.closest(".room-seat")
        if (!seat) return
        if (seat.classList.contains("room-seat-disabled")) return

        if (this.phaseValue === "place") {
            e.preventDefault()
            this.openSearch(seat)
        } else if (this.phaseValue === "overview" && seat.querySelector(".room-seat-detail")) {
            e.preventDefault()
            this.openDetail(seat)
        }
    }

    contextMenu(e) {
        if (this.phaseValue !== "define") return

        var seat = e.target.closest(".room-seat")
        if (!seat) return

        e.preventDefault()
        this.toggleSeatTarget.value = seat.dataset.seat
        this.toggleFormTarget.requestSubmit()
    }

    keydown(e) {
        if (e.key === "Escape") {
            var open = this.element.querySelector("details.room-missing[open]")
            if (open) open.removeAttribute("open")
        }

        var seat = e.target.closest(".room-seat")
        if (seat && (e.key === "Enter" || e.key === " ") && !this.popover) {
            e.preventDefault()
            seat.click()
        }
    }

    documentClick(e) {
        this.closeMissingList(e)
        if (!this.popover) return
        if (this.popover.contains(e.target)) return
        if (e.target.closest(".room-seat")) return
        this.closePopover()
    }

    // The list of students who are not in the room is a <details>, which stays
    // open until it is clicked again. Closing it on a click elsewhere is what
    // everything else on this page does.
    closeMissingList(e) {
        var open = this.element.querySelector("details.room-missing[open]")
        if (open && !open.contains(e.target)) open.removeAttribute("open")
    }

    // The column labels save themselves, so there is no Save button to forget.
    submitLabels(e) {
        e.target.form.requestSubmit()
    }

    // --- dragging a student to another table ---
    //
    // Only an occupied table is draggable, and only while placing. Dropping on
    // an empty table moves the student; dropping on an occupied one trades the
    // two, which is what the gesture looks like it should do and, unlike a
    // replace, leaves nobody unplaced. Dragging needs a mouse, so clicking a
    // table does everything dragging does.

    dragStart(e) {
        var seat = e.target.closest(".room-seat")
        if (!seat || !seat.dataset.submitId) return

        this.closePopover()
        this.dragged = seat
        seat.classList.add("room-seat-dragging")
        e.dataTransfer.effectAllowed = "move"
        // Firefox starts no drag at all without something on the transfer
        e.dataTransfer.setData("text/plain", seat.dataset.seat)
    }

    dragOver(e) {
        var seat = this.dropTarget(e)
        if (!seat) return

        e.preventDefault()
        e.dataTransfer.dropEffect = "move"
        if (seat !== this.over) {
            if (this.over) this.over.classList.remove("room-seat-over")
            seat.classList.add("room-seat-over")
            this.over = seat
        }
    }

    dragLeave(e) {
        var seat = e.target.closest(".room-seat")
        if (seat && seat === this.over && !seat.contains(e.relatedTarget)) {
            seat.classList.remove("room-seat-over")
            this.over = null
        }
    }

    drop(e) {
        var seat = this.dropTarget(e)
        if (!seat) return

        e.preventDefault()
        this.justDragged = true

        var submitId = this.dragged.dataset.submitId
        this.clearDragMarks()
        this.place(seat.dataset.seat, submitId, false, { swap: true })
    }

    dragEnd() {
        this.clearDragMarks()
    }

    // The table a drop would land on: any enabled table other than the one
    // being dragged.
    dropTarget(e) {
        if (!this.dragged) return null
        var seat = e.target.closest(".room-seat")
        if (!seat) return null
        if (seat === this.dragged) return null
        if (seat.classList.contains("room-seat-disabled")) return null
        return seat
    }

    clearDragMarks() {
        if (this.dragged) this.dragged.classList.remove("room-seat-dragging")
        if (this.over) this.over.classList.remove("room-seat-over")
        this.dragged = null
        this.over = null
    }

    // --- placing ---

    openSearch(seat) {
        var taken = seat.dataset.submitId
        var popover = this.openPopover(seat)

        var header = document.createElement("p")
        header.className = "room-popover-header"
        header.textContent = "Table " + seat.dataset.seatLabel
        popover.appendChild(header)

        if (taken) {
            var current = this.studentsValue.find((s) => String(s.id) === String(taken))
            var remove = document.createElement("button")
            remove.type = "button"
            remove.className = "btn btn-sm btn-outline-danger w-100 mb-2"
            remove.textContent = "Remove " + (current ? current.name : "this student")
            remove.addEventListener("click", () => this.place(seat.dataset.seat, "", false))
            popover.appendChild(remove)
        }

        var input = document.createElement("input")
        input.type = "text"
        input.className = "form-control form-control-sm"
        input.placeholder = taken ? "Replace with…" : "Type a name…"
        input.autocomplete = "off"
        popover.appendChild(input)

        var list = document.createElement("div")
        list.className = "room-popover-list"
        popover.appendChild(list)

        this.searchInput = input
        this.searchList = list
        this.searchSeat = seat

        input.addEventListener("input", () => this.renderMatches())
        input.addEventListener("keydown", (e) => this.searchKeydown(e))

        this.renderMatches()
        input.focus()
    }

    renderMatches() {
        var query = this.normalize(this.searchInput.value.trim())
        var seat = this.searchSeat.dataset.seat
        var matches = this.studentsValue.filter((student) => {
            if (student.seat === seat) return false
            if (!query) return true
            return this.normalize(student.name).split(/\s+/).some((part) => part.startsWith(query))
        })

        // whoever is already sitting somewhere goes last and is marked, so
        // picking one is a deliberate move rather than an accident
        matches.sort((a, b) => {
            if (!a.seat && b.seat) return -1
            if (a.seat && !b.seat) return 1
            return a.name.localeCompare(b.name)
        })

        this.searchList.innerHTML = ""
        this.activeIndex = -1

        if (matches.length === 0) {
            var none = document.createElement("p")
            none.className = "room-popover-empty"
            none.textContent = "Nobody taking this exam matches."
            this.searchList.appendChild(none)
            return
        }

        matches.slice(0, 12).forEach((student) => {
            var item = document.createElement("button")
            item.type = "button"
            item.className = "room-popover-item" + (student.seat ? " room-popover-item-placed" : "")
            item.dataset.submitId = student.id

            var name = document.createElement("span")
            name.textContent = student.name
            item.appendChild(name)

            var note = document.createElement("small")
            note.textContent = student.seat ? "at " + student.seat_label : (student.pin || "")
            item.appendChild(note)

            item.addEventListener("click", () => this.pick(student))
            this.searchList.appendChild(item)
        })

        // once you have typed something the first match is highlighted, so
        // Enter always picks one particular student rather than guessing
        if (query) {
            this.setActive(Array.from(this.searchList.querySelectorAll(".room-popover-item")), 0)
        }
    }

    searchKeydown(e) {
        var items = Array.from(this.searchList.querySelectorAll(".room-popover-item"))

        if (e.key === "ArrowDown") {
            e.preventDefault()
            this.setActive(items, this.activeIndex + 1)
        } else if (e.key === "ArrowUp") {
            e.preventDefault()
            this.setActive(items, this.activeIndex - 1)
        } else if (e.key === "Enter") {
            e.preventDefault()
            var chosen = items[this.activeIndex] || (items.length === 1 ? items[0] : null)
            if (chosen) chosen.click()
            return
        } else if (e.key === "Escape") {
            e.preventDefault()
            this.closePopover()
        }
    }

    setActive(items, index) {
        if (items.length === 0) return
        if (items[this.activeIndex]) items[this.activeIndex].classList.remove("active")
        this.activeIndex = ((index % items.length) + items.length) % items.length
        items[this.activeIndex].classList.add("active")
        items[this.activeIndex].scrollIntoView({ block: "nearest" })
    }

    pick(student) {
        var seat = this.searchSeat
        var occupied = seat.dataset.submitId

        if (student.seat && student.seat !== seat.dataset.seat) {
            var question = student.name + " is at " + student.seat_label +
                ". Move them to " + seat.dataset.seatLabel + "?"
            if (!window.confirm(question)) return
        }

        if (occupied) {
            var occupant = this.studentsValue.find((s) => String(s.id) === String(occupied))
            var replace = (occupant ? occupant.name : "The student there") +
                " will be taken off " + seat.dataset.seatLabel + " and left unplaced. Continue?"
            if (!window.confirm(replace)) return
        }

        this.place(seat.dataset.seat, student.id, true)
    }

    place(seat, submitId, replace, options = {}) {
        this.placeSeatTarget.value = seat
        this.placeSubmitTarget.value = submitId
        this.placeReplaceTarget.value = replace ? "1" : ""
        this.placeSwapTarget.value = options.swap ? "1" : ""
        this.closePopover()
        // after closing, so that closing does not wipe what we just noted
        this.remember(seat)
        this.placeFormTarget.requestSubmit()
    }

    // --- popover plumbing ---

    openPopover(seat) {
        this.closePopover()

        var popover = document.createElement("div")
        popover.className = "room-popover"
        seat.appendChild(popover)
        this.popover = popover

        // keep it on screen when the table is against the right edge
        var rect = popover.getBoundingClientRect()
        if (rect.right > window.innerWidth - 8) popover.classList.add("room-popover-left")

        return popover
    }

    // The detail block is already in the page, forms and all, so it is shown
    // where it stands rather than copied: a copy would duplicate the ids the
    // lock switch and its label rely on.
    openDetail(seat) {
        this.closePopover()
        var detail = seat.querySelector(".room-seat-detail")
        if (!detail) return
        detail.hidden = false
        detail.classList.add("room-popover", "room-popover-detail")
        if (detail.getBoundingClientRect().right > window.innerWidth - 8) {
            detail.classList.add("room-popover-left")
        }
        this.popover = detail
        this.popoverIsDetail = true

        // locking a student or resetting their IP redraws the whole room, so
        // the popover would close under your hand. Note which table it was on
        // and put it back afterwards.
        this.remember(seat.dataset.seat, { detail: true })
    }

    closePopover(options = {}) {
        if (!this.popover) return
        if (this.popoverIsDetail) {
            this.popover.hidden = true
            this.popover.classList.remove("room-popover", "room-popover-detail", "room-popover-left")
            this.popoverIsDetail = false
        } else {
            this.popover.remove()
        }
        this.popover = null
        this.searchInput = null
        this.searchList = null
        this.searchSeat = null
        if (options.forget !== false) this.forget()
    }

    forget() {
        try {
            sessionStorage.removeItem("room-map-focus")
            sessionStorage.removeItem("room-map-detail")
        } catch (e) { }
    }

    // The frame is re-rendered after a placement, which throws away what had
    // focus. Putting it back on the table you just filled keeps the room from
    // jumping away under you. Storage can be unavailable, and a lost focus is
    // not worth an error.
    remember(seat, options = {}) {
        try {
            sessionStorage.setItem("room-map-focus", seat)
            sessionStorage.setItem("room-map-detail", options.detail ? "1" : "")
        } catch (e) { }
    }

    restoreFocus() {
        var seat, reopen
        try {
            seat = sessionStorage.getItem("room-map-focus")
            reopen = sessionStorage.getItem("room-map-detail") === "1"
            sessionStorage.removeItem("room-map-focus")
            sessionStorage.removeItem("room-map-detail")
        } catch (e) {
            return
        }
        if (!seat) return

        var el = this.element.querySelector('.room-seat[data-seat="' + seat + '"]')
        if (!el) return

        el.focus({ preventScroll: true })
        if (reopen && this.phaseValue === "overview") this.openDetail(el)
    }

    // Lower case and without accents, so "jose" finds "José".
    normalize(text) {
        return text.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
    }
}
