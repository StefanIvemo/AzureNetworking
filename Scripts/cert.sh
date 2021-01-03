#/bin/bash
# Create root CA
openssl req -x509 -new -nodes -newkey rsa:4096 -keyout rootCA.key -sha256 -days 1024 -out rootCA.crt -subj "/C=US/ST=US/O=Self Signed/CN=Self Signed Root CA" -config openssl.cnf -extensions rootCA_ext

# Create intermediate CA request
openssl req -new -nodes -newkey rsa:4096 -keyout interCA.key -sha256 -out interCA.csr -subj "/C=US/ST=US/O=Self Signed/CN=Self Signed Intermediate CA"

# Sign on the intermediate CA
openssl x509 -req -in interCA.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out interCA.crt -days 1024 -sha256 -extfile openssl.cnf -extensions interCA_ext

# Export the intermediate CA into PFX
openssl pkcs12 -export -out interCA.pfx -inkey interCA.key -in interCA.crt -password "pass:"

openssl pkcs12 -export -out rootCA.pfx -inkey rootCA.key -in rootCA.crt -password "pass:"

interCA=$(az keyvault certificate import --vault-name $1 -n interCA -f interCA.pfx)
rootCA=$(az keyvault certificate import --vault-name $1 -n rootCA -f rootCA.pfx)

json="{\"certs\":{\"interCA\":\"$interCA\",\"rootCA\":\"$rootCA\"}}"

echo "$json" > $AZ_SCRIPTS_OUTPUT_PATH
