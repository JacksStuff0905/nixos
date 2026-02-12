macbook:
	sudo nixos-rebuild switch --flake ./#macbook

vm-docker:
	sudo nixos-rebuild switch --flake ./#vm-docker

remote:
	sudo nixos-rebuild switch --flake .#$(config) --target-host root@$(ip) --build-host ""
