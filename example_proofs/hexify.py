import codecs
filename = 'example_proofs/BrightonVsManU'
with open(filename + '.proof', 'rb') as f:
    content = f.read()
print(content)
hexStr = codecs.encode(content, "hex").__str__()[2:-1]
# print(hexStr)
hexStrDel = ""
for i in range(len(hexStr)):
    if (i % 2) == 0:
        hexStrDel += r"\x"
    hexStrDel += hexStr[i]
# print(hexStrDel)
outputHEX = open(filename + '_HEX', 'w')
outputHEX.write(hexStrDel)
