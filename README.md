# Ansible script to setup a VPS for syncing Obsidian notes and backups

To run the script, use the following command:
`ansible-playbook setup.yml -e "secrets_file=secrets.yml" --ask-vault-pass`

## Development

Run tests with
```bash
ansible-playbook setup.yml --syntax-check
ansible-galaxy collection install ansible.posix community.docker
ansible-lint
```
