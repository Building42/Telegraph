CA_PASSPHRASE=test
LOCALHOST_PASSPHRASE=test

cd ca

# Clean up: remove files
rm -f newcerts/*
rm -f p12/*
rm index.txt
rm *.old

# Clean up: create dummies
touch index.txt
echo 1001 > serial
echo 1000 > serial.old

# Step 1: Generate CA key
echo "Generating CA key"
openssl genrsa -aes256 -passout pass:$CA_PASSPHRASE -out private/ca.key 4096

# Step 2: Generate CA certificate
echo "Generating CA certificate"
openssl req -config config-ca.cnf -key private/ca.key \
        -new -x509 -sha256 -days 7300 \
        -extensions v3_ca -passin pass:$CA_PASSPHRASE \
        -out certs/ca.cert

# Step 3: Convert CA certificate
echo "Converting CA certificate"
openssl x509 -inform PEM -in certs/ca.cert -outform der -out der/ca.der

# Step 4: Generate localhost key
echo "Generate localhost key"
openssl genrsa -aes256 -passout pass:$LOCALHOST_PASSPHRASE -out private/localhost.key 2048

# Step 5: Generate localhost certificate
echo "Generating localhost certificate request"
openssl req -config config-localhost.cnf -key private/localhost.key \
        -new -sha256 -days 825 \
        -passin pass:$LOCALHOST_PASSPHRASE -out csr/localhost.csr

# Step 6: Sign the localhost certificate with the CA
echo "Signing localhost certificate"
openssl ca -config config-ca.cnf \
        -batch -notext -extensions server_cert \
        -in csr/localhost.csr -passin pass:$CA_PASSPHRASE \
        -out certs/localhost.cert

# Step 7: Convert localhost certificate
echo "Converting localhost certificate"
openssl x509 -inform PEM -in certs/localhost.cert -outform der -out der/localhost.der

# Step 8: Create localhost PKCS12 archive
echo "Create localhost PKCS12 archive"
openssl pkcs12 -export -inkey private/localhost.key -in certs/localhost.cert \
        -passin pass:$LOCALHOST_PASSPHRASE -passout pass:$LOCALHOST_PASSPHRASE \
        -out p12/localhost.p12
