import re

html = open('/tmp/bb.html').read()
text = re.sub(r'<[^>]+>', ' ', html)
text = re.sub(r'\s+', ' ', text)

# Find relevant sentences
keywords = ['contact', 'email', 'bounty', 'report', 'disclose', 'researcher',
            'account', 'test account', 'register', 'trial', 'signup', 'platform']

sentences = re.split(r'[.!?]', text)
for s in sentences:
    s = s.strip()
    if len(s) > 20 and any(k in s.lower() for k in keywords):
        print(s[:300])
        print()
