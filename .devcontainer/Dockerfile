FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:0-14

# Install Azure Functions Core Tools
RUN npm install -g azure-functions-core-tools@3 --unsafe-perm true

# Set the default shell to bash rather than sh
ENV SHELL /bin/bash