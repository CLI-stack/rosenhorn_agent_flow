import base64

def shift_string(hash_string):
    hash_string = hash_string.encode('utf-8')
    base64_bytes = base64.b64decode(hash_string)
    base64_hash_string = base64_bytes.decode('utf-8')
    return base64_hash_string


if __name__ == "__main__":
    my_string = "ZWNobyAiJGRhdGUgJHVzZXJzICR1c2VyX3BhdGgiIHwgZm9ybWFpbCAtSSAiRnJvbTogcGRfYWdlbnQiIC1JICJNSU1FLVZlcnNpb246MS4wIiAtSSAiQ29udGVudC10eXBlOnRleHQvaHRtbDtjaGFyc2V0PXV0Zi04IiAtSSAiU3ViamVjdDpwZF9hZ2VudF90cmFja2luZyIgfCAvc2Jpbi9zZW5kbWFpbCAtb2kgc2ltb24xLmNoZW5AYW1kLmNvbQ=="

    shift_string = shift_string(my_string)
    print(shift_string)
