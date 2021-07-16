window.MathJax = {
  tex: {
    inlineMath: [['$', '$'], ['\\(', '\\)']]
  }
};

document.addEventListener('turbo:load', function() {
	if(MathJax.typeset)
		MathJax.typeset();
});
