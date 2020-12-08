function save_in_place(element)
{
	element.nextSibling.classList.add('show')
	params = element.dataset
	Rails.ajax({
		url: `${params.url}`,
		type: 'put',
		data: `id=${params.id}&${params.model}[${params.property}]=${element.innerHTML}`,
		success: () => {
			element.nextSibling.classList.remove('show')
			element.blur()
		},
		error: () => {
			element.nextSibling.classList.add('text-warning')
		}
	})
	return false
}
