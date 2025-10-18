#!/usr/bin/env bash

LOGFILE="logs/install.log"
exec > >(tee -a "$LOGFILE") 2>&1

set -e

echo "=== Початок встановлення: $(date) ==="

# Функція перевірки версії
check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "[OK] $1 встановлено: $($1 --version 2>/dev/null | head -n1)"
        return 0
    else
        echo "[ ] $1 відсутній"
        return 1
    fi
}

# Docker
if ! check_command docker; then
    echo ">>> Встановлюю Docker..."
    sudo apt-get update -y
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
fi

# Docker Compose
if ! check_command docker-compose; then
    echo ">>> Встановлюю Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Python ≥ 3.9
PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}' || echo "0")
if [ "$(printf '%s\n' "3.9" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.9" ]; then
    echo ">>> Встановлюю Python 3.9+..."
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip python3-venv
fi

# pip
if ! check_command pip3; then
    echo ">>> Встановлюю pip..."
    sudo apt-get install -y python3-pip
fi

# ML-бібліотеки
for pkg in torch torchvision pillow django; do
    if python3 -m pip show $pkg >/dev/null 2>&1; then
        echo "[OK] Python пакет $pkg встановлено: $(python3 -m pip show $pkg | grep Version | awk '{print $2}')"
    else
        echo ">>> Встановлюю $pkg..."
        python3 -m pip install --upgrade $pkg
    fi
done

echo "=== Завершено: $(date) ==="