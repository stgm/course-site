window.MathJax = {
  tex: {
    inlineMath: [['$', '$'], ['\\(', '\\)']]
  }
};

document.addEventListener('turbolinks:load', function() {
	if(MathJax.typeset)
		MathJax.typeset();
});
