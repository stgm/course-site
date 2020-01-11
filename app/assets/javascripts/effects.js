Element.prototype.highlight_briefly = function ()
{
	this.onanimationend = function ()
	{
		this.classList.remove("highlight")
	};
	
	this.classList.add("highlight")
};
