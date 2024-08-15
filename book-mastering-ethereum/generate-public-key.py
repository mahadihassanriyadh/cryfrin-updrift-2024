from ecdsa import SigningKey, SECP256k1

private_key_hex = "f8f8a2f43c8376ccb0871305060d7b27b0554d2cc72bccf41b2705608452f315"

# Convert the private key from hex to bytes
private_key_bytes = bytes.fromhex(private_key_hex)

# Create a SigningKey object from the private key bytes
sk = SigningKey.from_string(private_key_bytes, curve=SECP256k1)

# Get the corresponding VerifyingKey (public key)
vk = sk.verifying_key

# Get the x and y coordinates of the public key
x = vk.pubkey.point.x()
y = vk.pubkey.point.y()

# Serialize the public key in the required format
public_key = "04" + format(x, '064x') + format(y, '064x')

print("Public Key:", public_key)