#!/bin/bash

# /* ---- 💫 Session Manager for Hyprland 💫 ---- */
# Manual session management interface

SESSION_DIR="$HOME/.config/hypr/sessions"
SCRIPTS_DIR="$HOME/.config/hypr/scripts"

# Function to show session manager menu
show_menu() {
    local choice=$(echo -e "💾 Save Current Session\n🔄 Restore Last Session\n📋 List Sessions\n🗑️ Clear Sessions\n❌ Cancel" | \
        rofi -dmenu -i -p "Session Manager" \
        -theme-str 'window {width: 400px; height: 300px;}' \
        -theme-str 'listview {lines: 5;}')
    
    case "$choice" in
        "💾 Save Current Session")
            save_current_session
            ;;
        "🔄 Restore Last Session")
            restore_last_session
            ;;
        "📋 List Sessions")
            list_sessions
            ;;
        "🗑️ Clear Sessions")
            clear_sessions
            ;;
        *)
            exit 0
            ;;
    esac
}

# Function to save current session
save_current_session() {
    "$SCRIPTS_DIR/SessionSave.sh" manual
    
    if [ $? -eq 0 ]; then
        notify-send "Session Manager" "Current session saved successfully" -t 3000 -i document-save
    else
        notify-send "Session Manager" "Failed to save session" -t 3000 -i dialog-error
    fi
}

# Function to restore last session
restore_last_session() {
    local response=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Restore session? This will launch apps from your last session.")
    
    if [ "$response" = "Yes" ]; then
        "$SCRIPTS_DIR/SessionRestore.sh" restore
    fi
}

# Function to list sessions
list_sessions() {
    local sessions_info=""
    
    if [ -f "$SESSION_DIR/last_session.json" ]; then
        local timestamp=$(jq -r '.timestamp' "$SESSION_DIR/last_session.json" 2>/dev/null || echo 'corrupted')
        local window_count=$(jq '.clients | length' "$SESSION_DIR/last_session.json" 2>/dev/null || echo '?')
        sessions_info="📅 Last Session: $timestamp ($window_count windows)\n"
    else
        sessions_info="❌ No sessions found\n"
    fi
    
    if [ -d "$SESSION_DIR/backups" ]; then
        sessions_info+="\n📦 Backup Sessions:\n"
        for backup in $(find "$SESSION_DIR/backups" -name "session_*.json" | sort -r | head -5); do
            local filename=$(basename "$backup")
            local timestamp=$(jq -r '.timestamp' "$backup" 2>/dev/null || echo 'corrupted')
            local window_count=$(jq '.clients | length' "$backup" 2>/dev/null || echo '?')
            sessions_info+="   $filename: $timestamp ($window_count windows)\n"
        done
    fi
    
    echo -e "$sessions_info" | rofi -dmenu -i -p "Session Information" \
        -theme-str 'window {width: 600px; height: 400px;}' \
        -theme-str 'listview {lines: 10;}'
}

# Function to clear sessions
clear_sessions() {
    local response=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Clear all sessions? This cannot be undone!")
    
    if [ "$response" = "Yes" ]; then
        rm -f "$SESSION_DIR/last_session.json"
        rm -rf "$SESSION_DIR/backups"
        mkdir -p "$SESSION_DIR/backups"
        notify-send "Session Manager" "All sessions cleared" -t 3000 -i user-trash
    fi
}

# Check if rofi is available
if ! command -v rofi >/dev/null 2>&1; then
    echo "Error: rofi is required for the session manager interface"
    exit 1
fi

# Create session directory if it doesn't exist
mkdir -p "$SESSION_DIR"

# Show the menu
show_menu