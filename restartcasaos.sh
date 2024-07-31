#!/bin/bash

sudo systemctl stop casaos
echo "CasaOS stoppé"
sudo systemctl start casaos
echo "CasaOS démarré"
