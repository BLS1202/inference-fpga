import time

import serial


# Change COM3 to your FPGA's UART port.
ser = serial.Serial(
    port="COM3",
    baudrate=115200,
    timeout=0.1,
)

VOCAB_SIZE = 27
LISTEN_SECONDS = 10.0


def decode_tokens(tokens):
    chars = "abcdefghijklmnopqrstuvwxyz"
    text = []
    for token in tokens:
        if token == VOCAB_SIZE - 1:
            break
        if 0 <= token < len(chars):
            text.append(chars[token])
    return "".join(text)


print("UART connected.")
print("Enter the initial token id. Use 26 for BOS/start.")
print("Press BTNC on the FPGA after sending the token.")
print("Type 'q' to quit.")

while True:
    token_input = input("\nInitial token id (0-26): ").strip()
    if token_input.lower() == "q":
        break

    try:
        token_id = int(token_input, 0)
    except ValueError:
        print("Please enter a valid decimal or hex integer.")
        continue

    if token_id < 0 or token_id >= VOCAB_SIZE:
        print(f"Token id must be between 0 and {VOCAB_SIZE - 1}.")
        continue

    ser.reset_input_buffer()
    ser.write(bytes([token_id]))
    ser.flush()

    print(f"Sent initial token={token_id} (0x{token_id:02X})")
    print(f"Listening for {LISTEN_SECONDS:.1f} seconds...")

    received = bytearray()
    deadline = time.monotonic() + LISTEN_SECONDS
    while time.monotonic() < deadline:
        chunk = ser.read(ser.in_waiting or 1)
        if chunk:
            received.extend(chunk)

    if received:
        tokens = list(received)
        dec_values = " ".join(str(token) for token in tokens)
        hex_values = " ".join(f"0x{token:02X}" for token in tokens)
        print(f"Received {len(tokens)} byte(s).")
        print(f"Tokens dec : {dec_values}")
        print(f"Tokens hex : {hex_values}")
        print(f"Decoded    : {decode_tokens(tokens)}")
    else:
        print("No response bytes received.")

ser.close()
print("UART closed.")
