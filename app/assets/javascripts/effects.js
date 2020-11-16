Element.prototype.highlight_briefly = function ()
{
	this.onanimationend = function ()
	{
		this.classList.remove("highlight-briefly")
	};
	
	this.classList.add("highlight-briefly")
};

function enableTooltips()
{
	var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-toggle="tooltip"]'))
	var tooltipList = tooltipTriggerList.map(
		function (tooltipTriggerEl)
		{
			return new bootstrap.Tooltip(tooltipTriggerEl)
		}
	)
}
