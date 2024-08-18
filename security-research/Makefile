clone:
	git clone "$(url)" --branch "$(branch)" --single-branch
	git reset --hard "$(commit)" 
add:
	git add -A
	git commit -S -m "$(m)"
	git push