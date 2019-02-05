function showExtra(id, imid) {
	if (document.getElementById(id).style.display == 'block') {
		document.getElementById(id).style.display = 'none';
		document.getElementById(imid).src = 'inform:/doc_images/extra.png';
	} else {
		document.getElementById(id).style.display = 'block';
		document.getElementById(imid).src = 'inform:/doc_images/extraclose.png';
	}
}
function showBasic(id) {
	if (document.getElementById(id).style.display == '') {
		document.getElementById(id).style.display = 'none';
	} else {
		document.getElementById(id).style.display = '';
	}
}
function showResp(id, imid) {
	if (document.getElementById(id)) {
		if (document.getElementById(id).style.display == 'block') {
			document.getElementById(id).style.display = 'none';
			document.getElementById(imid).src = 'inform:/doc_images/responses.png';
		} else {
			document.getElementById(id).style.display = 'block';
			document.getElementById(imid).src = 'inform:/doc_images/responsesclose.png';
		}
	}
}
function showAllResp(tot) {
	for (var i=0;i<tot;i++) {
		showResp('extra'+(1000000+i), 'plus'+(1000000+i));
	}
}
function pasteCode(code) {
	var myProject = project();
	myProject.selectView('source');
	myProject.pasteCode(code);
}
