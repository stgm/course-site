/* Edited version from https://github.com/jsvine/nbpreview */

let render_notebook = function (ipynb, holder) {
    let notebook = nb.parse(ipynb);
    let rendered  = notebook.render();

    holder.appendChild(rendered);
};

let load_json = function (json, holder) {
    let parsed = JSON.parse(json);
    render_notebook(parsed, holder);
};
