# Custom image for your team
FROM ghcr.io/hardisgroupcom/sfdx-hardis:latest

# Install your standard plugins
RUN npm install -g \
    sfdmu \
    @salesforce/plugin-packaging \
    sfdx-git-delta

RUN sf plugins
