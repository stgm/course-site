import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["cell"];

    navigate(event) {
        // leave word jumps and text selection to the browser
        if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;

        var cell = event.target;
        var rows = this.rows;
        var row = rows.findIndex((cells) => cells.includes(cell));
        if (row === -1) return;
        var column = rows[row].indexOf(cell);

        var destination;
        switch (event.key) {
            case "ArrowUp":
                destination = rows[row - 1] && rows[row - 1][column];
                break;
            case "ArrowDown":
                destination = rows[row + 1] && rows[row + 1][column];
                break;
            case "ArrowLeft":
                if (this.caretHeldInside(cell, 0)) return;
                destination = rows[row][column - 1];
                break;
            case "ArrowRight":
                if (this.caretHeldInside(cell, cell.value.length)) return;
                destination = rows[row][column + 1];
                break;
            default:
                return;
        }

        // at the edges of the grid, let the browser do whatever it normally does
        if (!destination) return;

        event.preventDefault();
        this.enter(destination, event.key);
    }

    // the cells of the grid, grouped per table row, in document order
    get rows() {
        var rows = new Map();
        for (var cell of this.cellTargets) {
            var row = cell.closest("tr");
            if (!rows.has(row)) rows.set(row, []);
            rows.get(row).push(cell);
        }
        return Array.from(rows.values());
    }

    // a text cell only hands over focus once the caret has reached its edge
    caretHeldInside(cell, edge) {
        if (!cell.hasAttribute("data-caret-guard")) return false;
        if (cell.selectionStart !== cell.selectionEnd) return true;
        return cell.selectionStart !== edge;
    }

    enter(cell, key) {
        cell.focus();
        if (cell.hasAttribute("data-caret-guard")) {
            // keep the caret going the way we were travelling
            var caret = key === "ArrowLeft" ? 0 : cell.value.length;
            cell.setSelectionRange(caret, caret);
        } else {
            // typing replaces the grade that is already there
            cell.select();
        }
    }
}
