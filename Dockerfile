FROM ghcr.io/hardisgroupcom/sfdx-hardis:latest

# Install recommended plugins
RUN npm install -g \
    @salesforce/plugin-packaging \
    sfdmu \
    sfdx-git-delta \
    sfdx-essentials

# Verify
RUN sf plugins
