.PHONY: % default

%:
	cd ~/homelab-public/ansible && \
	ansible-playbook playbooks/$@.yml \
		--vault-password-file ~/.ansible_vault_pass \
		-l $@ \
		$(if $(TAGS),--tags $(TAGS))
