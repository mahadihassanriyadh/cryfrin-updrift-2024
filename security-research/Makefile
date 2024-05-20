clone:
	git clone "$(url)" --branch "$(branch)" --single-branch
	git reset --hard "$(commit)" 
add:
	git add -A
	git commit -s -m "$(m)"
	git push