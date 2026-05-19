import re, glob

# Search all chunks for p0 definition and register endpoint
for fname in sorted(glob.glob('/tmp/chunk-*.js') + ['/tmp/main.js']):
    data = open(fname).read()

    # Look for p0 = something (base URL)
    p0_matches = re.findall(r'(?<![a-zA-Z])p0\s*=\s*["\']([^"\']{3,})["\']', data)
    if p0_matches:
        print(f"\n[{fname}] p0 =")
        for m in p0_matches[:3]:
            print(f"  {m}")

    # window.location or origin based
    origin_matches = re.findall(r'.{0,40}p0.{0,40}origin.{0,40}', data)
    if origin_matches:
        print(f"\n[{fname}] p0+origin:")
        for m in origin_matches[:2]:
            print(f"  {m[:150]}")

    # Register API calls
    reg_api = re.findall(r'.{0,60}api/register.{0,60}', data)
    if reg_api:
        print(f"\n[{fname}] /api/register:")
        for m in reg_api[:3]:
            print(f"  {m[:200]}")

    # Activation
    act = re.findall(r'.{0,60}api/activate.{0,60}', data)
    if act:
        print(f"\n[{fname}] /api/activate:")
        for m in act[:3]:
            print(f"  {m[:200]}")
