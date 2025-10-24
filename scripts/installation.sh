#!/bin/bash
# filepath: installation.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "installation.sh - Download and install security tools"
    echo
    echo "Usage:"
    echo "  ./installation.sh"
    echo "  ./installation.sh --help"
    echo
    echo "Description:"
    echo "  Downloads and installs comprehensive security tools including:"
    echo "  • Python3 and pipx"
    echo "  • NetExec (NXC) - Latest version"
    echo "  • Certipy-AD - Certificate exploitation"
    echo "  • Impacket - Latest version"
    echo "  • Kerbrute - Kerberos bruteforcing tool"
    echo "  • Al-Hussein-Technical-University tools"
    echo "  • Custom security scripts from setupscripts"
    echo
    echo "Installation Location:"
    echo "  • Tools: ~/.local/bin/"
    echo "  • Python packages: pipx managed (~/.local/share/pipx/)"
    echo
    echo "Requirements:"
    echo "  • Internet connection"
    echo "  • Python3 (will be installed via package manager if needed)"
    echo
    echo "Example:"
    echo "  ./installation.sh"
}

# Repository URLs
REPOS=(
    "https://github.com/0xZDH/kerbrute.git"
    "https://github.com/nationalcptc-teamtools/Al-Hussein-Technical-University"
    "https://github.com/SawyersPresent/setupscripts.git"
)

# Pipx packages to install
PIPX_PACKAGES=(
    "certipy-ad"
    "git+https://github.com/Pennyw0rth/NetExec"
    "git+https://github.com/fortra/impacket.git"
)

# Check if help is requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Set up home directory paths
setup_paths() {
    print_status "Setting up installation paths..."
    
    # Use current user's home directory
    HOME_DIR="$HOME"
    LOCAL_BIN="$HOME_DIR/.local/bin"
    
    # Create local bin directory if it doesn't exist
    mkdir -p "$LOCAL_BIN"
    
    # Add to PATH for current session
    export PATH="$LOCAL_BIN:$PATH"
    
    print_success "Installation directory: $LOCAL_BIN"
}

# Install system dependencies (tries multiple package managers)
install_system_dependencies() {
    print_status "Installing system dependencies..."
    
    # Function to check if command exists
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }
    
    # Check if python3 is available
    if ! command_exists python3; then
        print_status "Python3 not found, attempting to install..."
        
        # Try different package managers
        if command_exists apt; then
            sudo apt update && sudo apt install -y python3 python3-pip python3-venv git build-essential golang-go curl wget
        elif command_exists yum; then
            sudo yum install -y python3 python3-pip git gcc golang curl wget
        elif command_exists dnf; then
            sudo dnf install -y python3 python3-pip git gcc golang curl wget
        elif command_exists pacman; then
            sudo pacman -S --noconfirm python python-pip git base-devel go curl wget
        elif command_exists brew; then
            brew install python3 git go curl wget
        else
            print_warning "Could not detect package manager. Please install python3, pip, git, and golang manually."
            return 1
        fi
    else
        print_success "Python3 is already available"
    fi
    
    # Install pipx if not available
    if ! command_exists pipx; then
        print_status "Installing pipx..."
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    print_success "System dependencies ready"
}

# Setup pipx for user
setup_pipx() {
    print_status "Setting up pipx..."
    
    # Ensure pipx path is available
    python3 -m pipx ensurepath
    
    # Add pipx to current session PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    # Make pipx path persistent for user across different shells
    update_shell_config() {
        local config_file="$1"
        local path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
        
        if [[ -f "$config_file" ]]; then
            if ! grep -q "\$HOME/.local/bin" "$config_file"; then
                echo "$path_line" >> "$config_file"
                print_status "Updated $config_file"
            fi
        fi
    }
    
    # Update various shell configuration files
    update_shell_config "$HOME/.bashrc"
    update_shell_config "$HOME/.zshrc" 
    update_shell_config "$HOME/.profile"
    
    # For fish shell
    if [[ -d "$HOME/.config/fish" ]]; then
        mkdir -p "$HOME/.config/fish"
        fish_config="$HOME/.config/fish/config.fish"
        if [[ -f "$fish_config" ]]; then
            if ! grep -q "\$HOME/.local/bin" "$fish_config"; then
                echo "set -gx PATH \$HOME/.local/bin \$PATH" >> "$fish_config"
                print_status "Updated fish config"
            fi
        fi
    fi
    
    print_success "Pipx configured for user installation"
}

# Install pipx packages
install_pipx_packages() {
    print_status "Installing security tools with pipx..."
    
    for package in "${PIPX_PACKAGES[@]}"; do
        package_name=$(basename "$package" .git)
        if [[ "$package" == *"git+"* ]]; then
            # Extract the actual package name for git installations
            if [[ "$package" == *"NetExec"* ]]; then
                package_name="NetExec"
            elif [[ "$package" == *"impacket"* ]]; then
                package_name="impacket"
            fi
        fi
        
        print_status "Installing $package_name..."
        
        if pipx install "$package"; then
            print_success "Installed $package_name"
        else
            print_warning "Failed to install $package_name, trying alternative method..."
            
            # Fallback: try with --force
            if pipx install --force "$package"; then
                print_success "Installed $package_name (with --force)"
            else
                print_error "Failed to install $package_name"
            fi
        fi
    done
}

# Create temporary working directory
setup_workspace() {
    print_status "Setting up workspace..."
    
    TEMP_DIR=$(mktemp -d)
    TOOLS_DIR="$TEMP_DIR/tools"
    mkdir -p "$TOOLS_DIR"
    
    # Cleanup function
    cleanup() {
        print_status "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    }
    trap cleanup EXIT
    
    print_success "Workspace created: $TEMP_DIR"
}

# Download repositories
download_repos() {
    print_status "Downloading repositories..."
    
    cd "$TEMP_DIR"
    
    for repo in "${REPOS[@]}"; do
        repo_name=$(basename "$repo" .git)
        print_status "Cloning $repo_name..."
        
        if git clone "$repo" "$repo_name"; then
            print_success "Downloaded $repo_name"
        else
            print_error "Failed to download $repo_name"
            exit 1
        fi
    done
}

# Find and copy executable files
install_tools() {
    print_status "Installing tools to $LOCAL_BIN..."
    
    local installed_count=0
    
    # Find all executable files and scripts
    while IFS= read -r -d '' file; do
        # Skip directories, .git folders, and common non-executable files
        if [[ -d "$file" ]] || [[ "$file" == *".git"* ]] || [[ "$file" == *".md" ]] || [[ "$file" == *".txt" ]] || [[ "$file" == *".json" ]]; then
            continue
        fi
        
        # Check if file is executable or is a script
        if [[ -x "$file" ]] || [[ "$file" == *.py ]] || [[ "$file" == *.sh ]] || [[ "$file" == *.pl ]]; then
            filename=$(basename "$file")
            
            # Skip files that might cause conflicts
            if [[ "$filename" == "README"* ]] || [[ "$filename" == "LICENSE"* ]] || [[ "$filename" == "."* ]] || [[ "$filename" == "installation.sh" ]]; then
                continue
            fi
            
            # Copy to ~/.local/bin
            if cp "$file" "$LOCAL_BIN/$filename"; then
                chmod +x "$LOCAL_BIN/$filename"
                print_success "Installed: $filename"
                ((installed_count++))
            else
                print_warning "Failed to install: $filename"
            fi
        fi
    done < <(find "$TEMP_DIR" -type f -print0)
    
    print_success "Installed $installed_count tools to $LOCAL_BIN"
}

# Install specific tools that need special handling
install_special_tools() {
    print_status "Installing special tools..."
    
    cd "$TEMP_DIR"
    
    # Handle kerbrute specifically (build from source)
    if [[ -d "kerbrute" ]]; then
        cd kerbrute
        if [[ -f "main.go" ]]; then
            print_status "Building kerbrute from source..."
            if command -v go >/dev/null 2>&1; then
                if go build -o kerbrute main.go; then
                    cp kerbrute "$LOCAL_BIN/"
                    chmod +x "$LOCAL_BIN/kerbrute"
                    print_success "Built and installed kerbrute"
                else
                    print_warning "Failed to build kerbrute"
                fi
            else
                print_warning "Go not available, skipping kerbrute build"
            fi
        fi
        cd ..
    fi
    
    # Handle Python scripts from setupscripts
    if [[ -d "setupscripts/scripts" ]]; then
        cd setupscripts/scripts
        for script in *; do
            if [[ -f "$script" && ! "$script" == *.md && "$script" != "installation.sh" ]]; then
                cp "$script" "$LOCAL_BIN/"
                chmod +x "$LOCAL_BIN/$script"
                print_success "Installed: $script"
            fi
        done
        cd ../..
    fi
}

# Verify installations
verify_installation() {
    print_status "Verifying installations..."
    
    echo
    echo "=== PIPX TOOLS ==="
    if command -v pipx >/dev/null 2>&1; then
        pipx list
    else
        print_warning "pipx not found in PATH"
    fi
    
    echo
    echo "=== USER TOOLS (in $LOCAL_BIN) ==="
    
    local tool_count=0
    if [[ -d "$LOCAL_BIN" ]]; then
        for tool in "$LOCAL_BIN"/*; do
            if [[ -f "$tool" && -x "$tool" ]]; then
                tool_name=$(basename "$tool")
                printf "  %-20s => %s\n" "$tool_name" "$tool"
                ((tool_count++))
            fi
        done
    fi
    
    echo "  Total tools: $tool_count"
    
    echo
    echo "=== VERIFICATION ==="
    
    # Test some key tools
    tools_to_test=("nxc" "certipy" "impacket-secretsdump" "kerbrute")
    
    for tool in "${tools_to_test[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_success "$tool is available"
        else
            print_warning "$tool not found in PATH"
        fi
    done
    
    echo
    print_success "Installation complete! 🚀"
    echo
    echo "Installation Summary:"
    echo "• Installation directory: $LOCAL_BIN"
    echo "• Python packages: pipx managed"
    echo "• PATH updated in shell configs"
    echo
    echo "Tools installed:"
    echo "• NetExec (nxc) - Network exploitation"
    echo "• Certipy-AD - Certificate attacks"  
    echo "• Impacket suite - Protocol implementations"
    echo "• Kerbrute - Kerberos bruteforcing"
    echo "• Custom scripts - Various security tools"
    echo
    echo "Usage:"
    echo "• Restart your shell or run 'source ~/.bashrc' to update PATH"
    echo "• All tools are now available from anywhere: nxc, certipy, etc."
}

# Main execution
main() {
    echo "=============================================="
    echo "Security Tools Installation Script (User Mode)"
    echo "=============================================="
    echo
    
    setup_paths
    install_system_dependencies
    setup_pipx
    install_pipx_packages
    setup_workspace
    download_repos
    install_tools
    install_special_tools
    verify_installation
    
    echo
    print_success "All done! 🎯"
    echo "Installation location: $LOCAL_BIN"
    echo "Restart your shell or run 'source ~/.bashrc' to ensure all tools are in PATH"
}

# Run main function
main "$@"