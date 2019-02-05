function showExtra(id, imid) {
	if (document.getElementById(id).style.display == 'block') {
		document.getElementById(id).style.display = 'none';
		document.getElementById(imid).src = 'inform:/extra.png';
	} else {
		document.getElementById(id).style.display = 'block';
		document.getElementById(imid).src = 'inform:/extraclose.png';
	}
}
function openExtra(id, imid) {
	document.getElementById(id).style.display = 'block';
	document.getElementById(imid).src = 'inform:/extraclose.png';
}
function closeExtra(id, imid) {
	document.getElementById(id).style.display = 'none';
	document.getElementById(imid).src = 'inform:/extra.png';
}
function pasteCode(code) {
    var myProject = project();

    myProject.selectView('source');
    myProject.pasteCode(code);
}
