import re, glob

routes = set()
for f in glob.glob('/tmp/chunk-*.js') + ['/tmp/main.js']:
    try:
        data = open(f).read()
        # Angular router path definitions
        found = re.findall(r'path:\s*["\']([^"\']{1,60})["\']', data)
        routes.update(found)
    except:
        pass

print("=== ALL ANGULAR ROUTES ===")
for r in sorted(routes):
    print(r)
