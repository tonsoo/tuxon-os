#/bin/bash

# Display program version
version() {
    echo "$APP_NAME - ($VERSION)"
}



# Show padronized help message for a command
helpCommand() {
    echo "  $1            $2"
}



# Show help message
help() {
    echo "$APP_NAME"
    echo ""
    echo "$CMD [OPTIONS]"
    helpCommand "-h" "Prints this"
    helpCommand "-d" "Enabled debug mode on the script"
}
