import json, sys

data = json.load(open('/tmp/crt.json'))
names = sorted(set(
    n.strip()
    for d in data
    for n in d['name_value'].split('\n')
))
for n in names:
    if 'coinpoker.com' in n and not n.startswith('*'):
        print(n)
