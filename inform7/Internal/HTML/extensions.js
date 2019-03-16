function showExtra(id, imid) {
	if (document.getElementById(id).style.display == 'block') {
		document.getElementById(id).style.display = 'none';
		document.getElementById(imid).src = 'inform:/doc_images/extrarboff.png';
	} else {
		document.getElementById(id).style.display = 'block';
		document.getElementById(imid).src = 'inform:/doc_images/extrarbon.png';
	}
}
function openExtra(id, imid) {
	document.getElementById(id).style.display = 'block';
	document.getElementById(imid).src = 'inform:/doc_images/extrarbon.png';
}
function closeExtra(id, imid) {
	document.getElementById(id).style.display = 'none';
	document.getElementById(imid).src = 'inform:/doc_images/extrarboff.png';
}
