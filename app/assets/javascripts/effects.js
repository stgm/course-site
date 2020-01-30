Element.prototype.highlight_briefly = function ()
{
	this.onanimationend = function ()
	{
		this.classList.remove("highlight-briefly")
	};
	
	this.classList.add("highlight-briefly")
};
