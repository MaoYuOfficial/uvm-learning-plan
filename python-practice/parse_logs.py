PASS = 0
FAIL = 0
errors = 0
warnings = 0
f = open("D:/uvm-learning-plan/python-practice/test_fail.log","r",encoding="utf-8",errors="ignore")
for line in f:
    if "PASS:" in line:
        PASS = PASS + 1

    if "FAIL:" in line:
        FAIL = FAIL + 1

    if "Errors:" in line:
        words = line.split()
        errors = words[2].rstrip(",")
        warnings = words[4]

    print(line.rstrip())

if(PASS + FAIL == 0):
    print("PASS =" ,PASS, "FAIL =" ,FAIL,"通过率=没有检查行，不计算通过率","Errors =", errors,"Warnings =", warnings)
else:
    print("PASS =" ,PASS, "FAIL =" ,FAIL,"通过率 =", PASS / (PASS + FAIL),"Errors =", errors,"Warnings =", warnings)

f.close()