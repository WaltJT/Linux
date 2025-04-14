# DotfilesI3Arch

#!/bin/bash

BACKUP_DIR=~/dotfiles_backup


# Restaurar configuraciones

cp -r $BACKUP_DIR/.config/* ~/.config/

cp $BACKUP_DIR/.bashrc ~/

cp $BACKUP_DIR/.zshrc ~/

cp $BACKUP_DIR/.profile ~/

cp $BACKUP_DIR/.xinitrc ~/


# Restaurar fuentes, íconos y temas

cp -r $BACKUP_DIR/.fonts ~/

cp -r $BACKUP_DIR/.icons ~/

cp -r $BACKUP_DIR/.themes ~/

echo "Restauración completada."

Revisar que esta y que no, las ubicaciones son mas o menos las indicadas...

## Depende del equipo puede que auto-wake funcione o no, si el equipo cuenta con auto wake por BIOS no tiene sentido cargarlo ##
