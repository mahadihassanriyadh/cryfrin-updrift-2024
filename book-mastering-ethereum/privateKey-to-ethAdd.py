from ecdsa import SigningKey, SECP256k1
import sha3

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

# Serialize the public key in the required format (without the prefix 04)
public_key_bytes = bytes.fromhex(format(x, '064x') + format(y, '064x'))

# Compute the Keccak-256 hash of the public key
keccak = sha3.keccak_256()
keccak.update(public_key_bytes)
public_key_hash = keccak.hexdigest()

# The Ethereum address is the last 20 bytes of the hash
eth_address = "0x" + public_key_hash[-40:]

print("Public Key Hash:", public_key_hash)
print("Ethereum Address:", eth_address)