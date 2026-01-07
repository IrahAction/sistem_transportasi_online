import os
from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305

def main():
    # Data yang akan dienkripsi
    pesan = input("Masukkan Pesan : ")
    data = pesan.encode()

    # Associated Authenticated Data (tidak dienkripsi)
    aad = b"authenticated but unencrypted data"

    # Generate key dan nonce
    key = ChaCha20Poly1305.generate_key()
    nonce = os.urandom(12)

    # Inisialisasi ChaCha20-Poly1305
    chacha = ChaCha20Poly1305(key)

    # Enkripsi
    ciphertext = chacha.encrypt(nonce, data, aad)

    print("=== ENKRIPSI ===")
    print("Plaintext :", data)
    print("AAD       :", aad)
    print("Ciphertext:", ciphertext)

    # Dekripsi
    decrypted = chacha.decrypt(nonce, ciphertext, aad)

    print("\n=== DEKRIPSI ===")
    print("Hasil     :", decrypted)

if __name__ == "__main__":
    main()
