#!/bin/bash
cd /home/ubuntu
sudo apt update
sudo apt install python3-pip -y
sudo python3 -m pip install ansible --break-system-packages
tee -a playbook.yml > /dev/null <<EOF
---
- hosts: localhost
  tasks:
    - name: Install python
      ansible.builtin.apt:
        pkg:
          - python3
          - virtualenv
        update_cache: yes
      become: true
    - name: Baixando os arquivos do projeto
      ansible.builtin.git:
        repo: https://github.com/alura-cursos/clientes-leo-api.git
        dest: /home/ubuntu/tcc
        version: master
        force: true
    - name: Instalando dependencias com o pip (Django e Django Rest)
      ansible.builtin.pip:
        virtualenv: /home/ubuntu/tcc/venv
        requirements: /home/ubuntu/tcc/requirements.txt
    - name: Alterando o hosts do settings.py
      ansible.builtin.lineinfile:
        path: /home/ubuntu/tcc/setup/settings.py
        regexp: "ALLOWED_HOSTS ="
        line: 'ALLOWED_HOSTS = ["*"]'
        # Se não achar, não vai fazer nada
        backrefs: yes
    - name: Iniciando setup pip
      ansible.builtin.pip:
        name: setuptools
        virtualenv: /home/ubuntu/tcc/venv
    - name: configurando o banco de dados
      shell: ". /home/ubuntu/tcc/venv/bin/activate; python /home/ubuntu/tcc/manage.py migrate"
    - name: carregando os dados iniciais
      shell: ". /home/ubuntu/tcc/venv/bin/activate; python /home/ubuntu/tcc/manage.py loaddata clientes.json"
    - name: Iniciando o servidor
      shell: ". /home/ubuntu/tcc/venv/bin/activate; nohup python /home/ubuntu/tcc/manage.py runserver 0.0.0.0:8000 &"
EOT
ansible-playbook playbook.yml