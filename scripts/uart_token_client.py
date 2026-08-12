import serial

# Change COM3 to your FPGA's UART port.
ser = serial.Serial(
    port="COM3",
    baudrate=115200,
    timeout=5,
)

VOCAB_SIZE = 27
BLOCK_SIZE = 16

print("UART connected.")
print("Enter token id first, then position id.")
print("Type 'q' at either prompt to quit.")

while True:
    token_input = input("\nToken id (0-26): ").strip()
    if token_input.lower() == "q":
        break

    pos_input = input("Position id (0-15): ").strip()
    if pos_input.lower() == "q":
        break

    try:
        token_id = int(token_input, 0)
        pos_id = int(pos_input, 0)
    except ValueError:
        print("Please enter valid decimal or hex integers.")
        continue

    if token_id < 0 or token_id >= VOCAB_SIZE:
        print(f"Token id must be between 0 and {VOCAB_SIZE - 1}.")
        continue
    if pos_id < 0 or pos_id >= BLOCK_SIZE:
        print(f"Position id must be between 0 and {BLOCK_SIZE - 1}.")
        continue

    packet = bytes([token_id, pos_id])
    ser.write(packet)
    ser.flush()

    print(
        f"Sent token={token_id} (0x{token_id:02X}), "
        f"pos={pos_id} (0x{pos_id:02X})"
    )

    response = ser.read(1)
    if response:
        next_token = response[0]
        print(f"Received next_token={next_token} (0x{next_token:02X})")
    else:
        print("Timeout: no response from FPGA.")

ser.close()
print("UART closed.")
