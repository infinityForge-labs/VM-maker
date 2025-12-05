#!/bin/bash
set -euo pipefail

# =============================
# Enhanced Multi-VM Manager Pro
# =============================

# Color definitions
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[1;34m'
readonly MAGENTA='\033[1;35m'
readonly CYAN='\033[1;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly RESET='\033[0m'
readonly BOLD='\033[1m'

# Animation speed
readonly ANIM_SPEED=0.02

# Function to animate text
animate_text() {
    local text="$1"
    local color="${2:-$WHITE}"
    echo -ne "$color"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $ANIM_SPEED
    done
    echo -e "$RESET"
}

# Function to display animated header
display_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                ║
║  ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗███████╗ ██████╗ ██████╗  ██████╗   ║
║  ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔═══██╗██╔══██╗██╔════╝   ║
║  ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝ █████╗  ██║   ██║██████╔╝██║  ███╗  ║
║  ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝  ██╔══╝  ██║   ██║██╔══██╗██║   ██║  ║
║  ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║   ██║     ╚██████╔╝██║  ██║╚██████╔╝  ║
║  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ║
║                                                                                                ║
║                         ⚡ POWERED BY InfinityForge - VM Management Pro ⚡                     ║
║                                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

# Function to display colored output with icons
print_status() {
    local type=$1
    local message=$2
    
    case $type in
        "INFO") echo -e "${BLUE}${BOLD}[ℹ]${RESET} ${BLUE}$message${RESET}" ;;
        "WARN") echo -e "${YELLOW}${BOLD}[⚠]${RESET} ${YELLOW}$message${RESET}" ;;
        "ERROR") echo -e "${RED}${BOLD}[✖]${RESET} ${RED}$message${RESET}" ;;
        "SUCCESS") echo -e "${GREEN}${BOLD}[✓]${RESET} ${GREEN}$message${RESET}" ;;
        "INPUT") echo -ne "${CYAN}${BOLD}[→]${RESET} ${CYAN}$message${RESET}" ;;
        "PROCESS") echo -e "${MAGENTA}${BOLD}[⚙]${RESET} ${MAGENTA}$message${RESET}" ;;
        *) echo "[$type] $message" ;;
    esac
}

# Function to show loading animation
show_loading() {
    local message="$1"
    local duration="${2:-3}"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local end=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end ]; do
        for frame in "${frames[@]}"; do
            echo -ne "\r${MAGENTA}${BOLD}$frame${RESET} ${message}  "
            sleep 0.1
        done
    done
    echo -ne "\r${GREEN}${BOLD}✓${RESET} ${message}  \n"
}

# Function to draw a separator line
draw_separator() {
    local char="${1:-─}"
    local width=94
    echo -e "${GRAY}$(printf '%*s' "$width" | tr ' ' "$char")${RESET}"
}

# Function to display progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}Progress: [${GREEN}"
    printf '%*s' "$filled" | tr ' ' '█'
    printf "${GRAY}"
    printf '%*s' "$empty" | tr ' ' '░'
    printf "${CYAN}] ${WHITE}%3d%%${RESET}" "$percentage"
}

# Function to validate input
validate_input() {
    local type=$1
    local value=$2
    
    case $type in
        "number")
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                print_status "ERROR" "Must be a number"
                return 1
            fi
            ;;
        "size")
            if ! [[ "$value" =~ ^[0-9]+[GgMm]$ ]]; then
                print_status "ERROR" "Must be a size with unit (e.g., 100G, 512M)"
                return 1
            fi
            ;;
        "port")
            if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 23 ] || [ "$value" -gt 65535 ]; then
                print_status "ERROR" "Must be a valid port number (23-65535)"
                return 1
            fi
            ;;
        "name")
            if ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_status "ERROR" "VM name can only contain letters, numbers, hyphens, and underscores"
                return 1
            fi
            ;;
        "username")
            if ! [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                print_status "ERROR" "Username must start with a letter or underscore"
                return 1
            fi
            ;;
    esac
    return 0
}

# Function to check dependencies
check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img")
    local missing_deps=()
    
    print_status "PROCESS" "Checking dependencies..."
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "ERROR" "Missing dependencies: ${missing_deps[*]}"
        print_status "INFO" "On Ubuntu/Debian, try: sudo apt install qemu-system cloud-image-utils wget"
        exit 1
    fi
    print_status "SUCCESS" "All dependencies found"
    sleep 0.5
}

# Function to cleanup temporary files
cleanup() {
    if [ -f "user-data" ]; then rm -f "user-data"; fi
    if [ -f "meta-data" ]; then rm -f "meta-data"; fi
}

# Function to get all VM configurations
get_vm_list() {
    find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
}

# Function to load VM configuration
load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    
    if [[ -f "$config_file" ]]; then
        unset VM_NAME OS_TYPE CODENAME IMG_URL HOSTNAME USERNAME PASSWORD
        unset DISK_SIZE MEMORY CPUS SSH_PORT GUI_MODE PORT_FORWARDS IMG_FILE SEED_FILE CREATED
        unset IS_ISO
        source "$config_file"
        return 0
    else
        print_status "ERROR" "Configuration for VM '$vm_name' not found"
        return 1
    fi
}

# Function to save VM configuration
save_vm_config() {
    local config_file="$VM_DIR/$VM_NAME.conf"
    
    cat > "$config_file" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI_MODE="$GUI_MODE"
PORT_FORWARDS="$PORT_FORWARDS"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
IS_ISO="${IS_ISO:-false}"
EOF
    
    print_status "SUCCESS" "Configuration saved"
}

# Function to create new VM
create_new_vm() {
    display_header
    animate_text "🚀 Creating a New Virtual Machine" "$CYAN"
    draw_separator "═"
    echo
    
    # OS Selection
    print_status "INFO" "Available Operating Systems:"
    echo
    local os_options=()
    local i=1
    for os in "${!OS_OPTIONS[@]}"; do
        echo -e "  ${CYAN}${BOLD}$i)${RESET} ${WHITE}$os${RESET}"
        os_options[$i]="$os"
        ((i++))
    done
    echo
    
    while true; do
        read -p "$(print_status "INPUT" "Select OS (1-${#OS_OPTIONS[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#OS_OPTIONS[@]} ]; then
            local os="${os_options[$choice]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD IS_ISO <<< "${OS_OPTIONS[$os]}"
            IS_ISO="${IS_ISO:-false}"
            break
        else
            print_status "ERROR" "Invalid selection. Try again."
        fi
    done

    echo
    draw_separator
    animate_text "⚙️  Configuration Setup" "$MAGENTA"
    draw_separator
    echo

    # VM Configuration
    while true; do
        read -p "$(print_status "INPUT" "VM name [${DEFAULT_HOSTNAME}]: ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            if [[ -f "$VM_DIR/$VM_NAME.conf" ]]; then
                print_status "ERROR" "VM '$VM_NAME' already exists"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Hostname [${VM_NAME}]: ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        if validate_input "name" "$HOSTNAME"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Username [${DEFAULT_USERNAME}]: ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        if validate_input "username" "$USERNAME"; then
            break
        fi
    done

    while true; do
        read -s -p "$(print_status "INPUT" "Password [${DEFAULT_PASSWORD}]: ")" PASSWORD
        PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        echo
        if [ -n "$PASSWORD" ]; then
            break
        else
            print_status "ERROR" "Password cannot be empty"
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Disk size [20G]: ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        if validate_input "size" "$DISK_SIZE"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Memory in MB [2048]: ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        if validate_input "number" "$MEMORY"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Number of CPUs [2]: ")" CPUS
        CPUS="${CPUS:-2}"
        if validate_input "number" "$CPUS"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "SSH Port [2222]: ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then
            if ss -tln 2>/dev/null | grep -q ":$SSH_PORT "; then
                print_status "ERROR" "Port $SSH_PORT is already in use"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Enable GUI mode? (y/n) [n]: ")" gui_input
        GUI_MODE=false
        gui_input="${gui_input:-n}"
        if [[ "$gui_input" =~ ^[Yy]$ ]]; then 
            GUI_MODE=true
            break
        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
            break
        else
            print_status "ERROR" "Please answer y or n"
        fi
    done

    read -p "$(print_status "INPUT" "Port forwards (e.g., 8080:80) [none]: ")" PORT_FORWARDS

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date '+%Y-%m-%d %H:%M:%S')"

    echo
    draw_separator "═"
    setup_vm_image
    save_vm_config
    
    echo
    print_status "SUCCESS" "VM '$VM_NAME' created successfully!"
    sleep 2
}

# Function to setup VM image
setup_vm_image() {
    animate_text "📦 Preparing Virtual Machine Image..." "$MAGENTA"
    draw_separator
    echo
    
    mkdir -p "$VM_DIR"
    
    if [[ -f "$IMG_FILE" ]]; then
        print_status "INFO" "Image file already exists. Skipping download."
    else
        print_status "PROCESS" "Downloading: $IMG_URL"
        if wget --progress=bar:force:noscroll "$IMG_URL" -O "$IMG_FILE.tmp" 2>&1 | \
            while IFS= read -r line; do
                echo -ne "\r${CYAN}${line}${RESET}"
            done; then
            mv "$IMG_FILE.tmp" "$IMG_FILE"
            echo
            print_status "SUCCESS" "Download complete"
        else
            print_status "ERROR" "Failed to download image"
            exit 1
        fi
    fi
    
    if [[ "$IS_ISO" != "true" ]]; then
        print_status "PROCESS" "Resizing disk to $DISK_SIZE..."
        if qemu-img resize "$IMG_FILE" "$DISK_SIZE" 2>/dev/null; then
            print_status "SUCCESS" "Disk resized"
        else
            print_status "WARN" "Creating new disk image..."
            qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"
        fi

        print_status "PROCESS" "Configuring cloud-init..."
        cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD" | tr -d '\n')
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

        cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $HOSTNAME
EOF

        if cloud-localds "$SEED_FILE" user-data meta-data 2>/dev/null; then
            print_status "SUCCESS" "Cloud-init configured"
        else
            print_status "ERROR" "Failed to create cloud-init seed"
            exit 1
        fi
    else
        print_status "INFO" "ISO mode detected - skipping cloud-init"
    fi
}

# Function to start a VM
start_vm() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        display_header
        animate_text "🚀 Starting VM: $vm_name" "$GREEN"
        draw_separator "═"
        echo
        
        print_status "INFO" "SSH Access: ${CYAN}ssh -p $SSH_PORT $USERNAME@localhost${RESET}"
        print_status "INFO" "Password: ${YELLOW}$PASSWORD${RESET}"
        echo
        
        if [[ ! -f "$IMG_FILE" ]]; then
            print_status "ERROR" "VM image not found: $IMG_FILE"
            return 1
        fi
        
        show_loading "Initializing QEMU environment" 2
        
        local qemu_cmd=(
            qemu-system-x86_64
            -enable-kvm
            -m "$MEMORY"
            -smp "$CPUS"
            -cpu host
        )

        if [[ "$IS_ISO" == "true" ]]; then
            # ISO boot mode (for Proxmox and similar)
            qemu_cmd+=(
                -cdrom "$IMG_FILE"
                -boot order=d
                -drive "file=$VM_DIR/${VM_NAME}-disk.img,format=qcow2,if=virtio"
            )
            # Create disk if it doesn't exist
            if [[ ! -f "$VM_DIR/${VM_NAME}-disk.img" ]]; then
                qemu-img create -f qcow2 "$VM_DIR/${VM_NAME}-disk.img" "$DISK_SIZE"
            fi
        else
            # Cloud image mode
            qemu_cmd+=(
                -drive "file=$IMG_FILE,format=qcow2,if=virtio"
                -drive "file=$SEED_FILE,format=raw,if=virtio"
                -boot order=c
            )
        fi

        qemu_cmd+=(
            -device virtio-net-pci,netdev=n0
            -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
        )

        if [[ -n "$PORT_FORWARDS" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                qemu_cmd+=(-netdev "user,id=n${#qemu_cmd[@]},hostfwd=tcp::$host_port-:$guest_port")
            done
        fi

        if [[ "$GUI_MODE" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk,gl=on)
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
        fi

        qemu_cmd+=(
            -device virtio-balloon-pci
            -object rng-random,filename=/dev/urandom,id=rng0
            -device virtio-rng-pci,rng=rng0
        )

        print_status "SUCCESS" "Starting QEMU..."
        echo
        draw_separator "═"
        "${qemu_cmd[@]}"
        
        echo
        print_status "INFO" "VM $vm_name has shut down"
        sleep 2
    fi
}

# Function to delete a VM
delete_vm() {
    local vm_name=$1
    
    echo
    print_status "WARN" "⚠️  This will PERMANENTLY delete VM '$vm_name' and ALL its data!"
    echo
    read -p "$(print_status "INPUT" "Type 'DELETE' to confirm: ")" confirm
    
    if [[ "$confirm" == "DELETE" ]]; then
        if load_vm_config "$vm_name"; then
            show_loading "Deleting VM files" 2
            rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$vm_name.conf" "$VM_DIR/${vm_name}-disk.img"
            print_status "SUCCESS" "VM '$vm_name' deleted"
            sleep 1
        fi
    else
        print_status "INFO" "Deletion cancelled"
        sleep 1
    fi
}

# Function to show VM info
show_vm_info() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        display_header
        animate_text "📊 VM Information: $vm_name" "$CYAN"
        draw_separator "═"
        echo
        
        echo -e "${BOLD}${WHITE}General Information${RESET}"
        draw_separator "─"
        echo -e "  ${CYAN}VM Name:${RESET}      $VM_NAME"
        echo -e "  ${CYAN}OS Type:${RESET}      $OS_TYPE"
        echo -e "  ${CYAN}Hostname:${RESET}     $HOSTNAME"
        echo -e "  ${CYAN}Created:${RESET}      $CREATED"
        echo
        
        echo -e "${BOLD}${WHITE}Access Credentials${RESET}"
        draw_separator "─"
        echo -e "  ${CYAN}Username:${RESET}     $USERNAME"
        echo -e "  ${CYAN}Password:${RESET}     $PASSWORD"
        echo -e "  ${CYAN}SSH Port:${RESET}     $SSH_PORT"
        echo -e "  ${CYAN}SSH Command:${RESET}  ssh -p $SSH_PORT $USERNAME@localhost"
        echo
        
        echo -e "${BOLD}${WHITE}Hardware Configuration${RESET}"
        draw_separator "─"
        echo -e "  ${CYAN}Memory:${RESET}       ${MEMORY} MB"
        echo -e "  ${CYAN}CPUs:${RESET}         $CPUS"
        echo -e "  ${CYAN}Disk Size:${RESET}    $DISK_SIZE"
        echo -e "  ${CYAN}GUI Mode:${RESET}     $GUI_MODE"
        echo
        
        if [[ -n "$PORT_FORWARDS" ]]; then
            echo -e "${BOLD}${WHITE}Port Forwards${RESET}"
            draw_separator "─"
            echo -e "  ${CYAN}Forwards:${RESET}     $PORT_FORWARDS"
            echo
        fi
        
        echo -e "${BOLD}${WHITE}Storage Paths${RESET}"
        draw_separator "─"
        echo -e "  ${CYAN}Image:${RESET}        $IMG_FILE"
        echo -e "  ${CYAN}Seed:${RESET}         $SEED_FILE"
        echo
        
        draw_separator "═"
        read -p "$(print_status "INPUT" "Press Enter to continue...")"
    fi
}

# Function to check if VM is running
is_vm_running() {
    local vm_name=$1
    if pgrep -f "qemu-system-x86_64.*$vm_name" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to stop a running VM
stop_vm() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "PROCESS" "Stopping VM: $vm_name"
            show_loading "Shutting down gracefully" 2
            pkill -f "qemu-system-x86_64.*$IMG_FILE"
            sleep 2
            if is_vm_running "$vm_name"; then
                print_status "WARN" "Forcing termination..."
                pkill -9 -f "qemu-system-x86_64.*$IMG_FILE"
            fi
            print_status "SUCCESS" "VM $vm_name stopped"
        else
            print_status "INFO" "VM $vm_name is not running"
        fi
        sleep 1
    fi
}

# Main menu function
main_menu() {
    while true; do
        display_header
        
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}
        
        if [ $vm_count -gt 0 ]; then
            echo -e "${BOLD}${WHITE}📋 Virtual Machines${RESET} ${GRAY}(${vm_count} total)${RESET}"
            draw_separator "─"
            for i in "${!vms[@]}"; do
                local status_icon="⭘"
                local status_color=$GRAY
                local status_text="Stopped"
                if is_vm_running "${vms[$i]}"; then
                    status_icon="●"
                    status_color=$GREEN
                    status_text="Running"
                fi
                printf "  ${CYAN}%2d)${RESET} ${WHITE}%-20s${RESET} ${status_color}${status_icon} %s${RESET}\n" \
                    $((i+1)) "${vms[$i]}" "$status_text"
            done
            echo
            draw_separator
        fi
        
        echo
        echo -e "${BOLD}${WHITE}🎮 Main Menu${RESET}"
        draw_separator "─"
        echo -e "  ${CYAN}1)${RESET} ${WHITE}Create New VM${RESET}          ${GRAY}Launch a new virtual machine${RESET}"
        if [ $vm_count -gt 0 ]; then
            echo -e "  ${CYAN}2)${RESET} ${WHITE}Start VM${RESET}               ${GRAY}Boot an existing VM${RESET}"
            echo -e "  ${CYAN}3)${RESET} ${WHITE}Stop VM${RESET}                ${GRAY}Shutdown a running VM${RESET}"
            echo -e "  ${CYAN}4)${RESET} ${WHITE}VM Information${RESET}         ${GRAY}View detailed VM info${RESET}"
            echo -e "  ${CYAN}5)${RESET} ${WHITE}Edit Configuration${RESET}     ${GRAY}Modify VM settings${RESET}"
            echo -e "  ${CYAN}6)${RESET} ${WHITE}Delete VM${RESET}              ${GRAY}Remove a VM permanently${RESET}"
        fi
        echo -e "  ${CYAN}0)${RESET} ${WHITE}Exit${RESET}                   ${GRAY}Close the manager${RESET}"
        echo
        draw_separator "═"
        echo
        
        read -p "$(print_status "INPUT" "Choose an option: ")" choice
        
        case $choice in
            1)
                create_new_vm
                ;;
            2)
                if [ $vm_count -gt 0 ]; then
                    read -p "$(print_status "INPUT" "Enter VM number: ")" vm_num
                    if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                        start_vm "${vms[$((vm_num-1))]}"
                    else
                        print_status "ERROR" "Invalid selection"
                        sleep 1
                    fi
                fi
                ;;
            3)
                if [ $vm_count -gt 0 ]; then
                    read -p "$(print_status "INPUT" "Enter VM number: ")" vm_num
                    if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                        stop_vm "${vms[$((vm_num-1))]}"
                    else
                        print_status "ERROR" "Invalid selection"
                        sleep 1
                    fi
                fi
                ;;
            4)
                if [ $vm_count -gt 0 ]; then
                    read -p "$(print_status "INPUT" "Enter VM number: ")" vm_num
                    if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                        show_vm_info "${vms[$((vm_num-1))]}"
                    else
                        print_status "ERROR" "Invalid selection"
                        sleep 1
                    fi
                fi
                ;;
            5)
                if [ $vm_count -gt 0 ]; then
                    print_status "INFO" "Configuration editing - coming soon!"
                    sleep 1
                fi
                ;;
            6)
                if [ $vm_count -gt 0 ]; then
                    read -p "$(print_status "INPUT" "Enter VM number: ")" vm_num
                    if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                        delete_vm "${vms[$((vm_num-1))]}"
                    else
                        print_status "ERROR" "Invalid selection"
                        sleep 1
                    fi
                fi
                ;;
            0)
                echo
                animate_text "👋 Thank you for using InfinityForge VM Manager!" "$CYAN"
                echo
                exit 0
                ;;
            *)
                print_status "ERROR" "Invalid option"
                sleep 1
                ;;
         esac
    done
}
main_menu
