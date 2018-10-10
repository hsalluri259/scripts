#!/opt/app/python3/bin/python3.4
'''
Ask the user for a number. Depending on whether the number is even or odd, print out an appropriate message to the user. Hint: how does an even / odd number react differently when divided by 2?

Extras:

    If the number is a multiple of 4, print out a different message.
    Ask the user for two numbers: one number to check (call it num) and one number to divide by (check). If check divides evenly into num, tell that to the user. If not, print a different appropriate message.
'''
number = int(input("Enter a number:"))
if number % 2 == 0 and number % 4 == 0:
    print("%d is divided by 4" % number)
elif number % 2 == 0:
    print("%d is just Even" % number)
else:
    print("%d is Odd" % number)

num1 = int(input("Enter number1:"))
num2 = int(input("Enter number2:"))
if num1 % num2 == 0:
    print("%d is evenly divided by %d" % (num1,num2))
else:
    print("%d is not divided by %d" % (num1,num2))
