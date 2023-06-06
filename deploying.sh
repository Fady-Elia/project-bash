#!/bin/bash

report_error() {
  local function_name=$1
  echo -e "\e[31mError occurred while executing $function_name\e[0m"
  exit 1
}

execute_function() {
  local function_name=$1
  echo -e "\e[33mRunning $function_name...\e[0m"
  if $function_name; then
    echo -e "\e[32m$function_name completed successfully.\e[0m"
  else
    report_error $function_name
  fi
}

# Function to install Node.js
install_nodejs() {
  curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  sudo apt-get install -y nodejs
}

# Function to create an IP configuration file
create_ip_config() {
  sudo systemctl enable systemd-networkd.service
  sudo systemctl start systemd-networkd.service

  sudo mkdir -p /etc/network/interfaces.d/

  sudo tee /etc/network/interfaces.d/ens33.conf > /dev/null << EOL
auto ens33
iface ens33 inet static
    address 192.168.1.100
    netmask 255.255.255.0
EOL

  sudo systemctl restart systemd-networkd.service
}

# Function to create a Linux user called "node"
create_linux_user() {
  sudo useradd -m node
}

# Function to retrieve the IP address
get_ip_address() {
  ip_address=$(ip -4 addr show ens33 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
}

# Function to install PostgreSQL
install_postgresql() {
  sudo apt-get update
  sudo apt-get install postgresql postgresql-contrib -y
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
  sudo systemctl status postgresql
  sudo -u postgres psql -c "CREATE USER new_user WITH PASSWORD 'root';"
  sudo -u postgres createdb new_user
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE new_user TO new_user;" &
}

# Function to clone the GitHub repository
clone_repository() {
  git clone https://github.com/omarmohsen/pern-stack-example.git
}

# Function to run UI tests
run_ui_tests() {
  cd
  cd pern-stack-example/ui
  if ! command -v npm &>/dev/null; then
    sudo apt install npm -y
  fi
  npm run test 
}

# Function to build the UI
build_ui() {
  cd
  cd pern-stack-example/ui
  npm install
  npm run build 
}

# Function to set the backend environment
set_backend_env() {
  cd
  cd pern-stack-example/api
  sed -i "s/const HOST = 'localhost';/const HOST = '${ip_address//./\\.}';/" webpack.config.js
  sed -i "s/const PG_CONNECTION = 'postgresql:\/\/localhost\/pernstack';/const PG_CONNECTION = 'postgresql:\/\/new_user:root@localhost:5432\/new_user';/" webpack.config.js
  ENVIRONMENT=demo npm run build  
}

# Function to start the application
start_application() {
  cd
  cd pern-stack-example
  cp -r api/dist/* .
  cp api/swagger.css .
  node api.bundle.js
}

# Function to open the application in the browser
open_in_browser() {
  ip_address="192.168.1.100"  # Replace with your desired IP address
  echo -e "\e[32mOpening $ip_address in the browser...\e[0m"
  xdg-open "http://$ip_address"
}

# Execute the functions
execute_function install_nodejs
execute_function create_ip_config
create_linux_user
execute_function get_ip_address
execute_function install_postgresql
clone_repository
execute_function run_ui_tests
execute_function build_ui
execute_function set_backend_env
execute_function start_application
execute_function open_in_browser
